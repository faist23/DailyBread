//
//  AudioMiniPlayerBar.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// A floating, contemplative mini audio player bar displayed when readings are being read aloud.
///
/// Provides quick access to play/pause, next/previous reading, playback speed, and dismiss.
public struct AudioMiniPlayerBar: View {
    
    public var liturgicalColor: LiturgicalColor = .green
    @State private var player = AudioReadingPlayer.shared
    
    public init(liturgicalColor: LiturgicalColor = .green) {
        self.liturgicalColor = liturgicalColor
    }
    
    public var body: some View {
        if let reading = player.currentReading, player.isPlaying || player.isPaused {
            HStack(spacing: AppTheme.Spacing.compact) {
                // Sacred Flame / Headphone Icon
                ZStack {
                    Circle()
                        .fill(liturgicalColor.swiftUIColor.opacity(0.14))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: player.isPlaying ? "waveform" : "headphones")
                        .font(.scaled(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.solemnGold)
                        .symbolEffect(.variableColor.iterative, isActive: player.isPlaying)
                }
                
                // Reading Title & Counter
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(reading.type.shortName): \(reading.citation.displayReference)")
                        .font(.scaled(size: 13, weight: .bold, design: .serif))
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text("Reading \(player.currentReadingIndex + 1) of \(player.activeReadings.count)")
                            .font(.scaled(size: 11, weight: .medium))
                            .foregroundStyle(Color.secondary)
                        
                        Text("•")
                            .font(.scaled(size: 9))
                            .foregroundStyle(Color.secondary.opacity(0.6))
                        
                        // Speed Cycling Button
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                player.cycleSpeed()
                            }
                        } label: {
                            Text(player.speed.label)
                                .font(.scaled(size: 11, weight: .bold))
                                .foregroundStyle(liturgicalColor.uiAccentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(liturgicalColor.swiftUIColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer(minLength: 4)
                
                // Transport Controls
                HStack(spacing: AppTheme.Spacing.small) {
                    // Previous Reading
                    Button {
                        player.skipPrevious()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.scaled(size: 14))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .disabled(player.currentReadingIndex == 0)
                    .opacity(player.currentReadingIndex == 0 ? 0.35 : 1.0)
                    
                    // Play / Pause Toggle
                    Button {
                        if player.isPlaying {
                            player.pause()
                        } else {
                            player.resume()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(liturgicalColor.uiAccentColor)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.scaled(size: 14, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // Next Reading
                    Button {
                        player.skipNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.scaled(size: 14))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .disabled(player.currentReadingIndex + 1 >= player.activeReadings.count)
                    .opacity(player.currentReadingIndex + 1 >= player.activeReadings.count ? 0.35 : 1.0)
                    
                    // Close / Stop Button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            player.stop()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.scaled(size: 12, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                            .frame(width: 26, height: 26)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xlarge)
                    .fill(AppTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xlarge)
                            .stroke(liturgicalColor.swiftUIColor.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
            )
            .padding(.horizontal, AppTheme.Spacing.medium)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
