//
//  LectionaryCoverageTests.swift
//  DailyReadingsTests
//
//  Walks the real bundled lectionary and both bundled Bibles, so a citation that resolves to
//  nothing, to the wrong verses, or to no readings at all fails here rather than on a device.
//

import XCTest
@testable import DailyReadings

final class LectionaryCoverageTests: XCTestCase {

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> LiturgicalDay {
        let date = utc.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
        return LiturgicalCalendar.day(for: date, calendar: utc)
    }

    private func text(_ db: BibleDatabase, _ reference: String) async -> (verses: [BibleVerse], text: String) {
        let citation = ReadingCitation.parse(from: reference)!
        let verses = await db.queryVerses(citation: citation)
        return (verses, await db.formattedText(for: verses))
    }

    // MARK: - Whole-lectionary walk

    func testEveryCitationThrough2028ResolvesInBothBibles() async {
        var unresolved: [String] = []
        var date = utc.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 12))!
        let end = utc.date(from: DateComponents(year: 2028, month: 12, day: 31, hour: 12))!
        while date <= end {
            let liturgicalDay = LiturgicalCalendar.day(for: date, calendar: utc)
            for entry in PericoreIndex.shared.entries(for: liturgicalDay) {
                if await BibleDatabase.webc.queryVerses(citation: entry.citation).isEmpty {
                    unresolved.append("WEB-C \(liturgicalDay.id) \(entry.citation.displayReference)")
                }
                if await BibleDatabase.drb.queryVerses(citation: entry.citation).isEmpty {
                    unresolved.append("DRB \(liturgicalDay.id) \(entry.citation.displayReference)")
                }
            }
            date = utc.date(byAdding: .day, value: 1, to: date)!
        }
        XCTAssertTrue(unresolved.isEmpty, "Citations that return no verses: \(unresolved.prefix(20))")
    }

    func testDaysBeyondTheDatedDataStillHaveAGospel() {
        // lectionary_dates.json has no usable readings after 2027-05-31. The cycle index must carry on.
        var withoutGospel: [String] = []
        var date = utc.date(from: DateComponents(year: 2027, month: 6, day: 1, hour: 12))!
        let end = utc.date(from: DateComponents(year: 2027, month: 12, day: 31, hour: 12))!
        while date <= end {
            let liturgicalDay = LiturgicalCalendar.day(for: date, calendar: utc)
            if !PericoreIndex.shared.entries(for: liturgicalDay).contains(where: { $0.type == .gospel }) {
                withoutGospel.append("\(liturgicalDay.id) \(liturgicalDay.title)")
            }
            date = utc.date(byAdding: .day, value: 1, to: date)!
        }
        // Known gap: Thursday of the Third Week of Advent never appears in the dated data.
        XCTAssertLessThanOrEqual(withoutGospel.count, 1, "Days with no Gospel: \(withoutGospel)")
    }

    func testOrdinaryTimeWeekdayFollowsItsOwnYear() {
        // Tuesday of the 23rd Week: Year I reads Colossians, Year II reads 1 Corinthians; the Gospel is shared.
        let (dayOne, dayTwo) = (day(2027, 9, 7), day(2028, 9, 12))
        XCTAssertEqual(dayOne.title, "Tuesday of the Twenty-Third Week in Ordinary Time")
        XCTAssertEqual(dayTwo.title, dayOne.title)
        let yearOne = PericoreIndex.shared.cycleEntries(for: dayOne)
        let yearTwo = PericoreIndex.shared.cycleEntries(for: dayTwo)
        XCTAssertEqual(BibleBook.find(named: yearOne.first { $0.type == .firstReading }?.citation.book ?? ""), .colossians)
        XCTAssertEqual(BibleBook.find(named: yearTwo.first { $0.type == .firstReading }?.citation.book ?? ""), .firstCorinthians)
        XCTAssertEqual(yearOne.first { $0.type == .gospel }?.citation.chapter, yearTwo.first { $0.type == .gospel }?.citation.chapter)
    }

    func testAscensionSundayReadsTheAscensionNotTheSeventhSunday() {
        let entries = PericoreIndex.shared.entries(for: day(2027, 5, 9))
        let first = entries.first { $0.type == .firstReading }?.citation
        XCTAssertEqual(first?.chapter, 1)
        XCTAssertEqual(first?.verses, "1-11")
        XCTAssertEqual(BibleBook.find(named: entries.first { $0.type == .gospel }?.citation.book ?? ""), .mark)
    }

    func testADayWithNoDataReturnsNothingRatherThanInventedReadings() {
        // Fourth Sunday in Ordinary Time, Year C, has never appeared in the dated data.
        XCTAssertTrue(PericoreIndex.shared.entries(for: day(2028, 1, 30)).isEmpty)
    }

    // MARK: - Lectionary numbering → each Bible's numbering

    func testPsalm51StartsAtHaveMercyInBothBibles() async {
        let webc = await text(.webc, "Psalm 51:3-4, 5-6, 12-13")
        XCTAssertTrue(webc.text.hasPrefix("Have mercy on me"), webc.text)
        XCTAssertEqual(webc.verses.count, 6)
        let drb = await text(.drb, "Psalm 51:3-4, 5-6, 12-13")
        XCTAssertTrue(drb.text.hasPrefix("Have mercy on me"), drb.text)
    }

    func testPsalmTitleIsNotRead() async {
        let webc = await text(.webc, "Psalm 23:1-3a, 3b-4, 5, 6")
        XCTAssertTrue(webc.text.hasPrefix("The LORD is my shepherd"), webc.text)
    }

    func testJoelAndMalachiMapInWebC() async {
        let joel = await text(.webc, "Joel 3:1-5")
        XCTAssertEqual(joel.verses.map { "\($0.chapter):\($0.verse)" }, ["2:28", "2:29", "2:30", "2:31", "2:32"])
        let malachi = await text(.webc, "Malachi 3:19-20a")
        XCTAssertEqual(malachi.verses.map { "\($0.chapter):\($0.verse)" }, ["4:1", "4:2"])
    }

    func testIsaiahAndZechariahChapterBreaksMapInBothBibles() async {
        let isaiah = await text(.webc, "Is 8:23—9:3")
        XCTAssertEqual(isaiah.verses.map { "\($0.chapter):\($0.verse)" }, ["9:1", "9:2", "9:3", "9:4"])
        for db in [BibleDatabase.webc, BibleDatabase.drb] {
            let zechariah = await text(db, "Zechariah 2:14-17")
            XCTAssertEqual(zechariah.verses.map { "\($0.chapter):\($0.verse)" }, ["2:10", "2:11", "2:12", "2:13"])
        }
    }

    func testRomansDoxologyIsFoundInWebC() async {
        let romans = await text(.webc, "Romans 16:25-27")
        XCTAssertEqual(romans.verses.count, 3)
        XCTAssertTrue(romans.text.contains("able to establish you"), romans.text)
    }

    func testEstherAdditionCIsFoundInBothBibles() async {
        let webc = await text(.webc, "Esther C:12, 14-16, 23-25")
        XCTAssertEqual(webc.verses.count, 7)
        XCTAssertTrue(webc.text.contains("you alone are our king"), webc.text)
        let drb = await text(.drb, "Esther C:12, 14-16, 23-25")
        XCTAssertEqual(drb.verses.count, 7)
        XCTAssertTrue(drb.text.contains("O my Lord"), drb.text)
    }

    // MARK: - Citation parsing

    func testLongOrShortFormReadsTheLongFormInTheRightChapter() async {
        let matthew = await text(.webc, "Mt 4:12-23 or 4:12-17")
        XCTAssertEqual(Set(matthew.verses.map(\.chapter)), [4])
        XCTAssertEqual(matthew.verses.count, 12)
    }

    func testOpenEndedRangePastTheChapterEndIsNotTheWholeChapter() async {
        // Douay-Rheims has no mapping row that would rescue 8:23, so this must not return all of chapter 8.
        let isaiah = await text(.drb, "Is 8:23—9:3")
        XCTAssertLessThan(isaiah.verses.count, 8)
    }

    func testBookNameVariants() async {
        let roman = await text(.webc, "II Corinthians 5:1-5")
        XCTAssertEqual(roman.verses.count, 5)
        let glued = await text(.webc, "Psalm103:1-2, 11-12, 19-20")
        XCTAssertEqual(glued.verses.count, 6)
    }

    // MARK: - Rosary

    func testRosaryMysteriesFollowTheWeeklySchedule() {
        // 8-14 November 2026 runs Sunday to Saturday.
        let expected: [RosaryMysteryType] = [.glorious, .joyful, .sorrowful, .glorious, .luminous, .sorrowful, .joyful]
        for (offset, mystery) in expected.enumerated() {
            let date = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 8 + offset, hour: 12))!
            XCTAssertEqual(RosaryMysteryType.forDate(date), mystery, "day offset \(offset)")
        }
    }

    // MARK: - Audio passages

    @MainActor
    func testSpeechIsSplitIntoShortPassagesWithoutLosingText() {
        let sentence = "In those days a decree went out from Caesar Augustus that the whole world should be enrolled. "
        let reading = String(repeating: sentence, count: 12)
        let chunks = AudioReadingPlayer.speechChunks(reading)
        XCTAssertGreaterThan(chunks.count, 2)
        XCTAssertTrue(chunks.allSatisfy { $0.count <= 420 })
        XCTAssertEqual(chunks.joined(separator: " ").filter { !$0.isWhitespace }, reading.filter { !$0.isWhitespace })
        XCTAssertEqual(AudioReadingPlayer.speechChunks("The Word of the Lord."), ["The Word of the Lord."])
    }
}
