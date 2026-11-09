//
//  TodayView.swift
//  DailyBread
//
//  Created for DailyBread Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// The primary screen of DailyBread displaying today's Catholic Mass readings,
/// liturgical feast context, and Saint of the Day.
///
/// Designed with generous whitespace and calm pacing for contemplative prayer.
public struct TodayView: View {
    
    // MARK: - View Model & State
    
    @Bindable public var viewModel: TodayViewModel
    @State private var readingToPresent: Reading?
    
    // MARK: - Initialization
    
    public init(viewModel: TodayViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("DailyBread")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.primary.opacity(0.85))
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
    }
    
    // MARK: - Main Scroll Content
    
    private var mainScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // Liturgical Header & Date
                liturgicalHeaderSection
                
                // Error Alert if any
                if let error = viewModel.error {
                    errorBanner(message: error)
                }
                
                // Mass Readings Section
                if let readings = viewModel.dailyReadings?.readings, !readings.isEmpty {
                    readingsList(readings: readings)
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
