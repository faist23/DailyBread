//
//  ReadingsRepository.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+ | SwiftData | Modern Concurrency
//

import Foundation
import SwiftData
import Observation

/// Primary coordinator between offline and online Catholic scripture reading sources.
/// Implements a multi-tier fallback architecture:
/// 1. Primary: Cached NAB readings from SwiftData (`CachedReading`)
/// 2. Secondary: Online Evangelizo API client (`EvangelizioService`)
/// 3. Guaranteed Fallback: Local Douay-Rheims Bible (`BibleDatabase` + `PericoreIndex` + `LiturgicalCalendar`)
@Observable
public final class ReadingsRepository: @unchecked Sendable {
    /// Shared singleton instance accessible across the app.
    public static let shared = ReadingsRepository()

    /// Currently loaded readings for UI observation.
    public var currentReadings: DailyReadings?
    /// Whether a fetch operation is actively underway.
    public var isLoading: Bool = false
    /// Last error description encountered (if any, before successful fallback).
    public var lastError: String?
    /// The translation of the currently active readings ("NAB" or "DRB").
    public var activeTranslation: String = "NAB"
    
    // MARK: - Pre-fetching & Offline Cache State
    
    /// Whether NAB offline pre-fetching is currently running.
    public var isPrefetching: Bool = false
    /// Progress of pre-fetching from 0.0 to 1.0.
    public var prefetchProgress: Double = 0.0
    /// Total days targeted for pre-fetching.
    public var prefetchTotal: Int = 30
    /// Current day index being processed during pre-fetching.
    public var prefetchCurrent: Int = 0
    /// User-facing status string describing the current pre-fetch action.
    public var prefetchStatus: String = ""
    /// Total count of days in the next 30 days cached locally for NAB.
    public var cachedNABDaysCount: Int = 0

    // Dependencies
    private var modelContainer: ModelContainer?
    private let bibleDatabase: BibleDatabase
    private let pericoreIndex: PericoreIndex
    private let evangelizioService: EvangelizioService
    private let liturgicalCalendar: LiturgicalCalendar

    /// Designated initializer.
    public init(
        modelContainer: ModelContainer? = nil,
        bibleDatabase: BibleDatabase = .shared,
        pericoreIndex: PericoreIndex = .shared,
        evangelizioService: EvangelizioService = .shared,
        liturgicalCalendar: LiturgicalCalendar = .shared
    ) {
        self.modelContainer = modelContainer
        self.bibleDatabase = bibleDatabase
        self.pericoreIndex = pericoreIndex
        self.evangelizioService = evangelizioService
        self.liturgicalCalendar = liturgicalCalendar
    }

    /// Configures the SwiftData ModelContainer for persistent caching.
    public func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        purgeExpiredCache()
        Task { @MainActor in
            self.cachedNABDaysCount = self.countCachedNABDays(daysAhead: 30)
        }
    }

    // MARK: - Main Coordination API

    /// Fetches daily Mass readings for a given date with automatic caching and offline fallback.
    ///
    /// - Parameters:
    ///   - date: The target calendar date.
    ///   - preferredTranslation: "NAB" (online preferred) or "DRB" (offline Douay-Rheims).
    ///   - forceRefresh: If true, ignores cached copies and attempts a fresh network fetch.
    /// - Returns: A complete `DailyReadings` instance, guaranteed to return readings even if offline.
    @MainActor
    public func getReadings(
        for date: Date,
        preferredTranslation: String = "NAB",
        forceRefresh: Bool = false
    ) async -> DailyReadings {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let dateKey = CachedReading.makeDateKey(from: date)

        // 1. If user prefers NAB, attempt Cache -> Online -> Offline DRB
        if preferredTranslation.uppercased() == "NAB" {
            // Step 1A: Check SwiftData cache
            if !forceRefresh, let cached = fetchFromCache(dateKey: dateKey, translation: "NAB") {
                if !cached.isExpired, let readings = try? cached.decodeReadings() {
                    // Check if cached readings have valid citations
                    let hasMissingCitations = readings.readings.contains { $0.citation.book.trimmingCharacters(in: .whitespaces).isEmpty }
                    if !hasMissingCitations {
                        self.currentReadings = readings
                        self.activeTranslation = "NAB"
                        return readings
                    }
                    // If citations were missing from a previous cache, fall through to re-fetch/repair
                }
            }

            // Step 1B: Fetch from Evangelizo API
            do {
                let onlineReadings = try await fetchAndVerifyOnlineReadings(for: date)
                self.currentReadings = onlineReadings
                self.activeTranslation = "NAB"
                self.cachedNABDaysCount = countCachedNABDays(daysAhead: 30)
                return onlineReadings
            } catch {
                self.lastError = "Online fetch unavailable: \(error.localizedDescription). Using Douay-Rheims Bible."
            }
        }

        // 2. Guaranteed Fallback: Local Douay-Rheims Bible via BibleDatabase + PericoreIndex
        let fallbackReadings = await generateOfflineDouayRheimsReadings(for: date)
        self.currentReadings = fallbackReadings
        self.activeTranslation = "DRB"
        return fallbackReadings
    }

    /// Fetches and verifies NAB readings from the Evangelizo API, backfilling any missing citations
    /// from the official liturgical calendar/pericope index and saving them directly into SwiftData cache.
    @discardableResult
    public func fetchAndVerifyOnlineReadings(for date: Date) async throws -> DailyReadings {
        let onlineReadings = try await evangelizioService.fetchReadings(for: date)
        
        let liturgicalDay = liturgicalCalendar.liturgicalDay(for: date)
        let lectionaryEntries = pericoreIndex.entries(for: liturgicalDay)
        
        let verifiedReadings = onlineReadings.readings.map { reading -> Reading in
            if reading.citation.book.trimmingCharacters(in: .whitespaces).isEmpty,
               let match = lectionaryEntries.first(where: { $0.type == reading.type }) {
                return Reading(
                    id: reading.id,
                    type: reading.type,
                    citation: match.citation,
                    text: reading.text,
                    response: reading.response,
                    translation: "NAB"
                )
            }
            return reading
        }
        
        let finalDailyReadings = DailyReadings(
            id: onlineReadings.id,
            date: onlineReadings.date,
            liturgicalTitle: onlineReadings.liturgicalTitle,
            readings: verifiedReadings,
            translation: "NAB"
        )

        // Cache successful verified response in SwiftData
        saveToCache(readings: finalDailyReadings, translation: "NAB")
        return finalDailyReadings
    }

    // MARK: - Offline Pre-fetching Engine

    /// Calculates how many days within the next `daysAhead` window currently have unexpired NAB readings stored locally.
    @MainActor
    public func countCachedNABDays(daysAhead: Int = 30) -> Int {
        guard let container = modelContainer else { return 0 }
        let context = ModelContext(container)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<CachedReading>(
            predicate: #Predicate { $0.translation == "NAB" }
        )
        guard let allCached = try? context.fetch(descriptor) else { return 0 }

        let validKeys = Set(allCached.filter { !$0.isExpired }.map { $0.dateKey })

        var count = 0
        for offset in 0..<daysAhead {
            guard let targetDate = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let key = CachedReading.makeDateKey(from: targetDate)
            if validKeys.contains(key) {
                count += 1
            }
        }
        return count
    }

    /// Pre-fetches and caches the next `daysAhead` days of NAB Mass readings into local SwiftData storage.
    ///
    /// Respects server etiquette with gentle 120ms pauses between days and reports live progress.
    /// Skips any days that are already cached and valid.
    ///
    /// - Parameter daysAhead: The number of days ahead to ensure are cached (default: 30).
    /// - Returns: The number of newly downloaded and saved days.
    @MainActor
    @discardableResult
    public func prefetchNABReadings(daysAhead: Int = 30) async -> Int {
        guard !isPrefetching else { return 0 }

        isPrefetching = true
        prefetchProgress = 0.0
        prefetchTotal = daysAhead
        prefetchCurrent = 0
        prefetchStatus = "Checking offline cache..."

        defer {
            isPrefetching = false
            self.cachedNABDaysCount = countCachedNABDays(daysAhead: daysAhead)
            prefetchProgress = 1.0
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var newlyFetched = 0

        for offset in 0..<daysAhead {
            guard let targetDate = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let key = CachedReading.makeDateKey(from: targetDate)

            prefetchCurrent = offset + 1
            prefetchProgress = Double(offset + 1) / Double(daysAhead)

            // If already cached and valid, skip network fetch
            if let cached = fetchFromCache(dateKey: key, translation: "NAB"), !cached.isExpired {
                if let decoded = try? cached.decodeReadings() {
                    let hasMissing = decoded.readings.contains { $0.citation.book.trimmingCharacters(in: .whitespaces).isEmpty }
                    if !hasMissing {
                        continue
                    }
                }
            }

            let dateLabel = targetDate.formatted(.dateTime.month(.abbreviated).day())
            prefetchStatus = "Downloading readings for \(dateLabel)..."

            do {
                _ = try await fetchAndVerifyOnlineReadings(for: targetDate)
                newlyFetched += 1
                self.cachedNABDaysCount = countCachedNABDays(daysAhead: daysAhead)
                // Polite delay between API calls to avoid server rate limits
                try? await Task.sleep(nanoseconds: 120_000_000)
            } catch {
                // If a day fails, continue so the rest of the batch completes
                continue
            }
        }

        prefetchStatus = newlyFetched > 0 ? "Downloaded \(newlyFetched) days of readings." : "All 30 days are up to date."
        return newlyFetched
    }

    /// Automatically triggers a background pre-fetch if fewer than 14 days of NAB readings are cached locally.
    @MainActor
    public func triggerBackgroundPrefetchIfNeeded() {
        guard !isPrefetching else { return }
        let cached = countCachedNABDays(daysAhead: 30)
        self.cachedNABDaysCount = cached

        if cached < 14 {
            Task(priority: .utility) { [weak self] in
                await self?.prefetchNABReadings(daysAhead: 30)
            }
        }
    }

    /// Directly generates Douay-Rheims readings entirely offline without performing any network requests.
    public func getOfflineReadings(for date: Date) async -> DailyReadings {
        return await generateOfflineDouayRheimsReadings(for: date)
    }

    // MARK: - Offline Generation Pipeline

    private func generateOfflineDouayRheimsReadings(for date: Date) async -> DailyReadings {
        let liturgicalDay = liturgicalCalendar.liturgicalDay(for: date)
        let entries = pericoreIndex.entries(for: liturgicalDay)

        var readings: [Reading] = []

        for entry in entries {
            let verses = await bibleDatabase.queryVerses(citation: entry.citation)
            let formattedText = await bibleDatabase.formattedText(for: verses)

            let text = formattedText.isEmpty
                ? "[\(entry.citation.displayReference) — Douay-Rheims offline text.]"
                : formattedText

            let reading = Reading(
                type: entry.type,
                citation: entry.citation,
                text: text,
                response: entry.response,
                translation: "DRB"
            )
            readings.append(reading)
        }

        return DailyReadings(
            date: date,
            liturgicalTitle: liturgicalDay.title,
            readings: readings,
            translation: "DRB"
        )
    }

    // MARK: - SwiftData Persistence Helpers

    private func fetchFromCache(dateKey: String, translation: String) -> CachedReading? {
        guard let container = modelContainer else { return nil }
        let context = ModelContext(container)

        var descriptor = FetchDescriptor<CachedReading>(
            predicate: #Predicate { $0.dateKey == dateKey && $0.translation == translation }
        )
        descriptor.fetchLimit = 1

        do {
            let results = try context.fetch(descriptor)
            return results.first
        } catch {
            return nil
        }
    }

    private func saveToCache(readings: DailyReadings, translation: String) {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)

        do {
            let key = CachedReading.makeDateKey(from: readings.date)
            var descriptor = FetchDescriptor<CachedReading>(
                predicate: #Predicate { $0.dateKey == key }
            )
            descriptor.fetchLimit = 1

            if let existing = try context.fetch(descriptor).first {
                existing.translation = translation
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                existing.readingsJSON = try encoder.encode(readings)
                existing.fetchedAt = .now
            } else {
                let cached = try CachedReading.create(from: readings, translation: translation)
                context.insert(cached)
            }
            try context.save()
        } catch {
            // Non-critical caching error: ignore and proceed
        }
    }

    /// Removes expired readings (older than 90 days) from SwiftData cache.
    public func purgeExpiredCache() {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<CachedReading>()
        guard let allCached = try? context.fetch(descriptor) else { return }

        for item in allCached where item.isExpired {
            context.delete(item)
        }
        try? context.save()
    }
}

// MARK: - Devotional Scripture Bookmarks

/// Represents a saved/bookmarked scripture passage for personal meditation and devotional reflection.
public struct SavedBookmark: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let readingId: UUID
    public let date: Date
    public let liturgicalTitle: String
    public let readingType: ReadingType
    public let citation: ReadingCitation
    public let text: String
    public let response: String?
    public let translation: String
    public let savedAt: Date

    public init(
        id: UUID = UUID(),
        reading: Reading,
        date: Date = .now,
        liturgicalTitle: String,
        savedAt: Date = .now
    ) {
        self.id = id
        self.readingId = reading.id
        self.date = date
        self.liturgicalTitle = liturgicalTitle
        self.readingType = reading.type
        self.citation = reading.citation
        self.text = reading.text
        self.response = reading.response
        self.translation = reading.translation
        self.savedAt = savedAt
    }

    /// Converts this saved bookmark back into a Reading model for reader presentation or audio playback.
    public var asReading: Reading {
        Reading(
            id: readingId,
            type: readingType,
            citation: citation,
            text: text,
            response: response,
            translation: translation
        )
    }
}

/// Service managing devotional bookmarks of beloved Catholic Mass readings and Psalms.
@Observable
@MainActor
public final class BookmarkManager {
    public static let shared = BookmarkManager()

    private static let storageKey = "savedScriptureBookmarks"

    public private(set) var bookmarks: [SavedBookmark] = []

    public init() {
        loadBookmarks()
    }

    public func isBookmarked(reading: Reading) -> Bool {
        bookmarks.contains { $0.readingId == reading.id || ($0.citation == reading.citation && $0.readingType == reading.type) }
    }

    public func toggleBookmark(reading: Reading, date: Date = .now, liturgicalTitle: String = "") {
        if let index = bookmarks.firstIndex(where: { $0.readingId == reading.id || ($0.citation == reading.citation && $0.readingType == reading.type) }) {
            bookmarks.remove(at: index)
        } else {
            let newBookmark = SavedBookmark(
                reading: reading,
                date: date,
                liturgicalTitle: liturgicalTitle.isEmpty ? reading.type.displayTitle : liturgicalTitle
            )
            bookmarks.insert(newBookmark, at: 0)
        }
        saveBookmarks()
    }

    public func removeBookmark(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        saveBookmarks()
    }

    public func removeBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        saveBookmarks()
    }

    private func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.bookmarks = try decoder.decode([SavedBookmark].self, from: data)
        } catch {
            print("Failed to load bookmarks: \(error)")
        }
    }

    private func saveBookmarks() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(bookmarks)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            print("Failed to save bookmarks: \(error)")
        }
    }
}
