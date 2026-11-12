//
//  VerseOfTheDay.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Represents the liturgical Verse of the Day for personal prayer and meditation.
public struct VerseOfTheDay: Identifiable, Hashable, Sendable {
    public let id: UUID
    /// The scripture verse text.
    public let text: String
    /// The biblical passage citation (e.g., "John 15:5" or "Psalms 37:3").
    public let citation: String
    /// An optional thematic title or invitation (e.g., "Christ the True Vine" or "Trust & Peace").
    public let theme: String?
    /// The liturgical context or reading source (e.g., "From Today's Gospel" or "Responsorial Refrain").
    public let sourceNote: String
    
    public init(
        id: UUID = UUID(),
        text: String,
        citation: String,
        theme: String? = nil,
        sourceNote: String = "From Today's Readings"
    ) {
        self.id = id
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.citation = citation.trimmingCharacters(in: .whitespacesAndNewlines)
        self.theme = theme
        self.sourceNote = sourceNote
    }
}
