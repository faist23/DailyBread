//
//  AudioPlaybackTests.swift
//  DailyReadingsTests
//
//  Drives the real speech synthesizer to confirm playback moves through every passage and reading.
//

import XCTest
@testable import DailyReadings

@MainActor
final class AudioPlaybackTests: XCTestCase {

    private func reading(_ type: ReadingType, _ book: String, _ text: String) -> Reading {
        Reading(type: type, citation: ReadingCitation(book: book, chapter: 1, verses: "1-2"), text: text, translation: "WEBC")
    }

    func testPausesSeparateThePartsOfAReading() {
        let long = String(repeating: "The people who walked in darkness have seen a great light. ", count: 12)
        let passages = AudioReadingPlayer.passages(forParts: ["A reading from Isaiah.", long, "The Word of the Lord."])
        XCTAssertEqual(passages.first?.pauseAfter, AudioReadingPlayer.SpeechPause.betweenParts, "pause after the announcement")
        XCTAssertEqual(passages.last?.pauseAfter, AudioReadingPlayer.SpeechPause.afterReading, "pause after the reading")
        XCTAssertEqual(passages.last?.text, "The Word of the Lord.")
        let body = passages.dropFirst().dropLast()
        XCTAssertGreaterThan(body.count, 1)
        XCTAssertEqual(body.last?.pauseAfter, AudioReadingPlayer.SpeechPause.betweenParts, "pause before the acclamation")
        XCTAssertTrue(body.dropLast().allSatisfy { $0.pauseAfter == AudioReadingPlayer.SpeechPause.withinPart })
    }

    func testSkippingMovesBetweenReadings() async throws {
        let player = AudioReadingPlayer.shared
        let readings = [
            reading(.firstReading, "Isaiah", "Comfort my people."),
            reading(.responsorialPsalm, "Psalms", "The Lord is my shepherd."),
            reading(.gospel, "Mark", "Prepare the way of the Lord.")
        ]
        player.start(readings: readings, liturgicalTitle: "Test", liturgicalColor: .green)
        defer { player.stop() }
        player.skipNext()
        XCTAssertEqual(player.currentReadingIndex, 1)
        XCTAssertTrue(player.isPlaying)
        player.skipNext()
        XCTAssertEqual(player.currentReading?.type, .gospel)
        player.skipPrevious()
        XCTAssertEqual(player.currentReadingIndex, 1)
        player.cycleSpeed()
        XCTAssertEqual(player.currentReadingIndex, 1)
        XCTAssertTrue(player.isPlaying)
        player.cycleSpeed(); player.cycleSpeed()   // back to the original speed
    }

    func testPlaybackAdvancesThroughEveryReadingAndThenStops() async throws {
        let player = AudioReadingPlayer.shared
        let readings = [
            reading(.firstReading, "Isaiah", "Comfort my people. Speak tenderly to Jerusalem."),
            reading(.responsorialPsalm, "Psalms", "The Lord is my shepherd."),
            reading(.gospel, "Mark", "The beginning of the Gospel. Prepare the way of the Lord.")
        ]
        player.start(readings: readings, liturgicalTitle: "Test", liturgicalColor: .green)
        defer { player.stop() }

        var seen: [Int] = []
        let deadline = Date().addingTimeInterval(120)
        while Date() < deadline {
            if player.currentReading != nil, seen.last != player.currentReadingIndex { seen.append(player.currentReadingIndex) }
            if !player.isPlaying && !player.isPaused && player.currentReading == nil { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertEqual(seen, [0, 1, 2], "Readings reached, in order")
        XCTAssertFalse(player.isPlaying, "Playback ends after the last reading")
    }

    func testLiturgicalSpeechAnnouncementsOmitVerses() {
        let firstReading = Reading(
            type: .firstReading,
            citation: ReadingCitation(book: "Philemon", chapter: 1, verses: "7-20"),
            text: "I have had great joy in your love.",
            translation: "WEBC"
        )
        let firstParts = AudioReadingPlayer.liturgicalSpeechParts(for: firstReading)
        XCTAssertEqual(firstParts.first, "First Reading. A reading from the Letter of Saint Paul to Philemon.")
        XCTAssertFalse(firstParts.first!.contains("1:7-20"))

        let psalm = Reading(
            type: .responsorialPsalm,
            citation: ReadingCitation(book: "Psalms", chapter: 146, verses: "7, 8-9a, 9bc-10"),
            text: "Stanza 1\n\nStanza 2",
            response: "Praise the Lord, my soul!",
            translation: "WEBC"
        )
        let psalmParts = AudioReadingPlayer.liturgicalSpeechParts(for: psalm)
        XCTAssertEqual(psalmParts.first, "Responsorial Psalm. Psalm 146.")
        XCTAssertFalse(psalmParts.first!.contains("7, 8-9a"))

        let gospel = Reading(
            type: .gospel,
            citation: ReadingCitation(book: "Mark", chapter: 1, verses: "1-8"),
            text: "The beginning of the Gospel of Jesus Christ.",
            translation: "WEBC"
        )
        let gospelParts = AudioReadingPlayer.liturgicalSpeechParts(for: gospel)
        XCTAssertEqual(gospelParts.first, "The Holy Gospel according to Mark.")
        XCTAssertFalse(gospelParts.first!.contains("1:1-8"))
    }
}
