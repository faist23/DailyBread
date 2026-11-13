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
    
    @AppStorage("bibleTranslation") private var selectedTranslation: String = "World English Bible (WEB-C)"
    @AppStorage("scriptureFontSize") private var scriptureFontSize: Double = 18.0
    @AppStorage("readingLineSpacing") private var readingLineSpacing: Double = 7.0
    @AppStorage("reminderEnabled") private var reminderEnabled: Bool = false
    @AppStorage("reminderTimeInterval") private var reminderTimeInterval: Double = 25200 // 7:00 AM (7 * 3600)
    @AppStorage("holyDayAlertsEnabled") private var holyDayAlertsEnabled: Bool = true
    @AppStorage("selectedAudioVoiceId") private var selectedVoiceId: String = ""
    @AppStorage("ascensionOnThursday") private var ascensionOnThursday: Bool = false
    
    @State private var notificationManager = NotificationManager.shared
    @State private var audioPlayer = AudioReadingPlayer.shared
    @State private var readingsRepository = ReadingsRepository.shared
    @State private var bookmarkManager = BookmarkManager.shared
    @State private var showSettingsAlert: Bool = false
    
    // MARK: - Translation Options
    
    private let availableTranslations = [
        "World English Bible (WEB-C)",
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
                
                // Section 3: Liturgical Calendar
                calendarSection
                
                // Section 4: Devotional Bookmarks
                bookmarksSection
                
                // Section 4: Audio & Lector Voice
                audioSection
                
                // Section 4: Typography & Sizing
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
        .onAppear {
            if selectedVoiceId.isEmpty {
                selectedVoiceId = audioPlayer.selectedVoiceIdentifier
            }
            readingsRepository.cachedNABDaysCount = readingsRepository.countCachedNABDays(daysAhead: 30)
        }
        .onChange(of: selectedTranslation) { _, newTranslation in
            if newTranslation.contains("NAB") {
                readingsRepository.cachedNABDaysCount = readingsRepository.countCachedNABDays(daysAhead: 30)
                readingsRepository.triggerBackgroundPrefetchIfNeeded()
            }
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
            
            Toggle("Holy Day Vigil Alerts", isOn: Binding(
                get: { holyDayAlertsEnabled },
                set: { newValue in
                    holyDayAlertsEnabled = newValue
                    Task {
                        if newValue {
                            let granted = await notificationManager.requestAuthorization()
                            if granted {
                                await notificationManager.scheduleHolyDayVigilAlerts()
                            } else {
                                holyDayAlertsEnabled = false
                                showSettingsAlert = true
                            }
                        } else {
                            await notificationManager.cancelHolyDayAlerts()
                        }
                    }
                }
            ))
        } header: {
            Text("Prayer Reminders & Alerts")
        } footer: {
            Text("Receive daily notifications with the feast title and vigil alerts at 7:00 PM the evening before Holy Days of Obligation.")
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

            if selectedTranslation.contains("NAB") {
                offlineNABRow
            }
        } header: {
            Text("Scripture Translation")
        } footer: {
            if selectedTranslation.contains("NAB") {
                Text("New American Bible (NAB/NABRE). Liturgical text for the Dioceses of the United States. Pre-downloaded 30 days in advance via Evangelizo.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            } else if selectedTranslation.contains("Douay") {
                Text("Douay-Rheims (Challoner revision, 1752), public domain. Traditional English translated from the Latin Vulgate with all 73 Catholic books. 100% available offline.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            } else {
                Text("World English Bible (Catholic edition), public domain. Modern English with all 73 Catholic books. Private devotional reading; not the liturgical text read at Mass.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private var offlineNABRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label {
                    Text("Offline Availability")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                Spacer()
                Text("\(readingsRepository.cachedNABDaysCount) of 30 days stored")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
            
            if readingsRepository.isPrefetching {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: readingsRepository.prefetchProgress)
                        .tint(Color.accentColor)
                    HStack {
                        Text(readingsRepository.prefetchStatus.isEmpty ? "Downloading readings..." : readingsRepository.prefetchStatus)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Text("\(Int(readingsRepository.prefetchProgress * 100))%")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .monospacedDigit()
                    }
                }
            } else {
                Button {
                    Task {
                        await readingsRepository.prefetchNABReadings(daysAhead: 30)
                    }
                } label: {
                    HStack {
                        Image(systemName: readingsRepository.cachedNABDaysCount >= 28 ? "arrow.clockwise" : "arrow.down.circle")
                        Text(readingsRepository.cachedNABDaysCount >= 28 ? "Refresh 30-Day Offline Cache" : "Download Next 30 Days for Offline Use")
                    }
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Liturgical Calendar Section
    
    private var calendarSection: some View {
        Section {
            Toggle("Ascension on Thursday", isOn: $ascensionOnThursday)
        } header: {
            Text("Liturgical Calendar")
        } footer: {
            Text("Celebrated on Thursday (Easter + 39 days) in the ecclesiastical provinces of Boston, Hartford, New York, Newark, Omaha, and Philadelphia. Most US dioceses transfer the celebration to the Seventh Sunday of Easter.")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
        }
    }
    
    // MARK: - Devotional Bookmarks Section
    
    private var bookmarksSection: some View {
        Section {
            NavigationLink {
                BookmarksView()
            } label: {
                HStack {
                    Label {
                        Text("Saved Scripture & Bookmarks")
                    } icon: {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(LiturgicalColors.goldAccent)
                    }
                    Spacer()
                    if !bookmarkManager.bookmarks.isEmpty {
                        Text("\(bookmarkManager.bookmarks.count)")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        } header: {
            Text("Personal Devotions")
        } footer: {
            Text("Access your bookmarked Mass readings and Psalms for personal prayer and meditation.")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
        }
    }
    
    // MARK: - Audio & Lector Section
    
    private var audioSection: some View {
        Section {
            Picker("Lector Voice", selection: Binding(
                get: {
                    if !selectedVoiceId.isEmpty {
                        return selectedVoiceId
                    }
                    return audioPlayer.selectedVoiceIdentifier
                },
                set: { newId in
                    selectedVoiceId = newId
                    audioPlayer.selectedVoiceIdentifier = newId
                    UserDefaults.standard.set(newId, forKey: "selectedAudioVoiceId")
                }
            )) {
                ForEach(audioPlayer.availableVoices) { voice in
                    Text(voice.displayName).tag(voice.id)
                }
            }
            .pickerStyle(.menu)
            
            Picker("Speech Pacing", selection: Binding(
                get: { audioPlayer.speed },
                set: { audioPlayer.speed = $0 }
            )) {
                ForEach(PlaybackSpeed.allCases) { speed in
                    Text("\(speed.label) (\(speedTitle(speed)))").tag(speed)
                }
            }
            .pickerStyle(.menu)
            
            Button {
                let idToTest = selectedVoiceId.isEmpty ? audioPlayer.selectedVoiceIdentifier : selectedVoiceId
                audioPlayer.audition(voiceId: idToTest)
            } label: {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundStyle(AppTheme.Colors.solemnGold)
                    Text("Preview Voice")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Text("Audition Lector")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
            }
        } header: {
            Text("Audio & Lector Voice")
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Select your preferred voice and pacing for daily scripture.")
                Text("✨ Tip: For ultra-realistic studio voices, download Apple's free Enhanced voices in your iPhone Settings → Accessibility → Spoken Content → Voices → English (such as Daniel Enhanced, Samantha Enhanced, or Ava). They will automatically appear here.")
            }
            .font(.footnote)
            .foregroundStyle(Color.secondary)
        }
    }
    
    private func speedTitle(_ speed: PlaybackSpeed) -> String {
        switch speed {
        case .reverent: return "Contemplative"
        case .normal: return "Standard"
        case .brisk: return "Attentive"
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
            .font(.scaled(size: 14))
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
                        .font(.scaled(size: 28))
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
                        .font(.scaled(size: 12))
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Link(destination: URL(string: "https://www.vatican.va")!) {
                HStack {
                    Text("The Holy See (Vatican)")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.scaled(size: 12))
                        .foregroundStyle(Color.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Scripture Attributions")
                    .font(.scaled(size: 13, weight: .semibold))
                Text("Douay-Rheims Bible (Public Domain). Lectionary citations referenced in accord with the General Roman Calendar and Universal Norms on the Liturgical Year.")
                    .font(.scaled(size: 12))
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

// MARK: - Bookmarks & Saved Scripture View

/// View displaying all bookmarked Mass readings and Psalms for personal prayer and meditation.
public struct BookmarksView: View {
    @State private var bookmarkManager = BookmarkManager.shared
    @State private var selectedBookmark: SavedBookmark?

    public var body: some View {
        ZStack {
            AppTheme.Colors.groupedBackground
                .ignoresSafeArea()

            if bookmarkManager.bookmarks.isEmpty {
                emptyBookmarksView
            } else {
                List {
                    ForEach(bookmarkManager.bookmarks) { bookmark in
                        Button {
                            selectedBookmark = bookmark
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(bookmark.readingType.displayTitle)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(LiturgicalColors.goldAccent)
                                        .textCase(.uppercase)
                                    Spacer()
                                    Text(bookmark.date.formatted(.dateTime.month(.abbreviated).day().year()))
                                        .font(.caption2)
                                        .foregroundStyle(Color.secondary)
                                }

                                Text(bookmark.citation.displayReference)
                                    .font(.headline)
                                    .foregroundStyle(Color.primary)

                                Text(bookmark.text.prefix(140) + (bookmark.text.count > 140 ? "..." : ""))
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                                    .lineLimit(2)
                                    .lineSpacing(3)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { offsets in
                        bookmarkManager.removeBookmark(at: offsets)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Saved Scripture")
        .sheet(item: $selectedBookmark) { bookmark in
            NavigationStack {
                ReadingDetailView(reading: bookmark.asReading)
            }
        }
    }

    private var emptyBookmarksView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.scaled(size: 48))
                .foregroundStyle(Color.secondary.opacity(0.4))

            Text("No Saved Readings Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Tap the bookmark icon on any scripture reading or Psalm to save it here for prayer and meditation.")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
