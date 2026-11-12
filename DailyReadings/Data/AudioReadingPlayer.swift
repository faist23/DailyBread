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
    public let isHighQuality: Bool
    
    public var displayName: String {
        if isHighQuality {
            return "✨ \(name) (\(localeName)) • \(qualityDescription)"
        }
        return "\(name) (\(localeName))"
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
public final class AudioReadingPlayer: NSObject, @preconcurrency AVSpeechSynthesizerDelegate {
    
    public static let shared = AudioReadingPlayer()
    
    // MARK: - Observable State
    
    public private(set) var isPlaying: Bool = false
    public private(set) var isPaused: Bool = false
    public private(set) var currentReadingIndex: Int = 0
    public private(set) var currentReading: Reading?
    public private(set) var activeReadings: [Reading] = []
    public private(set) var liturgicalTitle: String = ""
    public private(set) var currentLiturgicalColor: LiturgicalColor?
    private var cachedArtwork: (key: String, image: UIImage)?
    public var speed: PlaybackSpeed = .normal {
        didSet {
            UserDefaults.standard.set(speed.rawValue, forKey: "audioReadingSpeed")
        }
    }
    
    /// User-selected speech voice identifier.
    public var selectedVoiceIdentifier: String {
        didSet {
            UserDefaults.standard.set(selectedVoiceIdentifier, forKey: "selectedAudioVoiceId")
            if isPlaying && !isAuditioning {
                synthesizer.stopSpeaking(at: .immediate)
                speakCurrentChunk()
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
    
    @ObservationIgnored
    private var _cachedAvailableVoices: [VoiceOption]?
    
    /// Filtered list of natural English voices available on the user's device (computed once and cached).
    public var availableVoices: [VoiceOption] {
        if let cached = _cachedAvailableVoices {
            return cached
        }
        let voices = Self.loadAvailableVoices()
        _cachedAvailableVoices = voices
        return voices
    }

    public static func loadAvailableVoices() -> [VoiceOption] {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let english = all.filter { v in
            v.language.starts(with: "en") &&
            !Self.excludedVoiceNames.contains(v.name.lowercased()) &&
            !v.identifier.contains("eloquence") &&
            !v.identifier.contains("siri") && // Siri voices cannot be spoken by AVSpeechSynthesizer in 3rd party apps
            !v.voiceTraits.contains(.isNoveltyVoice)
        }
        
        let sorted = english.sorted { (v1, v2) -> Bool in
            if v1.quality.rawValue != v2.quality.rawValue {
                return v1.quality.rawValue > v2.quality.rawValue
            }
            let p1 = Self.voicePriority(v1.name)
            let p2 = Self.voicePriority(v2.name)
            if p1 != p2 {
                return p1 < p2
            }
            return v1.name < v2.name
        }
        
        var seenKeys = Set<String>()
        var options: [VoiceOption] = []
        
        for v in sorted {
            let key = "\(v.name.lowercased())_\(v.language)"
            if !seenKeys.contains(key) {
                seenKeys.insert(key)
                let region: String
                switch v.language {
                case "en-US": region = "US"
                case "en-GB": region = "UK"
                case "en-IE": region = "Ireland"
                case "en-AU": region = "Australia"
                case "en-IN": region = "India"
                case "en-ZA": region = "South Africa"
                default: region = v.language
                }
                
                let isHighQuality = (v.quality == .premium || v.quality == .enhanced)
                let qualityDesc: String
                if v.quality == .premium {
                    qualityDesc = "Premium Studio"
                } else if v.quality == .enhanced {
                    qualityDesc = "Enhanced"
                } else {
                    qualityDesc = "Standard"
                }
                
                options.append(VoiceOption(
                    id: v.identifier,
                    name: v.name,
                    localeName: region,
                    qualityDescription: qualityDesc,
                    isHighQuality: isHighQuality
                ))
            }
        }
        return options
    }
    
    private static func voicePriority(_ name: String) -> Int {
        let lower = name.lowercased()
        if lower.contains("daniel") { return 1 }
        if lower.contains("samantha") { return 2 }
        if lower.contains("ava") { return 3 }
        if lower.contains("moira") { return 4 }
        if lower.contains("karen") { return 5 }
        if lower.contains("oliver") { return 6 }
        if lower.contains("serena") { return 7 }
        return 10
    }
    
    /// Determines the best natural voice identifier available on the device.
    public static func determineDefaultVoiceIdentifier() -> String {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let english = all.filter { v in
            v.language.starts(with: "en") &&
            !Self.excludedVoiceNames.contains(v.name.lowercased()) &&
            !v.identifier.contains("eloquence") &&
            !v.identifier.contains("siri") &&
            !v.voiceTraits.contains(.isNoveltyVoice)
        }
        
        // 1. Any installed Premium or Enhanced voice
        if let highQuality = english.first(where: { $0.quality == .premium || $0.quality == .enhanced }) {
            return highQuality.identifier
        }
        // 2. Daniel (British lectionary cadence)
        if let daniel = english.first(where: { $0.name.localizedCaseInsensitiveContains("daniel") }) {
            return daniel.identifier
        }
        // 3. Samantha (American clean tone)
        if let samantha = english.first(where: { $0.name.localizedCaseInsensitiveContains("samantha") }) {
            return samantha.identifier
        }
        // 4. Ava or Moira
        if let other = english.first(where: { $0.name.localizedCaseInsensitiveContains("ava") || $0.name.localizedCaseInsensitiveContains("moira") }) {
            return other.identifier
        }
        return english.first?.identifier ?? ""
    }
    
    // MARK: - Private Properties
    
    private let synthesizer = AVSpeechSynthesizer()
    private var isInterrupted: Bool = false
    private var isAuditioning: Bool = false
    private var remoteCommandsConfigured: Bool = false
    private var currentReadingUtterance: AVSpeechUtterance?
    private var currentAuditionUtterance: AVSpeechUtterance?
    private var currentStandaloneUtterance: AVSpeechUtterance?

    /// The current reading split into short passages, each spoken as its own utterance, so a change
    /// of speed or voice resumes from the passage being read instead of the top of the reading.
    private var currentChunks: [String] = []
    private var currentChunkIndex: Int = 0

    /// Identifier of the prayer or Rosary bead now being recited outside the Mass readings, if any.
    /// Views compare it with the identifier `speakStandalone` gave them to know whether they are speaking.
    public private(set) var standaloneSpeechID: UUID?
    
    // MARK: - Initialization
    
    override private init() {
        let savedVoice = UserDefaults.standard.string(forKey: "selectedAudioVoiceId") ?? ""
        if !savedVoice.isEmpty, AVSpeechSynthesisVoice(identifier: savedVoice) != nil {
            self.selectedVoiceIdentifier = savedVoice
        } else {
            self.selectedVoiceIdentifier = Self.determineDefaultVoiceIdentifier()
        }
        
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
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    public func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }
    
    public func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    private func setupRemoteCommands() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
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
        
        // Render or fetch cached liturgical illuminated artwork for Lock Screen
        let activeColor = currentLiturgicalColor ?? LiturgicalCalendar.shared.liturgicalDay(for: Date()).color
        let cacheKey = "\(reading.id.uuidString)_\(activeColor.rawValue)_\(liturgicalTitle)"
        
        let artworkImage: UIImage
        if let cached = cachedArtwork, cached.key == cacheKey {
            artworkImage = cached.image
        } else {
            artworkImage = LiturgicalArtworkGenerator.generateArtwork(
                reading: reading,
                liturgicalTitle: liturgicalTitle,
                color: activeColor
            )
            cachedArtwork = (key: cacheKey, image: artworkImage)
        }
        
        info[MPMediaItemPropertyArtwork] = LiturgicalArtworkGenerator.makeMediaItemArtwork(from: artworkImage)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let optionValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            Task { @MainActor [weak self] in
                guard let self,
                      let typeValue,
                      let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
                
                switch type {
                case .began:
                    self.isInterrupted = true
                    self.pause()
                case .ended:
                    self.isInterrupted = false
                    if let optionValue {
                        let options = AVAudioSession.InterruptionOptions(rawValue: optionValue)
                        if options.contains(.shouldResume) {
                            self.resume()
                        }
                    }
                @unknown default:
                    break
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor [weak self] in
                guard let self,
                      let reasonValue,
                      let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
                
                if reason == .oldDeviceUnavailable {
                    self.pause()
                }
            }
        }
    }
    
    // MARK: - Playback APIs
    
    /// Starts recitation of the provided readings.
    public func start(
        readings: [Reading],
        liturgicalTitle: String,
        startIndex: Int = 0,
        liturgicalColor: LiturgicalColor? = nil
    ) {
        guard !readings.isEmpty else { return }
        
        stop(deactivateSession: false)
        
        self.activeReadings = readings
        self.liturgicalTitle = liturgicalTitle
        self.currentLiturgicalColor = liturgicalColor ?? LiturgicalCalendar.shared.liturgicalDay(for: Date()).color
        self.currentReadingIndex = min(max(0, startIndex), readings.count - 1)
        self.currentReading = readings[self.currentReadingIndex]
        
        activateAudioSession()
        setupRemoteCommands()
        
        speakCurrentReading()
    }
    
    /// Plays or resumes recitation.
    public func play(readings: [Reading], liturgicalTitle: String, liturgicalColor: LiturgicalColor? = nil) {
        if isPaused && activeReadings == readings {
            resume()
        } else {
            start(readings: readings, liturgicalTitle: liturgicalTitle, startIndex: 0, liturgicalColor: liturgicalColor)
        }
    }
    
    /// Starts recitation directly at a specific reading.
    public func playSpecificReading(
        _ reading: Reading,
        in readings: [Reading],
        liturgicalTitle: String,
        liturgicalColor: LiturgicalColor? = nil
    ) {
        let index = readings.firstIndex(where: { $0.id == reading.id }) ?? 0
        start(readings: readings, liturgicalTitle: liturgicalTitle, startIndex: index, liturgicalColor: liturgicalColor)
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
        activateAudioSession()
        synthesizer.continueSpeaking()
        isPlaying = true
        isPaused = false
        updateNowPlayingInfo()
    }
    
    /// Stops speech playback completely and resets.
    public func stop(deactivateSession: Bool = true) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        currentReadingUtterance = nil
        currentAuditionUtterance = nil
        currentStandaloneUtterance = nil
        standaloneSpeechID = nil
        isAuditioning = false
        isPlaying = false
        isPaused = false
        currentReading = nil
        updateNowPlayingInfo()
        if deactivateSession {
            deactivateAudioSession()
        }
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
            speakCurrentChunk()
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
        
        currentChunks = liturgicalSpeechParts(for: reading).flatMap(Self.speechChunks)
        currentChunkIndex = 0
        speakCurrentChunk()
    }

    /// Speaks the current passage of the current reading.
    private func speakCurrentChunk() {
        guard currentChunkIndex < currentChunks.count else {
            stop()
            return
        }
        let isLastChunk = currentChunkIndex == currentChunks.count - 1
        let utterance = AVSpeechUtterance(string: currentChunks[currentChunkIndex])

        utterance.rate = speed.rawValue
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        // A short breath between passages; a contemplative pause after the reading.
        utterance.postUtteranceDelay = isLastChunk ? 1.2 : 0.15
        utterance.voice = selectNaturalVoice()

        self.isPlaying = true
        self.isPaused = false
        self.currentReadingUtterance = utterance
        self.currentAuditionUtterance = nil

        updateNowPlayingInfo()
        synthesizer.speak(utterance)
    }

    /// Splits text into passages of a few sentences each.
    static func speechChunks(_ text: String) -> [String] {
        let limit = 320
        guard text.count > limit else { return text.isEmpty ? [] : [text] }
        var chunks: [String] = []
        var current = ""
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { sentence, _, _, _ in
            guard let sentence else { return }
            if !current.isEmpty, current.count + sentence.count > limit {
                chunks.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = ""
            }
            current += sentence
        }
        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            chunks.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return chunks
    }

    // MARK: - Standalone Recitation (prayers, Rosary beads)

    /// Recites a prayer through the shared synthesizer and audio session, stopping any Mass reading
    /// in progress. The session is released when the prayer ends.
    ///
    /// - Returns: An identifier to compare with `standaloneSpeechID` and to pass to `stopStandalone`.
    @discardableResult
    public func speakStandalone(_ text: String, rate: Float, voice: AVSpeechSynthesisVoice? = nil) -> UUID {
        stop(deactivateSession: false)
        activateAudioSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.voice = voice ?? selectNaturalVoice()

        let id = UUID()
        currentStandaloneUtterance = utterance
        standaloneSpeechID = id
        synthesizer.speak(utterance)
        return id
    }

    /// Stops the standalone recitation with this identifier. Does nothing if something else is speaking.
    public func stopStandalone(_ id: UUID?) {
        guard let id, id == standaloneSpeechID else { return }
        stop()
    }
    
    /// Selects the chosen or highest quality natural English voice available on the user's device.
    public func selectNaturalVoice() -> AVSpeechSynthesisVoice? {
        let idToUse: String = {
            if let saved = UserDefaults.standard.string(forKey: "selectedAudioVoiceId"), !saved.isEmpty {
                return saved
            }
            return selectedVoiceIdentifier
        }()
        
        if !idToUse.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: idToUse) {
            return voice
        }
        
        let defId = Self.determineDefaultVoiceIdentifier()
        if !defId.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: defId) {
            return voice
        }
        
        return AVSpeechSynthesisVoice(language: "en-US")
    }
    
    /// Auditions a specific voice by introducing itself and reciting a liturgical acclamation.
    public func audition(voiceId: String) {
        // A preview ends whatever is being read; the listener restarts the reading with the new voice.
        stop(deactivateSession: false)
        isAuditioning = true

        if !voiceId.isEmpty {
            self.selectedVoiceIdentifier = voiceId
        }
        activateAudioSession()
        
        let targetId = voiceId.isEmpty ? selectedVoiceIdentifier : voiceId
        let voice = AVSpeechSynthesisVoice(identifier: targetId) ?? selectNaturalVoice()
        let voiceName = voice?.name ?? "Lector"
        
        let utterance = AVSpeechUtterance(string: "Hello, this is \(voiceName). The Word of the Lord. Thanks be to God.")
        utterance.rate = 0.48
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.voice = voice
        
        self.currentAuditionUtterance = utterance
        self.currentReadingUtterance = nil
        
        synthesizer.speak(utterance)
    }
    
    /// The reading as it is proclaimed: announcement, text, acclamation. One element per part.
    private func liturgicalSpeechParts(for reading: Reading) -> [String] {
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
            let response = (reading.response?.isEmpty == false ? reading.response : nil)
                ?? reading.effectivePsalmResponse
            if let response, !response.isEmpty {
                parts.append("Response: \(cleanScriptureForSpeech(response)).")
            }
            
            let stanzas = reading.text.components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            if stanzas.count > 1 {
                for stanza in stanzas {
                    parts.append(cleanScriptureForSpeech(stanza))
                    if let response, !response.isEmpty {
                        parts.append("Response: \(cleanScriptureForSpeech(response)).")
                    }
                }
            } else {
                parts.append(cleanScriptureForSpeech(reading.text))
                if let response, !response.isEmpty {
                    parts.append("Response: \(cleanScriptureForSpeech(response)).")
                }
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
        
        return parts.filter { !$0.isEmpty }
    }
    
    /// Phonetic pronunciations for biblical proper nouns that speech synthesizers often mispronounce.
    private static let phoneticSubstitutions: [(pattern: String, replacement: String)] = [
        ("\\bThessalonians\\b", "Thess-uh-lonians"),
        ("\\bColossians\\b", "Cuh-losh-uns"),
        ("\\bPhilemon\\b", "Figh-lee-mun"),
        ("\\bEcclesiastes\\b", "Eccles-ee-as-tees"),
        ("\\bDeuteronomy\\b", "Due-ter-on-uh-mee"),
        ("\\bHabakkuk\\b", "Hab-uh-kuk"),
        ("\\bZephaniah\\b", "Zef-uh-nigh-uh"),
        ("\\bZechariah\\b", "Zek-uh-righ-uh"),
        ("\\bNebuchadnezzar\\b", "Neb-yoo-kud-nez-er"),
        ("\\bEphesians\\b", "Ee-fee-zhuns"),
        ("\\bPhilippians\\b", "Fih-lip-ee-uns"),
        ("\\bCorinthians\\b", "Cuh-rin-thee-uns"),
        ("\\bGethsemane\\b", "Geth-sem-uh-nee"),
        ("\\bGolgotha\\b", "Gol-guh-thuh"),
        ("\\bCaiaphas\\b", "Kigh-uh-fus"),
        ("\\bBarabbas\\b", "Buh-rab-us"),
        ("\\bBethlehem\\b", "Beth-luh-hem"),
        ("\\bNazareth\\b", "Naz-er-eth")
    ]
    
    /// Cleans verse numbering, annotations, or symbols for natural, reverent speech.
    private func cleanScriptureForSpeech(_ text: String) -> String {
        var cleaned = text
            .replacingOccurrences(of: "\\[\\d+\\]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\(\\w\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "℟.", with: "Response, ")
            .replacingOccurrences(of: "℣.", with: "Verse, ")
            .replacingOccurrences(of: "([.,!?;:])\\s*\\n+", with: "$1 ", options: .regularExpression)
            .replacingOccurrences(of: "\\n+", with: ", ", options: .regularExpression)
            .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        for (pattern, replacement) in Self.phoneticSubstitutions {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        return cleaned
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        guard utterance === self.currentReadingUtterance else { return }
        self.isPlaying = true
        self.isPaused = false
        self.updateNowPlayingInfo()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if utterance === self.currentAuditionUtterance {
            self.currentAuditionUtterance = nil
            self.isAuditioning = false
            self.deactivateAudioSession()
            return
        }
        if utterance === self.currentStandaloneUtterance {
            self.currentStandaloneUtterance = nil
            self.standaloneSpeechID = nil
            self.deactivateAudioSession()
            return
        }
        guard utterance === self.currentReadingUtterance else { return }
        self.currentReadingUtterance = nil

        if self.currentChunkIndex + 1 < self.currentChunks.count {
            self.currentChunkIndex += 1
            self.speakCurrentChunk()
        } else if self.currentReadingIndex + 1 < self.activeReadings.count {
            self.currentReadingIndex += 1
            self.speakCurrentReading()
        } else {
            self.stop()
        }
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        guard utterance === self.currentReadingUtterance else { return }
        self.isPlaying = false
        self.isPaused = true
        self.updateNowPlayingInfo()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        guard utterance === self.currentReadingUtterance else { return }
        self.isPlaying = true
        self.isPaused = false
        self.updateNowPlayingInfo()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        if utterance === self.currentAuditionUtterance {
            self.currentAuditionUtterance = nil
            self.isAuditioning = false
            return
        }
        if utterance === self.currentStandaloneUtterance {
            self.currentStandaloneUtterance = nil
            self.standaloneSpeechID = nil
            return
        }
        // An utterance replaced by a newer one (skip, speed or voice change) reports its cancel
        // after the new one has started. Only the current utterance may change playback state.
        guard utterance === self.currentReadingUtterance else { return }
        self.currentReadingUtterance = nil
        self.isPlaying = false
        self.isPaused = false
    }
}

// MARK: - Liturgical Lock Screen Artwork Generator

/// Generates illuminated, missal-inspired liturgical artwork for iOS Lock Screen & Now Playing controls.
public enum LiturgicalArtworkGenerator {
    
    private static func serifFont(size: CGFloat, weight: UIFont.Weight = .regular, italic: Bool = false) -> UIFont {
        var desc = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor.withDesign(.serif) ?? UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
        if italic, let italicDesc = desc.withSymbolicTraits(.traitItalic) {
            desc = italicDesc
        }
        return UIFont(descriptor: desc, size: size)
    }
    
    /// Creates an MPMediaItemArtwork with a non-isolated request handler.
    /// This prevents Swift Concurrency MainActor assertion crashes when MediaPlayer queries the artwork on a background thread.
    nonisolated public static func makeMediaItemArtwork(from image: UIImage) -> MPMediaItemArtwork {
        MPMediaItemArtwork(boundsSize: image.size) { _ in
            image
        }
    }
    
    /// Generates a high-resolution, missal-styled cover artwork for the Lock Screen media player.
    public static func generateArtwork(
        reading: Reading?,
        liturgicalTitle: String,
        color: LiturgicalColor,
        size: CGSize = CGSize(width: 600, height: 600)
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            let bounds = CGRect(origin: .zero, size: size)
            
            // 1. Background Gradient based on Liturgical Color
            let (topColor, bottomColor) = gradientColors(for: color)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [topColor.cgColor, bottomColor.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: size.width / 2, y: 0),
                    end: CGPoint(x: size.width / 2, y: size.height),
                    options: []
                )
            }
            
            // 2. Central Radiant Glow (subtle sacred aura)
            let auraCenter = CGPoint(x: size.width / 2, y: 195)
            let auraColors = [
                UIColor(red: 235 / 255, green: 195 / 255, blue: 85 / 255, alpha: 0.18).cgColor,
                UIColor.clear.cgColor
            ] as CFArray
            if let auraGradient = CGGradient(colorsSpace: colorSpace, colors: auraColors, locations: [0.0, 1.0]) {
                cgContext.drawRadialGradient(
                    auraGradient,
                    startCenter: auraCenter,
                    startRadius: 0,
                    endCenter: auraCenter,
                    endRadius: 160,
                    options: []
                )
            }
            
            // 3. Illuminated Double Gold Borders
            let goldColor = UIColor(red: 220 / 255, green: 180 / 255, blue: 75 / 255, alpha: 0.85)
            let innerGoldColor = UIColor(red: 220 / 255, green: 180 / 255, blue: 75 / 255, alpha: 0.40)
            
            // Outer Border
            let outerRect = bounds.insetBy(dx: 24, dy: 24)
            let outerPath = UIBezierPath(roundedRect: outerRect, cornerRadius: 14)
            outerPath.lineWidth = 1.5
            goldColor.setStroke()
            outerPath.stroke()
            
            // Inner Border
            let innerRect = bounds.insetBy(dx: 32, dy: 32)
            let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: 10)
            innerPath.lineWidth = 0.75
            innerGoldColor.setStroke()
            innerPath.stroke()
            
            // Corner Flourishes (small gold diamonds)
            let corners = [
                CGPoint(x: outerRect.minX + 8, y: outerRect.minY + 8),
                CGPoint(x: outerRect.maxX - 8, y: outerRect.minY + 8),
                CGPoint(x: outerRect.minX + 8, y: outerRect.maxY - 8),
                CGPoint(x: outerRect.maxX - 8, y: outerRect.maxY - 8)
            ]
            for corner in corners {
                drawDiamond(at: corner, size: 5, color: goldColor, in: cgContext)
            }
            
            // 4. Sacred Latin Cross Emblem
            drawLatinCross(center: auraCenter, color: goldColor, in: cgContext)
            
            // 5. Typography: App Header
            let headerStyle = NSMutableParagraphStyle()
            headerStyle.alignment = .center
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: serifFont(size: 14, weight: .bold),
                .foregroundColor: goldColor,
                .kern: 3.5,
                .paragraphStyle: headerStyle
            ]
            let headerText = "DAILY READINGS"
            headerText.draw(in: CGRect(x: 40, y: 56, width: size.width - 80, height: 24), withAttributes: headerAttrs)
            
            // 6. Typography: Reading Title & Citation
            let readingTypeStyle = NSMutableParagraphStyle()
            readingTypeStyle.alignment = .center
            let readingTypeAttrs: [NSAttributedString.Key: Any] = [
                .font: serifFont(size: 21, weight: .bold),
                .foregroundColor: UIColor.white,
                .kern: 1.5,
                .paragraphStyle: readingTypeStyle
            ]
            let typeTitle = reading?.type.displayTitle.uppercased() ?? "HOLY SCRIPTURE"
            typeTitle.draw(in: CGRect(x: 40, y: 300, width: size.width - 80, height: 28), withAttributes: readingTypeAttrs)
            
            // Citation
            let citationStyle = NSMutableParagraphStyle()
            citationStyle.alignment = .center
            let citationAttrs: [NSAttributedString.Key: Any] = [
                .font: serifFont(size: 19, weight: .medium, italic: true),
                .foregroundColor: goldColor,
                .paragraphStyle: citationStyle
            ]
            let citationText = reading?.citation.displayReference ?? "Catholic Lectionary"
            citationText.draw(in: CGRect(x: 40, y: 334, width: size.width - 80, height: 26), withAttributes: citationAttrs)
            
            // Decorative Divider Line
            let dividerY: CGFloat = 378
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: 160, y: dividerY))
            dividerPath.addLine(to: CGPoint(x: size.width - 160, y: dividerY))
            dividerPath.lineWidth = 0.5
            innerGoldColor.setStroke()
            dividerPath.stroke()
            drawDiamond(at: CGPoint(x: size.width / 2, y: dividerY), size: 4, color: goldColor, in: cgContext)
            
            // 7. Typography: Feast / Solemnity Title
            let titleStyle = NSMutableParagraphStyle()
            titleStyle.alignment = .center
            titleStyle.lineBreakMode = .byTruncatingTail
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: serifFont(size: 17, weight: .regular),
                .foregroundColor: UIColor(white: 0.92, alpha: 1.0),
                .paragraphStyle: titleStyle
            ]
            let displayTitle = liturgicalTitle.isEmpty ? "Catholic Daily Mass Readings" : liturgicalTitle
            displayTitle.draw(in: CGRect(x: 48, y: 400, width: size.width - 96, height: 50), withAttributes: titleAttrs)
            
            // 8. Liturgical Season / Color Tag
            let tagStyle = NSMutableParagraphStyle()
            tagStyle.alignment = .center
            let tagAttrs: [NSAttributedString.Key: Any] = [
                .font: serifFont(size: 13, weight: .semibold),
                .foregroundColor: UIColor(white: 0.75, alpha: 0.9),
                .paragraphStyle: tagStyle
            ]
            let colorName = color.displayName
            let tagText = "✦ Liturgical Color: \(colorName) ✦"
            tagText.draw(in: CGRect(x: 40, y: 518, width: size.width - 80, height: 20), withAttributes: tagAttrs)
        }
    }
    
    private static func gradientColors(for color: LiturgicalColor) -> (top: UIColor, bottom: UIColor) {
        switch color {
        case .green:
            return (
                top: UIColor(red: 22 / 255, green: 74 / 255, blue: 48 / 255, alpha: 1.0),
                bottom: UIColor(red: 10 / 255, green: 30 / 255, blue: 20 / 255, alpha: 1.0)
            )
        case .violet:
            return (
                top: UIColor(red: 68 / 255, green: 26 / 255, blue: 98 / 255, alpha: 1.0),
                bottom: UIColor(red: 26 / 255, green: 10 / 255, blue: 42 / 255, alpha: 1.0)
            )
        case .red:
            return (
                top: UIColor(red: 128 / 255, green: 24 / 255, blue: 28 / 255, alpha: 1.0),
                bottom: UIColor(red: 46 / 255, green: 8 / 255, blue: 14 / 255, alpha: 1.0)
            )
        case .rose:
            return (
                top: UIColor(red: 158 / 255, green: 82 / 255, blue: 108 / 255, alpha: 1.0),
                bottom: UIColor(red: 68 / 255, green: 30 / 255, blue: 48 / 255, alpha: 1.0)
            )
        case .white:
            // Solemn Midnight Charcoal & Luminous Gold
            return (
                top: UIColor(red: 40 / 255, green: 38 / 255, blue: 46 / 255, alpha: 1.0),
                bottom: UIColor(red: 16 / 255, green: 15 / 255, blue: 20 / 255, alpha: 1.0)
            )
        case .black:
            return (
                top: UIColor(red: 32 / 255, green: 32 / 255, blue: 36 / 255, alpha: 1.0),
                bottom: UIColor(red: 12 / 255, green: 12 / 255, blue: 14 / 255, alpha: 1.0)
            )
        }
    }
    
    private static func drawLatinCross(center: CGPoint, color: UIColor, in context: CGContext) {
        let vWidth: CGFloat = 13
        let vHeight: CGFloat = 106
        let hWidth: CGFloat = 66
        let hHeight: CGFloat = 13
        let crossbarYOffset: CGFloat = -18 // 1/3 down from top
        
        let verticalRect = CGRect(
            x: center.x - vWidth / 2,
            y: center.y - vHeight / 2,
            width: vWidth,
            height: vHeight
        )
        let horizontalRect = CGRect(
            x: center.x - hWidth / 2,
            y: center.y + crossbarYOffset - hHeight / 2,
            width: hWidth,
            height: hHeight
        )
        
        color.setFill()
        let vPath = UIBezierPath(roundedRect: verticalRect, cornerRadius: 2.5)
        let hPath = UIBezierPath(roundedRect: horizontalRect, cornerRadius: 2.5)
        vPath.fill()
        hPath.fill()
    }
    
    private static func drawDiamond(at center: CGPoint, size: CGFloat, color: UIColor, in context: CGContext) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: center.x, y: center.y - size))
        path.addLine(to: CGPoint(x: center.x + size, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + size))
        path.addLine(to: CGPoint(x: center.x - size, y: center.y))
        path.close()
        color.setFill()
        path.fill()
    }
}
