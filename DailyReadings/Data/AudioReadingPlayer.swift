//
//  AudioReadingPlayer.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import AVFoundation
import Foundation
import MediaPlayer
import SwiftUI

/// Speed options for reverent liturgical audio reading.
public enum PlaybackSpeed: Float, CaseIterable, Identifiable, Sendable {
    case reverent = 0.44  // ~0.85x contemplative pace
    case normal = 0.49    // ~1.0x balanced pace
    case brisk = 0.54     // ~1.15x attentive pace
    
    public var id: Float { rawValue }
    
    public var label: String {
        switch self {
        case .reverent: return "0.8x"
        case .normal: return "1.0x"
        case .brisk: return "1.2x"
        }
    }
    
    public var next: PlaybackSpeed {
        switch self {
        case .reverent: return .normal
        case .normal: return .brisk
        case .brisk: return .reverent
        }
    }
}

/// Service managing reverent text-to-speech recitation of Catholic daily Mass readings.
///
/// Features:
/// - Background audio playback using `AVAudioSession` (.playback / .spokenAudio).
/// - Lock screen & Control Center Now Playing integration (`MPNowPlayingInfoCenter`, `MPRemoteCommandCenter`).
/// - Liturgical acclamations ("The Word of the Lord", "Thanks be to God").
/// - Seamless sequential advancement across all Mass readings with contemplative delays.
@MainActor
@Observable
public final class AudioReadingPlayer: NSObject, AVSpeechSynthesizerDelegate {
    
    public static let shared = AudioReadingPlayer()
    
    // MARK: - Observable State
    
    public private(set) var isPlaying: Bool = false
    public private(set) var isPaused: Bool = false
    public private(set) var currentReadingIndex: Int = 0
    public private(set) var currentReading: Reading?
    public private(set) var activeReadings: [Reading] = []
    public private(set) var liturgicalTitle: String = ""
    public var speed: PlaybackSpeed = .normal {
        didSet {
            UserDefaults.standard.set(speed.rawValue, forKey: "audioReadingSpeed")
        }
    }
    
    // MARK: - Private Properties
    
    private let synthesizer = AVSpeechSynthesizer()
    private var isInterrupted: Bool = false
    private var remoteCommandsConfigured: Bool = false
    
    // MARK: - Initialization
    
    override private init() {
        super.init()
        synthesizer.delegate = self
        
        let savedSpeed = UserDefaults.standard.float(forKey: "audioReadingSpeed")
        if savedSpeed > 0, let matched = PlaybackSpeed.allCases.first(where: { abs($0.rawValue - savedSpeed) < 0.01 }) {
            self.speed = matched
        }
        
        setupAudioSession()
        setupNotifications()
    }
    
    // MARK: - Audio Session & Remote Controls
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }
    
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    private func setupRemoteCommands() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true
        
        let center = MPRemoteCommandCenter.shared()
        
        center.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.resume() }
            return .success
        }
        
        center.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.pause() }
            return .success
        }
        
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in
                if self.isPlaying {
                    self.pause()
                } else if self.isPaused {
                    self.resume()
                }
            }
            return .success
        }
        
        center.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.skipNext() }
            return .success
        }
        
        center.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.skipPrevious() }
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let reading = currentReading else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = "\(reading.type.displayTitle): \(reading.citation.displayReference)"
        info[MPMediaItemPropertyArtist] = "DailyReadings"
        info[MPMediaItemPropertyAlbumTitle] = liturgicalTitle
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            
            switch type {
            case .began:
                self.isInterrupted = true
                self.pause()
            case .ended:
                self.isInterrupted = false
                if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        self.resume()
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Playback APIs
    
    /// Starts recitation of the provided readings.
    public func start(readings: [Reading], liturgicalTitle: String, startIndex: Int = 0) {
        guard !readings.isEmpty else { return }
        
        stop()
        
        self.activeReadings = readings
        self.liturgicalTitle = liturgicalTitle
        self.currentReadingIndex = min(max(0, startIndex), readings.count - 1)
        self.currentReading = readings[self.currentReadingIndex]
        
        activateAudioSession()
        setupRemoteCommands()
        
        speakCurrentReading()
    }
    
    /// Plays or resumes recitation.
    public func play(readings: [Reading], liturgicalTitle: String) {
        if isPaused && activeReadings == readings {
            resume()
        } else {
            start(readings: readings, liturgicalTitle: liturgicalTitle, startIndex: 0)
        }
    }
    
    /// Starts recitation directly at a specific reading.
    public func playSpecificReading(_ reading: Reading, in readings: [Reading], liturgicalTitle: String) {
        let index = readings.firstIndex(where: { $0.id == reading.id }) ?? 0
        start(readings: readings, liturgicalTitle: liturgicalTitle, startIndex: index)
    }
    
    /// Pauses current speech playback.
    public func pause() {
        guard isPlaying else { return }
        synthesizer.pauseSpeaking(at: .immediate)
        isPlaying = false
        isPaused = true
        updateNowPlayingInfo()
    }
    
    /// Resumes speech playback.
    public func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
        isPlaying = true
        isPaused = false
        updateNowPlayingInfo()
    }
    
    /// Stops speech playback completely and resets.
    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isPlaying = false
        isPaused = false
        currentReading = nil
        updateNowPlayingInfo()
        deactivateAudioSession()
    }
    
    /// Skips to the next reading in the liturgy.
    public func skipNext() {
        guard !activeReadings.isEmpty else { return }
        if currentReadingIndex + 1 < activeReadings.count {
            currentReadingIndex += 1
            currentReading = activeReadings[currentReadingIndex]
            synthesizer.stopSpeaking(at: .immediate)
            speakCurrentReading()
        } else {
            stop()
        }
    }
    
    /// Skips to the previous reading in the liturgy.
    public func skipPrevious() {
        guard !activeReadings.isEmpty else { return }
        if currentReadingIndex > 0 {
            currentReadingIndex -= 1
            currentReading = activeReadings[currentReadingIndex]
            synthesizer.stopSpeaking(at: .immediate)
            speakCurrentReading()
        } else {
            synthesizer.stopSpeaking(at: .immediate)
            speakCurrentReading()
        }
    }
    
    /// Changes playback speed. If currently playing, smoothly restarts the reading at the new speed.
    public func cycleSpeed() {
        speed = speed.next
        if isPlaying {
            synthesizer.stopSpeaking(at: .immediate)
            speakCurrentReading()
        }
    }
    
    // MARK: - Speech Synthesis
    
    private func speakCurrentReading() {
        guard currentReadingIndex < activeReadings.count else {
            stop()
            return
        }
        
        let reading = activeReadings[currentReadingIndex]
        self.currentReading = reading
        self.isPlaying = true
        self.isPaused = false
        
        let speechText = prepareLiturgicalSpeechText(for: reading)
        let utterance = AVSpeechUtterance(string: speechText)
        
        utterance.rate = speed.rawValue
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.postUtteranceDelay = 1.2
        utterance.voice = selectNaturalVoice()
        
        updateNowPlayingInfo()
        synthesizer.speak(utterance)
    }
    
    /// Selects the highest quality natural English voice available on the user's device.
    private func selectNaturalVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.starts(with: "en-") && ($0.language == "en-US" || $0.language == "en-GB")
        }
        
        if let premium = voices.first(where: { $0.quality == .premium }) {
            return premium
        }
        if let enhanced = voices.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        
        return AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice(language: Locale.current.identifier)
    }
    
    /// Formats scripture text with liturgical introductory announcements and acclamations.
    private func prepareLiturgicalSpeechText(for reading: Reading) -> String {
        var parts: [String] = []
        
        switch reading.type {
        case .firstReading:
            parts.append("First Reading. A reading from \(reading.citation.displayReference).")
            parts.append(cleanScriptureForSpeech(reading.text))
            parts.append("The Word of the Lord. Thanks be to God.")
            
        case .secondReading:
            parts.append("Second Reading. A reading from \(reading.citation.displayReference).")
            parts.append(cleanScriptureForSpeech(reading.text))
            parts.append("The Word of the Lord. Thanks be to God.")
            
        case .responsorialPsalm:
            parts.append("Responsorial Psalm. From \(reading.citation.displayReference).")
            if let response = reading.response, !response.isEmpty {
                parts.append("Response: \(cleanScriptureForSpeech(response)).")
            }
            parts.append(cleanScriptureForSpeech(reading.text))
            if let response = reading.response, !response.isEmpty {
                parts.append("Response: \(cleanScriptureForSpeech(response)).")
            }
            
        case .gospel:
            parts.append("The Holy Gospel according to \(reading.citation.book).")
            parts.append(cleanScriptureForSpeech(reading.text))
            parts.append("The Gospel of the Lord. Praise to you, Lord Jesus Christ.")
            
        case .gospelAcclamation:
            parts.append("Gospel Acclamation.")
            parts.append(cleanScriptureForSpeech(reading.text))
            
        case .sequence:
            parts.append("Sequence.")
            parts.append(cleanScriptureForSpeech(reading.text))
        }
        
        return parts.joined(separator: "\n\n")
    }
    
    /// Cleans verse numbering, annotations, or symbols for natural speech.
    private func cleanScriptureForSpeech(_ text: String) -> String {
        var cleaned = text
            .replacingOccurrences(of: "\\[\\d+\\]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\(\\w\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "℟.", with: "Response:")
            .replacingOccurrences(of: "℣.", with: "Verse:")
            .replacingOccurrences(of: "\n+", with: ". ", options: .regularExpression)
            .replacingOccurrences(of: "\\.{2,}", with: ".", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = true
            self.isPaused = false
            self.updateNowPlayingInfo()
        }
    }
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            if self.currentReadingIndex + 1 < self.activeReadings.count {
                self.currentReadingIndex += 1
                self.speakCurrentReading()
            } else {
                self.stop()
            }
        }
    }
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = false
            self.isPaused = true
            self.updateNowPlayingInfo()
        }
    }
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = true
            self.isPaused = false
            self.updateNowPlayingInfo()
        }
    }
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPlaying = false
            self.isPaused = false
        }
    }
}
