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
    @State private var audioPlayer = AudioReadingPlayer.shared
    @State private var bookmarkManager = BookmarkManager.shared
    
    private var isSpeaking: Bool {
        audioPlayer.currentReading?.id == reading.id && (audioPlayer.isPlaying || audioPlayer.isPaused)
    }
    
    private var isBookmarked: Bool {
        bookmarkManager.isBookmarked(reading: reading)
    }
    
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
                    if reading.type == .responsorialPsalm, let response = reading.effectivePsalmResponse ?? reading.psalmResponse ?? reading.response {
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
            borderColor: isSpeaking ? liturgicalColor.uiAccentColor : (reading.type == .gospel ? liturgicalColor.swiftUIColor.opacity(0.3) : nil)
        )
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(reading.type.displayTitle)
                        .readingTitleStyle(tintColor: liturgicalColor.uiAccentColor)
                    
                    if reading.type == .gospel {
                        Image(systemName: "cross.fill")
                            .font(.scaled(size: 10))
                            .foregroundStyle(liturgicalColor.uiAccentColor)
                    }
                    
                    if isSpeaking {
                        HStack(spacing: 3) {
                            Image(systemName: "waveform")
                                .font(.scaled(size: 10, weight: .semibold))
                                .symbolEffect(.variableColor.iterative, isActive: audioPlayer.isPlaying)
                            Text("Speaking")
                                .font(.scaled(size: 10, weight: .bold))
                        }
                        .foregroundStyle(liturgicalColor.uiAccentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(liturgicalColor.swiftUIColor.opacity(0.12))
                        .clipShape(Capsule())
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
                    .font(.scaled(size: 13, weight: .semibold))
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
                .font(.scaled(size: CGFloat(scriptureFontSize), weight: .bold, design: .serif))
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
            Button {
                if isSpeaking && audioPlayer.isPlaying {
                    audioPlayer.pause()
                } else if isSpeaking && audioPlayer.isPaused {
                    audioPlayer.resume()
                } else {
                    audioPlayer.start(readings: [reading], liturgicalTitle: reading.type.displayTitle)
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: isSpeaking && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.scaled(size: 14, weight: .semibold))
                    Text(isSpeaking && audioPlayer.isPlaying ? "Pause audio" : "Listen")
                        .font(.scaled(size: 13, weight: .medium))
                }
                .foregroundStyle(liturgicalColor.uiAccentColor)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button {
                bookmarkManager.toggleBookmark(
                    reading: reading,
                    date: .now,
                    liturgicalTitle: reading.type.displayTitle
                )
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.scaled(size: 14, weight: .medium))
                    .foregroundStyle(isBookmarked ? LiturgicalColors.goldAccent : Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Bookmark this reading")
            
            if let onSelect {
                Button(action: onSelect) {
                    HStack(spacing: 5) {
                        Text("Read full view")
                            .font(.scaled(size: 13, weight: .medium))
                        Image(systemName: "arrow.up.forward.app")
                            .font(.scaled(size: 12, weight: .medium))
                    }
                    .foregroundStyle(liturgicalColor.swiftUIColor)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
