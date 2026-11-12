//
//  CalendarView.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Liturgical calendar view displaying the Catholic liturgical year by month.
///
/// Features a 7-column grid, liturgical color dot indicators, swipe gestures
/// for month navigation, and quick access to Mass readings for any selected date.
public struct CalendarView: View {
    
    // MARK: - View Model & State
    
    @Bindable public var viewModel: CalendarViewModel
    @State private var dateNavigatingTo: Date?
    
    // MARK: - Grid Layout
    
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    
    // MARK: - Initialization
    
    public init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            AppTheme.Colors.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Month & Year Navigation Header
                    monthHeaderSection
                    
                    // Calendar Grid Card
                    calendarGridCard
                    
                    // Selected Day Preview & Action Banner
                    if let selected = viewModel.selectedDate {
                        selectedDaySummaryCard(for: selected)
                    }
                    
                    // Liturgical Season & Colors Legend
                    liturgicalLegendCard
                    
                    Spacer()
                        .frame(height: AppTheme.Spacing.xlarge)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.compact)
            }
        }
        .navigationTitle("Liturgical Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $dateNavigatingTo) { date in
            DateReadingsView(date: date)
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width < -50 {
                        // Swipe Left -> Next Month
                        viewModel.nextMonth()
                    } else if value.translation.width > 50 {
                        // Swipe Right -> Previous Month
                        viewModel.previousMonth()
                    }
                }
        )
    }
    
    // MARK: - Month Header Section
    
    private var monthHeaderSection: some View {
        HStack(alignment: .center) {
            Button {
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.scaled(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous month")
            
            Spacer()
            
            Text(viewModel.monthYearTitle)
                .font(.system(.title3, design: .serif).weight(.bold))
                .foregroundStyle(Color.primary)
            
            Spacer()
            
            Button {
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.scaled(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal, AppTheme.Spacing.small)
    }
    
    // MARK: - Calendar Grid Card
    
    private var calendarGridCard: some View {
        VStack(spacing: AppTheme.Spacing.compact) {
            // Weekday Column Headers (Su Mo Tu We Th Fr Sa)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(viewModel.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.scaled(size: 12, weight: .bold))
                        .foregroundStyle(Color.secondary.opacity(0.8))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)
            
            Divider()
                .padding(.bottom, 4)
            
            // Days Grid
            LazyVGrid(columns: columns, spacing: 6) {
                // Empty offset cells for starting weekday
                ForEach(0..<viewModel.firstWeekdayOffset, id: \.self) { _ in
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                
                // Active Days
                ForEach(viewModel.daysInCurrentMonth(), id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        liturgicalDay: viewModel.liturgicalDay(for: date),
                        isToday: viewModel.isToday(date),
                        isSelected: viewModel.isSelected(date),
                        onSelect: {
                            viewModel.selectDate(date)
                        }
                    )
                }
            }
        }
        .cardStyle(
            backgroundColor: AppTheme.Colors.cardBackground,
            cornerRadius: AppTheme.CornerRadius.large,
            padding: AppTheme.Spacing.medium
        )
    }
    
    // MARK: - Selected Day Summary Card
    
    private func selectedDaySummaryCard(for date: Date) -> some View {
        let day = viewModel.liturgicalDay(for: date)
        let color = day?.color ?? .green
        let accentColor = color.uiAccentColor
        let isWhite = (color == .white)
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(formattedSelectedDate(date))
                        .font(.scaled(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .textCase(.uppercase)
                    
                    Text(day?.title ?? "Feria")
                        .font(.scaled(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(Color.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if isWhite {
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().stroke(LiturgicalColors.goldAccent, lineWidth: 1.5))
                        .frame(width: 14, height: 14)
                } else {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 14, height: 14)
                }
            }
            
            HStack {
                if let day {
                    Text("\(day.rank.displayName) • \(day.color.displayName)")
                        .font(.scaled(size: 13, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                
                Spacer()
                
                Button {
                    dateNavigatingTo = date
                } label: {
                    HStack(spacing: 5) {
                        Text("View Readings")
                            .font(.scaled(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.scaled(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .cardStyle(
            backgroundColor: AppTheme.Colors.cardBackground,
            cornerRadius: AppTheme.CornerRadius.large,
            padding: AppTheme.Spacing.medium,
            borderColor: accentColor.opacity(0.35)
        )
        .transition(.scale(scale: 0.98).combined(with: .opacity))
    }
    
    // MARK: - Liturgical Legend
    
    private var liturgicalLegendCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("LITURGICAL COLORS")
                .font(.scaled(size: 11, weight: .bold))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .tracking(1.0)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 8)], spacing: 8) {
                legendItem(
                    name: "White / Gold",
                    dot: AnyView(
                        Circle()
                            .fill(Color.white)
                            .overlay(Circle().stroke(LiturgicalColors.goldAccent, lineWidth: 1.5))
                            .frame(width: 10, height: 10)
                    ),
                    description: "Feasts & Solemnities"
                )
                legendItem(
                    name: "Green",
                    dot: AnyView(
                        Circle()
                            .fill(LiturgicalColors.green)
                            .frame(width: 10, height: 10)
                    ),
                    description: "Ordinary Time"
                )
                legendItem(
                    name: "Violet",
                    dot: AnyView(
                        Circle()
                            .fill(LiturgicalColors.violet)
                            .frame(width: 10, height: 10)
                    ),
                    description: "Advent & Lent"
                )
                legendItem(
                    name: "Red",
                    dot: AnyView(
                        Circle()
                            .fill(LiturgicalColors.red)
                            .frame(width: 10, height: 10)
                    ),
                    description: "Martyrs & Pentecost"
                )
                legendItem(
                    name: "Rose",
                    dot: AnyView(
                        Circle()
                            .fill(LiturgicalColors.rose)
                            .frame(width: 10, height: 10)
                    ),
                    description: "Gaudete & Laetare"
                )
            }
        }
        .cardStyle(
            backgroundColor: AppTheme.Colors.cardBackground.opacity(0.8),
            cornerRadius: AppTheme.CornerRadius.medium,
            padding: AppTheme.Spacing.medium
        )
    }
    
    private func legendItem(name: String, dot: AnyView, description: String) -> some View {
        HStack(spacing: 6) {
            dot
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.scaled(size: 12, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Text(description)
                    .font(.scaled(size: 10, weight: .regular))
                    .foregroundStyle(Color.secondary)
            }
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Helpers
    
    private func formattedSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}
