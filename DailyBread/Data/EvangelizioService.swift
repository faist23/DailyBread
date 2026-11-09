//
//  EvangelizioService.swift
//  DailyBread
//
//  Created for DailyBread Catholic Daily Readings App.
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
        request.setValue("DailyBread-iOS", forHTTPHeaderField: "User-Agent")

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
            let referenceStr = (item["reference"] as? String)
                ?? (item["citation"] as? String)
                ?? (item["book"] as? String)
                ?? ""
            
            let citation = ReadingCitation.parse(from: referenceStr)
                ?? ReadingCitation(book: referenceStr, verses: "")

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
