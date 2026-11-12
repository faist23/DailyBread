//
//  ScriptureEngineTests.swift
//  DailyReadingsTests
//
//  Created for DailyReadings Tests.
//  iOS 17+ | Swift 6+
//

import XCTest
@testable import DailyReadings

final class ScriptureEngineTests: XCTestCase {

    // MARK: - 1. Hebrew ↔ Vulgate Psalm Numbering Tests

    func testVulgatePsalm23Mapping() {
        // Hebrew/Lectionary Psalm 23:1-6 -> Latin Vulgate Psalm 22:1-6 ("The Lord ruleth me")
        let slices = BibleDatabase.mapHebrewToVulgate(book: .psalms, chapter: 23, verseNumbers: [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices.first?.chapter, 22)
        XCTAssertEqual(slices.first?.verseNumbers, [1, 2, 3, 4, 5, 6])
    }

    func testVulgatePsalm116HighVersesMapping() {
        // Hebrew/Lectionary Psalm 116:12-18 -> Latin Vulgate Psalm 115:3-9 (offset -9)
        let slices = BibleDatabase.mapHebrewToVulgate(book: .psalms, chapter: 116, verseNumbers: [12, 13, 15, 16, 17, 18])
        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices.first?.chapter, 115)
        XCTAssertEqual(slices.first?.verseNumbers, [3, 4, 6, 7, 8, 9])
    }

    func testVulgatePsalm116LowVersesMapping() {
        // Hebrew/Lectionary Psalm 116:1-9 -> Latin Vulgate Psalm 114:1-9
        let slices = BibleDatabase.mapHebrewToVulgate(book: .psalms, chapter: 116, verseNumbers: [1, 2, 3])
        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices.first?.chapter, 114)
        XCTAssertEqual(slices.first?.verseNumbers, [1, 2, 3])
    }

    func testVulgatePsalm147HighVersesMapping() {
        // Hebrew/Lectionary Psalm 147:12-20 -> Latin Vulgate Psalm 147:1-9 (offset -11)
        let slices = BibleDatabase.mapHebrewToVulgate(book: .psalms, chapter: 147, verseNumbers: [12, 13, 14, 15])
        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices.first?.chapter, 147)
        XCTAssertEqual(slices.first?.verseNumbers, [1, 2, 3, 4])
    }

    func testVulgatePsalm147LowVersesMapping() {
        // Hebrew/Lectionary Psalm 147:1-11 -> Latin Vulgate Psalm 146:1-11
        let slices = BibleDatabase.mapHebrewToVulgate(book: .psalms, chapter: 147, verseNumbers: [1, 2, 3])
        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices.first?.chapter, 146)
        XCTAssertEqual(slices.first?.verseNumbers, [1, 2, 3])
    }

    // MARK: - 2. Joel and Malachi Chapter Alignments

    func testVulgateJoelChapter3Mapping() {
        // Hebrew Joel 3:1-5 -> Vulgate Joel 2:28-32 (offset +27)
        let slices = BibleDatabase.mapHebrewToVulgate(book: .joel, chapter: 3, verseNumbers: [1, 2, 3, 4, 5])
        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices.first?.chapter, 2)
        XCTAssertEqual(slices.first?.verseNumbers, [28, 29, 30, 31, 32])
    }

    func testVulgateJoelChapter4Mapping() {
        // Hebrew Joel 4:12-21 -> Vulgate Joel 3:12-21
        let slices = BibleDatabase.mapHebrewToVulgate(book: .joel, chapter: 4, verseNumbers: [12, 13, 14])
        XCTAssertEqual(slices.count, 1)
        XCTAssertEqual(slices.first?.chapter, 3)
        XCTAssertEqual(slices.first?.verseNumbers, [12, 13, 14])
    }

    func testVulgateMalachiChapter3HighVersesMapping() {
        // Hebrew Malachi 3:1-4, 23-24 -> Vulgate Malachi 3:1-4 and Malachi 4:5-6
        let slices = BibleDatabase.mapHebrewToVulgate(book: .malachi, chapter: 3, verseNumbers: [1, 2, 3, 4, 23, 24])
        XCTAssertEqual(slices.count, 2)
        XCTAssertEqual(slices[0].chapter, 3)
        XCTAssertEqual(slices[0].verseNumbers, [1, 2, 3, 4])
        XCTAssertEqual(slices[1].chapter, 4)
        XCTAssertEqual(slices[1].verseNumbers, [5, 6])
    }

    // MARK: - 3. Multi-Chapter and Cross-Chapter Citation Parsing

    func testCrossChapterCitationHebrews() {
        // "Heb 7:25—8:6"
        let spans = BibleDatabase.parseCitationSpans(baseChapter: 7, rawVerses: "25—8:6")
        XCTAssertEqual(spans.count, 2)
        XCTAssertEqual(spans[0].chapter, 7)
        XCTAssertEqual(spans[0].minVerse, 25)
        XCTAssertEqual(spans[1].chapter, 8)
        XCTAssertEqual(spans[1].verseNumbers, [1, 2, 3, 4, 5, 6])
    }

    func testMultiChapterSemicolonIsaiah() {
        // "Is 63:16b-17, 19b; 64:2-7"
        let spans = BibleDatabase.parseCitationSpans(baseChapter: 63, rawVerses: "16b-17, 19b; 64:2-7")
        XCTAssertEqual(spans.count, 2)
        XCTAssertEqual(spans[0].chapter, 63)
        XCTAssertEqual(spans[0].verseNumbers, [16, 17, 19])
        XCTAssertEqual(spans[1].chapter, 64)
        XCTAssertEqual(spans[1].verseNumbers, [2, 3, 4, 5, 6, 7])
    }

    func testThreeChapterSpan() {
        // "Tobit 6:10-11; 7:1bcde, 9-17; 8:4-9a"
        let spans = BibleDatabase.parseCitationSpans(baseChapter: 6, rawVerses: "10-11; 7:1bcde, 9-17; 8:4-9a")
        XCTAssertEqual(spans.count, 3)
        XCTAssertEqual(spans[0].chapter, 6)
        XCTAssertEqual(spans[0].verseNumbers, [10, 11])
        XCTAssertEqual(spans[1].chapter, 7)
        XCTAssertEqual(spans[1].verseNumbers, [1, 9, 10, 11, 12, 13, 14, 15, 16, 17])
        XCTAssertEqual(spans[2].chapter, 8)
        XCTAssertEqual(spans[2].verseNumbers, [4, 5, 6, 7, 8, 9])
    }

    // MARK: - 4. Live SQLite Bible Queries (WEB-C and DRB)

    func testWebCDatabaseQueryPsalm23() async {
        let db = BibleDatabase.webc
        let citation = ReadingCitation(book: "Psalms", chapter: 23, verses: "1-3")
        let verses = await db.queryVerses(citation: citation)
        XCTAssertFalse(verses.isEmpty, "Query must return verses from SQLite")
        let text = await db.formattedText(for: verses)
        XCTAssertTrue(text.contains("LORD is my shepherd") || text.contains("lack nothing"), "WEB-C Psalm 23 uses modern English")
    }

    func testWebCDatabaseQueryMatthew6() async {
        let db = BibleDatabase.webc
        let citation = ReadingCitation(book: "Matthew", chapter: 6, verses: "33")
        let verses = await db.queryVerses(citation: citation)
        XCTAssertFalse(verses.isEmpty)
        let text = await db.formattedText(for: verses)
        XCTAssertTrue(text.contains("seek first God’s Kingdom") || text.contains("righteousness"), "WEB-C Matthew 6:33 text match")
    }

    func testDRBDatabaseQueryPsalm23YieldsLordIsMyShepherd() async {
        let db = BibleDatabase.drb
        let citation = ReadingCitation(book: "Psalms", chapter: 23, verses: "1-3")
        let verses = await db.queryVerses(citation: citation)
        XCTAssertFalse(verses.isEmpty, "Query must return verses from SQLite")
        // In Douay-Rheims, Vulgate Psalm 22:1 text contains "The Lord ruleth me"
        let text = await db.formattedText(for: verses)
        XCTAssertTrue(text.contains("ruleth me") || text.contains("want nothing"), "Psalm 23 citation in DRB must query Vulgate Psalm 22")
    }

    func testDatabaseQueryCrossChapterHebrews() async {
        let db = BibleDatabase.webc
        let citation = ReadingCitation(book: "Hebrews", chapter: 7, verses: "25—8:2")
        let verses = await db.queryVerses(citation: citation)
        XCTAssertFalse(verses.isEmpty)
        let chapters = Set(verses.map(\.chapter))
        XCTAssertTrue(chapters.contains(7), "Must include verses from chapter 7")
        XCTAssertTrue(chapters.contains(8), "Must include verses from chapter 8")
    }
}
