//
//  RosaryDetailView.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Dedicated interactive meditation guide for the Most Holy Rosary.
///
/// Automatically identifies today's mystery set based on the day of the week,
/// presenting scripture references, fruits of the mystery, and decade meditations.
public struct RosaryDetailView: View {
    
    public var liturgicalColor: LiturgicalColor = .green
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMystery: RosaryMysteryType
    
    private let todayMystery: RosaryMysteryType
    
    public init(liturgicalColor: LiturgicalColor = .green) {
        self.liturgicalColor = liturgicalColor
        let current = RosaryMysteryType.forDate()
        self.todayMystery = current
        self._selectedMystery = State(initialValue: current)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Header Banner
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "circle.grid.cross.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("HOLY ROSARY")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1.4)
                        }
                        .foregroundStyle(liturgicalColor.uiAccentColor)
                        
                        Text(selectedMystery.rawValue)
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundStyle(Color.primary)
                        
                        HStack(spacing: 8) {
                            Text(selectedMystery.traditionalDays)
                                .font(.system(size: 13, weight: .medium, design: .serif))
                                .foregroundStyle(Color.secondary)
                            
                            if selectedMystery == todayMystery {
                                Text("TODAY")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(liturgicalColor.uiAccentColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(liturgicalColor.swiftUIColor.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, AppTheme.Spacing.small)
                    
                    // Mystery Selector Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Spacing.small) {
                            ForEach(RosaryMysteryType.allCases) { mystery in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedMystery = mystery
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        if mystery == todayMystery {
                                            Circle()
                                                .fill(liturgicalColor.uiAccentColor)
                                                .frame(width: 6, height: 6)
                                        }
                                        Text(mystery.rawValue.replacingOccurrences(of: " Mysteries", with: ""))
                                            .font(.system(size: 13, weight: selectedMystery == mystery ? .semibold : .regular))
                                    }
                                    .foregroundStyle(selectedMystery == mystery ? Color.primary : Color.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedMystery == mystery
                                            ? liturgicalColor.swiftUIColor.opacity(0.18)
                                            : Color.secondary.opacity(0.08)
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                selectedMystery == mystery
                                                    ? liturgicalColor.uiAccentColor.opacity(0.5)
                                                    : Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, AppTheme.Spacing.xxsmall)
                    
                    // Decades List
                    let decades = PrayersRepository.decades(for: selectedMystery)
                    VStack(spacing: AppTheme.Spacing.medium) {
                        ForEach(decades) { decade in
                            decadeCard(decade)
                        }
                    }
                    
                    // Closing Rosary Prayers Summary
                    rosaryClosingSection
                    
                    Spacer()
                        .frame(height: AppTheme.Spacing.xxlarge)
                }
                .padding(.horizontal, AppTheme.Spacing.large)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close Rosary Guide")
                }
            }
        }
    }
    
    // MARK: - Decade Card
    
    private func decadeCard(_ decade: RosaryDecade) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack(alignment: .center) {
                Text(decade.number.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(liturgicalColor.uiAccentColor)
                
                Spacer()
                
                Text(decade.scriptureRef)
                    .font(.system(size: 11, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.secondary)
            }
            
            Text(decade.title)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundStyle(Color.primary)
            
            HStack(spacing: 4) {
                Text("FRUIT OF THE MYSTERY:")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.missalRed)
                Text(decade.fruitOfMystery)
                    .font(.system(size: 12, weight: .medium, design: .serif).italic())
                    .foregroundStyle(Color.primary)
            }
            .padding(.vertical, 2)
            
            Text(decade.meditation)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(Color.primary)
                .lineSpacing(5)
                .padding(.top, 2)
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color(uiColor: UIColor { trait in
                    trait.userInterfaceStyle == .dark
                        ? UIColor(red: 30 / 255, green: 29 / 255, blue: 33 / 255, alpha: 1.0)
                        : UIColor(red: 253 / 255, green: 251 / 255, blue: 246 / 255, alpha: 1.0)
                }))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(liturgicalColor.swiftUIColor.opacity(0.18), lineWidth: 1)
        )
    }
    
    // MARK: - Closing Prayers Section
    
    private var rosaryClosingSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("THE FATIMA PRAYER")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(liturgicalColor.uiAccentColor)
            
            Text("O my Jesus, forgive us our sins, save us from the fires of hell, lead all souls to Heaven, especially those most in need of Thy mercy.")
                .font(.system(size: 14, weight: .regular, design: .serif).italic())
                .foregroundStyle(Color.secondary)
                .lineSpacing(4)
            
            Divider()
                .padding(.vertical, 4)
            
            Text("CONCLUDING PRAYER")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(liturgicalColor.uiAccentColor)
            
            Text("O God, whose only begotten Son, by His life, death, and resurrection, has purchased for us the rewards of eternal life, grant, we beseech Thee, that meditating upon these mysteries of the Most Holy Rosary of the Blessed Virgin Mary, we may imitate what they contain and obtain what they promise, through the same Christ our Lord. Amen.")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color.primary)
                .lineSpacing(4)
        }
        .padding(AppTheme.Spacing.medium)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
        .padding(.top, AppTheme.Spacing.medium)
    }
}
