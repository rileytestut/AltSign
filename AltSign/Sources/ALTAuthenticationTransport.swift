//
//  ALTAuthenticationTransport.swift
//  AltSign
//

import Foundation

/// Coordinates GrandSlam requests, including cooldowns shared by different sign-in steps.
/// This transport is deliberately separate from developer-services requests, which can mutate accounts.
final class ALTAuthenticationTransport
{
    struct Policy
    {
        // Conservative local defaults, not documented Apple service limits.
        var minimumInterval: TimeInterval = 12
        var rateLimitDelay: TimeInterval = 60
        var retryDelay: TimeInterval = 12
        var requestBudget: TimeInterval = 120
        var maximumAttempts = 4
    }

    typealias Completion = (Data?, HTTPURLResponse?, Error?) -> Void

    private final class Request
    {
        let request: URLRequest
        let requiresPropertyList: Bool
        let retriesTransientFailures: Bool
        let deadline: TimeInterval
        let completion: Completion
        var attempts = 0
        var retryNotBefore: TimeInterval = 0
        var lastError: Error?

        init(request: URLRequest, requiresPropertyList: Bool, retriesTransientFailures: Bool,
             deadline: TimeInterval, completion: @escaping Completion)
        {
            self.request = request
            self.requiresPropertyList = requiresPropertyList
            self.retriesTransientFailures = retriesTransientFailures
            self.deadline = deadline
            self.completion = completion
        }
    }

    private let queue = DispatchQueue(label: "com.rileytestut.AltSign.authentication-transport")
    private let callbackQueue = DispatchQueue(label: "com.rileytestut.AltSign.authentication-callbacks")
    private let policy: Policy
    private let configuration: () -> URLSessionConfiguration
    private var requests = [Request]()
    private var isRunning = false
    private var nextRequestTime: TimeInterval = 0
    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    init(policy: Policy = Policy(), configuration: @escaping () -> URLSessionConfiguration = { .ephemeral })
    {
        self.policy = policy
        self.configuration = configuration
    }

    func send(_ request: URLRequest, requiresPropertyList: Bool, retriesTransientFailures: Bool,
              completion: @escaping Completion)
    {
        let pending = Request(request: request, requiresPropertyList: requiresPropertyList,
                              retriesTransientFailures: retriesTransientFailures,
                              deadline: self.now + self.policy.requestBudget, completion: completion)
        self.queue.async {
            self.requests.append(pending)
            self.startNext()
        }
    }

    private func startNext()
    {
        guard !self.isRunning, !self.requests.isEmpty else { return }
        let pending = self.requests.removeFirst()
        let delay = max(0, max(self.nextRequestTime, pending.retryNotBefore) - self.now)
        let remaining = pending.deadline - self.now
        guard remaining > delay else
        {
            let error = pending.lastError ?? NSError(domain: NSURLErrorDomain, code: URLError.timedOut.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Apple authentication could not start before its timeout while waiting for another request or a server cooldown. Please try again later."])
            self.callbackQueue.async { pending.completion(nil, nil, error) }
            self.startNext()
            return
        }

        self.isRunning = true
        self.queue.asyncAfter(deadline: .now() + delay) {
            let remaining = pending.deadline - self.now
            guard remaining > 0 else
            {
                self.finish(pending, data: nil, response: nil, error: pending.lastError ?? URLError(.timedOut))
                return
            }
            pending.attempts += 1
            var request = pending.request
            request.timeoutInterval = min(request.timeoutInterval, remaining)
            // A new ephemeral session for every attempt avoids reusing a failing pooled connection.
            let session = URLSession(configuration: self.configuration())
            session.dataTask(with: request) { data, response, error in
                session.finishTasksAndInvalidate()
                self.queue.async {
                    self.received(pending, data: data, response: response as? HTTPURLResponse, error: error)
                }
            }.resume()
        }
    }

    private func received(_ pending: Request, data: Data?, response: HTTPURLResponse?, error: Error?)
    {
        let status = response?.statusCode ?? 0
        let retryAfter = Self.retryAfter(response?.value(forHTTPHeaderField: "Retry-After"))
        let isHTTPTransient = [429, 500, 502, 503, 504].contains(status)
        let networkError = error as? URLError
        let isNetworkTransient = networkError.map {
            [.timedOut, .networkConnectionLost, .cannotConnectToHost].contains($0.code)
        } ?? false

        var cooldown = self.policy.minimumInterval
        if status == 429 { cooldown = max(cooldown, self.policy.rateLimitDelay) }
        if isHTTPTransient, let retryAfter = retryAfter { cooldown = max(cooldown, retryAfter) }
        self.nextRequestTime = self.now + cooldown

        guard self.now < pending.deadline else
        {
            self.finish(pending, data: data, response: response, error: error ?? URLError(.timedOut))
            return
        }

        let dictionary = data.flatMap { try? PropertyListSerialization.propertyList(from: $0, format: nil) } as? [String: Any]
        let isSuccessfulHTTP = (200..<300).contains(status)
        // Preserve structured Apple service errors for the existing SRP/2FA error mapping.
        // A generic plist on a 5xx response must not be mistaken for successful authentication.
        let serviceStatus = (dictionary?["Response"] as? [String: Any])?["Status"] as? [String: Any]
        let serviceError = (serviceStatus?["ec"] as? Int) ?? (dictionary?["ec"] as? Int) ?? 0
        if error == nil,
           (isSuccessfulHTTP && (!pending.requiresPropertyList || dictionary != nil)
            || pending.requiresPropertyList && serviceError != 0)
        {
            self.finish(pending, data: data, response: response, error: nil)
            return
        }

        let responseError = error ?? Self.httpError(status: status, retryAfter: status == 429 ? cooldown : retryAfter)
        if pending.retriesTransientFailures, (isHTTPTransient || isNetworkTransient),
           pending.attempts < self.policy.maximumAttempts
        {
            let baseDelay = status == 429 ? self.policy.rateLimitDelay : self.policy.retryDelay
            let delay = max(cooldown, baseDelay * pow(2, Double(pending.attempts - 1)))
            pending.lastError = responseError
            pending.retryNotBefore = self.now + delay
            self.requests.insert(pending, at: 0)
            self.isRunning = false
            self.startNext()
            return
        }
        self.finish(pending, data: data, response: response, error: responseError)
    }

    private func finish(_ pending: Request, data: Data?, response: HTTPURLResponse?, error: Error?)
    {
        self.isRunning = false
        self.callbackQueue.async { pending.completion(data, response, error) }
        self.startNext()
    }

    static func retryAfter(_ value: String?, now: Date = Date()) -> TimeInterval?
    {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        if let seconds = Double(value), seconds.isFinite, seconds >= 0 { return seconds }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: value).map { max(0, $0.timeIntervalSince(now)) }
    }

    private static func httpError(status: Int, retryAfter: TimeInterval?) -> NSError
    {
        var description = "Apple authentication returned HTTP \(status) without a successful response."
        var userInfo: [String: Any] = ["ALTAuthenticationHTTPStatus": status]
        if let retryAfter = retryAfter
        {
            userInfo["ALTAuthenticationRetryAfter"] = retryAfter
            description += " Try again in at least \(String(format: "%.0f", ceil(retryAfter))) seconds."
        }
        // Never include the URL query, headers, request body, or response body in diagnostics.
        userInfo[NSLocalizedDescriptionKey] = description
        return NSError(domain: NSURLErrorDomain, code: URLError.badServerResponse.rawValue, userInfo: userInfo)
    }
}
