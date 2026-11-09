//
//  LiturgicalDay.swift
//  DailyBread
//
//  Created for DailyBread.
//  Copyright © 2026 DailyBread. All rights reserved.
//

import Foundation

/// Represents the complete liturgical computation for a single calendar day in the Roman Rite,
/// containing season, cycle, rank, color, and obligation data.
public struct LiturgicalDay: Identifiable, Hashable, Codable, Sendable, CustomStringConvertible {

    // MARK: - Core Required Properties

    /// The calendar date for this liturgical day.
    public let date: Date

    /// The liturgical season of the day (Advent, Christmas, Lent, Triduum, Easter, Ordinary Time).
    public let season: LiturgicalSeason

    /// The current week number within the season (1-indexed).
    public let seasonWeek: Int

    /// The primary liturgical title for the day (e.g. "Third Sunday of Advent", "Solemnity of the Assumption").
    public let title: String

    /// The precedence rank of the day according to the Universal Norms for the Liturgical Year (Ranks 1–12).
    public let rank: LiturgicalRank

    /// The liturgical vestment color prescribed for the day's celebration.
    public let color: LiturgicalColor

    /// The Sunday lectionary cycle (Year A, B, or C).
    public let sundayCycle: SundayCycle

    /// The weekday lectionary cycle (Year I or Year II) applicable to Ordinary Time first readings.
    public let weekdayCycle: WeekdayCycle

    /// Indicates whether this calendar day is a Sunday.
    public let isSunday: Bool

    /// Indicates whether this day is a Holy Day of Obligation in the Roman Catholic Church (US calendar).
    public let isHolyDayOfObligation: Bool

    /// The day of the week within the season/liturgical week: 0 = Sunday, 1 = Monday, ..., 6 = Saturday.
    public let dayOfWeekInSeason: Int

    // MARK: - Supplementary Liturgical Details

    /// The Psalter week in the Liturgy of the Hours (Week I, II, III, or IV).
    public let psalterWeek: PsalterWeek?

    /// Secondary subtitle or feast commemoration (e.g., "Memorial of St. Elizabeth Ann Seton").
    public let celebrationSubtitle: String?

    /// Whether this day is a day of mandatory fasting and abstinence from meat (Ash Wednesday and Good Friday).
    public let isFastAndAbstinence: Bool

    /// Whether this day is a day of mandatory abstinence from meat (Fridays of Lent in the US).
    public let isAbstinence: Bool

    /// If this celebration was transferred from another date due to calendar collision, the original date.
    public let transferredFromDate: Date?

    /// Optional memorials that may be celebrated on this weekday at the priest's discretion.
    public let optionalMemorials: [String]

    // MARK: - Identifiable

    /// Unique identifier based on the formatted date `yyyy-MM-dd`.
    public var id: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    // MARK: - Initializer

    public init(
        date: Date,
        season: LiturgicalSeason,
        seasonWeek: Int,
        title: String,
        rank: LiturgicalRank,
        color: LiturgicalColor,
        sundayCycle: SundayCycle,
        weekdayCycle: WeekdayCycle,
        isSunday: Bool,
        isHolyDayOfObligation: Bool,
        dayOfWeekInSeason: Int = 0,
        psalterWeek: PsalterWeek? = nil,
        celebrationSubtitle: String? = nil,
        isFastAndAbstinence: Bool = false,
        isAbstinence: Bool = false,
        transferredFromDate: Date? = nil,
        optionalMemorials: [String] = []
    ) {
        self.date = date
        self.season = season
        self.seasonWeek = seasonWeek
        self.title = title
        self.rank = rank
        self.color = color
        self.sundayCycle = sundayCycle
        self.weekdayCycle = weekdayCycle
        self.isSunday = isSunday
        self.isHolyDayOfObligation = isHolyDayOfObligation
        self.dayOfWeekInSeason = dayOfWeekInSeason
        self.psalterWeek = psalterWeek
        self.celebrationSubtitle = celebrationSubtitle
        self.isFastAndAbstinence = isFastAndAbstinence
        self.isAbstinence = isAbstinence
        self.transferredFromDate = transferredFromDate
        self.optionalMemorials = optionalMemorials
    }

    // MARK: - Compatibility Initializer

    public init(
        date: Date,
        season: LiturgicalSeason,
        seasonWeek: Int,
        title: String,
        rank: LiturgicalRank,
        color: LiturgicalColor,
        sundayCycle: SundayCycle,
        weekdayCycle: WeekdayCycle,
        isSunday: Bool,
        isHolyDayOfObligation: Bool
    ) {
        let weekday = Calendar.current.component(.weekday, from: date)
        self.init(
            date: date,
            season: season,
            seasonWeek: seasonWeek,
            title: title,
            rank: rank,
            color: color,
            sundayCycle: sundayCycle,
            weekdayCycle: weekdayCycle,
            isSunday: isSunday,
            isHolyDayOfObligation: isHolyDayOfObligation,
            dayOfWeekInSeason: weekday - 1
        )
    }

    // MARK: - Compatibility Properties

    /// Alias for seasonWeek.
    public var weekOfSeason: Int { seasonWeek }

    /// 1-based day of week matching Gregorian Calendar (1 = Sunday ... 7 = Saturday).
    public var dayOfWeek: Int { dayOfWeekInSeason + 1 }

    /// Lowercase day of week string ("sunday", "monday", etc.).
    public var dayOfWeekName: String {
        switch dayOfWeekInSeason {
        case 0: return "sunday"
        case 1: return "monday"
        case 2: return "tuesday"
        case 3: return "wednesday"
        case 4: return "thursday"
        case 5: return "friday"
        case 6: return "saturday"
        default: return "sunday"
        }
    }

    /// Whether this day is a Solemnity.
    public var isSolemnity: Bool { rank.isSolemnity }

    /// Whether this day is a Feast.
    public var isFeast: Bool { rank.isFeast }

    /// Whether this day is a Memorial.
    public var isMemorial: Bool { rank.isMemorial }

    // MARK: - CustomStringConvertible

    public var description: String {
        "LiturgicalDay(\(id), title: \"\(title)\", season: \(season.displayName) Wk \(seasonWeek), color: \(color.displayName), rank: \(rank.rawValue))"
    }

    // MARK: - Display Helpers

    /// Formats the date in long style (e.g., "Sunday, April 5, 2026").
    public var formattedDateLong: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    /// Formats the date in medium style (e.g., "Apr 5, 2026").
    public var formattedDateMedium: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    /// Full cycle summary for display in navigation headers (e.g., "Year B • Cycle II • Week I").
    public var cycleSummary: String {
        var components: [String] = [sundayCycle.displayName]
        if season == .ordinaryTime && !isSunday {
            components.append(weekdayCycle.cycleName)
        }
        if let psalter = psalterWeek {
            components.append(psalter.displayName)
        }
        return components.joined(separator: " • ")
    }
}
