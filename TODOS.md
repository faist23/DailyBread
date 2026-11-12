# DailyReadings — Project Status & TODOS

**Last Updated:** 2026-11-11  
**Current Version:** 1.0.0 (Build 12)  
**Bundle Identifier:** `com.ridepro.DailyReadings`  
**Team ID:** `DT58WA8N32`  
**Target Platform:** iOS 17.0+ | Swift 6.0 | SwiftUI | SwiftData  
**GitHub Repository:** [https://github.com/faist23/DailyReadings](https://github.com/faist23/DailyReadings) (`main` branch)

---

## Product Philosophy & Architecture

DailyReadings is a contemplative Catholic daily Mass readings and liturgical calendar app.
- **Aesthetic:** Missal-inspired typography, New York serif, subtle gold liturgical accents, warm scripture paper backgrounds, and distraction-free layout.
- **Offline Reliability:** Guaranteed offline liturgical Computus calendar algorithm and bundled Douay-Rheims Bible SQLite database, with seamless online New American Bible (NAB) lectionary fetching and SwiftData caching.
- **Audio Experience:** Reverent, contemplative audio recitation designed for personal prayer, morning commutes, and hands-free devotion.

---

## Recent Accomplishments (Completed)

### 1. Reverent Audio Recitation Engine (`AudioReadingPlayer`)
- Continuous, sequential recitation of daily Mass readings (First Reading, Responsorial Psalm, Second Reading, Gospel Acclamation, Gospel).
- Liturgical announcements and acclamations (*"The Word of the Lord. Thanks be to God."* / *"The Gospel of the Lord. Praise to you, Lord Jesus Christ."*).
- Full background playback using `AVAudioSession` (`.playback`, mode: `.spokenAudio`, `.duckOthers`).
- System Lock Screen & Control Center Now Playing integration (`MPNowPlayingInfoCenter`, `MPRemoteCommandCenter`) with play, pause, toggle, next, and previous reading commands.
- Floating `AudioMiniPlayerBar` with smooth animations, play/pause controls, and reading navigation.

### 2. Natural Voice Discovery & Legacy Synthesizer Elimination
- Purged all 28 legacy 1980s robotic novelty voices (*Albert, Bad News, Bahh, Bells, Boing, Bubbles, Cellos, Deranged, Fred, Good News, Hysterical, Junior, Kathy, Organ, Princess, Ralph, Trinoids, Whisper, Zarvox, Wobble, Eddy, Flo, Grandma, Grandpa, Reed, Rocko, Sandy, Shelley, Jester, Superstar*) and Eloquence engines.
- Excluded unentitled `com.apple.siri.*` identifiers that cause silent fallback on third-party iOS apps.
- Discovered and ranked natural voices:
  - **Daniel (UK / British)**: Dignified lectionary cadence.
  - **Samantha (US / American)**: Warm, balanced tone.
  - **Ava (US)**, **Moira (Ireland)**, **Karen (Australia)**.
  - Automatic detection and prioritization of Apple's **Enhanced** and **Premium Studio** neural voices.
- Added lector self-introduction preview: chosen voice introduces itself (*"Hello, this is [Name]. The Word of the Lord. Thanks be to God."*).

### 3. Settings & Voice Selector Instant Synchronization
- Resolved SwiftUI `@Observable` computed property desync by binding directly to `@AppStorage("selectedAudioVoiceId")` with a synchronous `Binding(get:set:)`.
- Selecting any voice from the Settings menu updates the UI and persists to `UserDefaults` and `AudioReadingPlayer` immediately, without requiring a preview tap.
- Added guidance footer informing users how to download Apple's free high-definition Studio voices in iOS Settings (*Settings → Accessibility → Spoken Content → Voices → English*).

### 4. App Renaming & App Store Preparation
- Renamed all targets, schemes, assets, directories, and documentation from `DailyBread` to `DailyReadings`.
- Bundle ID configured to `com.ridepro.DailyReadings`.
- Added Apple Privacy Manifest (`DailyReadings/PrivacyInfo.xcprivacy`) with required `NSPrivacyAccessedAPICategoryUserDefaults` justification (`CA92.1`).
- Bumped build version to `1.0.0 (2)` for App Store Connect ingestion.

### 5. Scripture & Liturgical Details
- Fixed New American Bible (NAB) lectionary citation display headers across all cards.
- Saint of the Day card on Today's view now defaults to expanded state with biographical blurbs and feast day notes.
- Punctuation cleaner for audio recitation replaces hard line breaks with natural comma pauses and maintains reverent 0.48 speech rate.

### 6. Liturgical Calendar Legibility & Color Consistency
- Fixed white day selection square visibility in [`CalendarDayCell.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Calendar/CalendarDayCell.swift): White/Gold days now render with rich liturgical gold background and crisp white date text when selected. Unselected dots render as a white circle with a gold rim.
- Fixed "View Readings >" button and feast rank text in [`CalendarView.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Calendar/CalendarView.swift): Switched from raw off-white to `uiAccentColor` (warm liturgical gold), ensuring high contrast and 100% legibility.
- Enhanced Liturgical Colors legend: Added "White / Gold" with a dual white-and-gold dot and expanded coverage to all canonical colors (White/Gold, Green, Violet, Red, Rose) in an adaptive grid that never clips.

### 7. NAB Prose Paragraph Flow Matching Douay-Rheims
- Resolved artificial line-break fragmentation in NAB readings in [`Reading.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Models/Reading.swift#L152-L185) and [`EvangelizioService.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/EvangelizioService.swift#L299-L335).
- Single-line verse breaks from the raw API export are now seamlessly flowed into natural, cohesive paragraphs matching the Douay-Rheims Bible, while preserving stanza structure in Responsorial Psalms.
- Integrated into `Reading.init(from: decoder)` so existing SwiftData cached readings automatically format into smooth paragraphs immediately.

### 8. Automatic 30-Day Offline NAB Pre-Fetching Engine (`ReadingsRepository`, `SettingsView`, `TodayViewModel`)
- Douay-Rheims (1609/1752) is in the public domain and bundled directly in the app SQLite database. The NAB translation is copyrighted by USCCB/CCD, which prohibits bundling the entire Bible in the app binary without a commercial license.
- Implemented an automatic 30-day liturgical lectionary pre-fetch engine in [`ReadingsRepository.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/ReadingsRepository.swift):
  - Fetches the upcoming 30 days of NAB Mass readings in the background whenever NAB is active.
  - Caches readings in SwiftData (`CachedReading`) with 90-day retention, providing seamless 100% offline access in church basements, airplanes, or while traveling.
  - Implements polite 120ms rate-limiting between days to respect server infrastructure.
  - Backfills missing book citations from official liturgical pericope calendar indices.
- Added an **Offline Availability** status card and manual trigger in [`SettingsView.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Settings/SettingsView.swift) displaying the exact count of locally cached days (e.g., *"30 of 30 days stored"*), a progress bar during download, and a *"Download / Refresh"* button.
- Wired automatic background prefetch checks in [`TodayViewModel.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/ViewModels/TodayViewModel.swift) when NAB is selected.

### 9. Dynamic Liturgical Lock Screen Artwork & Biblical Pronunciation Dictionary (`AudioReadingPlayer`)
- Built `LiturgicalArtworkGenerator`: dynamically renders high-resolution (600x600, 2x) illuminated missal cover artwork for `MPMediaItemPropertyArtwork`.
- Features canonical background gradients matching the liturgical season (Emerald, Royal Violet, Crimson, Gaudete Rose, Midnight Charcoal with Gold Radiance), double gold borders with diamond corner flourishes, a radiant Latin Cross emblem, tracked typography, scripture citations, and feast titles.
- Integrated with `MPNowPlayingInfoCenter` on iOS Lock Screen, Control Center, Dynamic Island, Apple Watch, and CarPlay with memory-efficient per-reading caching.
- Added phonetic pronunciation dictionary in `AudioReadingPlayer.cleanScriptureForSpeech` for commonly mispronounced biblical names (*Thessalonians, Colossians, Philemon, Ecclesiastes, Deuteronomy, Habakkuk, Zephaniah, Zechariah, Nebuchadnezzar, Ephesians, Philippians, Corinthians, Gethsemane, Golgotha, Caiaphas, Barabbas*).

### 10. Holy Days of Obligation Vigil Alerts & Prominent Banners (`LiturgicalCalendar`, `NotificationManager`, `TodayView`, `SettingsView`)
- Added Canon Law and USCCB abrogation rule evaluation for non-Sunday Holy Days of Obligation (Christmas, Immaculate Conception, Mary Mother of God, Assumption, All Saints).
- Added `nextHolyDayOfObligation(from:daysAhead:)` to scan upcoming obligations.
- Added automated evening vigil notifications at 7:00 PM the night before any non-Sunday Holy Day of Obligation, with a dedicated toggle in Settings under *Prayer Reminders & Alerts*.
- Added prominent liturgical gold banners on Today's view:
  - Day-of Banner: *"Catholics are obliged to assist at Mass today."*
  - Vigil Banner: *"Vigil of [Feast Title] • Tomorrow is a Holy Day of Obligation."*

### 11. Devotional Scripture Bookmarks (`BookmarkManager`, `ReadingCard`, `PsalmView`, `ReadingDetailView`, `BookmarksView`)
- Implemented `BookmarkManager` with persistence for bookmarked scripture passages, citations, liturgical titles, and dates.
- Added one-tap bookmark icon buttons with active gold highlight on `ReadingCard`, `PsalmView`, and `ReadingDetailView`.
- Built `BookmarksView` accessible from Settings under *Personal Devotions*, complete with scripture preview, swipe-to-delete, and full-screen reading presentation.

### 12. Thread Concurrency Fix for Now Playing Artwork
- Resolved `_dispatch_assert_queue_fail` crash (EXC_BREAKPOINT / SIGTRAP) occurring on device when tapping "Listen".
- Root cause: `MPMediaItemArtwork(boundsSize:requestHandler:)` closure inherited `@MainActor` from `AudioReadingPlayer`, but `MediaPlayer` calls it from its background worker queue (`Thread 8`).
- Fix: Extracted artwork creation to a `nonisolated public static func makeMediaItemArtwork(from image: UIImage) -> MPMediaItemArtwork` function in `LiturgicalArtworkGenerator`, removing actor isolation from the handler.

### 13. Continuous Background Audio & Lock Screen Recitation (`Info.plist`, `AudioReadingPlayer`)
- Enabled `UIBackgroundModes = ["audio"]` capability via `Info.plist` and `INFOPLIST_FILE` build configuration.
- Standardized `AVAudioSession` configuration with `options: []` for uninterrupted spoken word recitation.
- Added `UIApplication.shared.beginReceivingRemoteControlEvents()` to ensure lock screen and headphone play/pause/skip commands route reliably to the app.
- Added `UIBackgroundTaskIdentifier` safeguard during inter-utterance transitions in `speechSynthesizer(_:didFinish:)` so iOS will not suspend the process when advancing across readings while the device is locked.

### 14. Responsorial Psalm Antiphon Banner & Stanza Cues Restoration (`PsalmResponseProvider`, `Reading`, `PsalmView`)
- Built `PsalmResponseProvider` providing canonical Roman Catholic Lectionary responses across all 150 Psalms, biblical canticles (Exodus 15, 1 Sam 2, Daniel 3, Luke 1, etc.), and pericope overrides.
- Added `effectivePsalmResponse` to `Reading` so any Responsorial Psalm reading (whether freshly fetched from NAB Evangelizo API, loaded from Douay-Rheims SQLite, or restored from SwiftData cache) is guaranteed to provide the liturgical antiphon.
- Updated `PsalmView`, `ReadingCard`, `ReadingDetailView`, and `AudioReadingPlayer` to render the prominent missal-styled response banner with red "℟." rubric lettering and repeated response cues between stanzas, and recite the antiphon during audio playback.
- Fixed omission of final psalm response: Removed the `index < stanzas.count - 1` exclusion so the congregational refrain `℟. [Response]` is also displayed after the final stanza (and rendered in `ReadingDetailView` full-screen reader and spoken at the conclusion by the audio lector).

### 15. Liturgical Verse of the Day Hero Card (`VerseOfTheDayProvider`, `VerseOfDayCard`, `TodayView`)
- Added `VerseOfTheDay` model and `VerseOfTheDayProvider` that dynamically derives the day's keynote scripture from the Gospel Acclamation, the Gospel, or the Responsorial Psalm refrain, with seasonal fallback for offline reliability.
- Designed `VerseOfDayCard` featuring illuminated gold border, New York serif italic quotation, source tag, citation, and one-tap clipboard copy and native share actions.
- Positioned as the top hero focus card on `TodayView` above the Mass readings.

### 16. Catholic Treasury of Prayers & Interactive Rosary Tab (`PrayersView`, `PrayersRepository`, `RosaryDetailView`, `PrayerDetailView`, `MainTabView`)
- Added dedicated 4th tab `Prayers` to `MainTabView`.
- Built comprehensive offline Catholic prayers catalog categorized by *Daily Rhythm* (Morning Offering, Angelus, Regina Caeli, Grace, Evening Examen, Act of Contrition, Compline), *Foundational* (Our Father, Hail Mary, Glory Be, Apostles' Creed, Nicene Creed, Confiteor), *Marian & Devotional* (Memorare, Salve Regina, Angel of God, Magnificat, Divine Mercy Chaplet), and *Saints & Protection* (St. Michael, Anima Christi, St. Francis, St. Joseph, St. Patrick).
- Added traditional Latin text and side-by-side / toggle picker in `PrayerDetailView` for all traditional prayers.
- Integrated audio recitation directly into `PrayerDetailView` with Latin & English text-to-speech.
- Built interactive `RosaryDetailView` with automated day-of-week mystery detection (Joyful on Mon/Sat, Sorrowful on Tue/Fri, Glorious on Wed/Sun, Luminous on Thu), decade meditations, scripture references, and spiritual fruits.

### 17. "How to Pray the Rosary" Guide & Interactive Bead-by-Bead Companion (`HowToPrayRosaryView`, `GuidedRosaryView`, `GuidedRosaryBuilder`, `GuidedRosaryStep`, `RosaryDetailView`) (Build 11)
- Built `HowToPrayRosaryView`: Comprehensive beginner tutorial featuring the 6 sequential steps (Crucifix, opening Our Father & 3 Hail Marys, chain prayers, 5 decades, concluding Salve Regina), physical bead anatomy, weekly mystery rhythm, and contemplative advice for overcoming distractions.
- Built `GuidedRosaryStep` model and `GuidedRosaryBuilder`: Assembles the complete sequential bead-by-bead prayer journey (Sign of the Cross, Creed, opening virtues, decade announcements with scripture, Our Father, 10 Hail Marys with progress tracking, Glory Be, Fatima Prayer, and concluding Hail Holy Queen and closing prayer).
- Built `GuidedRosaryView`: Interactive full-screen prayer companion with:
  - Visual bead tracking: Active 10-dot decade row showing completed beads, current glowing bead, and remaining beads.
  - Overall progress bar and bead position badges (`Decade 1 • Bead 4 of 10`).
  - High-readability New York serif prayer typography with dynamic sizing.
  - Mystery meditation cards with scripture citations to keep the mind focused on Christ.
  - Gentle haptic feedback (`UIImpactFeedbackGenerator(style: .light)`) on every bead counted.
  - Speech recitation toggle (`AVSpeechSynthesizer`) for auditory prayer assistance.
  - Celebratory completion screen with concluding blessing.
- Integrated dual-mode segmented toggle (`Mysteries` / `How to Pray`) and one-tap `"Start Bead-by-Bead Rosary"` hero action in `RosaryDetailView`.
- Added dedicated `"How to Pray the Rosary"` entry in `PrayersRepository` and routed directly from `PrayersView`.

### 18. Liturgical Contrast Fix for White Feasts & Bead-by-Bead Buttons (`LiturgicalColors`, `RosaryDetailView`, `HowToPrayRosaryView`, `GuidedRosaryView`, `ReadingCard`, `PsalmView`) (Build 12)
- Fixed unreadable white-on-white text occurring on white liturgical feasts (e.g. St. Martin of Tours, Bishop).
- Root cause: Buttons in `RosaryDetailView` ("Start Bead-by-Bead Rosary") and `HowToPrayRosaryView` ("Start Guided Bead-by-Bead Rosary") rendered with `.foregroundStyle(Color.white)` over `.background(liturgicalColor.swiftUIColor)`, which resolves to ivory/white on white feast days.
- Added `primaryButtonBackground` and `primaryButtonForeground` to `LiturgicalColor`: Uses rich burnished liturgical gold (`rgb(175, 130, 30)`) on white feast days, providing high contrast and crisp legibility for white text across all primary action buttons.
- Updated reading category titles in `ReadingCard`, `PsalmView`, and `ReadingDetailView` to utilize `liturgicalColor.uiAccentColor` instead of raw `swiftUIColor` to ensure titles remain clearly legible on white solemnities.

---

## Active & Upcoming TODOS

### P1 — App Store Submission & TestFlight Monitoring
- [x] **Bump build version to 1.0.0 (Build 12)** in Xcode and upload to TestFlight.
- [ ] **App Store Connect Store Listing**:
  - App Name: `DailyReadings App` (or chosen brand name).
  - Subtitle: *Catholic Daily Mass Readings*.
  - Promotional text, description, support URL, and privacy policy URL.
  - App Store Screenshots (6.7" iPhone 16 Pro Max, 6.5" iPhone 11 Pro Max).

### P2 — Audio & Devotional Enhancements
- [ ] **Custom Phonetic Dictionary Expansion**:
  - Add user-requested biblical name pronunciations if any specific verses require tuning.
- [ ] **Expanded Saint of the Day Database**:
  - Expand biographies and patronage details for lesser-known regional memorials and optional feasts.
- [ ] **Scripture Card Image Sharing**:
  - Generate shareable illuminated card images directly from bookmarked passages for Instagram / Messages / Camera Roll.

---

## Key Files Reference

- **Audio Engine & Lock Screen**: [`DailyReadings/Data/AudioReadingPlayer.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/AudioReadingPlayer.swift)
- **Verse of the Day**: [`DailyReadings/Data/VerseOfTheDayProvider.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/VerseOfTheDayProvider.swift) | [`DailyReadings/Views/Today/VerseOfDayCard.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Today/VerseOfDayCard.swift)
- **Treasury of Prayers & Holy Rosary**: [`DailyReadings/Data/PrayersRepository.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/PrayersRepository.swift) | [`DailyReadings/Views/Prayers/PrayersView.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Prayers/PrayersView.swift)
- **Guided Rosary & Beginner Tutorial**: [`DailyReadings/Views/Prayers/GuidedRosaryView.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Prayers/GuidedRosaryView.swift) | [`DailyReadings/Views/Prayers/HowToPrayRosaryView.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Prayers/HowToPrayRosaryView.swift) | [`DailyReadings/Data/GuidedRosaryBuilder.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/GuidedRosaryBuilder.swift) | [`DailyReadings/Views/Prayers/RosaryDetailView.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Prayers/RosaryDetailView.swift)
- **Psalm Response Provider**: [`DailyReadings/Data/PsalmResponseProvider.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/PsalmResponseProvider.swift)
- **Readings Repository & Offline Cache**: [`DailyReadings/Data/ReadingsRepository.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/ReadingsRepository.swift)
- **Settings View**: [`DailyReadings/Views/Settings/SettingsView.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Settings/SettingsView.swift)
- **Today Readings View**: [`DailyReadings/Views/Today/TodayView.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Today/TodayView.swift)
- **Psalm View Component**: [`DailyReadings/Views/Today/PsalmView.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Today/PsalmView.swift)
- **Mini Player Bar**: [`DailyReadings/Views/Today/AudioMiniPlayerBar.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Today/AudioMiniPlayerBar.swift)
- **Liturgical Engine & Colors**: [`DailyReadings/Engine/LiturgicalCalendar.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Engine/LiturgicalCalendar.swift) | [`DailyReadings/Theme/LiturgicalColors.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Theme/LiturgicalColors.swift)
- **Privacy Manifest**: [`DailyReadings/PrivacyInfo.xcprivacy`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/PrivacyInfo.xcprivacy)
- **XcodeGen Specification**: [`DailyReadings/project.yml`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/project.yml)
