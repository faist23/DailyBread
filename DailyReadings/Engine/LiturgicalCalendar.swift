//
//  LiturgicalCalendar.swift
//  DailyReadings
//
//  Created for DailyReadings.
//  Copyright © 2026 DailyReadings. All rights reserved.
//

import Foundation

/// The core liturgical computation engine for the DailyReadings app.
///
/// Computes the liturgical day, season, week, rank, vestment color, lectionary cycle,
/// psalter week, and holy days of obligation for any given date in the Gregorian calendar.
///
/// Strictly conforms to:
/// - *Universal Norms for the Liturgical Year and the General Roman Calendar* (1969 / 2002)
/// - *General Instruction of the Roman Missal* (GIRM 3rd typical edition)
/// - *Proper Calendar for the Dioceses of the United States of America* (USCCB)
///
/// US Catholic Calendar Particulars:
/// - **Epiphany**: Transferred to the Sunday between January 2 and January 8.
/// - **Ascension**: Transferred to the Seventh Sunday of Easter (Easter + 42 days).
/// - **Corpus Christi**: Transferred to the Sunday following Trinity Sunday (Easter + 63 days).
/// - **Baptism of the Lord**: Celebrated on Sunday following Epiphany, or Monday if Epiphany is Jan 7 or 8.
/// - **Holy Days of Obligation**: Jan 1, Aug 15, and Nov 1 are abrogated when falling on Saturday or Monday.
public struct LiturgicalCalendar: Sendable {

    /// Shared singleton instance for dependency injection.
    public static let shared = LiturgicalCalendar()

    /// Public initializer.
    public init() {}

    /// Instance convenience method to compute the liturgical day for a date.
    public func liturgicalDay(for date: Date, calendar: Calendar = .current) -> LiturgicalDay {
        Self.day(for: date, calendar: calendar)
    }

    // MARK: - Primary Public Engine API

    /// Computes the complete liturgical day information for any given `Date`.
    ///
    /// - Parameters:
    ///   - date: The civil date to compute.
    ///   - calendar: The base calendar. Calculations are safely normalized to UTC noon to prevent timezone shifts.
    /// - Returns: A fully resolved `LiturgicalDay` value.
    public static func day(for date: Date, calendar: Calendar = .current) -> LiturgicalDay {
        let gmtCal = normalizedCalendar()
        let norm = normalize(date: date, calendar: calendar, gmtCal: gmtCal)
        let year = norm.year

        // 1. Compute anchor landmarks for calendar year and neighboring liturgical years
        let easter = Computus.easterDate(year: year)
        let adventStart = firstSundayOfAdvent(year: year, calendar: gmtCal)
        let prevAdventStart = firstSundayOfAdvent(year: year - 1, calendar: gmtCal)
        let nextAdventStart = firstSundayOfAdvent(year: year + 1, calendar: gmtCal)

        let epiphany = epiphanyDate(year: year, calendar: gmtCal)
        let baptism = baptismOfLordDate(year: year, calendar: gmtCal)
        let ashWednesday = Computus.ashWednesday(year: year)
        let holyThursday = Computus.holyThursday(year: year)
        let pentecost = Computus.pentecost(year: year)
        let christTheKing = christTheKingDate(year: year, calendar: gmtCal)

        // 2. Determine Liturgical Year and Lectionary Cycles
        let litYear = liturgicalYear(for: norm.normalizedDate, adventStart: adventStart, calendar: gmtCal)
        let sundayCycle = SundayCycle.forLiturgicalYear(litYear)
        let weekdayCycle = WeekdayCycle.forCalendarYear(year)
        let isSunday = (norm.weekday == 1)
        let dayOfWeekInSeason = norm.weekday - 1 // 0 = Sunday, 1 = Monday, ..., 6 = Saturday

        // 3. Compute Base Temporal Celebration (Seasons & Movable Feasts)
        let temporalDay = computeTemporalDay(
            date: norm.normalizedDate,
            year: year,
            month: norm.month,
            day: norm.day,
            weekday: norm.weekday,
            dayOfWeekInSeason: dayOfWeekInSeason,
            easter: easter,
            adventStart: adventStart,
            prevAdventStart: prevAdventStart,
            nextAdventStart: nextAdventStart,
            epiphany: epiphany,
            baptism: baptism,
            ashWednesday: ashWednesday,
            holyThursday: holyThursday,
            pentecost: pentecost,
            christTheKing: christTheKing,
            sundayCycle: sundayCycle,
            weekdayCycle: weekdayCycle,
            calendar: gmtCal
        )

        // 4. Check for Transferred Solemnities on this Date
        let transferred = FixedSolemnities.computeTransferredCelebrations(
            year: year,
            easterDate: easter,
            firstSundayOfAdvent: adventStart,
            calendar: gmtCal
        )

        let transferLandingOnToday = transferred.first { t in
            gmtCal.isDate(t.targetDate, inSameDayAs: norm.normalizedDate)
        }

        // 5. Check for Fixed Sanctoral Celebrations on this (month, day)
        let key = FixedSolemnities.CelebrationKey(month: norm.month, day: norm.day)
        let fixedCandidates = FixedSolemnities.celebrationsByMonthAndDay[key] ?? []

        // Filter out any fixed solemnity that was transferred AWAY from today to another date
        let filteredFixed = fixedCandidates.filter { candidate in
            !transferred.contains { t in
                t.originalMonth == candidate.month && t.originalDay == candidate.day
            }
        }

        // 6. Precedence Resolution (Universal Norms Table §59)
        var finalTitle = temporalDay.title
        var finalRank = temporalDay.rank
        var finalColor = temporalDay.color
        var finalSubtitle: String? = nil
        var transferredFromDate: Date? = nil
        var optionalMemorials: [String] = []

        if let transfer = transferLandingOnToday {
            // A transferred solemnity lands on this date (takes precedence over weekdays)
            finalTitle = transfer.celebration.title
            finalRank = transfer.celebration.rank
            finalColor = transfer.celebration.color
            finalSubtitle = transfer.transferReason
            var originalComps = DateComponents()
            originalComps.year = year
            originalComps.month = transfer.originalMonth
            originalComps.day = transfer.originalDay
            originalComps.hour = 12
            transferredFromDate = gmtCal.date(from: originalComps)
        } else if !filteredFixed.isEmpty {
            // Select the highest-ranking sanctoral candidate
            let sortedCandidates = filteredFixed.sorted { $0.rank < $1.rank }
            if let bestFixed = sortedCandidates.first {
                // If sanctoral candidate outranks temporal day:
                if bestFixed.rank.takesPrecedence(over: temporalDay.rank) {
                    finalTitle = bestFixed.title
                    finalRank = bestFixed.rank
                    finalColor = bestFixed.color
                    if sortedCandidates.count > 1 {
                        finalSubtitle = bestFixed.common
                    }
                } else if temporalDay.rank == .privilegedWeekday && (bestFixed.rank == .obligatoryMemorial || bestFixed.rank == .optionalMemorial) {
                    // On privileged weekdays (Dec 17-24, Lent), memorials become optional commemorations
                    optionalMemorials.append(bestFixed.title)
                    finalSubtitle = "Optional Commemoration: \(bestFixed.title)"
                } else if temporalDay.rank == .weekday && bestFixed.rank == .optionalMemorial {
                    // On ordinary weekdays, optional memorials may be celebrated
                    optionalMemorials.append(bestFixed.title)
                }
            }

            // Gather all optional memorials for reference
            for candidate in filteredFixed where candidate.rank == .optionalMemorial {
                if !optionalMemorials.contains(candidate.title) {
                    optionalMemorials.append(candidate.title)
                }
            }
        }

        // 7. Compute Holy Days of Obligation (United States Calendar)
        let isObligation = isHolyDayOfObligationInUS(
            date: norm.normalizedDate,
            month: norm.month,
            day: norm.day,
            weekday: norm.weekday,
            isSunday: isSunday,
            title: finalTitle,
            rank: finalRank,
            calendar: gmtCal
        )

        // 8. Compute Fasting and Abstinence
        let isFastAndAbstinence = isDayOfFastAndAbstinence(
            date: norm.normalizedDate,
            ashWednesday: ashWednesday,
            easter: easter,
            calendar: gmtCal
        )

        let isAbstinence = isDayOfAbstinence(
            date: norm.normalizedDate,
            season: temporalDay.season,
            weekday: norm.weekday,
            isFastAndAbstinence: isFastAndAbstinence,
            isSolemnity: finalRank.isSolemnity
        )

        // 9. Compute Psalter Week
        let psalter = PsalterWeek.forSeason(temporalDay.season, seasonWeek: temporalDay.seasonWeek)

        return LiturgicalDay(
            date: norm.normalizedDate,
            season: temporalDay.season,
            seasonWeek: temporalDay.seasonWeek,
            title: finalTitle,
            rank: finalRank,
            color: finalColor,
            sundayCycle: sundayCycle,
            weekdayCycle: weekdayCycle,
            isSunday: isSunday,
            isHolyDayOfObligation: isObligation,
            dayOfWeekInSeason: dayOfWeekInSeason,
            psalterWeek: psalter,
            celebrationSubtitle: finalSubtitle,
            isFastAndAbstinence: isFastAndAbstinence,
            isAbstinence: isAbstinence,
            transferredFromDate: transferredFromDate,
            optionalMemorials: optionalMemorials
        )
    }

    // MARK: - Calendar Queries

    /// Computes all liturgical days for a specified month.
    public static func days(forMonth month: Int, year: Int, calendar: Calendar = .current) -> [LiturgicalDay] {
        let gmtCal = normalizedCalendar()
        var comps = DateComponents(year: year, month: month, day: 1, hour: 12)
        comps.timeZone = TimeZone(secondsFromGMT: 0)
        guard let startOfMonth = gmtCal.date(from: comps),
              let range = gmtCal.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }

        return range.compactMap { dayNum in
            var dayComps = DateComponents(year: year, month: month, day: dayNum, hour: 12)
            dayComps.timeZone = TimeZone(secondsFromGMT: 0)
            guard let date = gmtCal.date(from: dayComps) else { return nil }
            return day(for: date, calendar: gmtCal)
        }
    }

    /// Computes all liturgical days for a full calendar year.
    public static func days(forYear year: Int, calendar: Calendar = .current) -> [LiturgicalDay] {
        (1...12).flatMap { days(forMonth: $0, year: year, calendar: calendar) }
    }

    // MARK: - Key Liturgical Landmarks

    /// First Sunday of Advent: The Sunday falling between November 27 and December 3 inclusive.
    /// (Equivalently, the fourth Sunday before Christmas Day).
    public static func firstSundayOfAdvent(year: Int, calendar: Calendar = .current) -> Date {
        let gmtCal = normalizedCalendar()
        for day in 27...33 {
            var m = 11
            var d = day
            if d > 30 {
                m = 12
                d -= 30
            }
            let date = FixedSolemnities.makeDate(year: year, month: m, day: d, calendar: gmtCal)
            if gmtCal.component(.weekday, from: date) == 1 {
                return date
            }
        }
        return FixedSolemnities.makeDate(year: year, month: 11, day: 27, calendar: gmtCal)
    }

    /// Epiphany of the Lord in the United States:
    /// Transferred to the Sunday occurring between January 2 and January 8.
    public static func epiphanyDate(year: Int, calendar: Calendar = .current) -> Date {
        let gmtCal = normalizedCalendar()
        for day in 2...8 {
            let date = FixedSolemnities.makeDate(year: year, month: 1, day: day, calendar: gmtCal)
            if gmtCal.component(.weekday, from: date) == 1 {
                return date
            }
        }
        return FixedSolemnities.makeDate(year: year, month: 1, day: 6, calendar: gmtCal)
    }

    /// Baptism of the Lord in the United States:
    /// - Normally celebrated on the Sunday following Epiphany.
    /// - **US Special Rule:** When Epiphany is celebrated on Sunday, January 7 or Sunday, January 8,
    ///   the Feast of the Baptism of the Lord is celebrated on the following Monday (January 8 or 9).
    public static func baptismOfLordDate(year: Int, calendar: Calendar = .current) -> Date {
        let gmtCal = normalizedCalendar()
        let epiphany = epiphanyDate(year: year, calendar: gmtCal)
        let epiphanyDay = gmtCal.component(.day, from: epiphany)

        if epiphanyDay == 7 || epiphanyDay == 8 {
            // Transferred to the immediately following Monday
            return gmtCal.date(byAdding: .day, value: 1, to: epiphany)!
        } else {
            // Celebrated on the following Sunday (7 days later)
            return gmtCal.date(byAdding: .day, value: 7, to: epiphany)!
        }
    }

    /// Solemnity of Our Lord Jesus Christ, King of the Universe:
    /// The 34th and last Sunday in Ordinary Time (the Sunday immediately preceding the First Sunday of Advent).
    public static func christTheKingDate(year: Int, calendar: Calendar = .current) -> Date {
        let gmtCal = normalizedCalendar()
        let advent = firstSundayOfAdvent(year: year, calendar: gmtCal)
        return gmtCal.date(byAdding: .day, value: -7, to: advent)!
    }

    /// Resolves the liturgical year number for a given calendar date.
    ///
    /// The liturgical year begins on the First Sunday of Advent (in late November or early December).
    /// If the date falls on or after the First Sunday of Advent of civil year Y, the liturgical year is Y + 1.
    /// Otherwise, the liturgical year is Y.
    public static func liturgicalYear(for date: Date, adventStart: Date? = nil, calendar: Calendar = .current) -> Int {
        let gmtCal = normalizedCalendar()
        let year = gmtCal.component(.year, from: date)
        let advent = adventStart ?? firstSundayOfAdvent(year: year, calendar: gmtCal)

        if date >= advent {
            return year + 1
        } else {
            return year
        }
    }

    // MARK: - Private Temporal Computation

    private struct TemporalDayComputation {
        let season: LiturgicalSeason
        let seasonWeek: Int
        let title: String
        let rank: LiturgicalRank
        let color: LiturgicalColor
    }

    private static func computeTemporalDay(
        date: Date,
        year: Int,
        month: Int,
        day: Int,
        weekday: Int,
        dayOfWeekInSeason: Int,
        easter: Date,
        adventStart: Date,
        prevAdventStart: Date,
        nextAdventStart: Date,
        epiphany: Date,
        baptism: Date,
        ashWednesday: Date,
        holyThursday: Date,
        pentecost: Date,
        christTheKing: Date,
        sundayCycle: SundayCycle,
        weekdayCycle: WeekdayCycle,
        calendar: Calendar
    ) -> TemporalDayComputation {
        let isSunday = (weekday == 1)
        let weekdayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let currentWeekdayName = weekdayNames[weekday - 1]

        // -------------------------------------------------------------
        // A. ADVENT SEASON (First Sunday of Advent through Dec 24)
        // -------------------------------------------------------------
        let christmasDay = FixedSolemnities.makeDate(year: year, month: 12, day: 25, calendar: calendar)
        if date >= adventStart && date < christmasDay {
            let daysFromAdvent = calendar.dateComponents([.day], from: adventStart, to: date).day ?? 0
            let weekNumber = (daysFromAdvent / 7) + 1

            if isSunday {
                let sundayOrdinal = ["First", "Second", "Third", "Fourth"][min(max(0, weekNumber - 1), 3)]
                let isGaudete = (weekNumber == 3)
                return TemporalDayComputation(
                    season: .advent,
                    seasonWeek: weekNumber,
                    title: "\(sundayOrdinal) Sunday of Advent",
                    rank: .primarySolemnity,
                    color: isGaudete ? .rose : .violet
                )
            } else if month == 12 && day >= 17 && day <= 24 {
                // Privileged Weekdays of Advent (December 17–24)
                let monthDayFormatter = DateFormatter()
                monthDayFormatter.dateFormat = "MMMM d"
                monthDayFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                let dateStr = monthDayFormatter.string(from: date)
                return TemporalDayComputation(
                    season: .advent,
                    seasonWeek: weekNumber,
                    title: "Weekday of Advent (\(dateStr))",
                    rank: .privilegedWeekday,
                    color: .violet
                )
            } else {
                // Ordinary Weekdays of Advent (up to Dec 16)
                let weekOrdinal = ["First", "Second", "Third", "Fourth"][min(max(0, weekNumber - 1), 3)]
                return TemporalDayComputation(
                    season: .advent,
                    seasonWeek: weekNumber,
                    title: "\(currentWeekdayName) of the \(weekOrdinal) Week of Advent",
                    rank: .weekday,
                    color: .violet
                )
            }
        }

        // -------------------------------------------------------------
        // B. CHRISTMAS SEASON: Dec 25 through Feast of the Baptism
        // -------------------------------------------------------------
        // B1. Christmas Eve / Christmas Day through Dec 31
        if month == 12 && day >= 25 {
            if day == 25 {
                return TemporalDayComputation(
                    season: .christmas,
                    seasonWeek: 1,
                    title: "The Nativity of the Lord (Christmas)",
                    rank: .primarySolemnity,
                    color: .white
                )
            }

            // Check Holy Family within Christmas Octave
            // Celebrated on the Sunday between Dec 26 and Dec 31;
            // or on Friday Dec 30 if Christmas is a Sunday.
            let christmasDate = FixedSolemnities.makeDate(year: year, month: 12, day: 25, calendar: calendar)
            let christmasWeekday = calendar.component(.weekday, from: christmasDate)

            if isSunday && day >= 26 && day <= 31 {
                return TemporalDayComputation(
                    season: .christmas,
                    seasonWeek: 1,
                    title: "The Holy Family of Jesus, Mary and Joseph",
                    rank: .feastOfLord,
                    color: .white
                )
            } else if christmasWeekday == 1 && day == 30 {
                // Christmas was Sunday -> Holy Family is Friday Dec 30
                return TemporalDayComputation(
                    season: .christmas,
                    seasonWeek: 1,
                    title: "The Holy Family of Jesus, Mary and Joseph",
                    rank: .feastOfLord,
                    color: .white
                )
            }

            // Days within Octave of the Nativity (Dec 26-31)
            let octaveDayNum = day - 24
            let ordinalSuffix: String
            switch octaveDayNum {
            case 5: ordinalSuffix = "Fifth"
            case 6: ordinalSuffix = "Sixth"
            case 7: ordinalSuffix = "Seventh"
            default: ordinalSuffix = "\(octaveDayNum)th"
            }

            return TemporalDayComputation(
                season: .christmas,
                seasonWeek: 1,
                title: "\(ordinalSuffix) Day within the Octave of the Nativity of the Lord",
                rank: .privilegedWeekday,
                color: .white
            )
        }

        // B2. January: Jan 1 through Baptism of the Lord
        if month == 1 && date <= baptism {
            if day == 1 {
                return TemporalDayComputation(
                    season: .christmas,
                    seasonWeek: 1,
                    title: "Solemnity of Mary, The Holy Mother of God",
                    rank: .generalSolemnity,
                    color: .white
                )
            }

            if calendar.isDate(date, inSameDayAs: epiphany) {
                return TemporalDayComputation(
                    season: .christmas,
                    seasonWeek: 2,
                    title: "The Epiphany of the Lord",
                    rank: .primarySolemnity,
                    color: .white
                )
            }

            if calendar.isDate(date, inSameDayAs: baptism) {
                return TemporalDayComputation(
                    season: .christmas,
                    seasonWeek: 2,
                    title: "The Baptism of the Lord",
                    rank: .feastOfLord,
                    color: .white
                )
            }

            // Days before or after Epiphany
            if date < epiphany {
                return TemporalDayComputation(
                    season: .christmas,
                    seasonWeek: 2,
                    title: "\(currentWeekdayName) before Epiphany",
                    rank: .weekday,
                    color: .white
                )
            } else {
                return TemporalDayComputation(
                    season: .christmas,
                    seasonWeek: 2,
                    title: "\(currentWeekdayName) after Epiphany",
                    rank: .weekday,
                    color: .white
                )
            }
        }

        // -------------------------------------------------------------
        // C. PASCHAL TRIDUUM (Holy Thursday Evening through Easter)
        // -------------------------------------------------------------
        let goodFriday = Computus.goodFriday(year: year)
        let holySaturday = Computus.holySaturday(year: year)

        if calendar.isDate(date, inSameDayAs: holyThursday) {
            return TemporalDayComputation(
                season: .paschalTriduum,
                seasonWeek: 1,
                title: "Holy Thursday (Mass of the Lord's Supper)",
                rank: .triduum,
                color: .white
            )
        }

        if calendar.isDate(date, inSameDayAs: goodFriday) {
            return TemporalDayComputation(
                season: .paschalTriduum,
                seasonWeek: 1,
                title: "Friday of the Passion of the Lord (Good Friday)",
                rank: .triduum,
                color: .red
            )
        }

        if calendar.isDate(date, inSameDayAs: holySaturday) {
            return TemporalDayComputation(
                season: .paschalTriduum,
                seasonWeek: 1,
                title: "Holy Saturday (Easter Vigil in the Holy Night)",
                rank: .triduum,
                color: .white
            )
        }

        if calendar.isDate(date, inSameDayAs: easter) {
            return TemporalDayComputation(
                season: .paschalTriduum,
                seasonWeek: 1,
                title: "Easter Sunday of the Resurrection of the Lord",
                rank: .triduum,
                color: .white
            )
        }

        // -------------------------------------------------------------
        // D. LENT (Ash Wednesday through Holy Thursday morning)
        // -------------------------------------------------------------
        if date >= ashWednesday && date < holyThursday {
            if calendar.isDate(date, inSameDayAs: ashWednesday) {
                return TemporalDayComputation(
                    season: .lent,
                    seasonWeek: 1,
                    title: "Ash Wednesday",
                    rank: .primarySolemnity,
                    color: .violet
                )
            }

            let palmSunday = Computus.palmSunday(year: year)
            if calendar.isDate(date, inSameDayAs: palmSunday) {
                return TemporalDayComputation(
                    season: .lent,
                    seasonWeek: 6,
                    title: "Palm Sunday of the Passion of the Lord",
                    rank: .primarySolemnity,
                    color: .red
                )
            }

            if date > palmSunday {
                // Holy Week (Monday, Tuesday, Wednesday)
                return TemporalDayComputation(
                    season: .lent,
                    seasonWeek: 6,
                    title: "\(currentWeekdayName) of Holy Week",
                    rank: .primarySolemnity,
                    color: .violet
                )
            }

            // Lent Weeks 1–5
            let firstSundayOfLent = calendar.date(byAdding: .day, value: 4, to: ashWednesday)!
            if date < firstSundayOfLent {
                // Days after Ash Wednesday (Thursday, Friday, Saturday)
                return TemporalDayComputation(
                    season: .lent,
                    seasonWeek: 1,
                    title: "\(currentWeekdayName) after Ash Wednesday",
                    rank: .privilegedWeekday,
                    color: .violet
                )
            }

            let daysFromFirstSunday = calendar.dateComponents([.day], from: firstSundayOfLent, to: date).day ?? 0
            let weekNumber = (daysFromFirstSunday / 7) + 1

            if isSunday {
                let sundayOrdinal = ["First", "Second", "Third", "Fourth", "Fifth"][min(max(0, weekNumber - 1), 4)]
                let isLaetare = (weekNumber == 4)
                return TemporalDayComputation(
                    season: .lent,
                    seasonWeek: weekNumber,
                    title: "\(sundayOrdinal) Sunday of Lent",
                    rank: .primarySolemnity,
                    color: isLaetare ? .rose : .violet
                )
            } else {
                let weekOrdinal = ["First", "Second", "Third", "Fourth", "Fifth"][min(max(0, weekNumber - 1), 4)]
                return TemporalDayComputation(
                    season: .lent,
                    seasonWeek: weekNumber,
                    title: "\(currentWeekdayName) of the \(weekOrdinal) Week of Lent",
                    rank: .privilegedWeekday,
                    color: .violet
                )
            }
        }

        // -------------------------------------------------------------
        // E. EASTER SEASON (Easter Monday through Pentecost)
        // -------------------------------------------------------------
        if date > easter && date <= pentecost {
            let daysFromEaster = calendar.dateComponents([.day], from: easter, to: date).day ?? 0
            let weekNumber = (daysFromEaster / 7) + 1

            // E1. Octave of Easter (Days 1–7 after Easter)
            if daysFromEaster < 7 {
                return TemporalDayComputation(
                    season: .easter,
                    seasonWeek: 1,
                    title: "\(currentWeekdayName) in the Octave of Easter",
                    rank: .primarySolemnity,
                    color: .white
                )
            }

            let divineMercySunday = Computus.divineMercySunday(year: year)
            if calendar.isDate(date, inSameDayAs: divineMercySunday) {
                return TemporalDayComputation(
                    season: .easter,
                    seasonWeek: 2,
                    title: "Second Sunday of Easter (Sunday of Divine Mercy)",
                    rank: .primarySolemnity,
                    color: .white
                )
            }

            if calendar.isDate(date, inSameDayAs: pentecost) {
                return TemporalDayComputation(
                    season: .easter,
                    seasonWeek: 8,
                    title: "Pentecost Sunday",
                    rank: .primarySolemnity,
                    color: .red
                )
            }

            let ascensionSunday = Computus.ascensionSunday(year: year)
            if calendar.isDate(date, inSameDayAs: ascensionSunday) {
                return TemporalDayComputation(
                    season: .easter,
                    seasonWeek: 7,
                    title: "The Ascension of the Lord",
                    rank: .primarySolemnity,
                    color: .white
                )
            }

            if isSunday {
                let sundayOrdinal = ["Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh"][min(max(0, weekNumber - 2), 5)]
                return TemporalDayComputation(
                    season: .easter,
                    seasonWeek: weekNumber,
                    title: "\(sundayOrdinal) Sunday of Easter",
                    rank: .primarySolemnity,
                    color: .white
                )
            } else {
                let weekOrdinal = ["Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh"][min(max(0, weekNumber - 2), 5)]
                return TemporalDayComputation(
                    season: .easter,
                    seasonWeek: weekNumber,
                    title: "\(currentWeekdayName) of the \(weekOrdinal) Week of Easter",
                    rank: .weekday,
                    color: .white
                )
            }
        }

        // -------------------------------------------------------------
        // F. ORDINARY TIME (Part 1 and Part 2)
        // -------------------------------------------------------------
        // F1. Ordinary Time Part 1: Day after Baptism through Shrove Tuesday
        if date > baptism && date < ashWednesday {
            // Week 1 begins on Monday (or Tuesday if Baptism was Monday)
            // The Sunday following Baptism is the Second Sunday in Ordinary Time (Week 2).
            let secondSundayOT: Date
            let baptismWeekday = calendar.component(.weekday, from: baptism)
            if baptismWeekday == 1 {
                // Baptism on Sunday -> 2nd Sunday OT is 7 days later
                secondSundayOT = calendar.date(byAdding: .day, value: 7, to: baptism)!
            } else {
                // Baptism on Monday -> 2nd Sunday OT is 6 days later
                secondSundayOT = calendar.date(byAdding: .day, value: 6, to: baptism)!
            }

            let weekNumber: Int
            if date < secondSundayOT {
                weekNumber = 1
            } else {
                let daysFromSecondSunday = calendar.dateComponents([.day], from: secondSundayOT, to: date).day ?? 0
                weekNumber = (daysFromSecondSunday / 7) + 2
            }

            if isSunday {
                return TemporalDayComputation(
                    season: .ordinaryTime,
                    seasonWeek: weekNumber,
                    title: "\(ordinal(weekNumber)) Sunday in Ordinary Time",
                    rank: .sundayChristmasOrdinary,
                    color: .green
                )
            } else {
                return TemporalDayComputation(
                    season: .ordinaryTime,
                    seasonWeek: weekNumber,
                    title: "\(currentWeekdayName) of the \(ordinal(weekNumber)) Week in Ordinary Time",
                    rank: .weekday,
                    color: .green
                )
            }
        }

        // F2. Ordinary Time Part 2: Monday after Pentecost through Christ the King week
        // Key algorithm: Count backwards from Christ the King (Week 34)
        if date > pentecost && date < adventStart {
            // General Ordinary Time Part 2 calculation:
            // Find the Sunday of the current week (for Sundays, the date itself; for weekdays, the preceding Sunday).
            // Exception: The week starting Monday after Pentecost has Pentecost as its preceding Sunday.
            let precedingSundayOffset = -(weekday - 1)
            let sundayOfCurrentWeek = calendar.date(byAdding: .day, value: precedingSundayOffset, to: date)!

            let weekNumber: Int
            if sundayOfCurrentWeek >= christTheKing {
                // The week following Christ the King (Monday–Saturday before Advent)
                weekNumber = 34
            } else if calendar.isDate(sundayOfCurrentWeek, inSameDayAs: pentecost) {
                // The week between Pentecost and Trinity Sunday.
                // It precedes Trinity Sunday by 1 week.
                let trinitySunday = Computus.trinitySunday(year: year)
                let weeksBeforeCTK = calendar.dateComponents([.weekOfYear], from: trinitySunday, to: christTheKing).weekOfYear ?? 0
                weekNumber = max(1, 34 - weeksBeforeCTK - 1)
            } else {
                let weeksBeforeCTK = calendar.dateComponents([.weekOfYear], from: sundayOfCurrentWeek, to: christTheKing).weekOfYear ?? 0
                weekNumber = max(1, 34 - weeksBeforeCTK)
            }

            // Check Movable Solemnities anchored to Pentecost:
            let maryMotherOfChurch = Computus.maryMotherOfTheChurch(year: year)
            if calendar.isDate(date, inSameDayAs: maryMotherOfChurch) {
                return TemporalDayComputation(
                    season: .ordinaryTime,
                    seasonWeek: weekNumber,
                    title: "Memorial of the Blessed Virgin Mary, Mother of the Church",
                    rank: .obligatoryMemorial,
                    color: .white
                )
            }

            let trinitySunday = Computus.trinitySunday(year: year)
            if calendar.isDate(date, inSameDayAs: trinitySunday) {
                return TemporalDayComputation(
                    season: .ordinaryTime,
                    seasonWeek: weekNumber,
                    title: "The Most Holy Trinity",
                    rank: .generalSolemnity,
                    color: .white
                )
            }

            let corpusChristi = Computus.corpusChristiSunday(year: year)
            if calendar.isDate(date, inSameDayAs: corpusChristi) {
                return TemporalDayComputation(
                    season: .ordinaryTime,
                    seasonWeek: weekNumber,
                    title: "The Most Holy Body and Blood of Christ (Corpus Christi)",
                    rank: .generalSolemnity,
                    color: .white
                )
            }

            let sacredHeart = Computus.sacredHeart(year: year)
            if calendar.isDate(date, inSameDayAs: sacredHeart) {
                return TemporalDayComputation(
                    season: .ordinaryTime,
                    seasonWeek: weekNumber,
                    title: "The Most Sacred Heart of Jesus",
                    rank: .generalSolemnity,
                    color: .white
                )
            }

            let immaculateHeart = Computus.immaculateHeart(year: year)
            if calendar.isDate(date, inSameDayAs: immaculateHeart) {
                return TemporalDayComputation(
                    season: .ordinaryTime,
                    seasonWeek: weekNumber,
                    title: "The Immaculate Heart of the Blessed Virgin Mary",
                    rank: .obligatoryMemorial,
                    color: .white
                )
            }

            if calendar.isDate(date, inSameDayAs: christTheKing) {
                return TemporalDayComputation(
                    season: .ordinaryTime,
                    seasonWeek: 34,
                    title: "Our Lord Jesus Christ, King of the Universe",
                    rank: .generalSolemnity,
                    color: .white
                )
            }

            if isSunday {
                return TemporalDayComputation(
                    season: .ordinaryTime,
                    seasonWeek: weekNumber,
                    title: "\(ordinal(weekNumber)) Sunday in Ordinary Time",
                    rank: .sundayChristmasOrdinary,
                    color: .green
                )
            } else {
                return TemporalDayComputation(
                    season: .ordinaryTime,
                    seasonWeek: weekNumber,
                    title: "\(currentWeekdayName) of the \(ordinal(weekNumber)) Week in Ordinary Time",
                    rank: .weekday,
                    color: .green
                )
            }
        }

        // Fallback default
        return TemporalDayComputation(
            season: .ordinaryTime,
            seasonWeek: 1,
            title: "Weekday in Ordinary Time",
            rank: .weekday,
            color: .green
        )
    }

    // MARK: - Holy Days of Obligation Evaluation (USCCB)

    private static func isHolyDayOfObligationInUS(
        date: Date,
        month: Int,
        day: Int,
        weekday: Int,
        isSunday: Bool,
        title: String,
        rank: LiturgicalRank,
        calendar: Calendar
    ) -> Bool {
        // 1. Every Sunday is always a Holy Day of Obligation (Canon 1246 §1)
        if isSunday {
            return true
        }

        // 2. The Nativity of the Lord (Christmas - December 25): Always of obligation
        if month == 12 && day == 25 {
            return true
        }

        // 3. Immaculate Conception: Patroness of the United States.
        // Treated as an obligation even when transferred to Monday, December 9, following the
        // Dicastery for Legislative Texts' September 2024 reply to the USCCB. Reports of a later
        // letter from the Dicastery for Divine Worship (January 2025) conflict on whether that
        // still holds. Confirm against the USCCB calendar before the next occurrence (2030).
        if title.contains("Immaculate Conception") {
            return true
        }

        // 4. USCCB Abrogation Rule:
        // Whenever January 1 (Mary, Mother of God), August 15 (Assumption), or November 1 (All Saints)
        // falls on a Saturday (weekday 7) or a Monday (weekday 2), the precept to attend Mass is abrogated.
        let isSaturdayOrMonday = (weekday == 2 || weekday == 7)

        // January 1: Solemnity of Mary, Mother of God
        if month == 1 && day == 1 {
            return !isSaturdayOrMonday
        }

        // August 15: Assumption of the Blessed Virgin Mary
        if month == 8 && day == 15 {
            return !isSaturdayOrMonday
        }

        // November 1: All Saints
        if month == 11 && day == 1 {
            return !isSaturdayOrMonday
        }

        return false
    }

    /// Scans upcoming days ahead and returns the next non-Sunday Holy Day of Obligation, if one occurs within `daysAhead`.
    public func nextHolyDayOfObligation(from date: Date = .now, daysAhead: Int = 30) -> (day: LiturgicalDay, daysAway: Int)? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)

        for offset in 1...daysAhead {
            guard let target = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let day = liturgicalDay(for: target)
            if day.isNonSundayHolyDayOfObligation {
                return (day, offset)
            }
        }
        return nil
    }

    // MARK: - Fasting and Abstinence Evaluation

    private static func isDayOfFastAndAbstinence(
        date: Date,
        ashWednesday: Date,
        easter: Date,
        calendar: Calendar
    ) -> Bool {
        if calendar.isDate(date, inSameDayAs: ashWednesday) {
            return true
        }
        let goodFriday = calendar.date(byAdding: .day, value: -2, to: easter)!
        if calendar.isDate(date, inSameDayAs: goodFriday) {
            return true
        }
        return false
    }

    private static func isDayOfAbstinence(
        date: Date,
        season: LiturgicalSeason,
        weekday: Int,
        isFastAndAbstinence: Bool,
        isSolemnity: Bool = false
    ) -> Bool {
        if isFastAndAbstinence {
            return true
        }
        // Canon 1251: Abstinence from meat is to be observed on all Fridays,
        // UNLESS a solemnity should fall on a Friday (e.g. Saint Joseph on March 19).
        if isSolemnity {
            return false
        }
        // In the US, all Fridays of Lent are mandatory days of abstinence from meat
        if season == .lent && weekday == 6 { // 6 = Friday
            return true
        }
        return false
    }

    // MARK: - Helpers

    private static func normalizedCalendar() -> Calendar {
        var gmtCal = Calendar(identifier: .gregorian)
        gmtCal.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return gmtCal
    }

    private static func normalize(
        date: Date,
        calendar: Calendar,
        gmtCal: Calendar
    ) -> (year: Int, month: Int, day: Int, weekday: Int, normalizedDate: Date) {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2026
        let m = comps.month ?? 1
        let d = comps.day ?? 1

        var normComps = DateComponents()
        normComps.year = y
        normComps.month = m
        normComps.day = d
        normComps.hour = 12
        normComps.minute = 0
        normComps.second = 0
        normComps.timeZone = TimeZone(secondsFromGMT: 0)

        let normDate = gmtCal.date(from: normComps) ?? date
        let weekday = gmtCal.component(.weekday, from: normDate)
        return (y, m, d, weekday, normDate)
    }

    private static func ordinal(_ number: Int) -> String {
        switch number {
        case 1: return "First"
        case 2: return "Second"
        case 3: return "Third"
        case 4: return "Fourth"
        case 5: return "Fifth"
        case 6: return "Sixth"
        case 7: return "Seventh"
        case 8: return "Eighth"
        case 9: return "Ninth"
        case 10: return "Tenth"
        case 11: return "Eleventh"
        case 12: return "Twelfth"
        case 13: return "Thirteenth"
        case 14: return "Fourteenth"
        case 15: return "Fifteenth"
        case 16: return "Sixteenth"
        case 17: return "Seventeenth"
        case 18: return "Eighteenth"
        case 19: return "Nineteenth"
        case 20: return "Twentieth"
        case 21: return "Twenty-First"
        case 22: return "Twenty-Second"
        case 23: return "Twenty-Third"
        case 24: return "Twenty-Fourth"
        case 25: return "Twenty-Fifth"
        case 26: return "Twenty-Sixth"
        case 27: return "Twenty-Seventh"
        case 28: return "Twenty-Eighth"
        case 29: return "Twenty-Ninth"
        case 30: return "Thirtieth"
        case 31: return "Thirty-First"
        case 32: return "Thirty-Second"
        case 33: return "Thirty-Third"
        case 34: return "Thirty-Fourth"
        default: return "\(number)th"
        }
    }
}
