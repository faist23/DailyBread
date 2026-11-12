//
//  GuidedRosaryStep.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Represents a single discrete step/bead in the interactive guided Holy Rosary.
public struct GuidedRosaryStep: Identifiable, Sendable {
    public let id: Int
    /// Short position description (e.g., "At the Crucifix", "Decade 1 • Bead 4 of 10").
    public let beadPosition: String
    /// The name of the prayer for this bead (e.g., "Apostles' Creed", "Our Father", "Hail Mary").
    public let prayerName: String
    /// The complete prayer text to recite on this bead.
    public let prayerText: String
    /// The current mystery title (if inside a decade).
    public let mysteryTitle: String?
    /// The spiritual fruit of the mystery.
    public let fruitOfMystery: String?
    /// Scripture passage reference for the mystery.
    public let scriptureRef: String?
    /// Decade meditation note.
    public let meditation: String?
    /// Decade number (1 through 5, or nil for introductory/concluding prayers).
    public let decadeNumber: Int?
    /// Bead index within the decade (1 through 10, or nil).
    public let beadIndex: Int?
    
    public init(
        id: Int,
        beadPosition: String,
        prayerName: String,
        prayerText: String,
        mysteryTitle: String? = nil,
        fruitOfMystery: String? = nil,
        scriptureRef: String? = nil,
        meditation: String? = nil,
        decadeNumber: Int? = nil,
        beadIndex: Int? = nil
    ) {
        self.id = id
        self.beadPosition = beadPosition
        self.prayerName = prayerName
        self.prayerText = prayerText.trimmingCharacters(in: .whitespacesAndNewlines)
        self.mysteryTitle = mysteryTitle
        self.fruitOfMystery = fruitOfMystery
        self.scriptureRef = scriptureRef
        self.meditation = meditation
        self.decadeNumber = decadeNumber
        self.beadIndex = beadIndex
    }
}
