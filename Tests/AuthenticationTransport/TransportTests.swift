import Foundation
import XCTest
@testable import AuthenticationTransport

private final class StubProtocol: URLProtocol
{
    struct Reply
    {
        var status = 200
        var headers: [String: String] = [:]
        var body = Data()
        var error: Error?
        var delay: TimeInterval = 0
    }
    private static let lock = NSLock()
    private static var replies = [Reply]()
    private static var starts = [TimeInterval]()
    private static var active = 0
    private static var maximumActive = 0
    private static var configurations = 0

    static func reset(_ values: [Reply])
    {
        lock.lock(); defer { lock.unlock() }
        replies = values; starts = []; active = 0; maximumActive = 0; configurations = 0
    }
    static func configuration() -> URLSessionConfiguration
    {
        lock.lock(); configurations += 1; lock.unlock()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubProtocol.self]
        return configuration
    }
    static var snapshot: (starts: [TimeInterval], maximumActive: Int, configurations: Int)
    {
        lock.lock(); defer { lock.unlock() }
        return (starts, maximumActive, configurations)
    }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading()
    {
        Self.lock.lock()
        guard !Self.replies.isEmpty else
        {
            Self.lock.unlock()
            XCTFail("Unexpected request")
            self.client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let reply = Self.replies.removeFirst()
        Self.starts.append(ProcessInfo.processInfo.systemUptime)
        Self.active += 1
        Self.maximumActive = max(Self.maximumActive, Self.active)
        Self.lock.unlock()
        DispatchQueue.global().asyncAfter(deadline: .now() + reply.delay) {
            Self.lock.lock(); Self.active -= 1; Self.lock.unlock()
            if let error = reply.error
            {
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            let response = HTTPURLResponse(url: self.request.url!, statusCode: reply.status, httpVersion: "HTTP/1.1", headerFields: reply.headers)!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: reply.body)
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
    override func stopLoading() {}
}

final class TransportTests: XCTestCase
{
    private let request = URLRequest(url: URL(string: "https://authentication.invalid/test")!)
    private var plist: Data { try! PropertyListSerialization.data(fromPropertyList: ["ok": true], format: .xml, options: 0) }
    private func transport(budget: TimeInterval = 2, attempts: Int = 4) -> ALTAuthenticationTransport
    {
        let policy = ALTAuthenticationTransport.Policy(minimumInterval: 0.02, rateLimitDelay: 0.04,
                                                       retryDelay: 0.02, requestBudget: budget, maximumAttempts: attempts)
        return ALTAuthenticationTransport(policy: policy, configuration: StubProtocol.configuration)
    }
    private func send(_ transport: ALTAuthenticationTransport, plist: Bool = true, retry: Bool = true,
                      check: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) -> XCTestExpectation
    {
        let done = expectation(description: "request completed")
        transport.send(self.request, requiresPropertyList: plist, retriesTransientFailures: retry) { data, response, error in
            check(data, response, error)
            done.fulfill()
        }
        return done
    }

    func testValidPlistSucceeds()
    {
        StubProtocol.reset([.init(body: self.plist)])
        let done = send(transport()) { data, response, error in
            XCTAssertNotNil(data); XCTAssertEqual(response?.statusCode, 200); XCTAssertNil(error)
        }
        wait(for: [done], timeout: 2)
    }

    func testHTMLAndArrayAreRejectedWithoutRetry()
    {
        let array = try! PropertyListSerialization.data(fromPropertyList: [1, 2], format: .xml, options: 0)
        StubProtocol.reset([.init(body: Data("<html>SECRET_RESPONSE</html>".utf8)), .init(body: array)])
        let transport = transport()
        let done = (0..<2).map { _ in send(transport) { _, _, error in
            XCTAssertNotNil(error); XCTAssertFalse(error!.localizedDescription.contains("SECRET_RESPONSE"))
        } }
        wait(for: done, timeout: 2)
        XCTAssertEqual(StubProtocol.snapshot.starts.count, 2)
    }

    func testStructuredAppleErrorIsPreserved()
    {
        let data = try! PropertyListSerialization.data(fromPropertyList: ["Response": ["Status": ["ec": -20101, "em": "Invalid credentials"]]], format: .xml, options: 0)
        StubProtocol.reset([.init(status: 401, body: data)])
        let done = send(transport()) { received, response, error in
            XCTAssertEqual(received, data); XCTAssertEqual(response?.statusCode, 401); XCTAssertNil(error)
        }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(StubProtocol.snapshot.starts.count, 1)
    }

    func testTransientPlistResponseIsNotTreatedAsSuccess()
    {
        StubProtocol.reset([.init(status: 503, body: self.plist), .init(body: self.plist)])
        let done = send(transport()) { _, response, error in XCTAssertNil(error); XCTAssertEqual(response?.statusCode, 200) }
        wait(for: [done], timeout: 2)
        let snapshot = StubProtocol.snapshot
        XCTAssertEqual(snapshot.starts.count, 2)
        XCTAssertEqual(snapshot.configurations, 2, "Each attempt creates its own session configuration")
        XCTAssertGreaterThanOrEqual(snapshot.starts[1] - snapshot.starts[0], 0.02)
    }

    func testRetryLimitAndCancellation()
    {
        StubProtocol.reset(Array(repeating: .init(status: 503), count: 3))
        let done = send(transport(attempts: 3)) { _, _, error in XCTAssertNotNil(error) }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(StubProtocol.snapshot.starts.count, 3)
        StubProtocol.reset([.init(error: URLError(.cancelled))])
        let cancelled = send(transport()) { _, _, error in XCTAssertEqual((error as NSError?)?.code, URLError.cancelled.rawValue) }
        wait(for: [cancelled], timeout: 2)
        XCTAssertEqual(StubProtocol.snapshot.starts.count, 1)
    }

    func testNetworkFailureCanRetry()
    {
        StubProtocol.reset([.init(error: URLError(.networkConnectionLost)), .init(body: self.plist)])
        let done = send(transport()) { _, _, error in XCTAssertNil(error) }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(StubProtocol.snapshot.starts.count, 2)
    }

    func testPermanentHTTPFailureIsNotRetried()
    {
        StubProtocol.reset([.init(status: 403, body: self.plist)])
        let done = send(transport()) { _, _, error in XCTAssertEqual((error as NSError?)?.userInfo["ALTAuthenticationHTTPStatus"] as? Int, 403) }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(StubProtocol.snapshot.starts.count, 1)
    }

    func testCodeDeliveryRejectsHTTPErrorWithoutReplay()
    {
        StubProtocol.reset([.init(status: 429, body: self.plist)])
        let done = send(transport(), plist: false, retry: false) { _, _, error in XCTAssertNotNil(error) }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(StubProtocol.snapshot.starts.count, 1)
    }

    func testEmptySuccessfulCodeDeliveryIsAllowed()
    {
        StubProtocol.reset([.init(status: 200)])
        let done = send(transport(), plist: false, retry: false) { _, _, error in XCTAssertNil(error) }
        wait(for: [done], timeout: 2)
    }

    func testCooldownAffectsAlreadyQueuedRequests()
    {
        StubProtocol.reset([.init(status: 429, headers: ["Retry-After": "0.12"]), .init(body: self.plist)])
        let transport = transport()
        let first = send(transport, retry: false) { _, _, error in XCTAssertNotNil(error) }
        let second = send(transport) { _, _, error in XCTAssertNil(error) }
        wait(for: [first, second], timeout: 2)
        let starts = StubProtocol.snapshot.starts
        XCTAssertEqual(starts.count, 2)
        XCTAssertGreaterThanOrEqual(starts[1] - starts[0], 0.12)
    }

    func testLongCooldownFailsBudgetWithoutSendingEarly()
    {
        StubProtocol.reset([.init(status: 429, headers: ["Retry-After": "300"])])
        let transport = transport(budget: 0.2)
        let first = send(transport) { _, _, error in
            XCTAssertEqual((error as NSError?)?.userInfo["ALTAuthenticationRetryAfter"] as? Double, 300)
        }
        let second = send(transport) { _, _, error in
            XCTAssertEqual((error as NSError?)?.code, URLError.timedOut.rawValue)
            XCTAssertNil((error as NSError?)?.userInfo["ALTAuthenticationHTTPStatus"], "A queued request has not received an HTTP response")
        }
        wait(for: [first, second], timeout: 1)
        XCTAssertEqual(StubProtocol.snapshot.starts.count, 1)
    }

    func testVeryLargeRetryAfterDoesNotOverflowOrSendEarly()
    {
        StubProtocol.reset([.init(status: 429, headers: ["Retry-After": "1e300"])])
        let done = send(transport(budget: 0.2)) { _, _, error in XCTAssertNotNil(error) }
        wait(for: [done], timeout: 1)
        XCTAssertEqual(StubProtocol.snapshot.starts.count, 1)
    }

    func testRequestsWaitForCompletionAndDoNotOverlap()
    {
        StubProtocol.reset([.init(body: self.plist, delay: 0.1), .init(body: self.plist)])
        let transport = transport()
        let first = send(transport) { _, _, error in XCTAssertNil(error) }
        let second = send(transport) { _, _, error in XCTAssertNil(error) }
        wait(for: [first, second], timeout: 2)
        let snapshot = StubProtocol.snapshot
        XCTAssertEqual(snapshot.maximumActive, 1)
        XCTAssertGreaterThanOrEqual(snapshot.starts[1] - snapshot.starts[0], 0.12)
    }

    func testRetryAfterParsing()
    {
        XCTAssertEqual(ALTAuthenticationTransport.retryAfter(" 60 "), 60)
        XCTAssertNil(ALTAuthenticationTransport.retryAfter("-2"))
        XCTAssertNil(ALTAuthenticationTransport.retryAfter("nan"))
        XCTAssertNil(ALTAuthenticationTransport.retryAfter("infinity"))
        XCTAssertNil(ALTAuthenticationTransport.retryAfter("invalid"))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        XCTAssertEqual(ALTAuthenticationTransport.retryAfter(formatter.string(from: now.addingTimeInterval(90)), now: now), 90)
        XCTAssertEqual(ALTAuthenticationTransport.retryAfter(formatter.string(from: now.addingTimeInterval(-90)), now: now), 0)
    }

    func testLateResponseDoesNotExtendRequestBudget()
    {
        StubProtocol.reset([.init(body: self.plist, delay: 0.12)])
        let done = send(transport(budget: 0.05)) { _, _, error in
            XCTAssertEqual((error as NSError?)?.code, URLError.timedOut.rawValue)
        }
        wait(for: [done], timeout: 1)
        XCTAssertEqual(StubProtocol.snapshot.starts.count, 1)
    }
}
