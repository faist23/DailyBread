//
//  DailyReadingsApp.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI
import SwiftData

/// The main application entry point for DailyReadings.
///
/// DailyReadings presents the official Catholic daily Mass readings, liturgical calendar,
/// and saints of the day in a calm, contemplative reading environment.
///
/// Creates and injects the `ReadingsRepository` with the SwiftData model container
/// so that online readings are cached for offline access.
@main
struct DailyReadingsApp: App {
    
    /// The SwiftData model container for caching readings.
    private let modelContainer: ModelContainer
    
    /// The shared readings repository wired to the model container and all data services.
    private let readingsRepository: ReadingsRepository
    
    // MARK: - Initialization
    
    init() {
        // Create the SwiftData model container for CachedReading persistence
        let container: ModelContainer
        do {
            container = try ModelContainer(for: CachedReading.self)
        } catch {
            // If SwiftData fails to initialize, create an in-memory fallback
            // so the app still launches (readings will work but not cache)
            do {
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try ModelContainer(for: CachedReading.self, configurations: config)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
        self.modelContainer = container
        
        // Configure the shared ReadingsRepository with the SwiftData model container
        ReadingsRepository.shared.configure(modelContainer: container)
        self.readingsRepository = .shared
    }
    
    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            MainTabView(readingsRepository: readingsRepository)
        }
        .modelContainer(modelContainer)
    }
}
