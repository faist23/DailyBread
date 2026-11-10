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

/// A human-friendly representation of an available text-to-speech voice option.
public struct VoiceOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let localeName: String
    public let qualityDescription: String
    
    public var displayName: String {
        "\(name) • \(localeName) (\(qualityDescription))"
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
    
    /// User-selected speech voice identifier.
    public var selectedVoiceIdentifier: String {
        get {
            UserDefaults.standard.string(forKey: "selectedAudioVoiceId") ?? defaultVoiceIdentifier
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "selectedAudioVoiceId")
            if isPlaying {
                synthesizer.stopSpeaking(at: .immediate)
                speakCurrentReading()
            }
        }
    }
    
    // MARK: - Excluded Legacy 1980s Novelty Voices
    
    private static let excludedVoiceNames: Set<String> = [
        "albert", "bad news", "bahh", "bells", "boing", "bubbles", "cellos",
        "deranged", "fred", "good news", "hysterical", "junior", "kathy",
        "organ", "princess", "ralph", "trinoids", "whisper", "zarvox", "wobble",
        "eddy", "flo", "grandma", "grandpa", "reed", "rocko", "sandy", "shelley",
        "jester", "superstar"
    ]
    
    /// Filtered list of natural, human-sounding English voices available on the user's device.
    public var availableVoices: [VoiceOption] {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let english = all.filter { v in
            v.language.starts(with: "en") &&
            !Self.excludedVoiceNames.contains(v.name.lowercased()) &&
            !v.identifier.contains("eloquence")
        }
        
        var seenKeys = Set<String>()
        var options: [VoiceOption] = []
        
        let sorted = english.sorted {
            if $0.quality.rawValue != $1.quality.rawValue {
                return $0.quality.rawValue > $1.quality.rawValue
            }
            return $0.name < $1.name
        }
        
        for v in sorted {
            let key = "\(v.name)_\(v.language)"
            if !seenKeys.contains(key) {
                seenKeys.insert(key)
                let region: String
                switch v.language {
                case "en-US": region = "American"
                case "en-GB": region = "British"
                case "en-IE": region = "Irish"
                case "en-AU": region = "Australian"
                case "en-IN": region = "Indian"
                case "en-ZA": region = "South African"
                default: region = v.language
                }
                
                let quality: String
                if v.identifier.contains("natural") || v.identifier.contains("siri") {
                    quality = "Neural / Siri"
                } else if v.quality == .premium {
                    quality = "Premium"
                } else if v.quality == .enhanced {
                    quality = "Enhanced"
                } else {
                    quality = "Natural"
                }
                
                let displayName = v.name == "Voice 4" ? "Siri (Voice 4)" : v.name
                
                options.append(VoiceOption(
                    id: v.identifier,
                    name: displayName,
                    localeName: region,
                    qualityDescription: quality
                ))
            }
        }
        return options
    }
    
    /// Default natural voice (prefers Siri Natural, Daniel, Samantha, Ava, Oliver, or Serena).
    public var defaultVoiceIdentifier: String {
        let options = availableVoices
        if let siri = options.first(where: { $0.id.contains("natural") || $0.id.contains("siri") }) {
            return siri.id
        }
        if let daniel = options.first(where: { $0.name.localizedCaseInsensitiveContains("daniel") }) {
            return daniel.id
        }
        if let samantha = options.first(where: { $0.name.localizedCaseInsensitiveContains("samantha") }) {
            return samantha.id
        }
        if let ava = options.first(where: { $0.name.localizedCaseInsensitiveContains("ava") }) {
            return ava.id
        }
        if let serena = options.first(where: { $0.name.localizedCaseInsensitiveContains("serena") }) {
            return serena.id
        }
        if let oliver = options.first(where: { $0.name.localizedCaseInsensitiveContains("oliver") }) {
            return oliver.id
        }
        if let moira = options.first(where: { $0.name.localizedCaseInsensitiveContains("moira") }) {
            return moira.id
        }
        return options.first?.id ?? ""
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
    
    /// Selects the chosen or highest quality natural English voice available on the user's device.
    public func selectNaturalVoice() -> AVSpeechSynthesisVoice? {
        let voiceId = selectedVoiceIdentifier
        if !voiceId.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            return voice
        }
        
        let defId = defaultVoiceIdentifier
        if !defId.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: defId) {
            return voice
        }
        
        let naturalOptions = availableVoices
        if let first = naturalOptions.first, let voice = AVSpeechSynthesisVoice(identifier: first.id) {
            return voice
        }
        
        return AVSpeechSynthesisVoice(language: "en-US")
    }
    
    /// Auditions a specific voice by reciting a brief liturgical acclamation.
    public func audition(voiceId: String) {
        stop()
        activateAudioSession()
        
        let voice = AVSpeechSynthesisVoice(identifier: voiceId) ?? selectNaturalVoice()
        
        let utterance = AVSpeechUtterance(string: "The Word of the Lord. Thanks be to God.")
        utterance.rate = speed.rawValue
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.voice = voice
        
        synthesizer.speak(utterance)
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
