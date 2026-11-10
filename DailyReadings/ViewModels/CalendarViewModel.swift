//
//  CalendarViewModel.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI
import Observation

/// View model managing the liturgical calendar month view, date selection,
/// and day cell coloring according to the Catholic liturgical year.
///
/// Wired to `LiturgicalCalendar.shared` for accurate liturgical computation
/// across all seasons, feasts, and ranks per UNLY and USCCB norms.
@Observable
@MainActor
public final class CalendarViewModel {
    
    // MARK: - State Properties
    
    /// The month currently being viewed (represented as the 1st of that month).
    public var currentMonth: Date = .now
    
    /// The currently selected date, if any.
    public var selectedDate: Date?
    
    /// Map of calendar dates (normalized to start of day) to their LiturgicalDay metadata.
    public var liturgicalDays: [Date: LiturgicalDay] = [:]
    
    /// Loading indicator state.
    public var isLoading: Bool = false
    
    // MARK: - Dependencies
    
    /// The liturgical calendar engine for computing feast days, seasons, and ranks.
    private let liturgicalCalendar: LiturgicalCalendar
    
    // MARK: - Calendar Computations
    
    private let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 1 // Sunday start
        return cal
    }()
    
    // MARK: - Initialization
    
    /// Designated initializer with optional dependency injection.
    ///
    /// - Parameter liturgicalCalendar: The computation engine (defaults to shared singleton).
    public init(liturgicalCalendar: LiturgicalCalendar = .shared) {
        self.liturgicalCalendar = liturgicalCalendar
        // Normalize currentMonth to start of month
        if let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) {
            self.currentMonth = startOfMonth
        }
        loadMonth()
    }
    
    // MARK: - Public Methods
    
    /// Loads liturgical day information for all days in the currently viewed month.
    public func loadMonth() {
        isLoading = true
        defer { isLoading = false }
        
        let days = daysInCurrentMonth()
        for date in days {
            let normalized = calendar.startOfDay(for: date)
            if liturgicalDays[normalized] == nil {
                liturgicalDays[normalized] = liturgicalCalendar.liturgicalDay(for: normalized)
            }
        }
    }
    
    /// Advances the calendar to the next month.
    public func nextMonth() {
        if let next = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentMonth = next
                loadMonth()
            }
        }
    }
    
    /// Moves the calendar to the previous month.
    public func previousMonth() {
        if let prev = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentMonth = prev
                loadMonth()
            }
        }
    }
    
    /// Selects a date and prepares navigation.
    public func selectDate(_ date: Date) {
        selectedDate = calendar.startOfDay(for: date)
    }
    
    /// Clears the date selection.
    public func clearSelection() {
        selectedDate = nil
    }
    
    /// Returns the liturgical day for a given date, if loaded.
    public func liturgicalDay(for date: Date) -> LiturgicalDay? {
        let normalized = calendar.startOfDay(for: date)
        return liturgicalDays[normalized]
    }
    
    // MARK: - Calendar Grid Helpers
    
    /// Formatted header title, e.g. "November 2026".
    public var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentMonth)
    }
    
    /// Weekday column symbols (Su, Mo, Tu, We, Th, Fr, Sa).
    public var weekdaySymbols: [String] {
        ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    }
    
    /// Returns all dates belonging to the current month.
    public func daysInCurrentMonth() -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else {
            return []
        }
        
        return range.compactMap { day -> Date? in
            calendar.date(bySetting: .day, value: day, of: currentMonth)
        }
    }
    
    /// Number of empty offset slots in the first week row.
    public var firstWeekdayOffset: Int {
        let weekday = calendar.component(.weekday, from: currentMonth)
        // 1 = Sunday -> offset 0
        return (weekday - calendar.firstWeekday + 7) % 7
    }
    
    /// Checks if a date corresponds to today's date.
    public func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    /// Checks if a date matches the currently selected date.
    public func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }
}
