//
//  TodayView.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// The primary screen of DailyReadings displaying today's Catholic Mass readings,
/// liturgical feast context, and Saint of the Day.
///
/// Designed with generous whitespace and calm pacing for contemplative prayer.
public struct TodayView: View {
    
    // MARK: - View Model & State
    
    @Bindable public var viewModel: TodayViewModel
    @State private var readingToPresent: Reading?
    @State private var audioPlayer = AudioReadingPlayer.shared
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Initialization
    
    public init(viewModel: TodayViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            AppTheme.Colors.groupedBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Liturgical Accent Bar
                Rectangle()
                    .fill(currentColor.uiAccentColor)
                    .frame(height: 4)
                    .shadow(color: currentColor.uiAccentColor.opacity(0.3), radius: 3, x: 0, y: 1)
                
                if viewModel.isLoading && viewModel.dailyReadings == nil {
                    loadingView
                } else {
                    mainScrollView
                }
            }
            
            // Floating Audio Mini Player Bar
            AudioMiniPlayerBar(liturgicalColor: currentColor)
                .padding(.bottom, AppTheme.Spacing.small)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("DailyReadings")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.primary.opacity(0.85))
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                if let readings = viewModel.dailyReadings?.readings, !readings.isEmpty {
                    Button {
                        if audioPlayer.isPlaying {
                            audioPlayer.pause()
                        } else if audioPlayer.isPaused {
                            audioPlayer.resume()
                        } else {
                            let title = viewModel.liturgicalDay?.title ?? "Today's Mass Readings"
                            audioPlayer.start(
                                readings: readings,
                                liturgicalTitle: title,
                                liturgicalColor: viewModel.liturgicalDay?.color
                            )
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: audioPlayer.isPlaying ? "waveform" : "headphones")
                                .font(.system(size: 13, weight: .semibold))
                                .symbolEffect(.variableColor.iterative, isActive: audioPlayer.isPlaying)
                            
                            Text(audioPlayer.isPlaying ? "Playing" : "Listen")
                                .font(.system(size: 13, weight: .semibold, design: .serif))
                        }
                        .foregroundStyle(currentColor.uiAccentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(currentColor.swiftUIColor.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(audioPlayer.isPlaying ? "Pause audio reading" : "Listen to readings")
                }
            }
        }
        .sheet(item: $readingToPresent) { reading in
            NavigationStack {
                ReadingDetailView(
                    reading: reading,
                    liturgicalColor: currentColor
                )
            }
        }
        .task {
            if viewModel.dailyReadings == nil {
                await viewModel.loadReadings()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let calendar = Calendar.current
                if !calendar.isDate(viewModel.currentDate, inSameDayAs: Date()) {
                    Task {
                        await viewModel.loadReadings(for: Date())
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            let calendar = Calendar.current
            if !calendar.isDate(viewModel.currentDate, inSameDayAs: Date()) {
                Task {
                    await viewModel.loadReadings(for: Date())
                }
            }
        }
    }
    
    // MARK: - Main Scroll Content
    
    private var mainScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Liturgical Header & Date
                liturgicalHeaderSection
                
                // Holy Day of Obligation Alert Banner
                if let day = viewModel.liturgicalDay, day.isNonSundayHolyDayOfObligation {
                    holyDayBanner(for: day)
                } else if let tomorrowHolyDay = LiturgicalCalendar.shared.nextHolyDayOfObligation(from: viewModel.currentDate, daysAhead: 1), tomorrowHolyDay.daysAway == 1 {
                    vigilBanner(for: tomorrowHolyDay.day)
                }
                
                // Error Alert if any
                if let error = viewModel.error {
                    errorBanner(message: error)
                }
                
                // Verse of the Day Card
                VerseOfDayCard(
                    verse: VerseOfTheDayProvider.verse(from: viewModel.dailyReadings, date: viewModel.currentDate),
                    liturgicalColor: currentColor
                )
                
                // Mass Readings Section
                if let readings = viewModel.dailyReadings?.readings, !readings.isEmpty {
                    readingsList(readings: readings)
                    
                    if let copyright = viewModel.dailyReadings?.copyright, !copyright.isEmpty {
                        Text(copyright)
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.small)
                            .padding(.top, 4)
                            .frame(maxWidth: .infinity)
                    }
                } else if !viewModel.isLoading {
                    emptyStateView
                }
                
                // Saint of the Day Section
                if let saint = viewModel.saint {
                    SaintOfDayCard(saint: saint, liturgicalColor: currentColor)
                        .padding(.top, AppTheme.Spacing.small)
                }
                
                // Bottom Contemplative Breathing Room
                Spacer()
                    .frame(height: AppTheme.Spacing.xxlarge)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.top, AppTheme.Spacing.medium)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Liturgical Header
    
    private var liturgicalHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Formatted Date
            Text(formattedDateString(for: viewModel.currentDate))
                .font(.system(.subheadline, design: .default).weight(.medium))
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .tracking(1.0)
            
            // Liturgical Day Title
            if let day = viewModel.liturgicalDay {
                Text(day.title.uppercased())
                    .liturgicalTitleStyle()
                    .fixedSize(horizontal: false, vertical: true)
                
                // Rank & Color Badge
                liturgicalBadge(for: day)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Liturgical Badge
    
    private func liturgicalBadge(for day: LiturgicalDay) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(day.color.uiAccentColor)
                .frame(width: 9, height: 9)
            
            Text("\(day.rank.displayName) • \(day.color.displayName)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(day.color.uiAccentColor)
            
            if day.isHolyDayOfObligation {
                Text("• Holy Day of Obligation")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(day.color.badgeBackground)
        .clipShape(Capsule())
    }
    
    // MARK: - Holy Day of Obligation Banners
    
    private func holyDayBanner(for day: LiturgicalDay) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.title3)
                .foregroundStyle(LiturgicalColors.goldAccent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Holy Day of Obligation")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primary)
                Text("Catholics are obliged to assist at Mass today.")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .background(LiturgicalColors.goldAccent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(LiturgicalColors.goldAccent.opacity(0.35), lineWidth: 1)
        )
    }
    
    private func vigilBanner(for holyDay: LiturgicalDay) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.subheadline)
                .foregroundStyle(LiturgicalColors.goldAccent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Vigil of \(holyDay.title)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                Text("Tomorrow is a Holy Day of Obligation. Remember to plan for Mass.")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            Spacer()
        }
        .padding(AppTheme.Spacing.compact)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Readings List
    
    private func readingsList(readings: [Reading]) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ForEach(readings) { reading in
                if reading.type == .responsorialPsalm {
                    PsalmView(
                        reading: reading,
                        liturgicalColor: currentColor,
                        onExpandDetail: {
                            readingToPresent = reading
                        }
                    )
                } else {
                    ReadingCard(
                        reading: reading,
                        liturgicalColor: currentColor,
                        onSelect: {
                            readingToPresent = reading
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Spacer()
            
            Image(systemName: "book.pages")
                .font(.system(size: 40))
                .foregroundStyle(currentColor.uiAccentColor)
                .symbolEffect(.pulse, options: .repeating)
            
            Text("Gathering Sacred Scripture…")
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundStyle(Color.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error Banner
    
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.orange)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(Color.primary)
            
            Spacer()
            
            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(currentColor.uiAccentColor)
        }
        .padding(AppTheme.Spacing.medium)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Text("No readings found for today.")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(Color.secondary)
            
            Button("Reload") {
                Task {
                    await viewModel.refresh()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(currentColor.uiAccentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xlarge)
    }
    
    // MARK: - Helpers
    
    private var currentColor: LiturgicalColor {
        viewModel.liturgicalDay?.color ?? .green
    }
    
    private func formattedDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}
