//
//  PrayersView.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Main container view for the Catholic Treasury of Prayers tab.
///
/// Provides category-based browsing, real-time search, interactive Rosary guide,
/// and full-screen missal prayer presentations with English and Latin texts.
public struct PrayersView: View {
    
    public var liturgicalColor: LiturgicalColor = .green
    
    @State private var repository = PrayersRepository.shared
    @State private var selectedCategory: PrayerCategory = .all
    @State private var searchQuery: String = ""
    @State private var selectedPrayer: Prayer?
    @State private var showRosaryGuide: Bool = false
    
    public init(liturgicalColor: LiturgicalColor = .green) {
        self.liturgicalColor = liturgicalColor
    }
    
    private var filteredPrayers: [Prayer] {
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return repository.search(query: searchQuery)
        }
        return repository.prayers(for: selectedCategory)
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                // Header Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Treasury of Prayers")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color.primary)
                    
                    Text("Traditional Roman Catholic devotions, daily prayers, and the Holy Rosary.")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .foregroundStyle(Color.secondary)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.top, AppTheme.Spacing.small)
                
                // Today's Rosary Mystery Quick Card
                todayRosaryBanner
                    .padding(.horizontal, AppTheme.Spacing.medium)
                
                // Category Filter Pills
                categoryFilterBar
                
                // Prayers List
                if filteredPrayers.isEmpty {
                    emptySearchResults
                } else {
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(filteredPrayers) { prayer in
                            prayerCard(prayer)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                }
                
                Spacer()
                    .frame(height: AppTheme.Spacing.xxlarge)
            }
        }
        .searchable(
            text: $searchQuery,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search prayers by name or keyword..."
        )
        .sheet(item: $selectedPrayer) { prayer in
            if prayer.isRosaryGuide {
                RosaryDetailView(liturgicalColor: liturgicalColor)
            } else {
                PrayerDetailView(prayer: prayer, liturgicalColor: liturgicalColor)
            }
        }
        .sheet(isPresented: $showRosaryGuide) {
            RosaryDetailView(liturgicalColor: liturgicalColor)
        }
    }
    
    // MARK: - Today's Rosary Quick Banner
    
    private var todayRosaryBanner: some View {
        let todayMystery = RosaryMysteryType.forDate()
        return Button {
            showRosaryGuide = true
        } label: {
            HStack(spacing: AppTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(liturgicalColor.swiftUIColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "circle.grid.cross.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(liturgicalColor.uiAccentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("TODAY'S ROSARY")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.2)
                            .foregroundStyle(liturgicalColor.uiAccentColor)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                        
                        Text(todayMystery.traditionalDays)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Text(todayMystery.rawValue)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundStyle(Color.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.6))
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(Color(uiColor: UIColor { trait in
                        trait.userInterfaceStyle == .dark
                            ? UIColor(red: 28 / 255, green: 27 / 255, blue: 31 / 255, alpha: 1.0)
                            : UIColor(red: 254 / 255, green: 252 / 255, blue: 247 / 255, alpha: 1.0)
                    }))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(liturgicalColor.uiAccentColor.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open today's Rosary mysteries")
    }
    
    // MARK: - Category Filter Bar
    
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.small) {
                ForEach(PrayerCategory.allCases) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: category.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(category.rawValue)
                                .font(.system(size: 13, weight: selectedCategory == category ? .semibold : .regular))
                        }
                        .foregroundStyle(selectedCategory == category ? Color.primary : Color.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            selectedCategory == category
                                ? liturgicalColor.swiftUIColor.opacity(0.18)
                                : Color.secondary.opacity(0.08)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedCategory == category
                                        ? liturgicalColor.uiAccentColor.opacity(0.4)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Prayer Card
    
    private func prayerCard(_ prayer: Prayer) -> some View {
        Button {
            selectedPrayer = prayer
        } label: {
            HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(prayer.title)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundStyle(Color.primary)
                        
                        if prayer.hasLatin {
                            Text("LATIN")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(liturgicalColor.uiAccentColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(liturgicalColor.swiftUIColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let latin = prayer.latinTitle, !latin.isEmpty {
                        Text(latin)
                            .font(.system(size: 13, weight: .medium, design: .serif).italic())
                            .foregroundStyle(Color.secondary)
                    }
                    
                    Text(cleanFirstLine(prayer.textEnglish))
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .foregroundStyle(Color.secondary.opacity(0.85))
                        .lineLimit(1)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(AppTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func cleanFirstLine(_ text: String) -> String {
        let firstLine = text.components(separatedBy: "\n").first ?? text
        return firstLine
            .replacingOccurrences(of: "℣.", with: "")
            .replacingOccurrences(of: "℟.", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Empty State
    
    private var emptySearchResults: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Spacer()
                .frame(height: 40)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(Color.secondary.opacity(0.5))
            Text("No prayers found matching \"\(searchQuery)\"")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundStyle(Color.secondary)
            Button("Clear Search") {
                searchQuery = ""
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(liturgicalColor.uiAccentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.large)
    }
}
