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
/// Loads definitions from the bundled `lectionary.json` and builds exact lookup keys
/// according to Roman Catholic Lectionary rules.
public final class PericoreIndex: Sendable {
    /// Shared singleton instance.
    public static let shared = PericoreIndex()

    /// Lectionary entries indexed by lookup key.
    private let index: [String: [LectionaryEntry]]
    /// Date-indexed lectionary entries ("YYYY-MM-DD") loaded from lectionary_dates.json
    private let dateIndex: [String: [LectionaryEntry]]

    /// Designated initializer. Loads index from `lectionary.json` and `lectionary_dates.json` or falls back to embedded seeds.
    public init(customURL: URL? = nil, customDatesURL: URL? = nil) {
        let url = customURL ?? Bundle.main.url(forResource: "lectionary", withExtension: "json")
        if let url, let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: [LectionaryEntry]].self, from: data) {
            self.index = decoded
        } else {
            // Built-in foundational seeds guaranteed to cover key liturgical days
            self.index = Self.seedLectionary
        }

        var loadedDates: [String: [LectionaryEntry]] = [:]
        let datesURL = customDatesURL ?? Bundle.main.url(forResource: "lectionary_dates", withExtension: "json")
        if let datesURL, let data = try? Data(contentsOf: datesURL),
           let rawDateDict = try? JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]] {
            for (dateKey, entriesArray) in rawDateDict {
                guard let firstEntry = entriesArray.first,
                      let readingsDict = firstEntry["readings"] as? [String: [[String: Any]]] else { continue }
                
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
    public func entries(for day: LiturgicalDay) -> [LectionaryEntry] {
        // 1. Check dateIndex for exact calendar date (YYYY-MM-DD)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Calendar.current.timeZone
        let dateKey = formatter.string(from: day.date)
        if let directDateMatches = dateIndex[dateKey], !directDateMatches.isEmpty {
            return directDateMatches
        }

        // 2. Check standard liturgical cycle lookup key
        let lookupKey = key(for: day)
        if let directMatches = index[lookupKey], !directMatches.isEmpty {
            return directMatches
        }

        // 3. Check if a fixed feast exists for this calendar date
        let month = Calendar.current.component(.month, from: day.date)
        let dayOfMonth = Calendar.current.component(.day, from: day.date)
        let fixedKey = String(format: "fixed_%02d_%02d", month, dayOfMonth)
        if let fixedMatches = index[fixedKey], !fixedMatches.isEmpty {
            return fixedMatches
        }

        // 4. Fallback default weekday or Sunday template if exact key isn't in lectionary file
        return fallbackEntries(for: day)
    }

    // MARK: - Key Generation Logic

    /// Builds the standard lectionary lookup key according to liturgical rules:
    /// - Sundays: "sunday_{cycle}_{season}_{week}" e.g. "sunday_A_advent_1"
    /// - Weekdays: "weekday_{cycle}_{season}_{week}_{dayOfWeek}" e.g. "weekday_I_ordinary_1_monday"
    /// - Fixed feasts: "fixed_{month}_{day}" e.g. "fixed_12_25" for Christmas
    /// - Proper seasons with single-year cycle: "weekday_{season}_{week}_{dayOfWeek}" (no cycle needed)
    public func key(for day: LiturgicalDay) -> String {
        // 1. Check if there are fixed feast readings for this date
        let cal = Calendar(identifier: .gregorian)
        let month = cal.component(.month, from: day.date)
        let dayOfMonth = cal.component(.day, from: day.date)
        let fixedKey = String(format: "fixed_%02d_%02d", month, dayOfMonth)
        if index[fixedKey] != nil {
            return fixedKey
        }

        let seasonStr: String
        switch day.season {
        case .ordinaryTime:
            seasonStr = "ordinary"
        case .paschalTriduum:
            seasonStr = "triduum"
        default:
            seasonStr = day.season.rawValue.lowercased()
        }

        let week = day.seasonWeek
        let dayOfWeekNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        let dayOfWeek = (0...6).contains(day.dayOfWeekInSeason) ? dayOfWeekNames[day.dayOfWeekInSeason] : "sunday"

        // 2. Sundays
        if day.isSunday {
            let cycle: String
            switch day.sundayCycle {
            case .yearA: cycle = "A"
            case .yearB: cycle = "B"
            case .yearC: cycle = "C"
            }
            return "sunday_\(cycle)_\(seasonStr)_\(week)"
        }

        // 3. Proper Seasons (Advent, Lent, Triduum, Easter) have a single-year cycle
        if day.season == .advent || day.season == .lent || day.season == .easter || day.season == .paschalTriduum {
            return "weekday_\(seasonStr)_\(week)_\(dayOfWeek)"
        }

        // 4. Ordinary Time Weekdays (2-year cycle: Year I and Year II)
        let cycle: String
        switch day.weekdayCycle {
        case .yearI: cycle = "I"
        case .yearII: cycle = "II"
        }
        return "weekday_\(cycle)_\(seasonStr)_\(week)_\(dayOfWeek)"
    }

    // MARK: - Fallback Template Generator

    private func fallbackEntries(for day: LiturgicalDay) -> [LectionaryEntry] {
        let isSunday = day.isSunday
        if isSunday {
            return [
                LectionaryEntry(
                    type: .firstReading,
                    citation: ReadingCitation(book: "Isaiah", chapter: 2, verses: "1-5")
                ),
                LectionaryEntry(
                    type: .responsorialPsalm,
                    citation: ReadingCitation(book: "Psalms", chapter: 122, verses: "1-2, 3-4, 8-9"),
                    response: "Let us go rejoicing to the house of the Lord."
                ),
                LectionaryEntry(
                    type: .secondReading,
                    citation: ReadingCitation(book: "Romans", chapter: 13, verses: "11-14")
                ),
                LectionaryEntry(
                    type: .gospelAcclamation,
                    citation: ReadingCitation(book: "Psalms", chapter: 85, verses: "8"),
                    response: "Show us, Lord, your love, and grant us your salvation."
                ),
                LectionaryEntry(
                    type: .gospel,
                    citation: ReadingCitation(book: "Matthew", chapter: 24, verses: "37-44")
                )
            ]
        } else {
            return [
                LectionaryEntry(
                    type: .firstReading,
                    citation: ReadingCitation(book: "Philippians", chapter: 2, verses: "1-4")
                ),
                LectionaryEntry(
                    type: .responsorialPsalm,
                    citation: ReadingCitation(book: "Psalms", chapter: 131, verses: "1, 2, 3"),
                    response: "In you, O Lord, I have found my peace."
                ),
                LectionaryEntry(
                    type: .gospelAcclamation,
                    citation: ReadingCitation(book: "John", chapter: 8, verses: "31-32"),
                    response: "If you remain in my word, you will truly be my disciples."
                ),
                LectionaryEntry(
                    type: .gospel,
                    citation: ReadingCitation(book: "Luke", chapter: 14, verses: "12-14")
                )
            ]
        }
    }

    // MARK: - Embedded Seed Lectionary Data

    private static let seedLectionary: [String: [LectionaryEntry]] = [
        // All Souls (November 2)
        "fixed_11_02": [
            LectionaryEntry(
                type: .firstReading,
                citation: ReadingCitation(book: "Wisdom", chapter: 3, verses: "1-9")
            ),
            LectionaryEntry(
                type: .responsorialPsalm,
                citation: ReadingCitation(book: "Psalms", chapter: 23, verses: "1-3a, 3b-4, 5, 6"),
                response: "The Lord is my shepherd; there is nothing I shall want."
            ),
            LectionaryEntry(
                type: .secondReading,
                citation: ReadingCitation(book: "Romans", chapter: 5, verses: "5-11")
            ),
            LectionaryEntry(
                type: .gospelAcclamation,
                citation: ReadingCitation(book: "Matthew", chapter: 25, verses: "34"),
                response: "Come, you who are blessed by my Father; inherit the kingdom prepared for you."
            ),
            LectionaryEntry(
                type: .gospel,
                citation: ReadingCitation(book: "John", chapter: 6, verses: "37-40")
            )
        ],

        // All Saints (November 1)
        "fixed_11_01": [
            LectionaryEntry(
                type: .firstReading,
                citation: ReadingCitation(book: "Revelation", chapter: 7, verses: "2-4, 9-14")
            ),
            LectionaryEntry(
                type: .responsorialPsalm,
                citation: ReadingCitation(book: "Psalms", chapter: 24, verses: "1-2, 3-4ab, 5-6"),
                response: "Lord, this is the people that longs to see your face."
            ),
            LectionaryEntry(
                type: .secondReading,
                citation: ReadingCitation(book: "1 John", chapter: 3, verses: "1-3")
            ),
            LectionaryEntry(
                type: .gospelAcclamation,
                citation: ReadingCitation(book: "Matthew", chapter: 11, verses: "28"),
                response: "Come to me, all you who labor and are burdened, and I will give you rest."
            ),
            LectionaryEntry(
                type: .gospel,
                citation: ReadingCitation(book: "Matthew", chapter: 5, verses: "1-12a")
            )
        ],

        // Christmas Day (December 25)
        "fixed_12_25": [
            LectionaryEntry(
                type: .firstReading,
                citation: ReadingCitation(book: "Isaiah", chapter: 52, verses: "7-10")
            ),
            LectionaryEntry(
                type: .responsorialPsalm,
                citation: ReadingCitation(book: "Psalms", chapter: 98, verses: "1, 2-3, 3-4, 5-6"),
                response: "All the ends of the earth have seen the saving power of God."
            ),
            LectionaryEntry(
                type: .secondReading,
                citation: ReadingCitation(book: "Hebrews", chapter: 1, verses: "1-6")
            ),
            LectionaryEntry(
                type: .gospelAcclamation,
                citation: ReadingCitation(book: "Luke", chapter: 2, verses: "14"),
                response: "A holy day has dawned upon us. Come, you nations, and adore the Lord."
            ),
            LectionaryEntry(
                type: .gospel,
                citation: ReadingCitation(book: "John", chapter: 1, verses: "1-18")
            )
        ],

        // First Sunday of Advent Year A
        "sunday_A_advent_1": [
            LectionaryEntry(
                type: .firstReading,
                citation: ReadingCitation(book: "Isaiah", chapter: 2, verses: "1-5")
            ),
            LectionaryEntry(
                type: .responsorialPsalm,
                citation: ReadingCitation(book: "Psalms", chapter: 122, verses: "1-2, 3-4, 8-9"),
                response: "Let us go rejoicing to the house of the Lord."
            ),
            LectionaryEntry(
                type: .secondReading,
                citation: ReadingCitation(book: "Romans", chapter: 13, verses: "11-14")
            ),
            LectionaryEntry(
                type: .gospelAcclamation,
                citation: ReadingCitation(book: "Psalms", chapter: 85, verses: "8"),
                response: "Show us, Lord, your love, and grant us your salvation."
            ),
            LectionaryEntry(
                type: .gospel,
                citation: ReadingCitation(book: "Matthew", chapter: 24, verses: "37-44")
            )
        ],

        // 31st Sunday in Ordinary Time Year B
        "sunday_B_ordinary_31": [
            LectionaryEntry(
                type: .firstReading,
                citation: ReadingCitation(book: "Deuteronomy", chapter: 6, verses: "2-6")
            ),
            LectionaryEntry(
                type: .responsorialPsalm,
                citation: ReadingCitation(book: "Psalms", chapter: 18, verses: "2-3, 3-4, 47, 51"),
                response: "I love you, Lord, my strength."
            ),
            LectionaryEntry(
                type: .secondReading,
                citation: ReadingCitation(book: "Hebrews", chapter: 7, verses: "23-28")
            ),
            LectionaryEntry(
                type: .gospelAcclamation,
                citation: ReadingCitation(book: "John", chapter: 14, verses: "23"),
                response: "Whoever loves me will keep my word, says the Lord."
            ),
            LectionaryEntry(
                type: .gospel,
                citation: ReadingCitation(book: "Mark", chapter: 12, verses: "28b-34")
            )
        ],

        // Ordinary Time Week 31 Monday Year II
        "weekday_II_ordinary_31_monday": [
            LectionaryEntry(
                type: .firstReading,
                citation: ReadingCitation(book: "Philippians", chapter: 2, verses: "1-4")
            ),
            LectionaryEntry(
                type: .responsorialPsalm,
                citation: ReadingCitation(book: "Psalms", chapter: 131, verses: "1, 2, 3"),
                response: "In you, O Lord, I have found my peace."
            ),
            LectionaryEntry(
                type: .gospelAcclamation,
                citation: ReadingCitation(book: "John", chapter: 8, verses: "31-32"),
                response: "If you remain in my word, you will truly be my disciples."
            ),
            LectionaryEntry(
                type: .gospel,
                citation: ReadingCitation(book: "Luke", chapter: 14, verses: "12-14")
            )
        ]
    ]
}
