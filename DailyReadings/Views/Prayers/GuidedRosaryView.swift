//
//  GuidedRosaryView.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import AVFoundation
import SwiftUI

/// An interactive, bead-by-bead prayer companion for the Holy Rosary.
///
/// Steps through each prayer from the opening Sign of the Cross to the closing Salve Regina,
/// tracking decade beads visually, displaying full prayer texts, offering contemplative
/// mystery meditations, and triggering gentle haptic taps as beads are counted.
public struct GuidedRosaryView: View {
    
    // MARK: - Properties
    
    public let mysteryType: RosaryMysteryType
    public var liturgicalColor: LiturgicalColor = .green
    
    @Environment(\.dismiss) private var dismiss
    @AppStorage("scriptureFontSize") private var scriptureFontSize: Double = 18.0
    
    @State private var steps: [GuidedRosaryStep] = []
    @State private var currentIndex: Int = 0
    @State private var isFinished: Bool = false
    @State private var isSpeaking: Bool = false
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var showMeditationSheet: Bool = false
    
    public init(
        mysteryType: RosaryMysteryType,
        liturgicalColor: LiturgicalColor = .green
    ) {
        self.mysteryType = mysteryType
        self.liturgicalColor = liturgicalColor
    }
    
    private var currentStep: GuidedRosaryStep? {
        guard currentIndex >= 0 && currentIndex < steps.count else { return nil }
        return steps[currentIndex]
    }
    
    private var progressFraction: Double {
        guard !steps.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(steps.count)
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.Colors.groupedBackground
                    .ignoresSafeArea()
                
                if isFinished {
                    completionView
                } else if let step = currentStep {
                    VStack(spacing: 0) {
                        // Top Progress Bar
                        progressBar
                        
                        // Scrollable Prayer & Mystery Area
                        ScrollView {
                            VStack(spacing: AppTheme.Spacing.medium) {
                                // Bead & Mystery Context Badge
                                beadHeaderCard(step: step)
                                
                                // Decade Beads Visual Indicator (if inside a decade)
                                if let beadIndex = step.beadIndex {
                                    decadeBeadDots(currentIndex: beadIndex)
                                        .padding(.vertical, 4)
                                }
                                
                                // Meditation Card (if mystery meditation exists)
                                if let meditation = step.meditation, step.beadIndex == nil {
                                    mysteryMeditationCard(step: step, meditation: meditation)
                                }
                                
                                // Prayer Text
                                prayerCard(step: step)
                            }
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .padding(.top, AppTheme.Spacing.small)
                            .padding(.bottom, 120) // spacing for bottom bar
                        }
                        
                        // Bottom Navigation Controls
                        bottomControlBar
                    }
                }
            }
            .navigationTitle(mysteryType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") {
                        stopSpeaking()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.secondary)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        toggleSpeech()
                    } label: {
                        Image(systemName: isSpeaking ? "stop.circle.fill" : "speaker.wave.2")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isSpeaking ? AppTheme.Colors.missalRed : liturgicalColor.uiAccentColor)
                    }
                    .accessibilityLabel(isSpeaking ? "Stop recitation" : "Recite prayer")
                }
            }
            .onAppear {
                if steps.isEmpty {
                    steps = GuidedRosaryBuilder.buildSteps(for: mysteryType)
                }
            }
            .onDisappear {
                stopSpeaking()
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(height: 3)
                
                Rectangle()
                    .fill(liturgicalColor.uiAccentColor)
                    .frame(width: geometry.size.width * CGFloat(progressFraction), height: 3)
                    .animation(.easeInOut(duration: 0.25), value: progressFraction)
            }
        }
        .frame(height: 3)
    }
    
    // MARK: - Bead Header Card
    
    private func beadHeaderCard(step: GuidedRosaryStep) -> some View {
        VStack(spacing: 4) {
            Text(step.beadPosition.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(liturgicalColor.uiAccentColor)
            
            Text(step.prayerName)
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.center)
            
            if let mystery = step.mysteryTitle {
                Text(mystery)
                    .font(.system(size: 13, weight: .medium, design: .serif).italic())
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 1)
            }
            
            if let fruit = step.fruitOfMystery {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                    Text("Fruit: \(fruit)")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(liturgicalColor.uiAccentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(liturgicalColor.swiftUIColor.opacity(0.1))
                .clipShape(Capsule())
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.small)
    }
    
    // MARK: - Decade Bead Dots (1-10)
    
    private func decadeBeadDots(currentIndex: Int) -> some View {
        HStack(spacing: 7) {
            ForEach(1...10, id: \.self) { bead in
                ZStack {
                    if bead < currentIndex {
                        // Completed bead
                        Circle()
                            .fill(liturgicalColor.uiAccentColor)
                            .frame(width: 14, height: 14)
                    } else if bead == currentIndex {
                        // Current bead (pulsing ring)
                        Circle()
                            .fill(liturgicalColor.uiAccentColor)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(liturgicalColor.uiAccentColor.opacity(0.4), lineWidth: 3)
                            )
                    } else {
                        // Future bead
                        Circle()
                            .stroke(Color.secondary.opacity(0.35), lineWidth: 1.5)
                            .frame(width: 14, height: 14)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.06))
        .clipShape(Capsule())
    }
    
    // MARK: - Mystery Meditation Card
    
    private func mysteryMeditationCard(step: GuidedRosaryStep, meditation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let scripture = step.scriptureRef {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 11))
                    Text(scripture)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(liturgicalColor.uiAccentColor)
            }
            
            Text(meditation)
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color.secondary)
                .lineSpacing(4)
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(liturgicalColor.swiftUIColor.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(liturgicalColor.uiAccentColor.opacity(0.25), lineWidth: 1)
        )
    }
    
    // MARK: - Prayer Card
    
    private func prayerCard(step: GuidedRosaryStep) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text(step.prayerText)
                .font(.system(size: CGFloat(scriptureFontSize), weight: .regular, design: .serif))
                .foregroundStyle(Color.primary)
                .lineSpacing(7)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppTheme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Bottom Control Bar
    
    private var bottomControlBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: AppTheme.Spacing.medium) {
                // Previous Bead Button
                Button {
                    previousBead()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Previous")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(currentIndex > 0 ? Color.primary : Color.secondary.opacity(0.4))
                    .frame(width: 100, height: 46)
                    .background(Color.secondary.opacity(currentIndex > 0 ? 0.08 : 0.03))
                    .clipShape(Capsule())
                }
                .disabled(currentIndex == 0)
                .buttonStyle(.plain)
                
                // Step Counter / Index
                VStack(spacing: 2) {
                    Text("\(currentIndex + 1) of \(steps.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.secondary)
                    Text("Bead")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.secondary.opacity(0.7))
                }
                .frame(minWidth: 60)
                
                // Next Bead / Advance Button
                Button {
                    nextBead()
                } label: {
                    HStack(spacing: 6) {
                        Text(currentIndex < steps.count - 1 ? "Next Bead" : "Complete")
                            .font(.system(size: 15, weight: .bold))
                        Image(systemName: currentIndex < steps.count - 1 ? "chevron.forward" : "checkmark")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(liturgicalColor.swiftUIColor)
                    .clipShape(Capsule())
                    .shadow(color: liturgicalColor.uiAccentColor.opacity(0.3), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.small)
            .background(AppTheme.Colors.cardBackground.ignoresSafeArea(edges: .bottom))
        }
    }
    
    // MARK: - Actions
    
    private func nextBead() {
        stopSpeaking()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.22)) {
            if currentIndex < steps.count - 1 {
                currentIndex += 1
            } else {
                isFinished = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    private func previousBead() {
        guard currentIndex > 0 else { return }
        stopSpeaking()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.22)) {
            currentIndex -= 1
        }
    }
    
    // MARK: - Speech
    
    private func toggleSpeech() {
        if isSpeaking {
            stopSpeaking()
        } else if let step = currentStep {
            speak(text: step.prayerText)
        }
    }
    
    private func speak(text: String) {
        stopSpeaking()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.88
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    private func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(liturgicalColor.swiftUIColor.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(liturgicalColor.uiAccentColor)
            }
            
            VStack(spacing: 8) {
                Text("Rosary Completed")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color.primary)
                
                Text(mysteryType.rawValue)
                    .font(.system(size: 16, weight: .medium, design: .serif).italic())
                    .foregroundStyle(Color.secondary)
            }
            
            VStack(spacing: 6) {
                Text("“May the divine assistance remain always with us, and may the souls of the faithful departed, through the mercy of God, rest in peace.”")
                    .font(.system(size: 15, weight: .regular, design: .serif).italic())
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, AppTheme.Spacing.large)
                
                Text("Amen.")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(Color.primary)
                    .padding(.top, 4)
            }
            .padding(.vertical, AppTheme.Spacing.medium)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Return to Prayers")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(liturgicalColor.swiftUIColor)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.bottom, AppTheme.Spacing.large)
        }
    }
}
