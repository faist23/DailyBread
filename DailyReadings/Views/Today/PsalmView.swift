//
//  PsalmView.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Specialized view for the Responsorial Psalm in Catholic Mass readings.
///
/// Features a prominent antiphon response banner with red rubric lettering ("℟."),
/// contemplative verse stanza layout, and distinct soft background styling.
public struct PsalmView: View {
    
    // MARK: - Properties
    
    public let reading: Reading
    public var liturgicalColor: LiturgicalColor = .green
    public var onExpandDetail: (() -> Void)?
    
    @AppStorage("scriptureFontSize") private var scriptureFontSize: Double = 18.0
    @State private var isCollapsed: Bool = false
    
    // MARK: - Initialization
    
    public init(
        reading: Reading,
        liturgicalColor: LiturgicalColor = .green,
        onExpandDetail: (() -> Void)? = nil
    ) {
        self.reading = reading
        self.liturgicalColor = liturgicalColor
        self.onExpandDetail = onExpandDetail
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            // Header Bar
            headerSection
            
            if !isCollapsed {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    // Prominent Antiphon / Response Box
                    if let response = reading.psalmResponse ?? reading.response {
                        responseBanner(response: response)
                    }
                    
                    // Stanzas with Missal Response Reminders
                    stanzasView
                    
                    // Fullscreen Reading Action
                    if let onExpandDetail {
                        fullReadingButton(action: onExpandDetail)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle(
            backgroundColor: psalmCardBackground,
            cornerRadius: AppTheme.CornerRadius.large,
            padding: AppTheme.Spacing.medium,
            borderColor: liturgicalColor.swiftUIColor.opacity(0.18)
        )
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(reading.type.displayTitle)
                    .readingTitleStyle(tintColor: liturgicalColor.swiftUIColor)
                
                Text(reading.citation.reference)
                    .readingCitationStyle()
            }
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isCollapsed.toggle()
                }
            } label: {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCollapsed ? "Expand Responsorial Psalm" : "Collapse Responsorial Psalm")
        }
    }
    
    // MARK: - Response Antiphon Banner
    
    private func responseBanner(response: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.small) {
            Text("℟.")
                .font(.system(size: CGFloat(scriptureFontSize), weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.Colors.missalRed)
            
            Text(response)
                .font(.scripturePsalmResponseFont(size: CGFloat(scriptureFontSize)))
                .foregroundStyle(Color.primary)
                .lineSpacing(4)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(AppTheme.Colors.missalRed.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(AppTheme.Colors.missalRed.opacity(0.18), lineWidth: 1)
        )
    }
    
    // MARK: - Stanzas
    
    private var stanzasView: some View {
        let stanzas = reading.text.components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        return VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            ForEach(Array(stanzas.enumerated()), id: \.offset) { index, stanza in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(stanza.trimmingCharacters(in: .whitespacesAndNewlines))
                        .scriptureBodyStyle(fontSize: CGFloat(scriptureFontSize), lineSpacing: 6)
                    
                    // Gentle repetition cue between stanzas
                    if index < stanzas.count - 1, let response = reading.psalmResponse ?? reading.response {
                        HStack(spacing: AppTheme.Spacing.xxsmall) {
                            Text("℟.")
                                .font(.system(size: 13, weight: .bold, design: .serif))
                                .foregroundStyle(AppTheme.Colors.missalRed)
                            
                            Text(response)
                                .font(.system(size: 13, weight: .regular, design: .serif).italic())
                                .foregroundStyle(Color.secondary)
                                .lineLimit(1)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Action Button
    
    private func fullReadingButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("Full Screen Reading")
                    .font(.system(size: 13, weight: .medium))
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(liturgicalColor.swiftUIColor)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    // MARK: - Styling
    
    private var psalmCardBackground: Color {
        // Slightly warm distinct background for the psalm
        Color(
            uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 32 / 255, green: 30 / 255, blue: 34 / 255, alpha: 1.0)
                    : UIColor(red: 254 / 255, green: 252 / 255, blue: 246 / 255, alpha: 1.0)
            }
        )
    }
}
