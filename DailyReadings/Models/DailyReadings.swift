//
//  DailyReadings.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Collection of all liturgical scripture readings for a specific day's Catholic Mass.
public struct DailyReadings: Identifiable, Codable, Hashable, Sendable {
    /// Unique identifier for this collection.
    public let id: UUID
    /// The calendar date for these readings.
    public let date: Date
    /// Liturgical title (e.g. "Monday of the Thirty-First Week in Ordinary Time" or "All Saints").
    public let liturgicalTitle: String
    /// The ordered array of readings for the Mass.
    public let readings: [Reading]
    /// Translation identifier (e.g. "DRB" or "NAB").
    public let translation: String
    /// Optional publisher/CCD copyright notice.
    public let copyright: String?
    
    /// Designated initializer.
    public init(
        id: UUID = UUID(),
        date: Date,
        liturgicalTitle: String,
        readings: [Reading],
        translation: String = "NAB",
        copyright: String? = nil
    ) {
        self.id = id
        self.date = date
        self.liturgicalTitle = liturgicalTitle
        self.readings = readings
        self.translation = translation
        self.copyright = copyright
    }

    /// Convenience initializer accepting a LiturgicalDay instance.
    public init(
        id: UUID = UUID(),
        date: Date,
        liturgicalDay: LiturgicalDay?,
        readings: [Reading],
        translation: String = "NAB",
        copyright: String? = nil
    ) {
        self.id = id
        self.date = date
        self.liturgicalTitle = liturgicalDay?.title ?? ""
        self.readings = readings
        self.translation = translation
        self.copyright = copyright
    }
    
    // MARK: - Liturgical Convenience Accessors
    
    /// The First Reading (usually Old Testament, or Acts during Eastertide).
    public var firstReading: Reading? {
        readings.first(where: { $0.type == .firstReading })
    }
    
    /// The Responsorial Psalm.
    public var psalm: Reading? {
        readings.first(where: { $0.type == .responsorialPsalm })
    }
    
    /// The Second Reading (Epistles / Apocalypse, present on Sundays and Solemnities).
    public var secondReading: Reading? {
        readings.first(where: { $0.type == .secondReading })
    }
    
    /// The Sequence hymn (e.g. Easter Victimae Paschali Laudes, Pentecost Veni Sancte Spiritus).
    public var sequence: Reading? {
        readings.first(where: { $0.type == .sequence })
    }
    
    /// The Gospel Acclamation (Alleluia or Lenten acclamation).
    public var gospelAcclamation: Reading? {
        readings.first(where: { $0.type == .gospelAcclamation })
    }
    
    /// The Holy Gospel.
    public var gospel: Reading? {
        readings.first(where: { $0.type == .gospel })
    }
    
    // MARK: - Formatting Helpers
    
    /// Human-readable date string (e.g. "Monday, November 2, 2026").
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case id, date, liturgicalTitle, readings, translation, copyright
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.date = try container.decode(Date.self, forKey: .date)
        self.liturgicalTitle = try container.decode(String.self, forKey: .liturgicalTitle)
        self.readings = try container.decode([Reading].self, forKey: .readings)
        self.translation = try container.decode(String.self, forKey: .translation)
        self.copyright = try container.decodeIfPresent(String.self, forKey: .copyright)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(liturgicalTitle, forKey: .liturgicalTitle)
        try container.encode(readings, forKey: .readings)
        try container.encode(translation, forKey: .translation)
        try container.encodeIfPresent(copyright, forKey: .copyright)
    }
}
