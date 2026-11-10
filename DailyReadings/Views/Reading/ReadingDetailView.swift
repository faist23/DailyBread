//
//  ReadingDetailView.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Full-screen contemplative reading view for Catholic daily Mass scripture texts.
///
/// Provides a comfortable, distraction-free reading layout with New York serif font,
/// adjustable text sizing via buttons or pinch gestures, translation badge,
/// and sharing capabilities.
public struct ReadingDetailView: View {
    
    // MARK: - Properties & Environment
    
    public let reading: Reading
    public var liturgicalColor: LiturgicalColor = .green
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("scriptureFontSize") private var scriptureFontSize: Double = 20.0
    @AppStorage("bibleTranslation") private var selectedTranslation: String = "Douay-Rheims"
    
    @State private var bookmarkManager = BookmarkManager.shared
    @State private var currentMagnification: CGFloat = 1.0
    
    // MARK: - Initialization
    
    public init(reading: Reading, liturgicalColor: LiturgicalColor = .green) {
        self.reading = reading
        self.liturgicalColor = liturgicalColor
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            // Calm scripture paper background
            AppTheme.Colors.scripturePaper
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Citation & Translation Bar
                topCitationHeader
                
                // Scripture Scrollable Reading Text
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                        // Title / Reading Category
                        Text(reading.type.displayTitle)
                            .readingTitleStyle(tintColor: liturgicalColor.swiftUIColor)
                            .padding(.top, AppTheme.Spacing.medium)
                        
                        // Responsorial Psalm Antiphon Banner
                        if reading.type == .responsorialPsalm, let response = reading.effectivePsalmResponse ?? reading.psalmResponse ?? reading.response {
                            psalmResponseBanner(response: response)
                        }
                        
                        // Full Scripture Text with Generous Leading
                        Text(reading.text.trimmingCharacters(in: .whitespacesAndNewlines))
                            .scriptureBodyStyle(
                                fontSize: CGFloat(scriptureFontSize) * currentMagnification,
                                lineSpacing: 9
                            )
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Traditional Missal Rubric Footer
                        missalRubricFooter
                        
                        Spacer()
                            .frame(height: AppTheme.Spacing.xxlarge)
                    }
                    .padding(.horizontal, AppTheme.Spacing.large)
                }
                .simultaneousGesture(
                    MagnifyGesture()
                        .onChanged { value in
                            currentMagnification = value.magnification
                        }
                        .onEnded { _ in
                            // Persist adjusted size clamped to reasonable range
                            let newSize = (scriptureFontSize * Double(currentMagnification)).clamped(to: 14...34)
                            scriptureFontSize = newSize
                            currentMagnification = 1.0
                        }
                )
                
                // Bottom Reader Controls Bar (Font +/- and Share)
                bottomControlsBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close Reader")
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        bookmarkManager.toggleBookmark(
                            reading: reading,
                            date: .now,
                            liturgicalTitle: reading.type.displayTitle
                        )
                    } label: {
                        let isBookmarked = bookmarkManager.isBookmarked(reading: reading)
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isBookmarked ? LiturgicalColors.goldAccent : liturgicalColor.swiftUIColor)
                    }
                    .accessibilityLabel(bookmarkManager.isBookmarked(reading: reading) ? "Remove bookmark" : "Bookmark this reading")

                    ShareLink(
                        item: "\(reading.type.displayTitle)\n\(reading.citation.reference)\n\n\(reading.text)",
                        subject: Text(reading.citation.reference),
                        message: Text("DailyReadings Scripture Reading")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(liturgicalColor.swiftUIColor)
                    }
                }
            }
        }
    }
    
    // MARK: - Top Citation Header
    
    private var topCitationHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(reading.citation.reference)
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .foregroundStyle(Color.primary)
            }
            
            Spacer()
            
            // Translation Badge
            Text(selectedTranslation)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(liturgicalColor.swiftUIColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(liturgicalColor.badgeBackground)
                .clipShape(Capsule())
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.vertical, AppTheme.Spacing.compact)
        .background(AppTheme.Colors.scripturePaper)
        .overlay(
            Rectangle()
                .fill(Color(uiColor: .separator).opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Responsorial Psalm Banner
    
    private func psalmResponseBanner(response: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.small) {
            Text("℟.")
                .font(.system(size: CGFloat(scriptureFontSize) * currentMagnification, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.Colors.missalRed)
            
            Text(response)
                .font(.scripturePsalmResponseFont(size: CGFloat(scriptureFontSize) * currentMagnification))
                .foregroundStyle(Color.primary)
                .lineSpacing(4)
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(AppTheme.Colors.missalRed.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(AppTheme.Colors.missalRed.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Missal Rubric Footer
    
    private var missalRubricFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Divider()
                .padding(.vertical, AppTheme.Spacing.small)
            
            if reading.type == .gospel {
                Text("The Gospel of the Lord.")
                    .font(.system(size: 14, weight: .semibold, design: .serif).italic())
                    .foregroundStyle(Color.secondary)
                Text("℟. Praise to you, Lord Jesus Christ.")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.Colors.missalRed)
            } else if reading.type != .responsorialPsalm {
                Text("The word of the Lord.")
                    .font(.system(size: 14, weight: .semibold, design: .serif).italic())
                    .foregroundStyle(Color.secondary)
                Text("℟. Thanks be to God.")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(AppTheme.Colors.missalRed)
            }
        }
        .padding(.top, AppTheme.Spacing.medium)
    }
    
    // MARK: - Bottom Controls Bar
    
    private var bottomControlsBar: some View {
        HStack(spacing: AppTheme.Spacing.large) {
            // Decrease Font Button
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    scriptureFontSize = max(14, scriptureFontSize - 2)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "textformat.size.smaller")
                    Text("A-")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            // Current Font Size Indicator
            Text("\(Int(scriptureFontSize)) pt")
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.secondary)
            
            // Increase Font Button
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    scriptureFontSize = min(32, scriptureFontSize + 2)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "textformat.size.larger")
                    Text("A+")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.12))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.compact)
        .background(AppTheme.Colors.cardBackground)
        .overlay(
            Rectangle()
                .fill(Color(uiColor: .separator).opacity(0.2))
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Clamping Helper

fileprivate extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
