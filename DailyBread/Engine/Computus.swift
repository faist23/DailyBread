//
//  Computus.swift
//  DailyBread
//
//  Created for DailyBread.
//  Copyright © 2026 DailyBread. All rights reserved.
//

import Foundation

/// Provides astronomical and liturgical calculations for Easter Sunday and all movable
/// feasts anchored to the Paschal cycle in the Gregorian calendar.
///
/// Implements the anonymous Gregorian algorithm published in the journal *Nature* in 1876,
/// commonly referred to as the Meeus/Jones/Butcher algorithm (or Butcher's algorithm).
/// This algorithm is exact for any Gregorian year without exception.
public struct Computus: Sendable {

    // MARK: - Core Easter Sunday Algorithm

    /// Computes the `DateComponents` for Easter Sunday in the specified Gregorian year.
    ///
    /// The calculation uses the Meeus/Jones/Butcher algorithm:
    /// - Parameter year: The Gregorian year (e.g. 2024, 2025, 2026).
    /// - Returns: A `DateComponents` containing the year, month (3 for March, 4 for April), and day.
    public static func easterSunday(year: Int) -> DateComponents {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return DateComponents(year: year, month: month, day: day)
    }

    /// Computes the `Date` for Easter Sunday in the specified Gregorian year.
    ///
    /// - Parameters:
    ///   - year: The Gregorian year.
    ///   - calendar: The `Calendar` instance to resolve the components. Defaults to a standard Gregorian calendar.
    /// - Returns: The resolved `Date` corresponding to Easter Sunday at 12:00:00 UTC to prevent timezone boundary shifts.
    public static func easterDate(year: Int, calendar: Calendar = .current) -> Date {
        var comps = easterSunday(year: year)
        comps.hour = 12
        comps.minute = 0
        comps.second = 0
        comps.timeZone = TimeZone(secondsFromGMT: 0)

        var gmtCalendar = Calendar(identifier: .gregorian)
        gmtCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return gmtCalendar.date(from: comps) ?? calendar.date(from: easterSunday(year: year))!
    }

    // MARK: - Derived Paschal Cycle Feasts

    /// Adds a given number of days to Easter Sunday of a specified year.
    ///
    /// - Parameters:
    ///   - days: The signed offset from Easter Sunday.
    ///   - year: The Gregorian year.
    /// - Returns: The resulting `Date`.
    public static func dateByAdding(days: Int, toEasterInYear year: Int) -> Date {
        let easter = easterDate(year: year)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return cal.date(byAdding: .day, value: days, to: easter)!
    }

    /// Ash Wednesday (Easter - 46 days). Marks the beginning of Lent.
    public static func ashWednesday(year: Int) -> Date {
        dateByAdding(days: -46, toEasterInYear: year)
    }

    /// Palm Sunday of the Passion of the Lord (Easter - 7 days).
    public static func palmSunday(year: Int) -> Date {
        dateByAdding(days: -7, toEasterInYear: year)
    }

    /// Holy Thursday (Easter - 3 days). Evening begins the Paschal Triduum.
    public static func holyThursday(year: Int) -> Date {
        dateByAdding(days: -3, toEasterInYear: year)
    }

    /// Friday of the Passion of the Lord / Good Friday (Easter - 2 days).
    public static func goodFriday(year: Int) -> Date {
        dateByAdding(days: -2, toEasterInYear: year)
    }

    /// Holy Saturday (Easter - 1 day).
    public static func holySaturday(year: Int) -> Date {
        dateByAdding(days: -1, toEasterInYear: year)
    }

    /// Second Sunday of Easter / Divine Mercy Sunday (Easter + 7 days).
    public static func divineMercySunday(year: Int) -> Date {
        dateByAdding(days: 7, toEasterInYear: year)
    }

    /// Ascension of the Lord on the traditional Thursday (Easter + 39 days).
    public static func ascensionThursday(year: Int) -> Date {
        dateByAdding(days: 39, toEasterInYear: year)
    }

    /// Ascension of the Lord transferred to the 7th Sunday of Easter (Easter + 42 days).
    /// Used in most dioceses in the United States.
    public static func ascensionSunday(year: Int) -> Date {
        dateByAdding(days: 42, toEasterInYear: year)
    }

    /// Pentecost Sunday (Easter + 49 days / the 50th day of the Easter season).
    public static func pentecost(year: Int) -> Date {
        dateByAdding(days: 49, toEasterInYear: year)
    }

    /// Memorial of the Blessed Virgin Mary, Mother of the Church (Monday after Pentecost, Easter + 50 days).
    public static func maryMotherOfTheChurch(year: Int) -> Date {
        dateByAdding(days: 50, toEasterInYear: year)
    }

    /// The Solemnity of the Most Holy Trinity (Sunday after Pentecost, Easter + 56 days).
    public static func trinitySunday(year: Int) -> Date {
        dateByAdding(days: 56, toEasterInYear: year)
    }

    /// The Solemnity of the Most Holy Body and Blood of Christ (Corpus Christi) transferred to Sunday (Easter + 63 days).
    /// Used in the United States and many other countries.
    public static func corpusChristiSunday(year: Int) -> Date {
        dateByAdding(days: 63, toEasterInYear: year)
    }

    /// Traditional Corpus Christi on Thursday after Trinity Sunday (Easter + 60 days).
    public static func corpusChristiThursday(year: Int) -> Date {
        dateByAdding(days: 60, toEasterInYear: year)
    }

    /// The Solemnity of the Most Sacred Heart of Jesus (19 days after Pentecost, Friday after Corpus Christi, Easter + 68 days).
    public static func sacredHeart(year: Int) -> Date {
        dateByAdding(days: 68, toEasterInYear: year)
    }

    /// The Memorial of the Immaculate Heart of the Blessed Virgin Mary (Saturday after Sacred Heart, Easter + 69 days).
    public static func immaculateHeart(year: Int) -> Date {
        dateByAdding(days: 69, toEasterInYear: year)
    }
}
