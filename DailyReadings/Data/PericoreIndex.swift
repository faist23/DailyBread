//
//  PericoreIndex.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Represents an item in the Lectionary index, linking a reading type, citation, and optional psalm response.
public struct LectionaryEntry: Codable, Hashable, Sendable {
    public let type: ReadingType
    public let citation: ReadingCitation
    public let response: String?

    public init(type: ReadingType, citation: ReadingCitation, response: String? = nil) {
        self.type = type
        self.citation = citation
        self.response = response
    }

    private enum CodingKeys: String, CodingKey {
        case type, book, chapter, verses, response, citation
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(ReadingType.self, forKey: .type)
        self.response = try container.decodeIfPresent(String.self, forKey: .response)

        if let directCitation = try? container.decode(ReadingCitation.self, forKey: .citation) {
            self.citation = directCitation
        } else {
            let book = try container.decode(String.self, forKey: .book)
            let chapter = try container.decodeIfPresent(Int.self, forKey: .chapter)
            let verses = try container.decode(String.self, forKey: .verses)
            self.citation = ReadingCitation(book: book, chapter: chapter, verses: verses)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(citation.book, forKey: .book)
        try container.encodeIfPresent(citation.chapter, forKey: .chapter)
        try container.encode(citation.verses, forKey: .verses)
        try container.encodeIfPresent(response, forKey: .response)
    }
}

/// Maps Catholic liturgical days to Bible passage citations and lectionary readings.
/// `lectionary_dates.json` holds readings by calendar date for the years it covers.
/// `lectionary.json` holds the same readings by liturgical cycle (built by `Scripts/BuildLectionaryIndex`),
/// so days outside the dated range still resolve.
public final class PericoreIndex: Sendable {
    /// Shared singleton instance.
    public static let shared = PericoreIndex()

    /// Lectionary entries indexed by lookup key.
    private let index: [String: [LectionaryEntry]]
    /// Date-indexed lectionary entries ("YYYY-MM-DD") loaded from lectionary_dates.json
    private let dateIndex: [String: [LectionaryEntry]]

    /// Designated initializer. Loads the cycle index from `lectionary.json` and the dated index from `lectionary_dates.json`.
    public init(customURL: URL? = nil, customDatesURL: URL? = nil) {
        let url = customURL ?? Bundle.main.url(forResource: "lectionary", withExtension: "json")
        if let url, let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: [LectionaryEntry]].self, from: data) {
            self.index = decoded
        } else {
            self.index = [:]
        }

        var loadedDates: [String: [LectionaryEntry]] = [:]
        let datesURL = customDatesURL ?? Bundle.main.url(forResource: "lectionary_dates", withExtension: "json")
        if let datesURL, let data = try? Data(contentsOf: datesURL),
           let rawDateDict = try? JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]] {
            for (dateKey, entriesArray) in rawDateDict {
                // A day with several Masses lists them all; some are placeholders with no readings.
                guard let readingsDict = entriesArray
                    .compactMap({ $0["readings"] as? [String: [[String: Any]]] })
                    .first(where: { !$0.isEmpty }) else { continue }
                
                var entries: [LectionaryEntry] = []
                
                // 1. First Reading
                if let list = readingsDict["first_reading"] {
                    for item in list {
                        if let citStr = item["citation"] as? String, let cit = ReadingCitation.parse(from: citStr) {
                            entries.append(LectionaryEntry(type: .firstReading, citation: cit))
                        }
                    }
                }
                
                // 2. Responsorial Psalm(s)
                let psalmKeys = ["responsorial_psalm", "responsorial_psalm_1", "responsorial_psalm_2", "responsorial_psalm_3"]
                for pKey in psalmKeys {
                    if let list = readingsDict[pKey] {
                        for item in list {
                            if let citStr = item["citation"] as? String, let cit = ReadingCitation.parse(from: citStr) {
                                let resp = (item["response"] as? String) ?? PsalmResponseProvider.response(for: cit)
                                entries.append(LectionaryEntry(type: .responsorialPsalm, citation: cit, response: resp))
                            }
                        }
                    }
                }
                
                // 3. Second Reading / Epistle
                for sKey in ["second_reading", "epistle"] {
                    if let list = readingsDict[sKey] {
                        for item in list {
                            if let citStr = item["citation"] as? String, let cit = ReadingCitation.parse(from: citStr) {
                                entries.append(LectionaryEntry(type: .secondReading, citation: cit))
                            }
                        }
                    }
                }
                
                // 4. Sequence
                if let list = readingsDict["sequence"] {
                    for item in list {
                        if let citStr = item["citation"] as? String, let cit = ReadingCitation.parse(from: citStr) {
                            entries.append(LectionaryEntry(type: .sequence, citation: cit))
                        }
                    }
                }
                
                // 5. Gospel Acclamation / Alleluia
                for aKey in ["alleluia", "verse_before_gospel"] {
                    if let list = readingsDict[aKey] {
                        for item in list {
                            if let citStr = item["citation"] as? String, let cit = ReadingCitation.parse(from: citStr) {
                                entries.append(LectionaryEntry(type: .gospelAcclamation, citation: cit))
                            }
                        }
                    }
                }
                
                // 6. Gospel
                if let list = readingsDict["gospel"] {
                    for item in list {
                        if let citStr = item["citation"] as? String, let cit = ReadingCitation.parse(from: citStr) {
                            entries.append(LectionaryEntry(type: .gospel, citation: cit))
                        }
                    }
                }
                
                if !entries.isEmpty {
                    loadedDates[dateKey] = entries
                }
            }
        }
        self.dateIndex = loadedDates
    }

    // MARK: - Query APIs

    /// Returns the array of `ReadingCitation`s assigned to the specified `LiturgicalDay`.
    public func citations(for day: LiturgicalDay) -> [ReadingCitation] {
        entries(for: day).map(\.citation)
    }

    /// Returns full `LectionaryEntry` records (including reading type and Psalm refrain) for the day.
    ///
    /// Looks up the exact calendar date first, then the liturgical-cycle keys for the day.
    /// Returns an empty array when the lectionary has nothing for the day. It never invents readings.
    public func entries(for day: LiturgicalDay) -> [LectionaryEntry] {
        let dated = dateIndex[Self.dateKey(for: day.date)] ?? []
        if dated.isEmpty || Self.cycleOnlyBases.contains(Self.baseKeys(for: day).last ?? "") {
            let cycle = cycleEntries(for: day)
            if !cycle.isEmpty { return cycle }
        }
        return dated
    }

    /// Days where the dated data carries a different Mass from the one this app's calendar keeps
    /// (the Seventh Sunday of Easter instead of the Ascension, the Pentecost Vigil, the Chrism Mass).
    /// The cycle index is authoritative for these.
    public static let cycleOnlyBases: Set<String> = ["ascension", "pentecost", "triduum_thursday"]

    /// Readings for the day from the liturgical-cycle index only, ignoring the dated index.
    ///
    /// A base key holds the readings every cycle shares; the key with a cycle suffix holds the
    /// readings particular to that cycle (for example an Ordinary Time weekday shares its Gospel
    /// across Years I and II but not its First Reading). A `proper_MM_DD` key then replaces the
    /// readings a memorial has of its own. A cycle the index has never seen yields only the shared
    /// readings; a solemnity or feast with no data yields nothing rather than the weekday's readings.
    public func cycleEntries(for day: LiturgicalDay) -> [LectionaryEntry] {
        let suffix = Self.cycleSuffix(for: day)
        let bases = Self.baseKeys(for: day)
        let fixed = bases.first { $0.hasPrefix("fixed_") }
        let primary = fixed ?? bases.last ?? ""

        var byType: [ReadingType: [LectionaryEntry]] = Dictionary(grouping: index[primary] ?? [], by: \.type)
        for (type, entries) in Dictionary(grouping: index["\(primary)_\(suffix)"] ?? [], by: \.type) {
            byType[type] = entries
        }
        if fixed == nil, let proper = bases.first(where: { $0.hasPrefix("proper_") }), !byType.isEmpty {
            for (type, entries) in Dictionary(grouping: index[proper] ?? [], by: \.type) {
                byType[type] = entries
            }
        }
        return ReadingType.allCases
            .sorted { $0.liturgicalOrder < $1.liturgicalOrder }
            .flatMap { byType[$0] ?? [] }
    }

    /// Every dated entry, keyed "yyyy-MM-dd". Used by `Scripts/BuildLectionaryIndex` to derive the cycle index.
    public var datedEntries: [String: [LectionaryEntry]] { dateIndex }

    /// The first lookup key for the day (most specific).
    public func key(for day: LiturgicalDay) -> String {
        Self.lookupKeys(for: day).first ?? ""
    }

    static func dateKey(for date: Date) -> String {
        let parts = utcCalendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    // MARK: - Liturgical-Cycle Keys

    /// Lookup keys for a liturgical day, most specific first.
    ///
    /// The Lectionary repeats on cycles, so a day is identified by what it is, not by its date:
    /// - a fixed-date solemnity or feast: `fixed_MM_DD`
    /// - a memorial with its own readings: `proper_MM_DD`
    /// - anything else: its place in the season, e.g. `ot_23_tuesday`, `lent_sun_3`, `advent_dec_18`
    ///
    /// Each base key appears with the day's cycle attached and on its own. Sundays, solemnities
    /// and feasts of the Lord follow the Sunday cycle (A/B/C); every other day follows the weekday cycle (I/II).
    public static func lookupKeys(for day: LiturgicalDay) -> [String] {
        let suffix = cycleSuffix(for: day)
        return baseKeys(for: day).flatMap { ["\($0)_\(suffix)", $0] }
    }

    /// "A", "B" or "C" for days that follow the Sunday cycle; "I" or "II" for the rest.
    public static func cycleSuffix(for day: LiturgicalDay) -> String {
        if day.isSunday || day.rank.rawValue <= LiturgicalRank.feastOfLord.rawValue {
            switch day.sundayCycle {
            case .yearA: return "A"
            case .yearB: return "B"
            case .yearC: return "C"
            }
        }
        return day.weekdayCycle == .yearI ? "I" : "II"
    }

    /// Base keys for a day without cycle suffixes: fixed feast, then proper memorial, then season.
    public static func baseKeys(for day: LiturgicalDay) -> [String] {
        var keys: [String] = []
        let date = utcCalendar.dateComponents([.year, .month, .day], from: day.date)
        let month = date.month ?? 1
        let dayOfMonth = date.day ?? 1

        // 1. A fixed-date solemnity or feast being celebrated today (on its own date or transferred).
        let origin = day.transferredFromDate.map { utcCalendar.dateComponents([.month, .day], from: $0) }
        let fixedMonth = origin?.month ?? month
        let fixedDay = origin?.day ?? dayOfMonth
        let celebrations = FixedSolemnities.celebrationsByMonthAndDay[FixedSolemnities.CelebrationKey(month: fixedMonth, day: fixedDay)] ?? []
        if celebrations.contains(where: { $0.title == day.title && $0.rank.rawValue <= LiturgicalRank.properFeast.rawValue }) {
            keys.append(String(format: "fixed_%02d_%02d", fixedMonth, fixedDay))
        }

        // 2. A memorial (or a weekday the calendar does not list a memorial for) with readings of its own.
        if day.rank.rawValue >= LiturgicalRank.obligatoryMemorial.rawValue {
            keys.append(String(format: "proper_%02d_%02d", month, dayOfMonth))
        }

        // 3. The day's place in the season.
        keys.append(seasonKey(for: day, year: date.year ?? 2026, month: month, dayOfMonth: dayOfMonth))
        return keys
    }

    private static func seasonKey(for day: LiturgicalDay, year: Int, month: Int, dayOfMonth: Int) -> String {
        let names = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        let dow = (0...6).contains(day.dayOfWeekInSeason) ? names[day.dayOfWeekInSeason] : "sunday"
        let week = day.seasonWeek
        let title = day.title

        switch day.season {
        case .advent:
            if day.isSunday { return "advent_sun_\(week)" }
            if month == 12 && dayOfMonth >= 17 { return "advent_dec_\(dayOfMonth)" }
            return "advent_\(week)_\(dow)"

        case .christmas:
            if month == 12 {
                if dayOfMonth == 25 { return "christmas_day" }
                if title.contains("Holy Family") { return "holy_family" }
                return "christmas_dec_\(dayOfMonth)"
            }
            if dayOfMonth == 1 { return "mary_mother_of_god" }
            if title.contains("Epiphany of the Lord") { return "epiphany" }
            if title.contains("Baptism of the Lord") { return "baptism_of_the_lord" }
            // Before Epiphany the Lectionary goes by date; after it, by day of the week.
            let epiphany = LiturgicalCalendar.epiphanyDate(year: year)
            return day.date < epiphany ? "christmas_jan_\(dayOfMonth)" : "christmas_after_epiphany_\(dow)"

        case .lent:
            if title == "Ash Wednesday" { return "ash_wednesday" }
            if day.isSunday { return "lent_sun_\(week)" }
            // The calendar numbers both "Thursday after Ash Wednesday" and "Thursday of the First
            // Week of Lent" as week 1, so tell them apart by distance from Ash Wednesday.
            let ashWednesday = Computus.ashWednesday(year: year)
            let daysIn = utcCalendar.dateComponents([.day], from: ashWednesday, to: day.date).day ?? 0
            if (1...3).contains(daysIn) { return "lent_after_ash_\(dow)" }
            return "lent_\(week)_\(dow)"

        case .paschalTriduum:
            return "triduum_\(dow)"

        case .easter:
            if title.contains("Ascension") { return "ascension" }
            if title.contains("Pentecost") { return "pentecost" }
            if day.isSunday { return "easter_sun_\(week)" }
            return "easter_\(week)_\(dow)"

        case .ordinaryTime:
            if title.contains("Most Holy Trinity") { return "trinity" }
            if title.contains("Body and Blood of Christ") { return "corpus_christi" }
            if title.contains("Sacred Heart of Jesus") { return "sacred_heart" }
            if title.contains("Immaculate Heart") { return "immaculate_heart" }
            if title.contains("Mother of the Church") { return "mary_mother_of_the_church" }
            if title.contains("King of the Universe") { return "christ_the_king" }
            if day.isSunday { return "ot_sun_\(week)" }
            return "ot_\(week)_\(dow)"
        }
    }
}
