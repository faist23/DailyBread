//
//  TodayViewModel.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI
import SwiftData
import Observation

/// View model managing today's Catholic daily Mass readings, liturgical day context,
/// and Saint of the Day.
///
/// Implements the iOS 17 `@Observable` pattern and modern Swift concurrency.
/// Wired to the real LiturgicalCalendar engine, ReadingsRepository, and SaintsDatabase.
@Observable
@MainActor
public final class TodayViewModel {
    
    // MARK: - State Properties
    
    /// The Mass readings for the loaded day.
    public var dailyReadings: DailyReadings?
    
    /// The liturgical day information (season, rank, liturgical color, week).
    public var liturgicalDay: LiturgicalDay?
    
    /// The Saint of the Day commemorated on this date, if any.
    public var saint: Saint?
    
    /// Indicates whether readings are currently being loaded.
    public var isLoading: Bool = false
    
    /// An optional error message if loading fails.
    public var error: String?
    
    /// The date currently displayed.
    public var currentDate: Date = .now
    
    /// The reading currently selected for detail presentation.
    public var selectedReading: Reading?
    
    // MARK: - Dependencies
    
    /// The readings repository providing multi-tier offline/online scripture fetching.
    private var readingsRepository: ReadingsRepository?
    
    /// The liturgical calendar engine for computing feast days, seasons, and ranks.
    private let liturgicalCalendar: LiturgicalCalendar
    
    /// The saints database for looking up commemorated saints by date.
    private let saintsDatabase: SaintsDatabase
    
    // MARK: - Initialization
    
    /// Designated initializer with dependency injection.
    ///
    /// - Parameters:
    ///   - readingsRepository: The repository for fetching readings. Can be set later via `configure(repository:)`.
    ///   - liturgicalCalendar: The liturgical computation engine (defaults to shared singleton).
    ///   - saintsDatabase: The saints lookup database (defaults to shared singleton).
    public init(
        readingsRepository: ReadingsRepository? = nil,
        liturgicalCalendar: LiturgicalCalendar = .shared,
        saintsDatabase: SaintsDatabase = .shared
    ) {
        self.readingsRepository = readingsRepository ?? .shared
        self.liturgicalCalendar = liturgicalCalendar
        self.saintsDatabase = saintsDatabase
    }
    
    /// Configures the readings repository after initialization (e.g., when modelContainer becomes available).
    public func configure(repository: ReadingsRepository) {
        self.readingsRepository = repository
    }
    
    // MARK: - Public Methods
    
    /// Loads the liturgical day, Mass readings, and saint for the given date.
    ///
    /// - Parameter date: The target date for which to fetch readings (defaults to now).
    public func loadReadings(for date: Date = .now) async {
        isLoading = true
        error = nil
        currentDate = date
        
        defer {
            isLoading = false
        }
        
        do {
            if Task.isCancelled { return }

            // 1. Compute liturgical day from the real engine
            let day = liturgicalCalendar.liturgicalDay(for: date)
            self.liturgicalDay = day
            
            // 2. Fetch readings via ReadingsRepository (honoring user's preferred translation)
            let translationPref = UserDefaults.standard.string(forKey: "bibleTranslation") ?? "World English Bible (WEB-C)"
            let targetTranslation: String
            if translationPref.contains("NAB") {
                targetTranslation = "NAB"
            } else if translationPref.contains("Douay") || translationPref.contains("DRB") {
                targetTranslation = "DRB"
            } else {
                targetTranslation = "WEBC"
            }
            
            if let repository = readingsRepository {
                let readings = await repository.getReadings(for: date, preferredTranslation: targetTranslation)
                if Task.isCancelled { return }
                self.dailyReadings = readings
                if targetTranslation == "NAB" {
                    repository.triggerBackgroundPrefetchIfNeeded()
                }
            } else {
                // Fallback: create a minimal ReadingsRepository without SwiftData cache
                let fallbackRepo = ReadingsRepository()
                let readings = await fallbackRepo.getReadings(for: date, preferredTranslation: targetTranslation)
                if Task.isCancelled { return }
                self.dailyReadings = readings
            }
            
            // 3. Look up the Saint of the Day or Solemnity/Feast blurb
            self.saint = saintsDatabase.saint(for: date, liturgicalDay: self.liturgicalDay)
            
        } catch is CancellationError {
            // Silently ignore task cancellation caused by view lifecycle or tab switching
            return
        } catch {
            guard !Task.isCancelled else { return }
            self.error = "Unable to load readings: \(error.localizedDescription)"
        }
    }
    
    /// Refreshes today's readings, forcing an update.
    public func refresh() async {
        // Clear existing data to trigger loading state
        dailyReadings = nil
        liturgicalDay = nil
        saint = nil
        await loadReadings(for: currentDate)
    }
    
    /// Clears any active error banner.
    public func clearError() {
        self.error = nil
    }
}
