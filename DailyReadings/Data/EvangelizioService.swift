//
//  EvangelizioService.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+ | URLSession
//

import Foundation

/// Errors that can occur during Evangelizo API network requests or response parsing.
public enum EvangelizioError: LocalizedError, Sendable {
    case invalidURL(String)
    case networkError(String)
    case badServerResponse(statusCode: Int)
    case decodingError(String)
    case noReadingsFound

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid Evangelizo endpoint URL: \(url)"
        case .networkError(let message):
            return "Network communication error: \(message)"
        case .badServerResponse(let code):
            return "Evangelizo server returned HTTP status \(code)."
        case .decodingError(let details):
            return "Failed to parse Evangelizo JSON: \(details)"
        case .noReadingsFound:
            return "No scripture readings found in the Evangelizo response for this date."
        }
    }
}

/// Modern async/await API client for fetching online Catholic Mass readings (NAB) from Evangelizo.
/// Base URL: https://publication.evangelizo.ws/AM/days/
public actor EvangelizioService {
    /// Shared actor instance.
    public static let shared = EvangelizioService()

    private let baseURLString: String
    private let urlSession: URLSession

    /// Designated initializer with configurable base URL and URLSession configuration.
    public init(
        baseURLString: String = "https://publication.evangelizo.ws/AM/days/",
        urlSession: URLSession? = nil
    ) {
        self.baseURLString = baseURLString
        if let session = urlSession {
            self.urlSession = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15
            config.timeoutIntervalForResource = 30
            config.requestCachePolicy = .reloadRevalidatingCacheData
            self.urlSession = URLSession(configuration: config)
        }
    }

    // MARK: - Public Fetch API

    /// Fetches and parses Catholic daily Mass readings for a given date from the Evangelizo API.
    /// Returns a structured `DailyReadings` instance with translation set to "NAB".
    public func fetchReadings(for date: Date) async throws -> DailyReadings {
        let dateString = formatDate(date)
        guard let url = URL(string: "\(baseURLString)\(dateString)") else {
            throw EvangelizioError.invalidURL("\(baseURLString)\(dateString)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("DailyReadings-iOS", forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            throw EvangelizioError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EvangelizioError.badServerResponse(statusCode: 0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw EvangelizioError.badServerResponse(statusCode: httpResponse.statusCode)
        }

        return try parseEvangelizoJSON(data, date: date)
    }

    // MARK: - Response Parsing

    private func parseEvangelizoJSON(_ data: Data, date: Date) throws -> DailyReadings {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw EvangelizioError.decodingError("Root JSON is not a valid dictionary.")
        }

        // Support root dictionary or nested "data" wrapper
        let root = (jsonObject["data"] as? [String: Any]) ?? jsonObject

        // Extract liturgical title
        let liturgicalTitle = extractLiturgicalTitle(from: root) ?? "Catholic Mass Readings"

        // Extract raw readings list
        let rawReadings: [[String: Any]]
        if let list = root["readings"] as? [[String: Any]] {
            rawReadings = list
        } else if let list = root["texts"] as? [[String: Any]] {
            rawReadings = list
        } else if let list = root["items"] as? [[String: Any]] {
            rawReadings = list
        } else {
            throw EvangelizioError.noReadingsFound
        }

        var parsedReadings: [Reading] = []

        for (index, item) in rawReadings.enumerated() {
            let type = determineReadingType(from: item, index: index, total: rawReadings.count)
            let citation = extractCitation(from: item)

            let rawText = (item["text"] as? String)
                ?? (item["content"] as? String)
                ?? ""
            let cleanText = cleanHTML(rawText)

            let rawResponse = (item["response"] as? String)
                ?? (item["verse_response"] as? String)
                ?? (item["refrain"] as? String)
            let cleanResponse = rawResponse != nil ? cleanHTML(rawResponse!) : nil

            let reading = Reading(
                type: type,
                citation: citation,
                text: cleanText,
                response: cleanResponse,
                translation: "NAB"
            )
            parsedReadings.append(reading)
        }

        guard !parsedReadings.isEmpty else {
            throw EvangelizioError.noReadingsFound
        }

        return DailyReadings(
            date: date,
            liturgicalTitle: liturgicalTitle,
            readings: parsedReadings,
            translation: "NAB"
        )
    }

    // MARK: - Classification Helpers

    private func determineReadingType(from item: [String: Any], index: Int, total: Int) -> ReadingType {
        let typeString = ((item["type"] as? String) ?? (item["title"] as? String) ?? "").lowercased()

        if typeString.contains("first") || typeString.contains("reading_1") || typeString.contains("1st") {
            return .firstReading
        } else if typeString.contains("psalm") || typeString.contains("responsorial") {
            return .responsorialPsalm
        } else if typeString.contains("second") || typeString.contains("reading_2") || typeString.contains("2nd") {
            return .secondReading
        } else if typeString.contains("sequence") {
            return .sequence
        } else if typeString.contains("acclamation") || typeString.contains("alleluia") {
            return .gospelAcclamation
        } else if typeString.contains("gospel") {
            return .gospel
        }

        // Fallback by standard liturgical order if type string is ambiguous
        if index == 0 {
            return .firstReading
        } else if index == 1 {
            return .responsorialPsalm
        } else if index == total - 1 {
            return .gospel
        } else if total >= 4 && index == total - 2 {
            return .gospelAcclamation
        } else if total >= 4 && index == 2 {
            return .secondReading
        }

        return .firstReading
    }

    private func extractLiturgicalTitle(from dict: [String: Any]) -> String? {
        if let title = dict["liturgical_title"] as? String, !title.isEmpty {
            return cleanHTML(title)
        }
        if let title = dict["title"] as? String, !title.isEmpty {
            return cleanHTML(title)
        }
        if let title = dict["feast"] as? String, !title.isEmpty {
            return cleanHTML(title)
        }
        if let title = dict["description"] as? String, !title.isEmpty {
            return cleanHTML(title)
        }
        return nil
    }

    // MARK: - Citation Extraction

    private func extractCitation(from item: [String: Any]) -> ReadingCitation {
        // 1. Direct formatted reference if provided as a string
        if let direct = (item["reference"] as? String) ?? (item["citation"] as? String), !direct.isEmpty {
            if let parsed = ReadingCitation.parse(from: direct) {
                return parsed
            }
        }
        
        // 2. Extract book name from dictionary or string
        var rawBookName = ""
        if let bookDict = item["book"] as? [String: Any] {
            rawBookName = (bookDict["short_title"] as? String)
                ?? (bookDict["full_title"] as? String)
                ?? (bookDict["code"] as? String)
                ?? ""
        }
        if rawBookName.isEmpty {
            rawBookName = (item["title"] as? String) ?? (item["book"] as? String) ?? ""
        }
        
        // Clean and resolve to canonical English book name (e.g. "Ezek" -> "Ezekiel", "1_Co" -> "1 Corinthians")
        let cleanRawBook = rawBookName.replacingOccurrences(of: "_", with: " ")
        let canonicalBook = BibleBook.find(named: cleanRawBook)?.canonicalName ?? cleanRawBook
        
        // 3. Format reference_displayed (e.g. "47,1-2.8-9.12." -> "47:1-2, 8-9, 12")
        let rawRef = (item["reference_displayed"] as? String) ?? ""
        let formattedReference = formatEvangelizoReference(book: canonicalBook, rawRef: rawRef)
        
        if let parsed = ReadingCitation.parse(from: formattedReference) {
            return parsed
        }
        
        // 4. Fallback: Parse reading_code (e.g. "Jn 2,13-22" or "1_Co 3,9c-11#1_Co 3,16-17")
        if let readingCode = item["reading_code"] as? String, !readingCode.isEmpty {
            let codeFormatted = formatReadingCode(readingCode, fallbackBook: canonicalBook)
            if let parsed = ReadingCitation.parse(from: codeFormatted) {
                return parsed
            }
        }
        
        return ReadingCitation(book: canonicalBook, verses: rawRef)
    }

    private func formatEvangelizoReference(book: String, rawRef: String) -> String {
        let trimmed = rawRef
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard !trimmed.isEmpty else { return book }
        
        // Remove Septuagint/Vulgate alternate numbering in parentheses, e.g. "46(45)" -> "46"
        var cleanRef = trimmed.replacingOccurrences(of: "\\(\\d+\\)", with: "", options: .regularExpression)
        
        // Evangelizo uses a comma to separate chapter from verses
        if let commaIndex = cleanRef.firstIndex(of: ",") {
            let chapter = String(cleanRef[..<commaIndex]).trimmingCharacters(in: .whitespaces)
            var verses = String(cleanRef[cleanRef.index(after: commaIndex)...]).trimmingCharacters(in: .whitespaces)
            verses = verses.replacingOccurrences(of: ".", with: ", ")
            return "\(book) \(chapter):\(verses)"
        } else {
            cleanRef = cleanRef.replacingOccurrences(of: ".", with: ", ")
            return "\(book) \(cleanRef)"
        }
    }

    private func formatReadingCode(_ code: String, fallbackBook: String) -> String {
        let segments = code.split(separator: "#")
        var formattedParts: [String] = []
        var detectedBook = fallbackBook
        
        for segment in segments {
            let part = segment.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: ",", with: ":")
            let components = part.split(separator: " ")
            if components.count >= 2 {
                let bookCode = String(components[0])
                if let matched = BibleBook.find(named: bookCode)?.canonicalName {
                    detectedBook = matched
                }
                formattedParts.append(String(components[1]))
            } else {
                formattedParts.append(part)
            }
        }
        
        let combinedVerses = formattedParts.joined(separator: ", ")
        return "\(detectedBook) \(combinedVerses)"
    }

    // MARK: - HTML Sanitization

    private func cleanHTML(_ html: String) -> String {
        var text = html
            // Strip Evangelizo inline scripture reference tags like [[Jn 2,13]] or [[Ez 47,1]]
            .replacingOccurrences(of: "\\[\\[[^\\]]+\\]\\]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&rsquo;", with: "’")
            .replacingOccurrences(of: "&lsquo;", with: "‘")
            .replacingOccurrences(of: "&ldquo;", with: "“")
            .replacingOccurrences(of: "&rdquo;", with: "”")
            .replacingOccurrences(of: "&mdash;", with: "—")
            .replacingOccurrences(of: "&ndash;", with: "–")

        // Clean redundant indentation and line breaks
        text = text.replacingOccurrences(of: "(?m)^[ \\t]+", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
