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
                let onlineReadings = try await evangelizioService.fetchReadings(for: date)
                
                // Safety net: ensure all citations are complete, backfilling from official USCCB lectionary if necessary
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
                self.currentReadings = finalDailyReadings
                self.activeTranslation = "NAB"
                return finalDailyReadings
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

    /// Directly generates Douay-Rheims readings entirely offline without performing any network requests.
    public func getOfflineReadings(for date: Date) async -> DailyReadings {
        return await generateOfflineDouayRheimsReadings(for: date)
    }

    // MARK: - Offline Generation Pipeline

    private func generateOfflineDouayRheimsReadings(for date: Date) async -> DailyReadings {
        let dateKey = CachedReading.makeDateKey(from: date)

        // Check if DRB reading is already cached in SwiftData
        if let cached = fetchFromCache(dateKey: dateKey, translation: "DRB"),
           !cached.isExpired,
           let readings = try? cached.decodeReadings() {
            return readings
        }

        // 1. Determine liturgical day and feast via LiturgicalCalendar engine
        let liturgicalDay = liturgicalCalendar.liturgicalDay(for: date)

        // 2. Query Lectionary citations and entries via PericoreIndex
        let entries = pericoreIndex.entries(for: liturgicalDay)

        // 3. Query Douay-Rheims verses from BibleDatabase
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

        let dailyReadings = DailyReadings(
            date: date,
            liturgicalTitle: liturgicalDay.title,
            readings: readings,
            translation: "DRB"
        )

        // Cache the offline-generated readings for fast subsequent access
        saveToCache(readings: dailyReadings, translation: "DRB")

        return dailyReadings
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
            let cached = try CachedReading.create(from: readings, translation: translation)
            context.insert(cached)
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
