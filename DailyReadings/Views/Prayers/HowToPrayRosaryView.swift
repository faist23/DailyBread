//
//  HowToPrayRosaryView.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Comprehensive instructional guide teaching users how to pray the Holy Rosary.
///
/// Features the 6 sequential steps, the physical anatomy of Rosary beads,
/// the weekly mystery rhythm, and practical spiritual advice for beginners.
public struct HowToPrayRosaryView: View {
    
    public var liturgicalColor: LiturgicalColor = .green
    public var onStartGuidedPrayer: (() -> Void)?
    
    public init(
        liturgicalColor: LiturgicalColor = .green,
        onStartGuidedPrayer: (() -> Void)? = nil
    ) {
        self.liturgicalColor = liturgicalColor
        self.onStartGuidedPrayer = onStartGuidedPrayer
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            // Hero Intro Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "book.pages.fill")
                        .font(.scaled(size: 12, weight: .bold))
                    Text("BEGINNER'S GUIDE")
                        .font(.scaled(size: 11, weight: .bold))
                        .tracking(1.4)
                }
                .foregroundStyle(liturgicalColor.uiAccentColor)
                
                Text("How to Pray the Rosary")
                    .font(.scaled(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.primary)
                
                Text("The Holy Rosary is a contemplative journey through the Gospel. As our lips repeat the gentle prayers of the angelic salutation, our hearts meditate on the mysteries of the life, death, and resurrection of Jesus Christ.")
                    .font(.scaled(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(Color.secondary)
                    .lineSpacing(4)
                
                if let onStartGuidedPrayer {
                    Button(action: onStartGuidedPrayer) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.circle.fill")
                                .font(.scaled(size: 15, weight: .semibold))
                            Text("Start Guided Bead-by-Bead Rosary")
                                .font(.scaled(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(liturgicalColor.primaryButtonForeground)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(liturgicalColor.primaryButtonBackground)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(liturgicalColor.swiftUIColor.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .stroke(liturgicalColor.uiAccentColor.opacity(0.3), lineWidth: 1)
            )
            
            // Section 1: The 6 Steps
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("The 6 Steps of the Rosary")
                    .font(.scaled(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(Color.primary)
                
                stepCard(
                    number: "1",
                    title: "At the Crucifix",
                    prayer: "Sign of the Cross & Apostles' Creed",
                    explanation: "Hold the crucifix in your hand. Make the Sign of the Cross ('In the name of the Father, and of the Son, and of the Holy Spirit'). Then profess your faith by reciting the Apostles' Creed."
                )
                
                stepCard(
                    number: "2",
                    title: "First Large Bead",
                    prayer: "Our Father",
                    explanation: "Move your fingers to the first single bead above the crucifix and pray the Our Father for the intentions of our Holy Father the Pope."
                )
                
                stepCard(
                    number: "3",
                    title: "Three Small Beads",
                    prayer: "Three Hail Marys",
                    explanation: "On the next group of three small beads, pray one Hail Mary on each bead, asking for an increase in the theological virtues of Faith, Hope, and Charity."
                )
                
                stepCard(
                    number: "4",
                    title: "On the Chain",
                    prayer: "Glory Be & Fatima Prayer",
                    explanation: "On the chain before the medal, pray the Glory Be in praise of the Holy Trinity, followed by the Fatima Prayer ('O my Jesus, forgive us our sins...')."
                )
                
                stepCard(
                    number: "5",
                    title: "The Five Decades",
                    prayer: "Our Father + 10 Hail Marys + Glory Be + Fatima Prayer",
                    explanation: "A decade consists of one set of 10 beads. For each of the five decades:\n• Announce the Mystery (e.g. 'The First Joyful Mystery: The Annunciation').\n• Pray 1 Our Father on the large bead.\n• Pray 10 Hail Marys on the 10 small beads while meditating quietly on the mystery.\n• Finish the decade with 1 Glory Be and 1 Fatima Prayer."
                )
                
                stepCard(
                    number: "6",
                    title: "Closing Prayers",
                    prayer: "Hail, Holy Queen & Concluding Prayer",
                    explanation: "After completing all 5 decades, hold the centerpiece medal and pray the Hail, Holy Queen (Salve Regina) followed by the Rosary Concluding Prayer. Conclude by making the Sign of the Cross."
                )
            }
            
            // Section 2: Weekly Mystery Schedule
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text("Weekly Mystery Schedule")
                    .font(.scaled(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(Color.primary)
                
                VStack(spacing: AppTheme.Spacing.small) {
                    mysteryScheduleRow(day: "Mondays & Saturdays", mystery: "Joyful Mysteries", focus: "The Incarnation & Childhood of Jesus")
                    mysteryScheduleRow(day: "Tuesdays & Fridays", mystery: "Sorrowful Mysteries", focus: "The Passion & Death of Our Lord")
                    mysteryScheduleRow(day: "Wednesdays & Sundays", mystery: "Glorious Mysteries", focus: "The Resurrection & Triumph of Heaven")
                    mysteryScheduleRow(day: "Thursdays", mystery: "Luminous Mysteries", focus: "The Public Ministry of Christ")
                }
            }
            
            // Section 3: Practical Beginner Advice
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Spiritual Advice for Beginners")
                    .font(.scaled(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(Color.primary)
                
                adviceBullet(
                    title: "Focus on the Mystery, Not Just Words",
                    text: "The vocal prayers (Hail Marys) are like a peaceful rhythm or background melody. Your heart's attention should rest gently on the scene of Christ's life."
                )
                
                adviceBullet(
                    title: "What if my mind wanders?",
                    text: "Distractions are normal. Do not become discouraged or restart the decade. When you notice your mind has drifted, simply bring your thoughts back to Jesus and Mary with peace."
                )
                
                adviceBullet(
                    title: "Start with one decade if needed",
                    text: "If 5 decades feel long, begin by praying one decade a day with your morning or evening prayers. Quality of devotion matters far more than speed."
                )
            }
            .padding(AppTheme.Spacing.medium)
            .background(Color.secondary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
        }
    }
    
    // MARK: - Components
    
    private func stepCard(number: String, title: String, prayer: String, explanation: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(liturgicalColor.swiftUIColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                Text(number)
                    .font(.scaled(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(liturgicalColor.uiAccentColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title.uppercased())
                    .font(.scaled(size: 11, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(liturgicalColor.uiAccentColor)
                
                Text(prayer)
                    .font(.scaled(size: 16, weight: .bold, design: .serif))
                    .foregroundStyle(Color.primary)
                
                Text(explanation)
                    .font(.scaled(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(Color.secondary)
                    .lineSpacing(4)
                    .padding(.top, 2)
            }
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(AppTheme.Colors.cardBorder, lineWidth: 1)
        )
    }
    
    private func mysteryScheduleRow(day: String, mystery: String, focus: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(day)
                    .font(.scaled(size: 12, weight: .bold))
                    .foregroundStyle(liturgicalColor.uiAccentColor)
                Spacer()
                Text(mystery)
                    .font(.scaled(size: 14, weight: .bold, design: .serif))
                    .foregroundStyle(Color.primary)
            }
            Text(focus)
                .font(.scaled(size: 12, weight: .regular, design: .serif).italic())
                .foregroundStyle(Color.secondary)
        }
        .padding(AppTheme.Spacing.small)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
    }
    
    private func adviceBullet(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.scaled(size: 14, weight: .bold, design: .serif))
                .foregroundStyle(Color.primary)
            Text(text)
                .font(.scaled(size: 13, weight: .regular, design: .serif))
                .foregroundStyle(Color.secondary)
                .lineSpacing(3)
        }
        .padding(.vertical, 2)
    }
}
