//
//  ClockSkew.swift
//  AltSign
//

import Foundation

/// Apple's authentication servers validate the anisette one-time password and the client time against their own clock,
/// and answer requests that don't line up with an opaque HTTP error (often 503). Comparing the `Date` header of that
/// response with the local clock lets us tell the user when their clock is the likely cause.
enum ClockSkew
{
    /// Differences smaller than this are ordinary network latency or normal drift.
    static let threshold: TimeInterval = 60
    
    /// Parses the `Date` header of an HTTP response (RFC 9110 "IMF-fixdate", e.g. "Tue, 03 Nov 2026 07:00:00 GMT").
    static func serverDate(fromHeader header: String?) -> Date?
    {
        guard let header = header?.trimmingCharacters(in: .whitespaces), !header.isEmpty else { return nil }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: header)
    }
    
    /// Seconds the local clock is behind the server (positive) or ahead of it (negative), or `nil` without a valid `Date` header.
    static func offset(serverDateHeader header: String?, localDate: Date = Date()) -> TimeInterval?
    {
        guard let serverDate = serverDate(fromHeader: header) else { return nil }
        return serverDate.timeIntervalSince(localDate)
    }
    
    /// A recovery suggestion when the local clock is far enough from the server's to be the likely problem; `nil` otherwise.
    static func recoverySuggestion(serverDateHeader header: String?, localDate: Date = Date()) -> String?
    {
        guard let offset = offset(serverDateHeader: header, localDate: localDate), abs(offset) >= threshold else { return nil }
        
        let minutes = max(1, Int((abs(offset) / 60).rounded()))
        let format = offset > 0 ?
            NSLocalizedString("The clock on this device is about %d min behind Apple's servers, which can make Apple reject the request. Set the date and time automatically in System Settings (turn it off and on again to force a resync), then try again.", comment: "") :
            NSLocalizedString("The clock on this device is about %d min ahead of Apple's servers, which can make Apple reject the request. Set the date and time automatically in System Settings (turn it off and on again to force a resync), then try again.", comment: "")
        return String(format: format, minutes)
    }
}
