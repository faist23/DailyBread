//
//  CachedReading.swift
//  DailyBread
//
//  Created for DailyBread Catholic Daily Readings App.
//  iOS 17+ | Swift 6+ | SwiftData
//

import Foundation
import SwiftData

/// SwiftData persistent model for locally caching daily readings.
/// Provides offline persistence and avoids redundant network calls.
@Model
public final class CachedReading {
    /// Date key formatted as "YYYY-MM-DD" (e.g. "2026-11-02").
    @Attribute(.unique) public var dateKey: String
    /// Translation identifier ("NAB" or "DRB").
    public var translation: String
    /// Serialized JSON data representation of the DailyReadings object.
    public var readingsJSON: Data
    /// Timestamp when this record was fetched and stored.
    public var fetchedAt: Date
    
    /// Cached readings expire after 90 days (90 * 86,400 seconds).
    public var isExpired: Bool {
        Date().timeIntervalSince(fetchedAt) > 90 * 86400
    }
    
    /// Designated initializer.
    public init(
        dateKey: String,
        translation: String,
        readingsJSON: Data,
        fetchedAt: Date = .now
    ) {
        self.dateKey = dateKey
        self.translation = translation
        self.readingsJSON = readingsJSON
        self.fetchedAt = fetchedAt
    }
    
    // MARK: - Convenience Helpers
    
    /// Generates a standardized "YYYY-MM-DD" date key from a Date.
    public static func makeDateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    /// Decodes the underlying DailyReadings payload.
    public func decodeReadings() throws -> DailyReadings {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DailyReadings.self, from: readingsJSON)
    }
    
    /// Creates a cached reading entity directly from a DailyReadings model.
    public static func create(
        from readings: DailyReadings,
        translation: String
    ) throws -> CachedReading {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(readings)
        let key = makeDateKey(from: readings.date)
        return CachedReading(
            dateKey: key,
            translation: translation,
            readingsJSON: data,
            fetchedAt: .now
        )
    }
}
