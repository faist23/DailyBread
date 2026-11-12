//
//  VerseOfTheDayProvider.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Intelligently derives the daily liturgical Verse of the Day from Mass readings
/// or canonical liturgical seasonal anchors.
public struct VerseOfTheDayProvider: Sendable {
    
    // MARK: - Public Provider API
    
    /// Derives the Verse of the Day directly from today's active liturgical Mass readings.
    /// If readings are not yet loaded, falls back to a curated liturgical calendar catalog.
    public static func verse(from dailyReadings: DailyReadings?, date: Date = .now) -> VerseOfTheDay {
        if let readings = dailyReadings?.readings, !readings.isEmpty {
            // 1. Gospel Acclamation: The Church's liturgical keynote verse for the day's liturgy
            if let acclamation = readings.first(where: { $0.type == .gospelAcclamation }),
               !acclamation.text.isEmpty {
                let clean = cleanVerseText(acclamation.text)
                if clean.count >= 15 && clean.count <= 280 {
                    let cit = acclamation.citation.displayReference.isEmpty
                        ? "Gospel Acclamation"
                        : acclamation.citation.displayReference
                    return VerseOfTheDay(
                        text: clean,
                        citation: cit,
                        theme: "Gospel Acclamation",
                        sourceNote: "Today's Liturgy"
                    )
                }
            }
            
            // 2. Gospel: The climax of the Liturgy of the Word
            if let gospel = readings.first(where: { $0.type == .gospel }), !gospel.text.isEmpty {
                if let keyVerse = extractKeySentence(from: gospel.text) {
                    return VerseOfTheDay(
                        text: keyVerse,
                        citation: gospel.citation.displayReference,
                        theme: "The Holy Gospel",
                        sourceNote: "Today's Gospel"
                    )
                }
            }
            
            // 3. Responsorial Psalm Antiphon: The congregation's heart prayer for the day
            if let psalm = readings.first(where: { $0.type == .responsorialPsalm }),
               let resp = psalm.effectivePsalmResponse, !resp.isEmpty {
                return VerseOfTheDay(
                    text: resp,
                    citation: psalm.citation.displayReference,
                    theme: "Responsorial Refrain",
                    sourceNote: "Today's Psalm"
                )
            }
        }
        
        // Seasonal fallback when offline or loading
        return seasonalFallbackVerse(for: date)
    }
    
    // MARK: - Key Sentence Extraction
    
    private static func extractKeySentence(from text: String) -> String? {
        let clean = cleanVerseText(text)
        let sentences = clean.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 20 && $0.count <= 220 }
        
        // Prefer sentences containing central words of Christ
        if let christQuote = sentences.first(where: {
            $0.localizedCaseInsensitiveContains("I am") ||
            $0.localizedCaseInsensitiveContains("Whoever") ||
            $0.localizedCaseInsensitiveContains("Blessed are") ||
            $0.localizedCaseInsensitiveContains("Love") ||
            $0.localizedCaseInsensitiveContains("Peace") ||
            $0.localizedCaseInsensitiveContains("Faith") ||
            $0.localizedCaseInsensitiveContains("Father")
        }) {
            return christQuote.hasSuffix(".") ? christQuote : "\(christQuote)."
        }
        
        if let first = sentences.first {
            return first.hasSuffix(".") ? first : "\(first)."
        }
        
        return nil
    }
    
    private static func cleanVerseText(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\\[\\[[^\\]]+\\]\\]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\[\\d+\\]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "℟.", with: "")
            .replacingOccurrences(of: "℣.", with: "")
            .replacingOccurrences(of: "^(Alleluia|Alleluia,|Alleluia!)\\s*", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Seasonal & Liturgical Fallback Catalog
    
    private static func seasonalFallbackVerse(for date: Date) -> VerseOfTheDay {
        let day = LiturgicalCalendar.shared.liturgicalDay(for: date)
        
        switch day.season {
        case .advent:
            return VerseOfTheDay(
                text: "The voice of one crying in the wilderness: Prepare the way of the Lord; make straight his paths.",
                citation: "Matthew 3:3",
                theme: "Hope & Preparation",
                sourceNote: "Season of Advent"
            )
        case .christmas:
            return VerseOfTheDay(
                text: "And the Word became flesh and dwelt among us, and we have seen his glory, full of grace and truth.",
                citation: "John 1:14",
                theme: "The Incarnation",
                sourceNote: "Christmas Season"
            )
        case .lent:
            return VerseOfTheDay(
                text: "Return to me with all your heart, with fasting, with weeping, and with mourning; for the Lord is gracious and merciful.",
                citation: "Joel 2:12-13",
                theme: "Repentance & Mercy",
                sourceNote: "Lenten Season"
            )
        case .paschalTriduum:
            return VerseOfTheDay(
                text: "No one has greater love than this, to lay down one's life for one's friends.",
                citation: "John 15:13",
                theme: "The Sacred Passion",
                sourceNote: "Paschal Triduum"
            )
        case .easter:
            return VerseOfTheDay(
                text: "This is the day the Lord has made; let us rejoice and be glad in it.",
                citation: "Psalms 118:24",
                theme: "The Resurrection",
                sourceNote: "Easter Season"
            )
        case .ordinaryTime:
            // Rotate contemplative verses based on day of year
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
            let fallbackList: [(text: String, cit: String, theme: String)] = [
                ("Trust in the Lord with all your heart, and do not rely on your own insight. In all your ways acknowledge him, and he will make straight your paths.", "Proverbs 3:5-6", "Trust in God"),
                ("The Lord is my light and my salvation; whom shall I fear? The Lord is the stronghold of my life.", "Psalms 27:1", "Courage & Faith"),
                ("Come to me, all who labor and are heavy laden, and I will give you rest. Take my yoke upon you, and learn from me, for I am gentle and lowly in heart.", "Matthew 11:28-29", "Peace in Christ"),
                ("I am the vine; you are the branches. Whoever abides in me and I in him, he it is that bears much fruit, for apart from me you can do nothing.", "John 15:5", "Abiding in Christ"),
                ("Be strong and of good courage; do not be frightened, neither be dismayed; for the Lord your God is with you wherever you go.", "Joshua 1:9", "God's Presence"),
                ("Peace I leave with you; my peace I give to you. Not as the world gives do I give to you. Let not your hearts be troubled, neither let them be afraid.", "John 14:27", "Divine Peace"),
                ("The Lord bless you and keep you; the Lord make his face to shine upon you and be gracious to you; the Lord lift up his countenance upon you and give you peace.", "Numbers 6:24-26", "Aaronic Blessing")
            ]
            let selected = fallbackList[dayOfYear % fallbackList.count]
            return VerseOfTheDay(
                text: selected.text,
                citation: selected.cit,
                theme: selected.theme,
                sourceNote: "Daily Scripture Focus"
            )
        }
    }
}
