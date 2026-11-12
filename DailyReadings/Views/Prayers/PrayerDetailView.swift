//
//  PrayerDetailView.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import AVFoundation
import SwiftUI

/// Full-screen contemplative reading view for a Catholic prayer.
///
/// Supports English and Latin side-by-side or toggle, reverent audio playback,
/// copy/share actions, and traditional missal typography.
public struct PrayerDetailView: View {
    
    public let prayer: Prayer
    public var liturgicalColor: LiturgicalColor = .green
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("scriptureFontSize") private var scriptureFontSize: Double = 18.0
    @State private var selectedLanguage: Language = .english
    @State private var hasCopied: Bool = false
    /// Identifier of this view's recitation in the shared audio player, while it is speaking.
    @State private var speechID: UUID?

    private var isSpeaking: Bool {
        speechID != nil && AudioReadingPlayer.shared.standaloneSpeechID == speechID
    }
    
    private enum Language: String, CaseIterable, Identifiable {
        case english = "English"
        case latin = "Latin"
        
        var id: String { rawValue }
    }
    
    public init(
        prayer: Prayer,
        liturgicalColor: LiturgicalColor = .green
    ) {
        self.prayer = prayer
        self.liturgicalColor = liturgicalColor
    }
    
    private var activePrayerText: String {
        if selectedLanguage == .latin, let latin = prayer.textLatin, !latin.isEmpty {
            return latin
        }
        return prayer.textEnglish
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    // Header Category & Subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: prayer.category.icon)
                                .font(.scaled(size: 12, weight: .semibold))
                            Text(prayer.category.rawValue.uppercased())
                                .font(.scaled(size: 11, weight: .bold))
                                .tracking(1.2)
                        }
                        .foregroundStyle(liturgicalColor.uiAccentColor)
                        
                        Text(prayer.title)
                            .font(.scaled(size: 26, weight: .bold, design: .serif))
                            .foregroundStyle(Color.primary)
                        
                        if let latinTitle = prayer.latinTitle, !latinTitle.isEmpty {
                            Text(latinTitle)
                                .font(.scaled(size: 16, weight: .medium, design: .serif).italic())
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .padding(.top, AppTheme.Spacing.small)
                    
                    // Language Switcher (if Latin text available)
                    if prayer.hasLatin {
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(Language.allCases) { lang in
                                Text(lang.rawValue).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 4)
                    }
                    
                    // Audio & Share Actions Bar
                    HStack(spacing: AppTheme.Spacing.medium) {
                        // Audio Recitation Button
                        Button {
                            toggleSpeech()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isSpeaking ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.scaled(size: 14, weight: .semibold))
                                Text(isSpeaking ? "Stop" : "Listen")
                                    .font(.scaled(size: 13, weight: .medium))
                            }
                            .foregroundStyle(liturgicalColor.uiAccentColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(liturgicalColor.swiftUIColor.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isSpeaking ? "Stop reciting prayer" : "Listen to prayer recited")
                        
                        Spacer()
                        
                        // Copy Button
                        Button {
                            UIPasteboard.general.string = "\(prayer.title)\n\n\(activePrayerText)"
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
                            HStack(spacing: 4) {
                                Image(systemName: hasCopied ? "checkmark" : "doc.on.doc")
                                    .font(.scaled(size: 12, weight: .medium))
                                if hasCopied {
                                    Text("Copied")
                                        .font(.scaled(size: 12, weight: .medium))
                                }
                            }
                            .foregroundStyle(hasCopied ? LiturgicalColors.goldAccent : Color.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Copy prayer text")
                        
                        // Share Button
                        ShareLink(
                            item: "\(prayer.title)\n\n\(activePrayerText)\n\n— DailyReadings for iOS",
                            subject: Text(prayer.title),
                            message: Text(activePrayerText)
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.scaled(size: 12, weight: .medium))
                                .foregroundStyle(Color.secondary)
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Share prayer")
                    }
                    
                    Divider()
                        .padding(.vertical, AppTheme.Spacing.xxsmall)
                    
                    // Prayer Body Text in Missal Typography
                    Text(activePrayerText)
                        .font(.scaled(size: CGFloat(scriptureFontSize), weight: .regular, design: .serif))
                        .foregroundStyle(Color.primary)
                        .lineSpacing(8)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Rubric or Source Card
                    if let note = prayer.rubricNote ?? prayer.source {
                        VStack(alignment: .leading, spacing: 6) {
                            if let source = prayer.source {
                                HStack(spacing: 4) {
                                    Text("SOURCE:")
                                        .font(.scaled(size: 10, weight: .bold))
                                        .foregroundStyle(liturgicalColor.uiAccentColor)
                                    Text(source)
                                        .font(.scaled(size: 12, weight: .medium, design: .serif))
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                            
                            if let rubric = prayer.rubricNote {
                                HStack(alignment: .top, spacing: 6) {
                                    Text("℟.")
                                        .font(.scaled(size: 12, weight: .bold, design: .serif))
                                        .foregroundStyle(AppTheme.Colors.missalRed)
                                    Text(rubric)
                                        .font(.scaled(size: 12, weight: .regular, design: .serif).italic())
                                        .foregroundStyle(Color.secondary)
                                }
                            }
                        }
                        .padding(AppTheme.Spacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                .fill(Color.secondary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                        )
                        .padding(.top, AppTheme.Spacing.medium)
                    }
                    
                    Spacer()
                        .frame(height: AppTheme.Spacing.xxlarge)
                }
                .padding(.horizontal, AppTheme.Spacing.large)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        stopSpeech()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.scaled(size: 13, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close prayer")
                }
            }
            .onDisappear {
                stopSpeech()
            }
        }
    }
    
    // MARK: - Speech Synthesis
    
    private func toggleSpeech() {
        if isSpeaking {
            stopSpeech()
        } else {
            startSpeech()
        }
    }
    
    private func startSpeech() {
        let cleaned = activePrayerText
            .replacingOccurrences(of: "℣.", with: "")
            .replacingOccurrences(of: "℟.", with: "")

        // Latin has no system voice on most devices; Italian is the closest pronunciation.
        let voice = selectedLanguage == .latin
            ? (AVSpeechSynthesisVoice(language: "la") ?? AVSpeechSynthesisVoice(language: "it-IT"))
            : nil

        speechID = AudioReadingPlayer.shared.speakStandalone(
            "\(prayer.title). \(cleaned)",
            rate: selectedLanguage == .latin ? 0.42 : 0.46,
            voice: voice
        )
    }
    
    private func stopSpeech() {
        AudioReadingPlayer.shared.stopStandalone(speechID)
        speechID = nil
    }
}
