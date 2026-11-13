//
//  NotificationManager.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+ | UserNotifications
//

import Foundation
import UserNotifications
import Observation

/// Service managing daily local notification reminders for Catholic Mass readings and prayer.
///
/// Automatically personalizes upcoming reminders with the day's liturgical feast title
/// (e.g. "Solemnity of Christ the King" or "St. Cecilia, Virgin & Martyr") computed via `LiturgicalCalendar`.
@Observable
@MainActor
public final class NotificationManager {
    
    /// Shared singleton instance.
    public static let shared = NotificationManager()
    
    /// Notification identifier prefix for scheduled daily reminders.
    private static let identifierPrefix = "com.ridepro.DailyReadings.reminder."
    private static let fallbackIdentifier = "com.ridepro.DailyReadings.reminder.recurring"
    private static let holyDayIdentifierPrefix = "com.ridepro.DailyReadings.holyday."
    
    /// Current notification authorization status.
    public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// Whether notifications are currently authorized by the user.
    public var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }
    
    // MARK: - Initialization
    
    public init() {
        Task {
            await checkAuthorization()
        }
    }
    
    // MARK: - Authorization
    
    /// Checks the current system notification settings.
    public func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
    }
    
    /// Requests notification permissions (alert, sound, badge) from the user.
    @discardableResult
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await checkAuthorization()
            return granted
        } catch {
            await checkAuthorization()
            return false
        }
    }
    
    // MARK: - Scheduling
    
    /// Constructs the rich liturgical notification content for a daily reminder,
    /// featuring the liturgical feast or saint in the subtitle and the Verse of the Day in the body.
    nonisolated public static func makeDailyReminderContent(for liturgicalDay: LiturgicalDay, verse: VerseOfTheDay) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        if liturgicalDay.isNonSundayHolyDayOfObligation {
            content.title = "Holy Day of Obligation 🔔"
        } else if liturgicalDay.isSunday {
            content.title = "Sunday Mass Readings 📖"
        } else {
            content.title = "DailyReadings 📖"
        }
        content.subtitle = liturgicalDay.title
        
        let cleanText = verse.text.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”'"))
        let formattedVerse: String
        if cleanText.count > 180 {
            let truncated = cleanText.prefix(175).trimmingCharacters(in: .whitespaces)
            formattedVerse = "\(truncated)…"
        } else {
            formattedVerse = cleanText
        }
        
        if !formattedVerse.isEmpty {
            let citationSuffix = verse.citation.isEmpty ? "" : " — \(verse.citation)"
            content.body = "“\(formattedVerse)”\(citationSuffix)"
        } else {
            content.body = "Today's Mass readings and scripture reflection are ready for your prayer."
        }
        content.sound = .default
        return content
    }
    
    /// Schedules daily prayer reminders at the specified time of day.
    ///
    /// Pre-schedules personalized, single notifications for the next 30 days using the liturgical calendar
    /// and Verse of the Day, avoiding duplicate alerts.
    ///
    /// - Parameter time: A date containing the target hour and minute for the daily reminder.
    public func scheduleDailyReminders(at time: Date) async {
        // If authorization has not yet been requested, prompt the user
        if authorizationStatus == .notDetermined {
            let granted = await requestAuthorization()
            guard granted else { return }
        } else {
            await checkAuthorization()
            guard isAuthorized else { return }
        }
        
        let center = UNUserNotificationCenter.current()
        
        // Remove existing daily reminders and legacy recurring alerts
        await cancelDailyReminders()
        
        let calendar = Calendar.current
        let targetHour = calendar.component(.hour, from: time)
        let targetMinute = calendar.component(.minute, from: time)
        
        // Pre-schedule the next 30 days with individualized liturgical titles and Verse of the Day
        let now = Date.now
        for dayOffset in 0..<30 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = targetHour
            components.minute = targetMinute
            components.second = 0
            
            guard let fireDate = calendar.date(from: components), fireDate > now else {
                continue // Skip times in the past for today
            }
            
            let liturgicalDay = LiturgicalCalendar.shared.liturgicalDay(for: targetDate)
            let readings = await ReadingsRepository.shared.getOfflineReadings(for: targetDate)
            let verseOfTheDay = VerseOfTheDayProvider.verse(from: readings, date: targetDate)
            
            let content = Self.makeDailyReminderContent(for: liturgicalDay, verse: verseOfTheDay)
            
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "\(Self.identifierPrefix)\(dayOffset)",
                content: content,
                trigger: trigger
            )
            
            try? await center.add(request)
        }
        
        // Schedule Holy Day Vigil Alerts if enabled
        let holyDayAlertsEnabled = UserDefaults.standard.bool(forKey: "holyDayAlertsEnabled")
        if holyDayAlertsEnabled {
            await scheduleHolyDayVigilAlerts()
        }
    }
    
    /// Schedules evening vigil alerts (at 7:00 PM the night before) for any Holy Days of Obligation in the next 30 days.
    public func scheduleHolyDayVigilAlerts() async {
        if authorizationStatus == .notDetermined {
            let granted = await requestAuthorization()
            guard granted else { return }
        } else {
            await checkAuthorization()
            guard isAuthorized else { return }
        }
        
        let center = UNUserNotificationCenter.current()
        await cancelHolyDayAlerts()
        
        let calendar = Calendar.current
        let now = Date.now
        
        for offset in 1...30 {
            guard let targetDate = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let day = LiturgicalCalendar.shared.liturgicalDay(for: targetDate)
            
            if day.isNonSundayHolyDayOfObligation {
                // Schedule for the evening before at 7:00 PM (19:00)
                guard let vigilDate = calendar.date(byAdding: .day, value: -1, to: targetDate) else { continue }
                var vigilComponents = calendar.dateComponents([.year, .month, .day], from: vigilDate)
                vigilComponents.hour = 19
                vigilComponents.minute = 0
                vigilComponents.second = 0
                
                guard let fireDate = calendar.date(from: vigilComponents), fireDate > now else { continue }
                
                let content = UNMutableNotificationContent()
                content.title = "Tomorrow is a Holy Day of Obligation 🔔"
                content.subtitle = day.title
                content.body = "Catholics are obliged to assist at Mass for this solemn feast. Remember to plan for Mass."
                content.sound = .default
                
                let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(Self.holyDayIdentifierPrefix)\(day.id)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }
    
    /// Cancels scheduled Holy Day vigil reminders.
    public func cancelHolyDayAlerts() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.holyDayIdentifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: toRemove)
    }
    
    /// Cancels scheduled daily morning reminders (including any legacy recurring alerts).
    public func cancelDailyReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) || $0 == Self.fallbackIdentifier }
        center.removePendingNotificationRequests(withIdentifiers: toRemove)
    }
    
    /// Cancels all pending DailyReadings reminders (both daily prayer reminders and holy day alerts).
    public func cancelReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) || $0 == Self.fallbackIdentifier || $0.hasPrefix(Self.holyDayIdentifierPrefix) }
        
        center.removePendingNotificationRequests(withIdentifiers: toRemove)
    }
}
