//
//  BibleVerse.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Represents a single verse from Sacred Scripture as queried from the Bible database.
public struct BibleVerse: Identifiable, Codable, Hashable, Sendable {
    /// Database primary key or canonical unique verse identifier.
    public let id: Int
    /// 1-based canonical book index (1 = Genesis ... 73 = Revelation).
    public let bookId: Int
    /// Full or standard book name (e.g. "Wisdom", "Matthew").
    public let bookName: String
    /// Chapter number.
    public let chapter: Int
    /// Verse number within the chapter.
    public let verse: Int
    /// Text of the verse.
    public let text: String
    
    /// Designated initializer.
    public init(
        id: Int,
        bookId: Int,
        bookName: String,
        chapter: Int,
        verse: Int,
        text: String
    ) {
        self.id = id
        self.bookId = bookId
        self.bookName = bookName
        self.chapter = chapter
        self.verse = verse
        self.text = text
    }
    
    /// Short citation reference for this verse (e.g. "John 3:16").
    public var reference: String {
        "\(bookName) \(chapter):\(verse)"
    }
}
