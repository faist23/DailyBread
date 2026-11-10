//
//  ReadingCard.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// A card displaying a single Catholic Mass reading (First Reading, Responsorial Psalm,
/// Second Reading, Gospel).
///
/// Provides smooth expansion/collapse animation, New York serif scripture rendering,
/// and responsive Dynamic Type font scaling.
public struct ReadingCard: View {
    
    // MARK: - Properties
    
    public let reading: Reading
    public var liturgicalColor: LiturgicalColor = .green
    public var onSelect: (() -> Void)?
    
    @AppStorage("scriptureFontSize") private var scriptureFontSize: Double = 18.0
    @State private var isCollapsed: Bool = false
    
    // MARK: - Initialization
    
    public init(
        reading: Reading,
        liturgicalColor: LiturgicalColor = .green,
        onSelect: (() -> Void)? = nil
    ) {
        self.reading = reading
        self.liturgicalColor = liturgicalColor
        self.onSelect = onSelect
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            // Header Section
            headerView
            
            // Body Content (Collapsible)
            if !isCollapsed {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    // Responsorial Psalm Antiphon Highlight
                    if reading.type == .responsorialPsalm, let response = reading.psalmResponse ?? reading.response {
                        psalmResponseHighlight(response: response)
                    }
                    
                    // Scripture Text in New York Serif
                    Text(reading.text.trimmingCharacters(in: .whitespacesAndNewlines))
                        .scriptureBodyStyle(fontSize: CGFloat(scriptureFontSize), lineSpacing: 7)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Footer Bar with Citation and Fullscreen Action
                    footerView
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle(
            backgroundColor: AppTheme.Colors.cardBackground,
            cornerRadius: AppTheme.CornerRadius.large,
            padding: AppTheme.Spacing.medium,
            borderColor: reading.type == .gospel ? liturgicalColor.swiftUIColor.opacity(0.3) : nil
        )
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(reading.type.displayTitle)
                        .readingTitleStyle(tintColor: liturgicalColor.swiftUIColor)
                    
                    if reading.type == .gospel {
                        Image(systemName: "cross.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(liturgicalColor.swiftUIColor)
                    }
                }
                
                Text(reading.citation.reference)
                    .readingCitationStyle()
            }
            
            Spacer()
            
            // Expand/Collapse Toggle Button
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isCollapsed.toggle()
                }
            } label: {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCollapsed ? "Expand reading" : "Collapse reading")
        }
    }
    
    // MARK: - Responsorial Psalm Antiphon
    
    private func psalmResponseHighlight(response: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.small) {
            Text("℟.")
                .font(.system(size: CGFloat(scriptureFontSize), weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.Colors.missalRed)
            
            Text(response)
                .font(.scripturePsalmResponseFont(size: CGFloat(scriptureFontSize)))
                .foregroundStyle(Color.primary)
                .lineSpacing(4)
        }
        .padding(AppTheme.Spacing.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(AppTheme.Colors.missalRed.opacity(0.06))
        )
    }
    
    // MARK: - Footer View
    
    private var footerView: some View {
        HStack {
            Spacer()
            
            if let onSelect {
                Button(action: onSelect) {
                    HStack(spacing: 5) {
                        Text("Read full view")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(liturgicalColor.swiftUIColor)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
