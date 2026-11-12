//
//  BuildLectionaryIndex
//
//  Derives DailyReadings/Resources/lectionary.json (readings by liturgical cycle) from
//  lectionary_dates.json (readings by calendar date), so days outside the dated range resolve.
//
//  Build and run from the repository root:
//
//    swiftc -O -o /tmp/build-lectionary Scripts/BuildLectionaryIndex/main.swift \
//      DailyReadings/Engine/*.swift DailyReadings/Models/LiturgicalDay.swift \
//      DailyReadings/Models/Reading.swift DailyReadings/Models/BibleVerse.swift \
//      DailyReadings/Data/BibleDatabase.swift DailyReadings/Data/PsalmResponseProvider.swift \
//      DailyReadings/Data/PericoreIndex.swift -lsqlite3
//    /tmp/build-lectionary DailyReadings/Resources Scripts/lectionary_seeds.json
//
//  Add `--holdout 2026-01-01` to build from earlier dates only and report how many later
//  dates the cycle index predicts exactly. Nothing is written in that mode.
//

import Foundation

let arguments = CommandLine.arguments
guard arguments.count >= 3 else {
    print("usage: build-lectionary <Resources dir> <seeds.json> [--holdout yyyy-MM-dd]")
    exit(2)
}
let resources = URL(fileURLWithPath: arguments[1])
let seedsURL = URL(fileURLWithPath: arguments[2])
let holdout: String? = arguments.firstIndex(of: "--holdout").map { arguments[$0 + 1] }

var utc = Calendar(identifier: .gregorian)
utc.timeZone = TimeZone(secondsFromGMT: 0)!

func date(from key: String) -> Date {
    let parts = key.split(separator: "-").compactMap { Int($0) }
    return utc.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))!
}

/// Identifies a reading by book, chapter and first verse. Looser than the citation text on purpose:
/// the dated data spells the same reading several ways ("Ps 51:3-4" / "Psalm 51:3-4, 5-6 and 17").
func readingIdentity(_ entry: LectionaryEntry) -> String {
    let book = BibleBook.find(named: entry.citation.book).map { String($0.rawValue) } ?? entry.citation.book.lowercased()
    let firstVerse = entry.citation.verses.drop { !$0.isNumber }.prefix { $0.isNumber }
    return "\(book):\(entry.citation.chapter ?? 0):\(firstVerse)"
}

struct Observation {
    let dateKey: String
    let day: LiturgicalDay
    let base: String            // fixed_MM_DD or the season key
    let proper: String?         // proper_MM_DD when the day is a memorial or plain weekday
    let suffix: String
    let byType: [ReadingType: [LectionaryEntry]]

    func identity(of type: ReadingType) -> String? { byType[type]?.first.map(readingIdentity) }
}

/// The reading seen most often for a type; the most recent date wins a tie.
func mostCommon(_ observations: [Observation], type: ReadingType) -> (identity: String, entries: [LectionaryEntry])? {
    let present = observations.filter { $0.byType[type] != nil }
    let counts = Dictionary(grouping: present, by: { $0.identity(of: type)! }).mapValues(\.count)
    guard let best = present.max(by: { a, b in
        let (ca, cb) = (counts[a.identity(of: type)!]!, counts[b.identity(of: type)!]!)
        return ca != cb ? ca < cb : a.dateKey < b.dateKey
    }) else { return nil }
    return (best.identity(of: type)!, best.byType[type]!)
}

let emptyIndexURL = FileManager.default.temporaryDirectory.appendingPathComponent("empty-lectionary-\(UUID().uuidString).json")
try Data("{}".utf8).write(to: emptyIndexURL)
let dated = PericoreIndex(customURL: emptyIndexURL, customDatesURL: resources.appendingPathComponent("lectionary_dates.json")).datedEntries

var observations: [Observation] = []
var heldOut: [Observation] = []
for key in dated.keys.sorted() {
    guard let entries = dated[key], !entries.isEmpty else { continue }
    let day = LiturgicalCalendar.day(for: date(from: key), calendar: utc)
    let bases = PericoreIndex.baseKeys(for: day)
    let fixed = bases.first { $0.hasPrefix("fixed_") }
    let observation = Observation(
        dateKey: key, day: day,
        base: fixed ?? bases.last!,
        proper: fixed == nil ? bases.first { $0.hasPrefix("proper_") } : nil,
        suffix: PericoreIndex.cycleSuffix(for: day),
        byType: Dictionary(grouping: entries, by: \.type)
    )
    if let holdout, key >= holdout { heldOut.append(observation) } else { observations.append(observation) }
}

var index: [String: [LectionaryEntry]] = [:]

// 1. Readings a memorial has of its own: the same reading on the same date in two or more years
//    whose weekday readings differ. Usually just the Gospel (Guardian Angels) or the First Reading
//    and Psalm (Saint Barnabas); the rest of the day follows the weekday.
var properIdentity: [String: [ReadingType: String]] = [:]
for (proper, group) in Dictionary(grouping: observations.filter { $0.proper != nil }, by: { $0.proper! }) {
    var entries: [LectionaryEntry] = []
    for type in [ReadingType.firstReading, .responsorialPsalm, .gospel] {
        let sameReading = Dictionary(grouping: group.filter { $0.byType[type] != nil }, by: { $0.identity(of: type)! })
        guard let (id, matches) = sameReading.max(by: { $0.value.count < $1.value.count }),
              Set(matches.map(\.base)).count >= 2 else { continue }
        let latest = matches.max { $0.dateKey < $1.dateKey }!
        entries += latest.byType[type]!
        properIdentity[proper, default: [:]][type] = id
        if type == .gospel, let acclamation = latest.byType[.gospelAcclamation] {
            entries += acclamation
            properIdentity[proper, default: [:]][.gospelAcclamation] = latest.identity(of: .gospelAcclamation)
        }
    }
    if !entries.isEmpty { index[proper] = entries }
}

/// True when this observation's reading of `type` belongs to the memorial, not to the weekday.
func isProper(_ observation: Observation, _ type: ReadingType) -> Bool {
    guard let proper = observation.proper, let id = properIdentity[proper]?[type] else { return false }
    return observation.identity(of: type) == id
}

// 2. Season and fixed-feast readings, one reading type at a time. A reading goes under the base
//    key when at least two cycles were seen and they all agree; otherwise under each cycle's key.
for (base, group) in Dictionary(grouping: observations, by: \.base) {
    for type in ReadingType.allCases {
        let usable = group.filter { $0.byType[type] != nil && !isProper($0, type) }
        var perCycle: [String: (identity: String, entries: [LectionaryEntry])] = [:]
        for (suffix, cell) in Dictionary(grouping: usable, by: \.suffix) {
            perCycle[suffix] = mostCommon(cell, type: type)
        }
        guard !perCycle.isEmpty else { continue }
        // What the Lectionary's structure already settles:
        // - only Ordinary Time weekdays have a two-year cycle, and only for the First Reading and Psalm;
        // - a saint's feast has the same readings every year.
        let followsWeekdayCycle = group.allSatisfy { $0.suffix == "I" || $0.suffix == "II" }
        let variesByWeekdayCycle = base.hasPrefix("ot_") && (type == .firstReading || type == .responsorialPsalm)
        if followsWeekdayCycle && !variesByWeekdayCycle {
            index[base, default: []] += mostCommon(usable, type: type)!.entries
        } else if perCycle.count >= 2, Set(perCycle.values.map(\.identity)).count == 1 {
            index[base, default: []] += mostCommon(usable, type: type)!.entries
        } else {
            for (suffix, reading) in perCycle {
                index["\(base)_\(suffix)", default: []] += reading.entries
            }
        }
    }
}

// 3. Hand-entered readings for days the dated data never carries (days with several Masses).
//    A derived key always wins over a seed.
//    The exception is a day where the dated data carries the wrong Mass for this app's calendar:
//    - Ascension Sunday: the data has the Seventh Sunday of Easter (for provinces keeping Thursday);
//    - Pentecost: the data has the Vigil;
//    - Holy Thursday: the data has the Chrism Mass.
//    For those the seed replaces whatever was derived. `PericoreIndex` also skips the dated data for them.
let seeds = (try? JSONDecoder().decode([String: [LectionaryEntry]].self, from: Data(contentsOf: seedsURL))) ?? [:]
for base in PericoreIndex.cycleOnlyBases {
    for key in index.keys where key == base || key.hasPrefix(base + "_") {
        index[key] = nil
    }
}
var seedsUsed: [String] = []
for (key, entries) in seeds where index[key] == nil {
    index[key] = entries
    seedsUsed.append(key)
}

print("dated days read: \(dated.count)  cycle keys: \(index.count)  memorials with readings of their own: \(properIdentity.count)  seeds used: \(seedsUsed.sorted())")

let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
let output = try encoder.encode(index)

if holdout != nil {
    let trialURL = FileManager.default.temporaryDirectory.appendingPathComponent("trial-lectionary-\(UUID().uuidString).json")
    try output.write(to: trialURL)
    let trial = PericoreIndex(customURL: trialURL, customDatesURL: emptyIndexURL)
    var exact = 0, partial: [String] = [], wrong: [String] = [], missing: [String] = []
    for observation in heldOut {
        let predicted = Dictionary(grouping: trial.cycleEntries(for: observation.day), by: \.type)
        if predicted.isEmpty {
            missing.append("\(observation.dateKey) \(observation.day.title) [\(observation.base)_\(observation.suffix)]")
            continue
        }
        var bad: [String] = [], absent: [String] = []
        for type in [ReadingType.firstReading, .responsorialPsalm, .secondReading, .gospel] {
            guard let wanted = observation.identity(of: type) else { continue }
            guard let got = predicted[type]?.first.map(readingIdentity) else { absent.append(type.shortName); continue }
            if got != wanted { bad.append("\(type.shortName) wanted \(wanted) got \(got)") }
        }
        if !bad.isEmpty {
            wrong.append("\(observation.dateKey) \(observation.day.title) [\(observation.base)_\(observation.suffix)] \(bad.joined(separator: "; "))")
        } else if !absent.isEmpty {
            partial.append("\(observation.dateKey) \(observation.day.title) [\(observation.base)_\(observation.suffix)] missing \(absent.joined(separator: ", "))")
        } else {
            exact += 1
        }
    }
    print("held-out days: \(heldOut.count)  all readings right: \(exact)  right but incomplete: \(partial.count)  a wrong reading: \(wrong.count)  no readings: \(missing.count)")
    print("--- a wrong reading"); wrong.forEach { print($0) }
    print("--- right but incomplete"); partial.forEach { print($0) }
    print("--- no readings"); missing.forEach { print($0) }
} else {
    try output.write(to: resources.appendingPathComponent("lectionary.json"))
    print("wrote \(output.count) bytes to lectionary.json")
}
