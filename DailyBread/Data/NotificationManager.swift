//
//  NotificationManager.swift
//  DailyBread
//
//  Created for DailyBread Catholic Daily Readings App.
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
    private static let identifierPrefix = "com.craigfaist.DailyBread.reminder."
    private static let fallbackIdentifier = "com.craigfaist.DailyBread.reminder.recurring"
    
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
    
    /// Schedules daily prayer reminders at the specified time of day.
    ///
    /// Pre-schedules personalized notifications for the next 7 days using the liturgical calendar,
    /// plus a recurring fallback reminder.
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
        
        // Remove existing DailyBread notifications first
        await cancelReminders()
        
        let calendar = Calendar.current
        let targetHour = calendar.component(.hour, from: time)
        let targetMinute = calendar.component(.minute, from: time)
        
        // 1. Pre-schedule the next 7 days with individualized liturgical titles
        let now = Date.now
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
            var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
            components.hour = targetHour
            components.minute = targetMinute
            components.second = 0
            
            guard let fireDate = calendar.date(from: components), fireDate > now else {
                continue // Skip times in the past for today
            }
            
            let liturgicalDay = LiturgicalCalendar.shared.liturgicalDay(for: targetDate)
            
            let content = UNMutableNotificationContent()
            content.title = "DailyBread 🍞"
            content.subtitle = liturgicalDay.title
            content.body = "Today's Mass readings and scripture reflection are ready for your prayer."
            content.sound = .default
            
            let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "\(Self.identifierPrefix)\(dayOffset)",
                content: content,
                trigger: trigger
            )
            
            try? await center.add(request)
        }
        
        // 2. Schedule recurring fallback reminder
        let fallbackContent = UNMutableNotificationContent()
        fallbackContent.title = "DailyBread 🍞"
        fallbackContent.subtitle = "Time for Sacred Scripture"
        fallbackContent.body = "Begin your day with today's Catholic Mass readings and daily prayer."
        fallbackContent.sound = .default
        
        var recurringComponents = DateComponents()
        recurringComponents.hour = targetHour
        recurringComponents.minute = targetMinute
        
        let recurringTrigger = UNCalendarNotificationTrigger(dateMatching: recurringComponents, repeats: true)
        let recurringRequest = UNNotificationRequest(
            identifier: Self.fallbackIdentifier,
            content: fallbackContent,
            trigger: recurringTrigger
        )
        
        try? await center.add(recurringRequest)
    }
    
    /// Cancels all pending DailyBread reminders.
    public func cancelReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) || $0 == Self.fallbackIdentifier }
        
        center.removePendingNotificationRequests(withIdentifiers: toRemove)
    }
}
