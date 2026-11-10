//
//  SettingsView.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Settings view allowing customization of Bible translation, scripture typography,
/// font sizing, and viewing lectionary attributions and prayer sources.
public struct SettingsView: View {
    
    // MARK: - Stored Preferences
    
    @AppStorage("bibleTranslation") private var selectedTranslation: String = "Douay-Rheims"
    @AppStorage("scriptureFontSize") private var scriptureFontSize: Double = 18.0
    @AppStorage("readingLineSpacing") private var readingLineSpacing: Double = 7.0
    @AppStorage("reminderEnabled") private var reminderEnabled: Bool = false
    @AppStorage("reminderTimeInterval") private var reminderTimeInterval: Double = 25200 // 7:00 AM (7 * 3600)
    
    @State private var notificationManager = NotificationManager.shared
    @State private var showSettingsAlert: Bool = false
    
    // MARK: - Translation Options
    
    private let availableTranslations = [
        "Douay-Rheims",
        "New American Bible (NAB)"
    ]
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            AppTheme.Colors.groupedBackground
                .ignoresSafeArea()
            
            Form {
                // Section 1: Daily Reminder
                reminderSection

                // Section 2: Translation Picker
                translationSection
                
                // Section 3: Typography & Sizing
                typographySection
                
                // Section 4: Live Reading Preview
                livePreviewSection
                
                // Section 5: About DailyReadings
                aboutSection
                
                // Section 6: Credits & Sources
                creditsSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Notifications Disabled", isPresented: $showSettingsAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable notifications for DailyReadings in iOS Settings to receive daily prayer reminders.")
        }
        .task {
            await notificationManager.checkAuthorization()
        }
    }
    
    // MARK: - Daily Reminder Helpers
    
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                let calendar = Calendar.current
                let hours = Int(reminderTimeInterval) / 3600
                let minutes = (Int(reminderTimeInterval) % 3600) / 60
                return calendar.date(bySettingHour: hours, minute: minutes, second: 0, of: .now) ?? .now
            },
            set: { newDate in
                let calendar = Calendar.current
                let hours = calendar.component(.hour, from: newDate)
                let minutes = calendar.component(.minute, from: newDate)
                reminderTimeInterval = Double(hours * 3600 + minutes * 60)
                if reminderEnabled {
                    Task {
                        await notificationManager.scheduleDailyReminders(at: newDate)
                    }
                }
            }
        )
    }
    
    // MARK: - Daily Reminder Section
    
    private var reminderSection: some View {
        Section {
            Toggle("Daily Prayer Reminder", isOn: Binding(
                get: { reminderEnabled },
                set: { newValue in
                    reminderEnabled = newValue
                    Task {
                        if newValue {
                            let granted = await notificationManager.requestAuthorization()
                            if granted {
                                await notificationManager.scheduleDailyReminders(at: reminderTime.wrappedValue)
                            } else {
                                reminderEnabled = false
                                showSettingsAlert = true
                            }
                        } else {
                            await notificationManager.cancelReminders()
                        }
                    }
                }
            ))
            
            if reminderEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        } header: {
            Text("Daily Prayer Reminder")
        } footer: {
            Text("Receive a gentle daily notification with today's liturgical feast and a reminder to pray.")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
        }
    }
    
    // MARK: - Translation Section
    
    private var translationSection: some View {
        Section {
            Picker("Translation", selection: $selectedTranslation) {
                ForEach(availableTranslations, id: \.self) { translation in
                    Text(translation).tag(translation)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Scripture Translation")
        } footer: {
            Text("Select between the historic Douay-Rheims Catholic translation and the New American Bible lectionary text.")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
        }
    }
    
    // MARK: - Typography Section
    
    private var typographySection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Text("Reading Font Size")
                    Spacer()
                    Text("\(Int(scriptureFontSize)) pt")
                        .foregroundStyle(Color.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "textformat.size.smaller")
                        .foregroundStyle(Color.secondary)
                    
                    Slider(
                        value: $scriptureFontSize,
                        in: 14...32,
                        step: 1
                    )
                    
                    Image(systemName: "textformat.size.larger")
                        .foregroundStyle(Color.secondary)
                }
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                HStack {
                    Text("Line Spacing")
                    Spacer()
                    Text("\(Int(readingLineSpacing)) pt")
                        .foregroundStyle(Color.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                Slider(
                    value: $readingLineSpacing,
                    in: 4...14,
                    step: 1
                )
            }
            .padding(.vertical, 4)
            
            Button("Reset to Defaults") {
                withAnimation {
                    scriptureFontSize = 18.0
                    readingLineSpacing = 7.0
                }
            }
            .font(.system(size: 14))
            .foregroundStyle(Color.red)
        } header: {
            Text("Typography & Readability")
        }
    }
    
    // MARK: - Live Preview Section
    
    private var livePreviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("FIRST READING")
                    .readingTitleStyle(tintColor: LiturgicalColors.green)
                
                Text("Wisdom 3:1")
                    .readingCitationStyle()
                
                Text("The souls of the just are in the hand of God, and no torment shall touch them.")
                    .scriptureBodyStyle(fontSize: CGFloat(scriptureFontSize), lineSpacing: CGFloat(readingLineSpacing))
                    .padding(.top, 4)
            }
            .padding(.vertical, 8)
        } header: {
            Text("Sample Preview")
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(LiturgicalColors.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DailyReadings")
                            .font(.system(.title3, design: .serif).weight(.bold))
                        Text("Catholic Daily Readings")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                }
                
                Text("DailyReadings is a Catholic daily readings companion designed for calm, contemplative prayer and meditation on the Word of God as proclaimed in the sacred liturgy of the Church.")
                    .font(.system(.callout, design: .serif))
                    .foregroundStyle(Color.primary.opacity(0.85))
                    .lineSpacing(4)
            }
            .padding(.vertical, 6)
        } header: {
            Text("About DailyReadings")
        }
    }
    
    // MARK: - Credits & Sources Section
    
    private var creditsSection: some View {
        Section {
            Link(destination: URL(string: "https://bible.usccb.org/daily-bible-reading")!) {
                HStack {
                    Text("USCCB Daily Readings")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Link(destination: URL(string: "https://www.vatican.va")!) {
                HStack {
                    Text("The Holy See (Vatican)")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Scripture Attributions")
                    .font(.system(size: 13, weight: .semibold))
                Text("Douay-Rheims Bible (Public Domain). Lectionary citations referenced in accord with the General Roman Calendar and Universal Norms on the Liturgical Year.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Attributions & Guidelines")
        } footer: {
            Text("DailyReadings • Designed for contemplative prayer")
                .font(.caption2)
                .foregroundStyle(Color.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
