//
//  VerseOfDayCard.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Top hero card on Today view presenting the liturgical Verse of the Day.
///
/// Anchors the user's morning prayer with a quiet, contemplative scripture focus,
/// citation, and one-tap copy or sharing.
public struct VerseOfDayCard: View {
    
    // MARK: - Properties
    
    public let verse: VerseOfTheDay
    public var liturgicalColor: LiturgicalColor = .green
    
    @State private var hasCopied: Bool = false
    @State private var showShareSheet: Bool = false
    
    public init(
        verse: VerseOfTheDay,
        liturgicalColor: LiturgicalColor = .green
    ) {
        self.verse = verse
        self.liturgicalColor = liturgicalColor
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            // Header Bar
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(liturgicalColor.uiAccentColor)
                
                Text("VERSE OF THE DAY")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .tracking(1.4)
                    .foregroundStyle(liturgicalColor.uiAccentColor)
                
                Spacer()
                
                Text(verse.sourceNote.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(Capsule())
            }
            
            // Scripture Quotation in New York Serif
            Text("“\(verse.text)”")
                .font(.system(size: 17, weight: .regular, design: .serif).italic())
                .foregroundStyle(Color.primary)
                .lineSpacing(5)
                .padding(.vertical, 4)
                .fixedSize(horizontal: false, vertical: true)
            
            // Footer: Citation and Action Buttons
            HStack(alignment: .center) {
                Text(verse.citation)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundStyle(liturgicalColor.swiftUIColor)
                
                if let theme = verse.theme, !theme.isEmpty {
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary.opacity(0.6))
                    Text(theme)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color.secondary)
                }
                
                Spacer()
                
                // Copy Button
                Button {
                    UIPasteboard.general.string = "“\(verse.text)” — \(verse.citation)"
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        hasCopied = true
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        await MainActor.run {
                            withAnimation {
                                hasCopied = false
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: hasCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .semibold))
                        if hasCopied {
                            Text("Copied")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .foregroundStyle(hasCopied ? LiturgicalColors.goldAccent : Color.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Copy verse to clipboard")
                
                // Share Button
                ShareLink(
                    item: "“\(verse.text)” — \(verse.citation)\nDaily Mass Readings (DailyReadings for iOS)",
                    subject: Text("Verse of the Day — \(verse.citation)"),
                    message: Text("“\(verse.text)” — \(verse.citation)")
                ) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .padding(6)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Share Verse of the Day")
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(liturgicalColor.uiAccentColor.opacity(0.35), lineWidth: 1)
        )
    }
    
    // MARK: - Styling
    
    private var cardBackgroundColor: Color {
        Color(
            uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: 28 / 255, green: 27 / 255, blue: 30 / 255, alpha: 1.0)
                    : UIColor(red: 253 / 255, green: 251 / 255, blue: 245 / 255, alpha: 1.0)
            }
        )
    }
}
