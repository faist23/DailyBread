//
//  MainTabView.swift
//  DailyBread
//
//  Created for DailyBread Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Main container view providing 3-tab navigation across DailyBread:
/// Today's readings, Liturgical Calendar, and Settings.
///
/// Dynamically updates the tab bar tint to reflect the active liturgical color.
public struct MainTabView: View {
    
    // MARK: - State & View Models
    
    @State private var selectedTab: Tab = .today
    @State private var todayViewModel: TodayViewModel
    @State private var calendarViewModel = CalendarViewModel()
    
    /// The shared readings repository injected from the app level.
    private let readingsRepository: ReadingsRepository
    
    // MARK: - Tab Item Enum
    
    public enum Tab: Int, Hashable {
        case today = 0
        case calendar = 1
        case settings = 2
    }
    
    // MARK: - Initialization
    
    /// Creates the main tab view with an injected readings repository.
    ///
    /// - Parameter readingsRepository: The repository for fetching scripture readings,
    ///   wired to SwiftData caching, Evangelizo API, and offline Douay-Rheims fallback.
    public init(readingsRepository: ReadingsRepository) {
        self.readingsRepository = readingsRepository
        self._todayViewModel = State(initialValue: TodayViewModel(readingsRepository: readingsRepository))
    }
    
    // MARK: - Body
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Today
            NavigationStack {
                TodayView(viewModel: todayViewModel)
            }
            .tabItem {
                Label("Today", systemImage: selectedTab == .today ? "house.fill" : "house")
            }
            .tag(Tab.today)
            
            // Tab 2: Calendar
            NavigationStack {
                CalendarView(viewModel: calendarViewModel)
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(Tab.calendar)
            
            // Tab 3: Settings
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: selectedTab == .settings ? "gearshape.fill" : "gearshape")
            }
            .tag(Tab.settings)
        }
        .tint(tabBarTintColor)
        .task {
            if todayViewModel.liturgicalDay == nil {
                await todayViewModel.loadReadings()
            }
            // Refresh upcoming liturgical reminders if enabled
            if UserDefaults.standard.bool(forKey: "reminderEnabled") {
                let interval = UserDefaults.standard.double(forKey: "reminderTimeInterval")
                let timeInterval = interval > 0 ? interval : 25200 // Default 7:00 AM
                let calendar = Calendar.current
                let hours = Int(timeInterval) / 3600
                let minutes = (Int(timeInterval) % 3600) / 60
                if let targetDate = calendar.date(bySettingHour: hours, minute: minutes, second: 0, of: .now) {
                    await NotificationManager.shared.scheduleDailyReminders(at: targetDate)
                }
            }
        }
    }
    
    // MARK: - Dynamic Liturgical Tint
    
    /// The accent color for active tab items, reflecting today's liturgical season/day.
    private var tabBarTintColor: Color {
        todayViewModel.liturgicalDay?.color.uiAccentColor ?? LiturgicalColors.green
    }
}

#Preview {
    MainTabView(readingsRepository: ReadingsRepository())
}
