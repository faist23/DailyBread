//
//  DateReadingsView.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Screen displaying the Catholic daily Mass readings for any selected calendar date.
///
/// Reuses the `ReadingCard` and `PsalmView` components, and supports left/right swipe
/// gestures to navigate seamlessly to the previous or next day's readings.
public struct DateReadingsView: View {
    
    // MARK: - Properties & State
    
    @State private var viewModel: TodayViewModel
    @State private var date: Date
    @State private var readingToPresent: Reading?
    @State private var audioPlayer = AudioReadingPlayer.shared
    
    // MARK: - Initialization
    
    public init(date: Date) {
        self._date = State(initialValue: date)
        // Create a TodayViewModel wired to the real engine services
        self._viewModel = State(initialValue: TodayViewModel())
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.Colors.groupedBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Liturgical Color Stripe
                Rectangle()
                    .fill(currentColor.uiAccentColor)
                    .frame(height: 4)
                
                if viewModel.isLoading && viewModel.dailyReadings == nil {
                    loadingView
                } else {
                    contentScrollView
                }
            }
            
            // Floating Audio Mini Player Bar
            AudioMiniPlayerBar(liturgicalColor: currentColor)
                .padding(.bottom, AppTheme.Spacing.small)
        }
        .navigationTitle(navigationTitleString)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let readings = viewModel.dailyReadings?.readings, !readings.isEmpty {
                    Button {
                        if audioPlayer.isPlaying {
                            audioPlayer.pause()
                        } else if audioPlayer.isPaused {
                            audioPlayer.resume()
                        } else {
                            let title = viewModel.liturgicalDay?.title ?? formattedFullDateString(for: date)
                            audioPlayer.start(
                                readings: readings,
                                liturgicalTitle: title,
                                liturgicalColor: viewModel.liturgicalDay?.color
                            )
                        }
                    } label: {
                        Image(systemName: audioPlayer.isPlaying ? "waveform" : "headphones")
                            .font(.scaled(size: 14, weight: .semibold))
                            .symbolEffect(.variableColor.iterative, isActive: audioPlayer.isPlaying)
                            .foregroundStyle(currentColor.uiAccentColor)
                    }
                    .accessibilityLabel(audioPlayer.isPlaying ? "Pause audio reading" : "Listen to readings")
                }
                
                Button {
                    navigateDay(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.scaled(size: 14, weight: .semibold))
                }
                .accessibilityLabel("Previous Day")
                
                Button {
                    navigateDay(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.scaled(size: 14, weight: .semibold))
                }
                .accessibilityLabel("Next Day")
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
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width < -50 {
                        navigateDay(by: 1) // Swipe left -> Next day
                    } else if value.translation.width > 50 {
                        navigateDay(by: -1) // Swipe right -> Previous day
                    }
                }
        )
        .task(id: date) {
            await viewModel.loadReadings(for: date)
        }
    }
    
    // MARK: - Content Scroll View
    
    private var contentScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Header Information
                liturgicalHeaderSection
                
                // Mass Readings
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
                
                // Saint of the Day (if commemorated)
                if let saint = viewModel.saint {
                    SaintOfDayCard(saint: saint, liturgicalColor: currentColor)
                        .padding(.top, AppTheme.Spacing.small)
                }
                
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
    
    // MARK: - Header
    
    private var liturgicalHeaderSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(formattedFullDateString(for: date))
                .font(.system(.subheadline, design: .default).weight(.medium))
                .foregroundStyle(Color.secondary)
                .textCase(.uppercase)
                .tracking(1.0)
            
            if let day = viewModel.liturgicalDay {
                Text(day.title.uppercased())
                    .liturgicalTitleStyle()
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(day.color.uiAccentColor)
                        .frame(width: 9, height: 9)
                    
                    Text("\(day.rank.displayName) • \(day.color.displayName)")
                        .font(.scaled(size: 13, weight: .semibold))
                        .foregroundStyle(day.color.uiAccentColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(day.color.badgeBackground)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            ProgressView()
                .tint(currentColor.swiftUIColor)
                .scaleEffect(1.2)
            Text("Loading Readings…")
                .font(.scaled(size: 15, design: .serif))
                .foregroundStyle(Color.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Text("No readings available for this date.")
                .font(.scaled(size: 16, design: .serif))
                .foregroundStyle(Color.secondary)
            
            if let url = usccbURL {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text("View readings on USCCB.org")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.scaled(size: 14, weight: .medium))
                    .foregroundStyle(currentColor.uiAccentColor)
                }
                .padding(.top, AppTheme.Spacing.small)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xlarge)
    }

    private var usccbURL: URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddyy"
        let dateStr = formatter.string(from: date)
        return URL(string: "https://bible.usccb.org/bible/readings/\(dateStr).cfm")
    }
    
    // MARK: - Navigation Actions
    
    private func navigateDay(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: date) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.date = newDate
            }
        }
    }
    
    // MARK: - Formatting Helpers
    
    private var currentColor: LiturgicalColor {
        viewModel.liturgicalDay?.color ?? .green
    }
    
    private var navigationTitleString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formattedFullDateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}
