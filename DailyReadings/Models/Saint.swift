//
//  Saint.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Model representing a Catholic saint or blessed commemorated on the liturgical calendar.
public struct Saint: Codable, Identifiable, Hashable, Sendable {
    /// Unique identifier for the saint (e.g. "augustine_of_hippo").
    public let id: String
    /// The canonical or popular name (e.g. "St. Augustine of Hippo").
    public let name: String
    /// The liturgical feast date formatted as "MM-DD" (e.g. "08-28").
    public let feastDate: String
    /// Liturgical or ecclesiastical title (e.g. "Bishop and Doctor of the Church", "Virgin and Martyr").
    public let title: String?
    /// Historical era (e.g. "Early Church (354-430 AD)", "13th Century").
    public let era: String?
    /// Comprehensive biography and spiritual legacy.
    public let biography: String
    /// Array of patronage causes, groups, or places (e.g. ["Theologians", "Printers", "Brewers"]).
    public let patronages: [String]?
    /// Optional remote or asset URL for the saint's icon or portrait.
    public let imageURL: String?
    
    /// Designated initializer.
    public init(
        id: String,
        name: String,
        feastDate: String,
        title: String? = nil,
        era: String? = nil,
        biography: String,
        patronages: [String]? = nil,
        imageURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.feastDate = feastDate
        self.title = title
        self.era = era
        self.biography = biography
        self.patronages = patronages
        self.imageURL = imageURL
    }

    /// Convenience initializer accepting UUID id and default feastDate.
    public init(
        id: UUID = UUID(),
        name: String,
        feastDate: String = "",
        title: String? = nil,
        era: String? = nil,
        biography: String,
        patronages: [String]? = nil,
        imageURL: String? = nil
    ) {
        self.id = id.uuidString
        self.name = name
        self.feastDate = feastDate
        self.title = title
        self.era = era
        self.biography = biography
        self.patronages = patronages
        self.imageURL = imageURL
    }
    
    // MARK: - Convenience Helpers
    
    /// Composed display subtitle combining title and era.
    public var displaySubtitle: String {
        switch (title, era) {
        case let (t?, e?):
            return "\(t) • \(e)"
        case let (t?, nil):
            return t
        case let (nil, e?):
            return e
        case (nil, nil):
            return ""
        }
    }
    
    /// Comma-separated string of patronages (e.g. "Theologians, Printers").
    public var formattedPatronages: String? {
        guard let patronages, !patronages.isEmpty else { return nil }
        return patronages.joined(separator: ", ")
    }
}
