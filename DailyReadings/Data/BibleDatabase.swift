//
//  BibleDatabase.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+ | SQLite3
//

import Foundation
import SQLite3

// MARK: - BibleBook Enum (73 Catholic Books)

/// Canonical enumeration of the 73 books of the Catholic Bible (Douay-Rheims version),
/// mapping canonical book IDs, official English names, Vulgate Latin names, and common abbreviations.
public enum BibleBook: Int, CaseIterable, Codable, Sendable {
    // Old Testament (46 Books)
    case genesis = 1
    case exodus = 2
    case leviticus = 3
    case numbers = 4
    case deuteronomy = 5
    case joshua = 6
    case judges = 7
    case ruth = 8
    case firstSamuel = 9         // 1 Kings in DRB/Vulgate
    case secondSamuel = 10       // 2 Kings in DRB/Vulgate
    case firstKings = 11         // 3 Kings in DRB/Vulgate
    case secondKings = 12        // 4 Kings in DRB/Vulgate
    case firstChronicles = 13    // 1 Paralipomenon
    case secondChronicles = 14   // 2 Paralipomenon
    case ezra = 15               // 1 Esdras
    case nehemiah = 16           // 2 Esdras
    case tobit = 17              // Tobias
    case judith = 18
    case esther = 19
    case job = 20
    case psalms = 21
    case proverbs = 22
    case ecclesiastes = 23       // Qoheleth
    case songOfSongs = 24        // Canticle of Canticles
    case wisdom = 25             // Wisdom of Solomon
    case sirach = 26             // Ecclesiasticus
    case isaiah = 27             // Isaias
    case jeremiah = 28           // Jeremias
    case lamentations = 29
    case baruch = 30
    case ezekiel = 31            // Ezechiel
    case daniel = 32
    case hosea = 33              // Osee
    case joel = 34
    case amos = 35
    case obadiah = 36            // Abdias
    case jonah = 37              // Jonas
    case micah = 38              // Micheas
    case nahum = 39
    case habakkuk = 40           // Habacuc
    case zephaniah = 41          // Sophonias
    case haggai = 42             // Aggeus
    case zechariah = 43          // Zacharias
    case malachi = 44            // Malachias
    case firstMaccabees = 45     // 1 Machabees
    case secondMaccabees = 46    // 2 Machabees

    // New Testament (27 Books)
    case matthew = 47
    case mark = 48
    case luke = 49
    case john = 50
    case acts = 51
    case romans = 52
    case firstCorinthians = 53
    case secondCorinthians = 54
    case galatians = 55
    case ephesians = 56
    case philippians = 57
    case colossians = 58
    case firstThessalonians = 59
    case secondThessalonians = 60
    case firstTimothy = 61
    case secondTimothy = 62
    case titus = 63
    case philemon = 64
    case hebrews = 65
    case james = 66
    case firstPeter = 67
    case secondPeter = 68
    case firstJohn = 69
    case secondJohn = 70
    case thirdJohn = 71
    case jude = 72
    case revelation = 73         // Apocalypse

    /// Canonical English name.
    public var canonicalName: String {
        switch self {
        case .genesis: return "Genesis"
        case .exodus: return "Exodus"
        case .leviticus: return "Leviticus"
        case .numbers: return "Numbers"
        case .deuteronomy: return "Deuteronomy"
        case .joshua: return "Joshua"
        case .judges: return "Judges"
        case .ruth: return "Ruth"
        case .firstSamuel: return "1 Samuel"
        case .secondSamuel: return "2 Samuel"
        case .firstKings: return "1 Kings"
        case .secondKings: return "2 Kings"
        case .firstChronicles: return "1 Chronicles"
        case .secondChronicles: return "2 Chronicles"
        case .ezra: return "Ezra"
        case .nehemiah: return "Nehemiah"
        case .tobit: return "Tobit"
        case .judith: return "Judith"
        case .esther: return "Esther"
        case .job: return "Job"
        case .psalms: return "Psalms"
        case .proverbs: return "Proverbs"
        case .ecclesiastes: return "Ecclesiastes"
        case .songOfSongs: return "Song of Songs"
        case .wisdom: return "Wisdom"
        case .sirach: return "Sirach"
        case .isaiah: return "Isaiah"
        case .jeremiah: return "Jeremiah"
        case .lamentations: return "Lamentations"
        case .baruch: return "Baruch"
        case .ezekiel: return "Ezekiel"
        case .daniel: return "Daniel"
        case .hosea: return "Hosea"
        case .joel: return "Joel"
        case .amos: return "Amos"
        case .obadiah: return "Obadiah"
        case .jonah: return "Jonah"
        case .micah: return "Micah"
        case .nahum: return "Nahum"
        case .habakkuk: return "Habakkuk"
        case .zephaniah: return "Zephaniah"
        case .haggai: return "Haggai"
        case .zechariah: return "Zechariah"
        case .malachi: return "Malachi"
        case .firstMaccabees: return "1 Maccabees"
        case .secondMaccabees: return "2 Maccabees"
        case .matthew: return "Matthew"
        case .mark: return "Mark"
        case .luke: return "Luke"
        case .john: return "John"
        case .acts: return "Acts"
        case .romans: return "Romans"
        case .firstCorinthians: return "1 Corinthians"
        case .secondCorinthians: return "2 Corinthians"
        case .galatians: return "Galatians"
        case .ephesians: return "Ephesians"
        case .philippians: return "Philippians"
        case .colossians: return "Colossians"
        case .firstThessalonians: return "1 Thessalonians"
        case .secondThessalonians: return "2 Thessalonians"
        case .firstTimothy: return "1 Timothy"
        case .secondTimothy: return "2 Timothy"
        case .titus: return "Titus"
        case .philemon: return "Philemon"
        case .hebrews: return "Hebrews"
        case .james: return "James"
        case .firstPeter: return "1 Peter"
        case .secondPeter: return "2 Peter"
        case .firstJohn: return "1 John"
        case .secondJohn: return "2 John"
        case .thirdJohn: return "3 John"
        case .jude: return "Jude"
        case .revelation: return "Revelation"
        }
    }

    /// The official Roman Catholic Lectionary spoken announcement for this book at Mass
    /// (e.g. "the Letter of Saint Paul to Philemon", "the Book of Genesis", "the Book of the Prophet Isaiah").
    public var liturgicalAnnouncement: String {
        switch self {
        case .genesis: return "the Book of Genesis"
        case .exodus: return "the Book of Exodus"
        case .leviticus: return "the Book of Leviticus"
        case .numbers: return "the Book of Numbers"
        case .deuteronomy: return "the Book of Deuteronomy"
        case .joshua: return "the Book of Joshua"
        case .judges: return "the Book of Judges"
        case .ruth: return "the Book of Ruth"
        case .firstSamuel: return "the first Book of Samuel"
        case .secondSamuel: return "the second Book of Samuel"
        case .firstKings: return "the first Book of Kings"
        case .secondKings: return "the second Book of Kings"
        case .firstChronicles: return "the first Book of Chronicles"
        case .secondChronicles: return "the second Book of Chronicles"
        case .ezra: return "the Book of Ezra"
        case .nehemiah: return "the Book of Nehemiah"
        case .tobit: return "the Book of Tobit"
        case .judith: return "the Book of Judith"
        case .esther: return "the Book of Esther"
        case .job: return "the Book of Job"
        case .psalms: return "the Book of Psalms"
        case .proverbs: return "the Book of Proverbs"
        case .ecclesiastes: return "the Book of Ecclesiastes"
        case .songOfSongs: return "the Song of Songs"
        case .wisdom: return "the Book of Wisdom"
        case .sirach: return "the Book of Sirach"
        case .isaiah: return "the Book of the Prophet Isaiah"
        case .jeremiah: return "the Book of the Prophet Jeremiah"
        case .lamentations: return "the Book of Lamentations"
        case .baruch: return "the Book of the Prophet Baruch"
        case .ezekiel: return "the Book of the Prophet Ezekiel"
        case .daniel: return "the Book of the Prophet Daniel"
        case .hosea: return "the Book of the Prophet Hosea"
        case .joel: return "the Book of the Prophet Joel"
        case .amos: return "the Book of the Prophet Amos"
        case .obadiah: return "the Book of the Prophet Obadiah"
        case .jonah: return "the Book of the Prophet Jonah"
        case .micah: return "the Book of the Prophet Micah"
        case .nahum: return "the Book of the Prophet Nahum"
        case .habakkuk: return "the Book of the Prophet Habakkuk"
        case .zephaniah: return "the Book of the Prophet Zephaniah"
        case .haggai: return "the Book of the Prophet Haggai"
        case .zechariah: return "the Book of the Prophet Zechariah"
        case .malachi: return "the Book of the Prophet Malachi"
        case .firstMaccabees: return "the first Book of Maccabees"
        case .secondMaccabees: return "the second Book of Maccabees"

        case .matthew: return "the holy Gospel according to Matthew"
        case .mark: return "the holy Gospel according to Mark"
        case .luke: return "the holy Gospel according to Luke"
        case .john: return "the holy Gospel according to John"

        case .acts: return "the Acts of the Apostles"
        case .romans: return "the Letter of Saint Paul to the Romans"
        case .firstCorinthians: return "the first Letter of Saint Paul to the Corinthians"
        case .secondCorinthians: return "the second Letter of Saint Paul to the Corinthians"
        case .galatians: return "the Letter of Saint Paul to the Galatians"
        case .ephesians: return "the Letter of Saint Paul to the Ephesians"
        case .philippians: return "the Letter of Saint Paul to the Philippians"
        case .colossians: return "the Letter of Saint Paul to the Colossians"
        case .firstThessalonians: return "the first Letter of Saint Paul to the Thessalonians"
        case .secondThessalonians: return "the second Letter of Saint Paul to the Thessalonians"
        case .firstTimothy: return "the first Letter of Saint Paul to Timothy"
        case .secondTimothy: return "the second Letter of Saint Paul to Timothy"
        case .titus: return "the Letter of Saint Paul to Titus"
        case .philemon: return "the Letter of Saint Paul to Philemon"
        case .hebrews: return "the Letter to the Hebrews"
        case .james: return "the Letter of Saint James"
        case .firstPeter: return "the first Letter of Saint Peter"
        case .secondPeter: return "the second Letter of Saint Peter"
        case .firstJohn: return "the first Letter of Saint John"
        case .secondJohn: return "the second Letter of Saint John"
        case .thirdJohn: return "the third Letter of Saint John"
        case .jude: return "the Letter of Saint Jude"
        case .revelation: return "the Book of Revelation"
        }
    }

    /// Number of chapters in this book.
    public var chapterCount: Int {
        switch self {
        case .genesis: return 50
        case .exodus: return 40
        case .leviticus: return 27
        case .numbers: return 36
        case .deuteronomy: return 34
        case .joshua: return 24
        case .judges: return 21
        case .ruth: return 4
        case .firstSamuel: return 31
        case .secondSamuel: return 24
        case .firstKings: return 22
        case .secondKings: return 25
        case .firstChronicles: return 29
        case .secondChronicles: return 36
        case .ezra: return 10
        case .nehemiah: return 13
        case .tobit: return 14
        case .judith: return 16
        case .esther: return 16
        case .job: return 42
        case .psalms: return 150
        case .proverbs: return 31
        case .ecclesiastes: return 12
        case .songOfSongs: return 8
        case .wisdom: return 19
        case .sirach: return 51
        case .isaiah: return 66
        case .jeremiah: return 52
        case .lamentations: return 5
        case .baruch: return 6
        case .ezekiel: return 48
        case .daniel: return 14
        case .hosea: return 14
        case .joel: return 3
        case .amos: return 9
        case .obadiah: return 1
        case .jonah: return 4
        case .micah: return 7
        case .nahum: return 3
        case .habakkuk: return 3
        case .zephaniah: return 3
        case .haggai: return 2
        case .zechariah: return 14
        case .malachi: return 4
        case .firstMaccabees: return 16
        case .secondMaccabees: return 15
        case .matthew: return 28
        case .mark: return 16
        case .luke: return 24
        case .john: return 21
        case .acts: return 28
        case .romans: return 16
        case .firstCorinthians: return 16
        case .secondCorinthians: return 13
        case .galatians: return 6
        case .ephesians: return 6
        case .philippians: return 4
        case .colossians: return 4
        case .firstThessalonians: return 5
        case .secondThessalonians: return 3
        case .firstTimothy: return 6
        case .secondTimothy: return 4
        case .titus: return 3
        case .philemon: return 1
        case .hebrews: return 13
        case .james: return 5
        case .firstPeter: return 5
        case .secondPeter: return 3
        case .firstJohn: return 5
        case .secondJohn: return 1
        case .thirdJohn: return 1
        case .jude: return 1
        case .revelation: return 22
        }
    }

    /// Resolves any common book name, abbreviation, Douay-Rheims or Latin title to a canonical BibleBook.
    public static func find(named rawName: String) -> BibleBook? {
        var clean = rawName
            .lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "first", with: "1")
            .replacingOccurrences(of: "second", with: "2")
            .replacingOccurrences(of: "third", with: "3")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Roman-numeral prefixes ("II Corinthians"). Longest first, and only at the start of the name.
        for (roman, digit) in [("iii ", "3 "), ("ii ", "2 "), ("i ", "1 ")] where clean.hasPrefix(roman) {
            clean = digit + clean.dropFirst(roman.count)
            break
        }

        if clean.hasPrefix("see ") {
            clean = String(clean.dropFirst(4)).trimmingCharacters(in: .whitespaces)
        }
        if clean.hasPrefix("cf ") {
            clean = String(clean.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        }
        if clean.hasPrefix("psalm") || clean.hasPrefix("ps") {
            return .psalms
        }
        if !clean.isEmpty && clean.allSatisfy({ $0.isNumber }) {
            return .psalms
        }
        if clean == "phiippians" || clean == "phippians" {
            return .philippians
        }
        if clean == "sirarch" {
            return .sirach
        }
        if clean == "col1" {
            return .colossians
        }
        if clean == "mt13" {
            return .matthew
        }

        switch clean {
        case "gn", "gen", "genesis": return .genesis
        case "ex", "exod", "exodus": return .exodus
        case "lv", "lev", "leviticus": return .leviticus
        case "nm", "num", "numbers": return .numbers
        case "dt", "deut", "deuteronomy": return .deuteronomy
        case "jos", "josh", "joshua", "josue": return .joshua
        case "jg", "jgs", "judg", "judges": return .judges
        case "ru", "ruth": return .ruth
        case "1 sm", "1 sam", "1 samuel", "1 kgs (drb)", "1 kings (drb)": return .firstSamuel
        case "2 sm", "2 sam", "2 samuel", "2 kgs (drb)", "2 kings (drb)": return .secondSamuel
        case "1 kgs", "1 ki", "1 kings", "3 kgs", "3 kings": return .firstKings
        case "2 kgs", "2 ki", "2 kings", "4 kgs", "4 kings": return .secondKings
        case "1 chr", "1 chron", "1 chronicles", "1 paralipomenon": return .firstChronicles
        case "2 chr", "2 chron", "2 chronicles", "2 paralipomenon": return .secondChronicles
        case "ezr", "ezra", "1 esdras": return .ezra
        case "neh", "nehemiah", "2 esdras": return .nehemiah
        case "tb", "tob", "tobit", "tobias": return .tobit
        case "jdt", "jth", "judith": return .judith
        case "est", "esth", "esther": return .esther
        case "jb", "job": return .job
        case "ps", "pss", "psalm", "psalms": return .psalms
        case "prv", "prov", "proverbs": return .proverbs
        case "eccl", "qoh", "ecclesiastes", "qoheleth": return .ecclesiastes
        case "sg", "song", "cant", "canticle of canticles", "song of songs", "song of solomon": return .songOfSongs
        case "ws", "wis", "wisdom", "wisdom of solomon": return .wisdom
        case "sir", "sirach", "ecclus", "ecclesiasticus": return .sirach
        case "is", "isa", "isaiah", "isaias": return .isaiah
        case "jr", "jer", "jeremiah", "jeremias": return .jeremiah
        case "lm", "lam", "lamentations": return .lamentations
        case "ba", "bar", "baruch": return .baruch
        case "ez", "ezek", "ezekiel", "ezechiel": return .ezekiel
        case "dn", "dan", "daniel": return .daniel
        case "os", "hos", "hosea", "osee": return .hosea
        case "jl", "joel": return .joel
        case "am", "amos": return .amos
        case "ob", "obad", "obadiah", "abdias": return .obadiah
        case "jon", "jonah", "jonas": return .jonah
        case "mi", "mic", "micah", "micheas": return .micah
        case "na", "nah", "nahum": return .nahum
        case "hb", "hab", "habakkuk", "habacuc": return .habakkuk
        case "zep", "zeph", "zephaniah", "sophanias", "sophonia": return .zephaniah
        case "hg", "hag", "haggai", "aggeus": return .haggai
        case "zc", "zec", "zech", "zechariah", "zacharias": return .zechariah
        case "ml", "mal", "malachi", "malachias": return .malachi
        case "1 mc", "1 macc", "1 maccabees", "1 machabees": return .firstMaccabees
        case "2 mc", "2 macc", "2 maccabees", "2 machabees": return .secondMaccabees
        case "mt", "matt", "matthew": return .matthew
        case "mk", "mrk", "mark": return .mark
        case "lk", "luk", "luke": return .luke
        case "jn", "jhn", "john": return .john
        case "ac", "act", "acts", "acts of the apostles": return .acts
        case "ro", "rom", "romans": return .romans
        case "1 co", "1 cor", "1 corinthians": return .firstCorinthians
        case "2 co", "2 cor", "2 corinthians": return .secondCorinthians
        case "ga", "gal", "galatians": return .galatians
        case "ep", "eph", "ephesians": return .ephesians
        case "php", "phil", "philippians": return .philippians
        case "col", "colossians": return .colossians
        case "1 th", "1 thes", "1 thess", "1 thessalonians": return .firstThessalonians
        case "2 th", "2 thes", "2 thess", "2 thessalonians": return .secondThessalonians
        case "1 tm", "1 tim", "1 timothy": return .firstTimothy
        case "2 tm", "2 tim", "2 timothy": return .secondTimothy
        case "ti", "tit", "titus": return .titus
        case "phm", "phlm", "philemon": return .philemon
        case "heb", "hebrews": return .hebrews
        case "jm", "jas", "james": return .james
        case "1 pt", "1 pet", "1 peter": return .firstPeter
        case "2 pt", "2 pet", "2 peter": return .secondPeter
        case "1 jn", "1 john": return .firstJohn
        case "2 jn", "2 john": return .secondJohn
        case "3 jn", "3 john": return .thirdJohn
        case "jd", "jude": return .jude
        case "rv", "rev", "revelation", "apoc", "apocalypse": return .revelation
        default:
            // Match against canonical name
            return BibleBook.allCases.first { $0.canonicalName.lowercased() == clean }
        }
    }
}

// MARK: - Versification Map

/// Translates Lectionary (Hebrew) verse numbering into the numbering a bundled Bible uses.
///
/// Built by `Scripts/build_versification.py` from the Copenhagen Alliance standard mappings and
/// stored in `versification.json`. Verses with no entry keep their number.
public struct VersificationMap: Sendable {
    public struct Target: Sendable, Hashable {
        public let chapter: Int
        public let verse: Int
    }

    private let targets: [Int: [Target]]
    private let lectionaryMaxVerses: [Int: [Int]]
    /// Psalm titles this Bible prints at the start of verse 1, keyed by its own psalm number.
    private let psalmTitles: [Int: String]

    private static func key(_ book: Int, _ chapter: Int, _ verse: Int) -> Int {
        (book << 20) | (chapter << 10) | verse
    }

    /// Loads the table named `name` ("webc" or "drb") from `versification.json`.
    public init?(named name: String, url: URL? = nil) {
        guard let url = url ?? Bundle.main.url(forResource: "versification", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let table = root[name] as? [String: [[Int]]] else {
            return nil
        }
        var targets: [Int: [Target]] = [:]
        for (bookKey, rows) in table {
            guard let book = Int(bookKey) else { continue }
            for row in rows where row.count == 4 {
                targets[Self.key(book, row[0], row[1]), default: []].append(Target(chapter: row[2], verse: row[3]))
            }
        }
        self.targets = targets

        var maxVerses: [Int: [Int]] = [:]
        for (bookKey, counts) in (root["lectionaryMaxVerses"] as? [String: [Int]]) ?? [:] {
            if let book = Int(bookKey) { maxVerses[book] = counts }
        }
        self.lectionaryMaxVerses = maxVerses

        var titles: [Int: String] = [:]
        for (psalm, title) in (root["\(name)PsalmTitles"] as? [String: String]) ?? [:] {
            if let number = Int(psalm) { titles[number] = title }
        }
        self.psalmTitles = titles
    }

    /// Verse 1 of a psalm without its title line. A responsorial psalm never includes the title.
    public func psalmTextWithoutTitle(psalm: Int, verseOneText: String) -> String {
        guard let title = psalmTitles[psalm], verseOneText.hasPrefix(title) else { return verseOneText }
        return String(verseOneText.dropFirst(title.count)).trimmingCharacters(in: .whitespaces)
    }

    /// Where a Lectionary verse lives in this Bible. An empty result means the verse is a psalm
    /// title that has no verse of its own here.
    public func resolve(book: Int, chapter: Int, verse: Int) -> [Target] {
        guard let mapped = targets[Self.key(book, chapter, verse)] else {
            return [Target(chapter: chapter, verse: verse)]
        }
        return mapped.filter { $0.verse > 0 }
    }

    /// Number of verses the chapter has in Lectionary numbering, when known.
    public func lectionaryVerseCount(book: Int, chapter: Int) -> Int? {
        guard let counts = lectionaryMaxVerses[book], chapter >= 1, chapter <= counts.count else { return nil }
        return counts[chapter - 1]
    }
}

// MARK: - BibleDatabase Actor

/// Thread-safe SQLite query layer for the bundled Douay-Rheims Bible.
/// Uses the raw SQLite3 C API to query verses efficiently.
public actor BibleDatabase {
    private nonisolated(unsafe) var dbPointer: OpaquePointer?
    private let databaseURL: URL?
    public let isVulgateNumbering: Bool
    /// Lectionary-to-Bible verse numbering for this translation. Nil means "same numbering".
    public let versification: VersificationMap?
    
    /// Default shared actor instance using the bundled World English Bible (Catholic edition).
    public static let shared = BibleDatabase.webc

    /// Dedicated actor instance for World English Bible (Catholic edition), which uses English verse numbering.
    public static let webc = BibleDatabase(resourceName: "bible_webc", isVulgateNumbering: false, versification: VersificationMap(named: "webc"))

    /// Dedicated actor instance for Douay-Rheims Bible with Latin Vulgate numbering.
    public static let drb = BibleDatabase(resourceName: "bible_drb", isVulgateNumbering: true, versification: VersificationMap(named: "drb"))

    /// Initializes the database connection with an optional custom file URL or resource name.
    public init(
        databaseURL: URL? = nil,
        resourceName: String = "bible_webc",
        isVulgateNumbering: Bool = false,
        versification: VersificationMap? = nil
    ) {
        let url = databaseURL ?? Bundle.main.url(forResource: resourceName, withExtension: "sqlite")
        self.databaseURL = url
        self.isVulgateNumbering = isVulgateNumbering
        self.versification = versification
        
        guard let targetURL = url else {
            self.dbPointer = nil
            return
        }
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(targetURL.path, &db, flags, nil) == SQLITE_OK {
            self.dbPointer = db
        } else {
            if let db {
                sqlite3_close(db)
            }
            self.dbPointer = nil
        }
    }

    deinit {
        if let db = dbPointer {
            sqlite3_close(db)
        }
    }

    // MARK: - Verse Range Parsing

    /// Parses complex liturgical verse specifications into an ordered array of unique verse numbers.
    /// Handles ranges: "1-5", "1–5"
    /// Handles lists: "1, 3-4, 6"
    /// Handles sub-verse liturgical notations: "1-3a, 3b-4" -> [1, 2, 3, 4]
    public static func parseVerseNumbers(from verseString: String) -> [Int] {
        let trimmed = verseString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var resultVerses = Set<Int>()
        // Normalize en-dashes and em-dashes to standard hyphens
        let normalized = trimmed
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: ";", with: ",")

        // Split comma-delimited segments
        let segments = normalized.split(separator: ",")
        for rawSegment in segments {
            let segment = rawSegment.trimmingCharacters(in: .whitespaces)
            guard !segment.isEmpty else { continue }

            if segment.contains("-") {
                let rangeParts = segment.split(separator: "-")
                if rangeParts.count >= 2 {
                    let startStr = extractLeadingDigits(from: String(rangeParts[0]))
                    let endStr = extractLeadingDigits(from: String(rangeParts[1]))
                    if let start = Int(startStr), let end = Int(endStr), start <= end {
                        for v in start...end {
                            resultVerses.insert(v)
                        }
                    } else if let single = Int(startStr) {
                        resultVerses.insert(single)
                    }
                }
            } else {
                let singleStr = extractLeadingDigits(from: segment)
                if let v = Int(singleStr) {
                    resultVerses.insert(v)
                }
            }
        }

        return resultVerses.sorted()
    }

    private static func extractLeadingDigits(from string: String) -> String {
        var digits = ""
        for char in string.trimmingCharacters(in: .whitespaces) {
            if char.isNumber {
                digits.append(char)
            } else if !digits.isEmpty {
                // Stop once we hit a non-digit like 'a', 'b', etc.
                break
            }
        }
        return digits
    }

    // MARK: - Query Methods

    /// Represents a single slice of a Bible query targeting a specific book, chapter, and set of verses.
    public struct BibleQuerySlice: Sendable, Hashable {
        public let bookId: Int
        public let chapter: Int
        public let verseNumbers: [Int]

        public init(bookId: Int, chapter: Int, verseNumbers: [Int] = []) {
            self.bookId = bookId
            self.chapter = chapter
            self.verseNumbers = verseNumbers
        }
    }

    /// Represents a parsed span of a scripture citation for chapter-by-chapter retrieval.
    public struct CitationSpan: Sendable {
        public let chapter: Int
        public let minVerse: Int?
        public let maxVerse: Int?
        public let verseNumbers: [Int]?
        public let all: Bool

        public init(chapter: Int, minVerse: Int? = nil, maxVerse: Int? = nil, verseNumbers: [Int]? = nil, all: Bool = false) {
            self.chapter = chapter
            self.minVerse = minVerse
            self.maxVerse = maxVerse
            self.verseNumbers = verseNumbers
            self.all = all
        }
    }

    /// Parses multi-chapter citations (semicolons, e.g. "63:16b-17; 64:2-7") and cross-chapter spans
    /// (dashes, e.g. "7:25—8:6", "12:31-13:13") into structured, chapter-delimited spans.
    public static func parseCitationSpans(baseChapter: Int?, rawVerses: String) -> [CitationSpan] {
        let initialChapter = baseChapter ?? 1
        var trimmed = rawVerses.trimmingCharacters(in: .whitespacesAndNewlines)
        // "4:12-23 or 4:12-17" offers a long and a short form. Read the long form, which comes first.
        if let alternative = trimmed.range(of: " or ", options: .caseInsensitive) {
            trimmed = String(trimmed[..<alternative.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        guard !trimmed.isEmpty else {
            return [CitationSpan(chapter: initialChapter, all: true)]
        }

        let chunks = trimmed.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        var currentChapter = initialChapter
        var spans: [CitationSpan] = []

        for chunk in chunks {
            if let dashRange = chunk.range(of: #"[—–\-]\s*\d+\s*:"#, options: .regularExpression) {
                let beforeDash = String(chunk[..<dashRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                let afterDash = String(chunk[dashRange.upperBound...]).trimmingCharacters(in: .whitespaces)

                let matchedPattern = String(chunk[dashRange])
                let endChapterDigits = matchedPattern.filter { $0.isNumber }
                let endChapter = Int(endChapterDigits) ?? (currentChapter + 1)

                let startVerseStr = extractLeadingDigits(from: beforeDash)
                let startVerse = Int(startVerseStr) ?? 1
                spans.append(CitationSpan(chapter: currentChapter, minVerse: startVerse))

                if endChapter > currentChapter + 1 {
                    for midChapter in (currentChapter + 1)..<endChapter {
                        spans.append(CitationSpan(chapter: midChapter, all: true))
                    }
                }

                let endVerseStr = extractLeadingDigits(from: afterDash)
                let endVerse = Int(endVerseStr) ?? 1

                var endChapterVerseString = "1-\(endVerse)"
                if let commaIndex = afterDash.firstIndex(of: ",") {
                    let trailing = afterDash[commaIndex...]
                    endChapterVerseString.append(String(trailing))
                }
                let endVerses = parseVerseNumbers(from: endChapterVerseString)
                spans.append(CitationSpan(chapter: endChapter, verseNumbers: endVerses))
                currentChapter = endChapter
            } else if let colonIdx = chunk.firstIndex(of: ":") {
                let chapterPart = String(chunk[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                let versesPart = String(chunk[chunk.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                let chapterNumStr = extractLeadingDigits(from: chapterPart)
                if let newChapter = Int(chapterNumStr) {
                    currentChapter = newChapter
                }
                let verses = parseVerseNumbers(from: versesPart)
                spans.append(CitationSpan(chapter: currentChapter, verseNumbers: verses))
            } else {
                let verses = parseVerseNumbers(from: chunk)
                spans.append(CitationSpan(chapter: currentChapter, verseNumbers: verses))
            }
        }

        return spans.isEmpty ? [CitationSpan(chapter: initialChapter, all: true)] : spans
    }

    /// Maps Hebrew/Lectionary chapter and verses to Vulgate (Douay-Rheims) chapter and verses.
    /// Accurately handles Psalm numbering differences (Psalms 9–147), Joel chapter splits,
    /// and Malachi chapter splits.
    public static func mapHebrewToVulgate(book: BibleBook, chapter: Int, verseNumbers: [Int]) -> [BibleQuerySlice] {
        switch book {
        case .psalms:
            return mapHebrewPsalmToVulgate(chapter: chapter, verseNumbers: verseNumbers)
        case .joel:
            return mapHebrewJoelToVulgate(chapter: chapter, verseNumbers: verseNumbers)
        case .malachi:
            return mapHebrewMalachiToVulgate(chapter: chapter, verseNumbers: verseNumbers)
        case .sirach:
            return mapHebrewSirachToVulgate(chapter: chapter, verseNumbers: verseNumbers)
        default:
            return [BibleQuerySlice(bookId: book.rawValue, chapter: chapter, verseNumbers: verseNumbers)]
        }
    }

    private static func mapHebrewPsalmToVulgate(chapter: Int, verseNumbers: [Int]) -> [BibleQuerySlice] {
        let bookId = BibleBook.psalms.rawValue

        switch chapter {
        case 1...8:
            return [BibleQuerySlice(bookId: bookId, chapter: chapter, verseNumbers: verseNumbers)]

        case 9:
            // Hebrew Psalm 9 = Vulgate Psalm 9:1-21
            return [BibleQuerySlice(bookId: bookId, chapter: 9, verseNumbers: verseNumbers)]

        case 10:
            // Hebrew Psalm 10 = Vulgate Psalm 9:22-39 (+21)
            let mapped = verseNumbers.isEmpty ? [] : verseNumbers.map { $0 + 21 }
            return [BibleQuerySlice(bookId: bookId, chapter: 9, verseNumbers: mapped)]

        case 11...113:
            // Vulgate = Hebrew - 1
            return [BibleQuerySlice(bookId: bookId, chapter: chapter - 1, verseNumbers: verseNumbers)]

        case 114:
            // Hebrew Psalm 114 = Vulgate Psalm 113:1-8
            return [BibleQuerySlice(bookId: bookId, chapter: 113, verseNumbers: verseNumbers)]

        case 115:
            // Hebrew Psalm 115 = Vulgate Psalm 113:9-26 (+8)
            let mapped = verseNumbers.isEmpty ? [] : verseNumbers.map { $0 + 8 }
            return [BibleQuerySlice(bookId: bookId, chapter: 113, verseNumbers: mapped)]

        case 116:
            // Hebrew 116:1-9 -> Vulgate 114:1-9
            // Hebrew 116:10-19 -> Vulgate 115:1-10 (-9)
            if verseNumbers.isEmpty {
                return [
                    BibleQuerySlice(bookId: bookId, chapter: 114, verseNumbers: []),
                    BibleQuerySlice(bookId: bookId, chapter: 115, verseNumbers: [])
                ]
            }
            var slices: [BibleQuerySlice] = []
            let lowVerses = verseNumbers.filter { $0 <= 9 }
            let highVerses = verseNumbers.filter { $0 >= 10 }.map { $0 - 9 }
            if !lowVerses.isEmpty {
                slices.append(BibleQuerySlice(bookId: bookId, chapter: 114, verseNumbers: lowVerses))
            }
            if !highVerses.isEmpty {
                slices.append(BibleQuerySlice(bookId: bookId, chapter: 115, verseNumbers: highVerses))
            }
            return slices

        case 117...146:
            // Vulgate = Hebrew - 1
            return [BibleQuerySlice(bookId: bookId, chapter: chapter - 1, verseNumbers: verseNumbers)]

        case 147:
            // Hebrew 147:1-11 -> Vulgate 146:1-11
            // Hebrew 147:12-20 -> Vulgate 147:1-9 (-11)
            if verseNumbers.isEmpty {
                return [
                    BibleQuerySlice(bookId: bookId, chapter: 146, verseNumbers: []),
                    BibleQuerySlice(bookId: bookId, chapter: 147, verseNumbers: [])
                ]
            }
            var slices: [BibleQuerySlice] = []
            let lowVerses = verseNumbers.filter { $0 <= 11 }
            let highVerses = verseNumbers.filter { $0 >= 12 }.map { $0 - 11 }
            if !lowVerses.isEmpty {
                slices.append(BibleQuerySlice(bookId: bookId, chapter: 146, verseNumbers: lowVerses))
            }
            if !highVerses.isEmpty {
                slices.append(BibleQuerySlice(bookId: bookId, chapter: 147, verseNumbers: highVerses))
            }
            return slices

        case 148...150:
            return [BibleQuerySlice(bookId: bookId, chapter: chapter, verseNumbers: verseNumbers)]

        default:
            return [BibleQuerySlice(bookId: bookId, chapter: chapter, verseNumbers: verseNumbers)]
        }
    }

    private static func mapHebrewJoelToVulgate(chapter: Int, verseNumbers: [Int]) -> [BibleQuerySlice] {
        let bookId = BibleBook.joel.rawValue
        switch chapter {
        case 3:
            // Hebrew Joel 3:1-5 = Vulgate Joel 2:28-32 (+27)
            let mapped = verseNumbers.isEmpty ? Array(28...32) : verseNumbers.map { $0 + 27 }
            return [BibleQuerySlice(bookId: bookId, chapter: 2, verseNumbers: mapped)]
        case 4:
            // Hebrew Joel 4:1-21 = Vulgate Joel 3:1-21
            return [BibleQuerySlice(bookId: bookId, chapter: 3, verseNumbers: verseNumbers)]
        default:
            return [BibleQuerySlice(bookId: bookId, chapter: chapter, verseNumbers: verseNumbers)]
        }
    }

    private static func mapHebrewMalachiToVulgate(chapter: Int, verseNumbers: [Int]) -> [BibleQuerySlice] {
        let bookId = BibleBook.malachi.rawValue
        guard chapter == 3 else {
            return [BibleQuerySlice(bookId: bookId, chapter: chapter, verseNumbers: verseNumbers)]
        }
        if verseNumbers.isEmpty {
            return [
                BibleQuerySlice(bookId: bookId, chapter: 3, verseNumbers: []),
                BibleQuerySlice(bookId: bookId, chapter: 4, verseNumbers: [])
            ]
        }
        var slices: [BibleQuerySlice] = []
        let lowVerses = verseNumbers.filter { $0 <= 18 }
        let highVerses = verseNumbers.filter { $0 > 18 }.map { $0 - 18 }
        if !lowVerses.isEmpty {
            slices.append(BibleQuerySlice(bookId: bookId, chapter: 3, verseNumbers: lowVerses))
        }
        if !highVerses.isEmpty {
            slices.append(BibleQuerySlice(bookId: bookId, chapter: 4, verseNumbers: highVerses))
        }
        return slices
    }

    private static func mapHebrewSirachToVulgate(chapter: Int, verseNumbers: [Int]) -> [BibleQuerySlice] {
        let bookId = BibleBook.sirach.rawValue
        switch chapter {
        case 50:
            // Lectionary Sirach 50:22-24 = Vulgate Ecclesiasticus 50:24-26 (+2)
            let mapped = verseNumbers.map { ($0 >= 22 && $0 <= 24) ? $0 + 2 : $0 }
            return [BibleQuerySlice(bookId: bookId, chapter: 50, verseNumbers: mapped)]
        default:
            return [BibleQuerySlice(bookId: bookId, chapter: chapter, verseNumbers: verseNumbers)]
        }
    }

    /// Locates Lectionary "Esther C" (the prayers of Mordecai and Esther) in a bundled Bible.
    ///
    /// The Lectionary letters the Greek additions to Esther; neither bundled Bible does.
    /// Douay-Rheims prints addition C as 13:8-18 and 14:1-19; WEB-C prints it as 4:18-47.
    /// Only addition C is read at Mass, so the other letters are not mapped.
    static func estherAdditionSlice(verses: String, isVulgateNumbering: Bool) -> BibleQuerySlice? {
        let trimmed = verses.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("C:") else { return nil }
        let cited = parseVerseNumbers(from: String(trimmed.dropFirst(2))).filter { (1...30).contains($0) }
        guard !cited.isEmpty else { return nil }
        let bookId = BibleBook.esther.rawValue

        guard isVulgateNumbering else {
            return BibleQuerySlice(bookId: bookId, chapter: 4, verseNumbers: cited.map { $0 + 17 })
        }
        // A citation never spans both prayers, so one chapter is enough.
        if cited.allSatisfy({ $0 <= 11 }) {
            return BibleQuerySlice(bookId: bookId, chapter: 13, verseNumbers: cited.map { $0 + 7 })
        }
        return BibleQuerySlice(bookId: bookId, chapter: 14, verseNumbers: cited.filter { $0 >= 12 }.map { $0 - 11 })
    }

    /// Queries the Bible database using a `ReadingCitation` written in Lectionary numbering.
    ///
    /// Each cited verse is first listed in Lectionary numbering, then translated to this Bible's
    /// numbering (`versification`, plus the hand-written Vulgate rules for Psalms, Joel and Malachi),
    /// and only then read from SQLite.
    public func queryVerses(citation: ReadingCitation) -> [BibleVerse] {
        guard let book = BibleBook.find(named: citation.book) else {
            return []
        }
        var slices: [BibleQuerySlice] = []

        if book == .esther, let addition = Self.estherAdditionSlice(verses: citation.verses, isVulgateNumbering: isVulgateNumbering) {
            return queryVerses(bookId: addition.bookId, chapter: addition.chapter, verseNumbers: addition.verseNumbers)
        }

        let spans = Self.parseCitationSpans(baseChapter: citation.chapter, rawVerses: citation.verses)

        for span in spans {
            let knownLength = versification?.lectionaryVerseCount(book: book.rawValue, chapter: span.chapter)

            // 1. The cited verses, in Lectionary numbering. Nil means "the whole chapter, length unknown".
            let cited: [Int]?
            if let specific = span.verseNumbers {
                cited = specific
            } else if let min = span.minVerse {
                if let knownLength {
                    cited = min <= knownLength ? Array(min...knownLength) : []
                } else {
                    cited = queryChapter(bookId: book.rawValue, chapter: span.chapter).map(\.verse).filter { $0 >= min }
                }
            } else if let knownLength {
                cited = Array(1...max(1, knownLength))
            } else {
                cited = nil
            }

            // An open-ended range that starts past the end of the chapter cites nothing here.
            // It must not fall through to "whole chapter".
            if let cited, cited.isEmpty { continue }

            // 2. Translate to this Bible's numbering.
            if isVulgateNumbering, book == .psalms || book == .joel || book == .malachi || book == .sirach {
                slices.append(contentsOf: Self.mapHebrewToVulgate(book: book, chapter: span.chapter, verseNumbers: cited ?? []))
            } else if let cited, let versification {
                var current: (chapter: Int, verses: [Int])?
                for verse in cited {
                    for target in versification.resolve(book: book.rawValue, chapter: span.chapter, verse: verse) {
                        if current?.chapter == target.chapter {
                            if current?.verses.last != target.verse { current?.verses.append(target.verse) }
                        } else {
                            if let done = current {
                                slices.append(BibleQuerySlice(bookId: book.rawValue, chapter: done.chapter, verseNumbers: done.verses))
                            }
                            current = (target.chapter, [target.verse])
                        }
                    }
                }
                if let done = current {
                    slices.append(BibleQuerySlice(bookId: book.rawValue, chapter: done.chapter, verseNumbers: done.verses))
                }
            } else {
                slices.append(BibleQuerySlice(bookId: book.rawValue, chapter: span.chapter, verseNumbers: cited ?? []))
            }
        }

        // 3. Read from SQLite, skipping a verse already returned by the previous slice.
        var allVerses: [BibleVerse] = []
        for slice in slices {
            for verse in queryVerses(bookId: slice.bookId, chapter: slice.chapter, verseNumbers: slice.verseNumbers) {
                if let last = allVerses.last, last.chapter == verse.chapter, last.verse == verse.verse { continue }
                if book == .psalms, verse.verse == 1, let versification {
                    let text = versification.psalmTextWithoutTitle(psalm: verse.chapter, verseOneText: verse.text)
                    if text.isEmpty { continue }
                    allVerses.append(BibleVerse(id: verse.id, bookId: verse.bookId, bookName: verse.bookName, chapter: verse.chapter, verse: verse.verse, text: text))
                    continue
                }
                allVerses.append(verse)
            }
        }
        return allVerses
    }

    /// Queries the Bible database by book name, chapter, and verse range.
    public func queryVerses(bookName: String, chapter: Int?, verses: String) -> [BibleVerse] {
        let citation = ReadingCitation(book: bookName, chapter: chapter, verses: verses)
        return queryVerses(citation: citation)
    }

    /// Queries verses by book ID, chapter, and verse range string.
    public func queryVerses(bookId: Int, chapter: Int, verseString: String) -> [BibleVerse] {
        guard let book = BibleBook(rawValue: bookId) else { return [] }
        let citation = ReadingCitation(book: book.canonicalName, chapter: chapter, verses: verseString)
        return queryVerses(citation: citation)
    }

    /// Queries specific verse numbers within a book and chapter.
    /// If `verseNumbers` is empty, returns all verses of the chapter.
    public func queryVerses(bookId: Int, chapter: Int, verseNumbers: [Int]) -> [BibleVerse] {
        guard let db = dbPointer else {
            // When bundled database is not present, return a placeholder verse
            let bookName = BibleBook(rawValue: bookId)?.canonicalName ?? "Scripture"
            let versesText = verseNumbers.isEmpty ? "All" : verseNumbers.map(String.init).joined(separator: ", ")
            return [
                BibleVerse(
                    id: (bookId * 100_000) + (chapter * 1_000) + (verseNumbers.first ?? 1),
                    bookId: bookId,
                    bookName: bookName,
                    chapter: chapter,
                    verse: verseNumbers.first ?? 1,
                    text: "[\(bookName) \(chapter):\(versesText) — Douay-Rheims text loaded from Bible database.]"
                )
            ]
        }

        // Query the chapter rows and filter/sort in memory
        let query = """
            SELECT id, book_id, chapter, verse, text
            FROM verses
            WHERE book_id = ? AND chapter = ?
            ORDER BY verse ASC;
        """

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return fallbackQueryWithAlternateSchema(bookId: bookId, chapter: chapter, verseNumbers: verseNumbers)
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int(statement, 1, Int32(bookId))
        sqlite3_bind_int(statement, 2, Int32(chapter))

        var chapterVerses: [BibleVerse] = []
        let bookName = BibleBook(rawValue: bookId)?.canonicalName ?? "Unknown"

        while sqlite3_step(statement) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(statement, 0))
            let bId = Int(sqlite3_column_int(statement, 1))
            let ch = Int(sqlite3_column_int(statement, 2))
            let v = Int(sqlite3_column_int(statement, 3))
            let text: String
            if let textPtr = sqlite3_column_text(statement, 4) {
                text = String(cString: textPtr)
            } else {
                text = ""
            }

            let verse = BibleVerse(
                id: id,
                bookId: bId,
                bookName: bookName,
                chapter: ch,
                verse: v,
                text: text
            )
            chapterVerses.append(verse)
        }

        if verseNumbers.isEmpty {
            return chapterVerses
        }

        let requestedSet = Set(verseNumbers)
        return chapterVerses.filter { requestedSet.contains($0.verse) }
    }

    /// Queries the entire contents of a chapter.
    public func queryChapter(bookId: Int, chapter: Int) -> [BibleVerse] {
        return queryVerses(bookId: bookId, chapter: chapter, verseNumbers: [])
    }

    /// Alternate schema query fallback (handles databases where column is named 'book' instead of 'book_id').
    private func fallbackQueryWithAlternateSchema(bookId: Int, chapter: Int, verseNumbers: [Int]) -> [BibleVerse] {
        guard let db = dbPointer else { return [] }
        let query = """
            SELECT id, book, chapter, verse, text
            FROM verses
            WHERE book = ? AND chapter = ?
            ORDER BY verse ASC;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int(statement, 1, Int32(bookId))
        sqlite3_bind_int(statement, 2, Int32(chapter))

        var results: [BibleVerse] = []
        let bookName = BibleBook(rawValue: bookId)?.canonicalName ?? "Unknown"
        let requestedSet = Set(verseNumbers)

        while sqlite3_step(statement) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(statement, 0))
            let bId = Int(sqlite3_column_int(statement, 1))
            let ch = Int(sqlite3_column_int(statement, 2))
            let v = Int(sqlite3_column_int(statement, 3))
            let text: String
            if let textPtr = sqlite3_column_text(statement, 4) {
                text = String(cString: textPtr)
            } else {
                text = ""
            }

            if verseNumbers.isEmpty || requestedSet.contains(v) {
                results.append(
                    BibleVerse(
                        id: id,
                        bookId: bId,
                        bookName: bookName,
                        chapter: ch,
                        verse: v,
                        text: text
                    )
                )
            }
        }

        return results
    }

    /// Formats an array of BibleVerse items into a cohesive reading text block.
    public func formattedText(for verses: [BibleVerse], includeVerseNumbers: Bool = false) -> String {
        guard !verses.isEmpty else { return "" }
        if includeVerseNumbers {
            return verses
                .map { "[\($0.verse)] \($0.text.trimmingCharacters(in: .whitespaces))" }
                .joined(separator: " ")
        } else {
            return verses
                .map { $0.text.trimmingCharacters(in: .whitespaces) }
                .joined(separator: " ")
        }
    }

    /// Formats a Responsorial Psalm into missal stanzas separated by "\n\n".
    ///
    /// The Roman Catholic Lectionary divides the responsorial psalm into distinct stanzas
    /// indicated by commas or semicolons in the citation (e.g. "Ps 146:7, 8-9a, 9bc-10" or "Ps 23:1-3a, 3b-4, 5, 6").
    /// This method queries each stanza, divides shared verses at clause/sentence boundaries without duplication,
    /// and formats each stanza separated by "\n\n" so views and audio players can present the congregational
    /// response after each stanza.
    public func formattedPsalmText(citation: ReadingCitation, includeVerseNumbers: Bool = false) -> String {
        let rawSegments = citation.verses
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard rawSegments.count > 1 else {
            let verses = queryVerses(citation: citation)
            return formattedText(for: verses, includeVerseNumbers: includeVerseNumbers)
        }

        // Query verses for each stanza segment
        var stanzaVersesList: [[BibleVerse]] = []
        for segment in rawSegments {
            let stanzaCitation = ReadingCitation(book: citation.book, chapter: citation.chapter, verses: segment)
            let verses = queryVerses(citation: stanzaCitation)
            stanzaVersesList.append(verses)
        }

        // Cleanly partition overlapping verses between adjacent stanzas (e.g. 1-3a and 3b-4, or 8-9a and 9bc-10)
        var stanzas: [String] = []
        for i in 0..<stanzaVersesList.count {
            var currentVerses = stanzaVersesList[i]

            // If the next stanza shares the last verse of this stanza
            if i + 1 < stanzaVersesList.count {
                if let lastVerse = currentVerses.last,
                   let nextFirst = stanzaVersesList[i + 1].first,
                   lastVerse.chapter == nextFirst.chapter,
                   lastVerse.verse == nextFirst.verse {
                    let parts = Self.splitVerseParts(lastVerse.text)
                    if !parts.first.isEmpty && !parts.rest.isEmpty {
                        // Replace last verse in current stanza with first part
                        currentVerses[currentVerses.count - 1] = BibleVerse(
                            id: lastVerse.id,
                            bookId: lastVerse.bookId,
                            bookName: lastVerse.bookName,
                            chapter: lastVerse.chapter,
                            verse: lastVerse.verse,
                            text: parts.first
                        )
                        // Replace first verse in next stanza with rest part
                        stanzaVersesList[i + 1][0] = BibleVerse(
                            id: nextFirst.id,
                            bookId: nextFirst.bookId,
                            bookName: nextFirst.bookName,
                            chapter: nextFirst.chapter,
                            verse: nextFirst.verse,
                            text: parts.rest
                        )
                    } else {
                        // Cannot split text cleanly: leave whole verse in first stanza and remove duplicate from second
                        stanzaVersesList[i + 1].removeFirst()
                    }
                }
            }

            let text = formattedText(for: currentVerses, includeVerseNumbers: includeVerseNumbers)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                stanzas.append(text)
            }
        }

        // Fallback: If stanzas came out empty, query the entire citation normally
        if stanzas.isEmpty {
            let verses = queryVerses(citation: citation)
            return formattedText(for: verses, includeVerseNumbers: includeVerseNumbers)
        }

        return stanzas.joined(separator: "\n\n")
    }

    /// Splits verse text into two parts at a natural sentence or clause boundary.
    private static func splitVerseParts(_ text: String) -> (first: String, rest: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Sentence ending (. ! ?) followed by whitespace and a capital letter or quote
        let sentencePattern = #"(?<=[.!?])\s+(?=[A-Z“\"'‘])"#
        if let regex = try? NSRegularExpression(pattern: sentencePattern) {
            let nsString = trimmed as NSString
            let matches = regex.matches(in: trimmed, range: NSRange(location: 0, length: nsString.length))
            if let firstMatch = matches.first {
                let firstPart = nsString.substring(to: firstMatch.range.location).trimmingCharacters(in: .whitespaces)
                let restPart = nsString.substring(from: firstMatch.range.location + firstMatch.range.length).trimmingCharacters(in: .whitespaces)
                if !firstPart.isEmpty && !restPart.isEmpty {
                    return (firstPart, restPart)
                }
            }
        }

        // 2. Colon or semicolon (: or ;) followed by whitespace
        let clausePattern = #"(?<=[;:])\s+"#
        if let regex = try? NSRegularExpression(pattern: clausePattern) {
            let nsString = trimmed as NSString
            let matches = regex.matches(in: trimmed, range: NSRange(location: 0, length: nsString.length))
            if let firstMatch = matches.first {
                let firstPart = nsString.substring(to: firstMatch.range.location).trimmingCharacters(in: .whitespaces)
                let restPart = nsString.substring(from: firstMatch.range.location + firstMatch.range.length).trimmingCharacters(in: .whitespaces)
                if !firstPart.isEmpty && !restPart.isEmpty {
                    return (firstPart, restPart)
                }
            }
        }

        return (trimmed, "")
    }
}
