//
//  LiturgicalCycle.swift
//  DailyReadings
//
//  Created for DailyReadings.
//  Copyright © 2026 DailyReadings. All rights reserved.
//

import Foundation

// MARK: - Sunday Lectionary Cycle (Three-Year Cycle)

/// The three-year lectionary cycle used for Sunday Mass readings in the Roman Rite.
///
/// Established by Pope St. Paul VI in 1969, each year focuses on one of the Synoptic Gospels:
/// - Year A: Gospel of Saint Matthew
/// - Year B: Gospel of Saint Mark (with John 6 during summer Ordinary Time)
/// - Year C: Gospel of Saint Luke
/// (The Gospel of Saint John is proclaimed during Lent and Easter in all three years).
///
/// **Formula:** The liturgical year begins on the First Sunday of Advent (November/December).
/// If `liturgicalYear % 3 == 1`, it is **Year A**.
/// If `liturgicalYear % 3 == 2`, it is **Year B**.
/// If `liturgicalYear % 3 == 0`, it is **Year C**.
public enum SundayCycle: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    /// Year A: Features the Gospel of Saint Matthew.
    case yearA

    /// Year B: Features the Gospel of Saint Mark (supplemented by John 6).
    case yearB

    /// Year C: Features the Gospel of Saint Luke.
    case yearC

    public var id: String {
        rawValue
    }

    /// English display name (e.g. "Year A").
    public var displayName: String {
        switch self {
        case .yearA:
            return "Year A"
        case .yearB:
            return "Year B"
        case .yearC:
            return "Year C"
        }
    }

    /// The principal evangelist featured in this Sunday cycle.
    public var primaryEvangelist: String {
        switch self {
        case .yearA:
            return "Saint Matthew"
        case .yearB:
            return "Saint Mark"
        case .yearC:
            return "Saint Luke"
        }
    }

    /// Devotional description of the Sunday cycle.
    public var description: String {
        switch self {
        case .yearA:
            return "Readings centered on the Gospel of Matthew, emphasizing Jesus as the fulfillment of Old Testament prophecy."
        case .yearB:
            return "Readings centered on the Gospel of Mark, presenting Jesus as the suffering Servant and Son of God, with the Bread of Life discourse from John."
        case .yearC:
            return "Readings centered on the Gospel of Luke, highlighting Christ's mercy, compassion, prayer, and the Holy Spirit."
        }
    }

    /// Determines the `SundayCycle` for a given liturgical year integer.
    ///
    /// - Parameter liturgicalYear: The year number for the liturgical year (e.g. 2024 for 2023–2024).
    /// - Returns: The corresponding `SundayCycle`.
    public static func forLiturgicalYear(_ liturgicalYear: Int) -> SundayCycle {
        let remainder = ((liturgicalYear % 3) + 3) % 3
        switch remainder {
        case 1:
            return .yearA
        case 2:
            return .yearB
        case 0:
            return .yearC
        default:
            return .yearA
        }
    }

    /// The subsequent Sunday cycle in rotation.
    public var next: SundayCycle {
        switch self {
        case .yearA: return .yearB
        case .yearB: return .yearC
        case .yearC: return .yearA
        }
    }

    // MARK: - Compatibility Aliases

    public static let A: SundayCycle = .yearA
    public static let B: SundayCycle = .yearB
    public static let C: SundayCycle = .yearC
}

// MARK: - Weekday Lectionary Cycle (Two-Year Cycle)

/// The two-year lectionary cycle used for weekday First Readings during Ordinary Time.
///
/// - Year I (Cycle I): Proclaimed in odd-numbered calendar years (e.g., 2023, 2025, 2027).
/// - Year II (Cycle II): Proclaimed in even-numbered calendar years (e.g., 2024, 2026, 2028).
///
/// **Note:** This cycle applies exclusively to the first reading of weekday Masses in Ordinary Time.
/// The Gospel readings remain the same each year, and other liturgical seasons have proper seasonal readings.
public enum WeekdayCycle: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    /// Year I (Cycle I): Odd calendar years.
    case yearI

    /// Year II (Cycle II): Even calendar years.
    case yearII

    public var id: String {
        rawValue
    }

    /// English display name (e.g. "Year I").
    public var displayName: String {
        switch self {
        case .yearI:
            return "Year I"
        case .yearII:
            return "Year II"
        }
    }

    /// Roman numeral / canonical cycle name (e.g. "Cycle I").
    public var cycleName: String {
        switch self {
        case .yearI:
            return "Cycle I"
        case .yearII:
            return "Cycle II"
        }
    }

    /// Determines the `WeekdayCycle` for a given civil calendar year.
    ///
    /// - Parameter calendarYear: The civil year (e.g. 2026).
    /// - Returns: `.yearI` if odd; `.yearII` if even.
    public static func forCalendarYear(_ calendarYear: Int) -> WeekdayCycle {
        (calendarYear % 2 != 0) ? .yearI : .yearII
    }

    /// The alternating weekday cycle.
    public var next: WeekdayCycle {
        switch self {
        case .yearI: return .yearII
        case .yearII: return .yearI
        }
    }

    // MARK: - Compatibility Aliases

    public static let I: WeekdayCycle = .yearI
    public static let II: WeekdayCycle = .yearII
}

// MARK: - Psalter Week (Four-Week Cycle of the Divine Office)

/// The four-week psalter cycle of the Liturgy of the Hours (Divine Office).
///
/// Through this four-week cycle, the Church distributes the recitation of the 150 psalms,
/// canticles, and daily prayers of the Breviary across the month.
public enum PsalterWeek: Int, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    case week1 = 1
    case week2 = 2
    case week3 = 3
    case week4 = 4

    public var id: Int {
        rawValue
    }

    /// English display title (e.g. "Week I").
    public var displayName: String {
        switch self {
        case .week1:
            return "Week I"
        case .week2:
            return "Week II"
        case .week3:
            return "Week III"
        case .week4:
            return "Week IV"
        }
    }

    /// Description of the psalter week in the Liturgy of the Hours.
    public var fullTitle: String {
        "Psalter Week \(displayName)"
    }

    /// The subsequent week in the four-week cycle.
    public var next: PsalterWeek {
        switch self {
        case .week1: return .week2
        case .week2: return .week3
        case .week3: return .week4
        case .week4: return .week1
        }
    }

    /// Resolves the Psalter week for a given liturgical season and season week number.
    ///
    /// - Parameters:
    ///   - season: The liturgical season.
    ///   - seasonWeek: The week number within that season (1-indexed).
    /// - Returns: The corresponding `PsalterWeek`.
    public static func forSeason(_ season: LiturgicalSeason, seasonWeek: Int) -> PsalterWeek {
        let index = max(1, seasonWeek)
        switch season {
        case .advent:
            // Advent 1 = Week I, Advent 2 = Week II, Advent 3 = Week III, Advent 4 = Week IV
            let val = ((index - 1) % 4) + 1
            return PsalterWeek(rawValue: val) ?? .week1

        case .christmas:
            // Christmas octave and time uses proper seasonal office; default to Week I
            return .week1

        case .lent:
            // Lent 1 = Week I, Lent 2 = Week II, Lent 3 = Week III, Lent 4 = Week IV, Lent 5 = Week I, Holy Week = Week II
            if index == 6 { return .week2 }
            let val = ((index - 1) % 4) + 1
            return PsalterWeek(rawValue: val) ?? .week1

        case .paschalTriduum:
            return .week1

        case .easter:
            // Easter Octave has proper office.
            // 2nd Sunday of Easter begins Week I, 3rd Sunday = Week II, 4th = Week III, 5th = Week IV, 6th = Week I, 7th = Week II
            if index <= 1 { return .week1 }
            let offset = (index - 2) % 4
            return PsalterWeek(rawValue: offset + 1) ?? .week1

        case .ordinaryTime:
            // Ordinary Time Week N maps directly to ((N - 1) % 4) + 1
            let val = ((index - 1) % 4) + 1
            return PsalterWeek(rawValue: val) ?? .week1
        }
    }
}
