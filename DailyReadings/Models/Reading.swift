//
//  Reading.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// The liturgical type/category of a Catholic Mass scripture reading.
public enum ReadingType: String, Codable, CaseIterable, Sendable {
    case firstReading = "First Reading"
    case responsorialPsalm = "Responsorial Psalm"
    case secondReading = "Second Reading"
    case gospelAcclamation = "Gospel Acclamation"
    case gospel = "Gospel"
    case sequence = "Sequence"
    
    /// Short display title suitable for compact badges or tab headers.
    public var shortName: String {
        switch self {
        case .firstReading:
            return "Reading 1"
        case .responsorialPsalm:
            return "Psalm"
        case .secondReading:
            return "Reading 2"
        case .gospelAcclamation:
            return "Acclamation"
        case .gospel:
            return "Gospel"
        case .sequence:
            return "Sequence"
        }
    }
    
    /// Default canonical order in the Catholic Mass liturgy.
    public var liturgicalOrder: Int {
        switch self {
        case .firstReading: return 1
        case .responsorialPsalm: return 2
        case .secondReading: return 3
        case .sequence: return 4
        case .gospelAcclamation: return 5
        case .gospel: return 6
        }
    }
    
    /// Full display title matching rawValue.
    public var displayTitle: String {
        rawValue
    }
}

/// Represents a Scripture passage citation (book, optional chapter, verse range).
public struct ReadingCitation: Codable, Hashable, Sendable {
    /// Canonical or commonly abbreviated book name (e.g. "Wisdom", "Wis", "Matthew").
    public let book: String
    /// Chapter number, or nil for single-chapter books (e.g. Philemon, Jude).
    public let chapter: Int?
    /// Verse range string (e.g. "1-5", "1, 3-4, 6", or "1-3a, 3b-4").
    public let verses: String
    
    /// Memberwise initializer.
    public init(book: String, chapter: Int? = nil, verses: String) {
        self.book = book.trimmingCharacters(in: .whitespacesAndNewlines)
        self.chapter = chapter
        self.verses = verses.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Convenience initializer using start and end verse integers.
    public init(book: String, chapter: Int? = nil, verseStart: Int, verseEnd: Int, reference: String? = nil) {
        self.book = book.trimmingCharacters(in: .whitespacesAndNewlines)
        self.chapter = chapter
        self.verses = "\(verseStart)-\(verseEnd)"
    }
    
    /// Alias for displayReference.
    public var reference: String {
        displayReference
    }
    
    /// Formatted human-readable reference (e.g. "Wisdom 3:1-9" or "Philemon 9-10").
    public var displayReference: String {
        if let chapter {
            return "\(book) \(chapter):\(verses)"
        }
        return "\(book) \(verses)"
    }
    
    /// Parses a standard reference string (e.g. "Wisdom 3:1-9", "Ps 23:1-3a, 3b-4", "Phlm 9-10").
    public static func parse(from reference: String) -> ReadingCitation? {
        var trimmed = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        // Strip common lectionary note prefixes
        let prefixes = ["See ", "see ", "SEE ", "Cf. ", "cf. ", "CF. ", "Cf ", "cf "]
        for prefix in prefixes {
            if trimmed.hasPrefix(prefix) {
                trimmed = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // Match "Book Chapter:Verses"
        if let colonIndex = trimmed.firstIndex(of: ":") {
            let beforeColon = trimmed[..<colonIndex].trimmingCharacters(in: .whitespaces)
            let verses = trimmed[trimmed.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
            
            // Extract the chapter (trailing digits in beforeColon)
            if let lastSpace = beforeColon.lastIndex(of: " ") {
                let bookPart = String(beforeColon[..<lastSpace]).trimmingCharacters(in: .whitespaces)
                let chapterPart = String(beforeColon[beforeColon.index(after: lastSpace)...]).trimmingCharacters(in: .whitespaces)
                if let chapterNum = Int(chapterPart) {
                    return ReadingCitation(book: bookPart, chapter: chapterNum, verses: verses)
                }
            } else if let chapterNum = Int(beforeColon) {
                // If beforeColon is purely a number, it refers to a Psalm number (e.g., "103:1-2")
                return ReadingCitation(book: "Psalms", chapter: chapterNum, verses: verses)
            }
        }
        
        // Single-chapter books or direct verses (e.g. "Philemon 9-10")
        if let lastSpace = trimmed.lastIndex(of: " ") {
            let bookPart = String(trimmed[..<lastSpace]).trimmingCharacters(in: .whitespaces)
            let versePart = String(trimmed[trimmed.index(after: lastSpace)...]).trimmingCharacters(in: .whitespaces)
            return ReadingCitation(book: bookPart, chapter: nil, verses: versePart)
        }
        
        return ReadingCitation(book: trimmed, chapter: nil, verses: "")
    }
}

/// Model for a single Catholic Mass scripture reading.
public struct Reading: Identifiable, Codable, Hashable, Sendable {
    /// Unique identifier for this reading instance.
    public let id: UUID
    /// The liturgical type/role of this reading (e.g. First Reading, Gospel).
    public let type: ReadingType
    /// The passage citation.
    public let citation: ReadingCitation
    /// The scripture text.
    public let text: String
    /// For psalms: the congregational refrain/response.
    public let response: String?
    /// Alias for response.
    public var psalmResponse: String? { response }
    
    /// For psalms: the canonical congregational refrain/response, guaranteed to return
    /// the liturgical antiphon even if the remote API payload omitted it.
    public var effectivePsalmResponse: String? {
        guard type == .responsorialPsalm else { return nil }
        if let response, !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return response.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return PsalmResponseProvider.response(for: citation, text: text)
    }
    
    /// Translation identifier: "DRB" (Douay-Rheims) or "NAB" (New American Bible).
    public let translation: String
    
    /// Sanitizes and formats scripture text:
    /// - Strips Evangelizo inline verse reference brackets like `[[Jn 2,13]]` or `[[...]]`.
    /// - For prose readings (Epistles, Gospels, OT narrative), joins individual verses into flowing paragraphs.
    /// - For psalms, preserves stanzas separated by `\n\n` while keeping poetic lines cleanly spaced.
    public static func sanitizeText(_ rawText: String, type: ReadingType? = nil) -> String {
        var text = rawText
            // 1. Strip inline verse reference brackets like [[Jn 2,13]] or [[Ap 7,2]]
            .replacingOccurrences(of: "\\[\\[[^\\]]+\\]\\]", with: "", options: .regularExpression)
            // 2. Standardize line endings
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        // 3. For Psalms, preserve stanza structure
        if type == .responsorialPsalm {
            text = text.replacingOccurrences(of: "(?m)^[ \\t]+", with: "", options: .regularExpression)
            text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 4. For prose readings (First Reading, Second Reading, Gospel, Acclamation, Sequence):
        // Preserve intentional paragraph breaks (two or more newlines) while flowing single-line verse breaks
        let paragraphs = text.components(separatedBy: "\n\n")

        let cleanedParagraphs = paragraphs.compactMap { paragraph -> String? in
            let flow = paragraph
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return flow.isEmpty ? nil : flow
        }

        return cleanedParagraphs.joined(separator: "\n\n")
    }

    /// Designated initializer.
    public init(
        id: UUID = UUID(),
        type: ReadingType,
        citation: ReadingCitation,
        text: String,
        response: String? = nil,
        psalmResponse: String? = nil,
        translation: String = "NAB"
    ) {
        self.id = id
        self.type = type
        self.citation = citation
        self.text = Self.sanitizeText(text, type: type)
        let rawResp = response ?? psalmResponse
        let cleanedResp = rawResp != nil ? Self.sanitizeText(rawResp!, type: type) : nil
        if type == .responsorialPsalm && (cleanedResp == nil || cleanedResp?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true) {
            self.response = PsalmResponseProvider.response(for: citation, text: text)
        } else {
            self.response = cleanedResp
        }
        self.translation = translation
    }
    
    // MARK: - Codable Implementation
    
    private enum CodingKeys: String, CodingKey {
        case id, type, citation, text, response, translation
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.type = try container.decode(ReadingType.self, forKey: .type)
        self.citation = try container.decode(ReadingCitation.self, forKey: .citation)
        let rawText = try container.decode(String.self, forKey: .text)
        self.text = Self.sanitizeText(rawText, type: self.type)
        if let rawResp = try container.decodeIfPresent(String.self, forKey: .response),
           !rawResp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.response = Self.sanitizeText(rawResp, type: self.type)
        } else if self.type == .responsorialPsalm {
            self.response = PsalmResponseProvider.response(for: self.citation, text: self.text)
        } else {
            self.response = nil
        }
        self.translation = try container.decode(String.self, forKey: .translation)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(citation, forKey: .citation)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(response, forKey: .response)
        try container.encode(translation, forKey: .translation)
    }
}
