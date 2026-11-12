//
//  Prayer.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Primary category grouping for traditional Catholic prayers.
public enum PrayerCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case all = "All"
    case daily = "Daily Rhythm"
    case foundational = "Foundational"
    case marian = "Marian"
    case rosary = "Holy Rosary"
    case saints = "Saints & Protection"
    case devotions = "Devotions"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .all: return "sparkles"
        case .daily: return "sun.and.horizon.fill"
        case .foundational: return "cross.fill"
        case .marian: return "heart.fill"
        case .rosary: return "circle.grid.cross.fill"
        case .saints: return "shield.fill"
        case .devotions: return "flame.fill"
        }
    }
}

/// A Catholic prayer item with English and optional traditional Latin text.
public struct Prayer: Identifiable, Hashable, Sendable {
    public let id: String
    /// The English title (e.g., "Our Father", "The Angelus", "Prayer to St. Michael").
    public let title: String
    /// Optional traditional Latin title (e.g., "Pater Noster", "Angelus Domini", "Sancte Michael").
    public let latinTitle: String?
    /// The primary devotional category.
    public let category: PrayerCategory
    /// The English prayer text.
    public let textEnglish: String
    /// Optional Latin prayer text.
    public let textLatin: String?
    /// Traditional attribution, author, or liturgical source.
    public let source: String?
    /// Liturgical note, indulgenced rubric, or traditional time of prayer.
    public let rubricNote: String?
    /// Indicates whether this prayer has specialized step-by-step decade guide (e.g. The Rosary).
    public let isRosaryGuide: Bool
    
    public init(
        id: String,
        title: String,
        latinTitle: String? = nil,
        category: PrayerCategory,
        textEnglish: String,
        textLatin: String? = nil,
        source: String? = nil,
        rubricNote: String? = nil,
        isRosaryGuide: Bool = false
    ) {
        self.id = id
        self.title = title
        self.latinTitle = latinTitle
        self.category = category
        self.textEnglish = textEnglish.trimmingCharacters(in: .whitespacesAndNewlines)
        self.textLatin = textLatin?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.source = source
        self.rubricNote = rubricNote
        self.isRosaryGuide = isRosaryGuide
    }
    
    /// Returns true if this prayer includes traditional Latin text.
    public var hasLatin: Bool {
        guard let textLatin else { return false }
        return !textLatin.isEmpty
    }
}
