# DailyReadings — Architecture, Engineering & Codebase Guide

This document provides a comprehensive technical overview of **DailyReadings**, designed to brief code reviewers, auditing tools, and AI assistants (such as Claude AI) on the application's architecture, design invariants, data flow, concurrency model, and intentional engineering decisions.

---

## 1. Executive Summary & Product Vision

**DailyReadings** is a native iOS Catholic devotional application built for iOS 17+ using Swift 6, SwiftUI, and SwiftData. Its mission is to provide a calm, sacred, and distraction-free environment for daily prayer and scripture reading centered on the Catholic Mass.

### Key Tenets
1. **Contemplative Missal Aesthetic**: Typographical hierarchy inspired by classic liturgical missals (New York serif, subtle gold accents, rubric red `℟.` antiphons, and warm scripture paper surfaces).
2. **100% Offline Resilience**: Users must be able to read Mass readings in church basements, airplanes, or rural retreats without internet connectivity.
3. **Canonical Liturgical Accuracy**: Computes feast days, liturgical seasons, vestment colors, and Sunday/weekday cycles entirely on-device using official Catholic liturgical algorithms (General Instruction of the Roman Missal & USCCB norms).
4. **Reverent Audio Experience**: Hands-free, sequential spoken-word recitation of the Mass readings and prayers with lock screen controls, background playback, and seasonal illuminated artwork.

---

## 2. Technical Stack & Environment

| Component | Specification |
| :--- | :--- |
| **Platform** | iOS 17.0+ (iPhone & iPad universal) |
| **Language** | Swift 6.0 (`SWIFT_STRICT_CONCURRENCY = complete`) |
| **UI Framework** | SwiftUI (declarative, `@Observable` state pattern) |
| **Persistence** | SwiftData (`@Model CachedReading`) + SQLite (`bible_drb.sqlite`) + `UserDefaults` |
| **Audio** | `AVFoundation` (`AVSpeechSynthesizer`, `AVAudioSession`), `MediaPlayer` (`MPNowPlayingInfoCenter`) |
| **Project Spec** | [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) generating `DailyReadings.xcodeproj` |
| **Bundle ID** | `com.ridepro.DailyReadings` |
| **Team ID** | `DT58WA8N32` |
| **Privacy** | Apple Privacy Manifest compliant (`DailyReadings/PrivacyInfo.xcprivacy`) |

---

## 3. High-Level Architecture

DailyReadings follows a decoupled, unidirectional architecture structured into four distinct layers:

```
┌────────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION LAYER                            │
│  SwiftUI Views: TodayView, CalendarView, PrayersView, SettingsView     │
│  @Observable ViewModels: TodayViewModel, CalendarViewModel             │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                       DOMAIN & LITURGICAL ENGINE                       │
│  LiturgicalCalendar, Computus, LiturgicalRank, LiturgicalSeason        │
│  Models: LiturgicalDay, Reading, DailyReadings, Prayer, RosaryMystery  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                       DATA & REPOSITORY LAYER                          │
│  ReadingsRepository (Multi-tier cache coordinator)                     │
│  ├── SwiftData Cache (CachedReading)                                  │
│  ├── EvangelizioService (Online NAB Lectionary API + 30-Day Prefetch)  │
│  └── BibleDatabase (Bundled Douay-Rheims SQLite Actor)                 │
│  Auxiliary Providers: PsalmResponseProvider, VerseOfTheDayProvider,    │
│                       PrayersRepository, SaintsDatabase, PericoreIndex │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                    SERVICES & HARDWARE INTEGRATION                     │
│  AudioReadingPlayer (Background audio, speech, lock screen artwork)    │
│  NotificationManager (Holy Days of Obligation vigil push alerts)       │
│  BookmarkManager (Scripture passage bookmark persistence)              │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Subsystem Deep-Dive

### 4.1. Canonical Liturgical Engine (`DailyReadings/Engine/`)
The liturgical engine operates entirely offline without third-party network dependencies.
* **`Computus.swift`**: Full implementation of the Meeus/Jones/Butcher algorithm to calculate Easter Sunday for any Gregorian year, from which all movable feasts are derived (Ash Wednesday, Palm Sunday, Holy Thursday, Good Friday, Ascension, Pentecost, Trinity Sunday, Corpus Christi, Sacred Heart, Christ the King).
* **`LiturgicalCalendar.swift`**: Evaluates season (Advent, Christmas, Ordinary Time, Lent, Triduum, Easter), cycle (Sunday Year A/B/C, Weekday Cycle I/II), rank precedence (Solemnity > Feast > Memorial > Optional Memorial > Ferial), and psalter week (Weeks I–IV).
* **`FixedSolemnities.swift`**: Calculates fixed universal and USCCB solemnities and feasts (e.g., Immaculate Conception, Assumption, All Saints). Evaluates USCCB abrogation rules (when Jan 1, Aug 15, or Nov 1 falls on a Saturday or Monday, the obligation to attend Mass is abrogated).
* **`LiturgicalColor.swift` & `LiturgicalColors.swift`**: Maps GIRM canonical colors (White, Red, Green, Violet, Rose, Black) with tailored tints for light/dark mode. Implements `primaryButtonBackground` using burnished gold (`#AF821E`) for White feasts to guarantee high WCAG contrast against white text.

### 4.2. Multi-Tier Bible & Lectionary Pipeline (`DailyReadings/Data/`)
A core design requirement is transparent scripture attribution and zero-compromise offline devotional reading:
1. **Tier 1: Bundled World English Bible (Catholic Edition, WEB-C) [Default]**:
   - Bundled in `bible_webc.sqlite` (35,379 verses, all 73 Catholic books including Greek Esther and Daniel).
   - Completely public domain; modern American English with Hebrew psalm numbering that natively aligns with Catholic lectionary citations.
   - Transparently labeled in-app: *"World English Bible (Catholic edition), public domain. Private devotional reading; not the liturgical text read at Mass."*
2. **Tier 2: Bundled Douay-Rheims Bible (DRB) [Traditional]**:
   - The historic Douay-Rheims (1609/1752 Challoner revision) is public domain, bundled in `bible_drb.sqlite`.
   - Incorporates automated Hebrew ↔ Latin Vulgate Psalm mappings (e.g. lectionary Psalm 23 maps to Vulgate Psalm 22 *"The Lord ruleth me"*), cross-chapter span parsing, and Joel/Malachi chapter offsets.
   - Transparently labeled: *"Douay-Rheims Bible (Challoner Revision, 1752), public domain. Translated from the Latin Vulgate."*
3. **Tier 3: Online NAB Testing Tier (`EvangelizioService`) & USCCB Links**:
   - The New American Bible (NAB/NABRE) is the liturgical translation for US dioceses. Digital permissions are administered by the Confraternity of Christian Doctrine (CCD) via the USCCB.
   - Supported for personal developer testing via Evangelizo feed with polite 30-day SwiftData pre-fetching (`CachedReading`), full CCD copyright attribution, and direct links to official daily readings at `bible.usccb.org`.
   - **Catholic American Bible (CAB) Roadmap**: The USCCB permissions office has placed digital licensing on hold pending the 2027 release of the Catholic American Bible. DailyReadings is registered on the digital permissions waitlist (`nabperm@usccb.org`).
4. **Responsorial Psalm Enhancements (`PsalmResponseProvider`)**: Provides canonical lectionary responses for all 150 Psalms and Biblical Canticles (Exodus 15, Daniel 3, Luke 1, etc.), guaranteeing the red rubric **℟.** banner and stanza cues even if third-party APIs truncate them.

### 4.3. Reverent Audio Recitation Engine (`AudioReadingPlayer.swift`)
* **Background Audio Capability**: Enabled via `UIBackgroundModes = ["audio"]` and `AVAudioSession(category: .playback, mode: .spokenAudio)`.
* **Lock Screen & Remote Command Center**: Full `MPNowPlayingInfoCenter` and `MPRemoteCommandCenter` integration (play, pause, skip forward/backward).
* **Thread Safety Architecture**: To avoid `_dispatch_assert_queue_fail` crashes (since `MPMediaItemArtwork` handlers run on background `Thread 8` outside Swift's main actor), artwork creation is isolated in `nonisolated public static func makeMediaItemArtwork(from:)`.
* **Dynamic Missal Artwork Generator**: Generates 600×600 illuminated missal book cover art on the fly, colored according to the day's liturgical season with double gold foil borders and Latin cross emblems.
* **Natural Voice Engine**: Automatically filters out legacy 1980s robotic voices and unentitled Siri identifiers. Prioritizes natural lectionary voices (e.g. Daniel UK, Samantha US, Ava, Moira) and Apple Studio/Enhanced neural voices.
* **Phonetic Pronunciation Dictionary**: Automatically cleanses difficult biblical names and places before speech synthesis (*Thessalonians, Colossians, Ecclesiastes, Gethsemane, Golgotha, Caiaphas, Barabbas*).
* **Background Task Guard**: Utilizes `UIBackgroundTaskIdentifier` during speech inter-utterance transitions so iOS will not suspend playback while the screen is locked.

### 4.4. Devotional Modules
* **Verse of the Day (`VerseOfTheDayProvider`, `VerseOfDayCard`)**: Dynamically derives the morning keynote focus scripture from the Gospel Acclamation, the Gospel, or the Responsorial Psalm refrain, anchored in the day's Mass.
* **Catholic Treasury of Prayers (`PrayersRepository`, `PrayersView`, `PrayerDetailView`)**: Comprehensive offline treasury across 5 categories (*Daily Rhythm, Foundational, Marian, Saints & Protection, Devotions*) with English and traditional Latin texts, speech synthesis in both languages, and quick search.
* **Interactive Holy Rosary (`HowToPrayRosaryView`, `GuidedRosaryView`, `GuidedRosaryBuilder`, `RosaryDetailView`)**:
  * Dual-mode view: "Mysteries" (today's mystery detection, fruits, scripture) and "How to Pray" (6-step tutorial, bead anatomy, beginner advice).
  * Interactive bead-by-bead prayer companion with visual 10-bead decade track, haptic taps (`UIImpactFeedbackGenerator`), scripture context, and completion blessing.
* **Holy Days of Obligation Vigil Alerts (`NotificationManager`)**: Evaluates Canon Law and USCCB calendars, scheduling 7:00 PM vigil push notifications the evening before an obligation.

---

## 5. Codebase Directory Structure

```
DailyReadings/
├── project.yml                       # XcodeGen project specification
├── README.md                         # Product overview & features
├── TODOS.md                          # Build-by-build changelog & roadmap
├── ARCHITECTURE.md                   # Technical & architectural reference (this file)
└── DailyReadings/
    ├── DailyReadingsApp.swift        # App entry point, SwiftData schema configuration
    ├── Info.plist                    # App metadata & UIBackgroundModes configuration
    ├── PrivacyInfo.xcprivacy         # Apple Privacy Manifest
    │
    ├── Engine/                       # Pure Swift canonical liturgical engine
    │   ├── Computus.swift            # Easter & movable feast astronomical calculations
    │   ├── FixedSolemnities.swift    # Fixed calendar solemnities & USCCB abrogation rules
    │   ├── LiturgicalCalendar.swift  # Main calendar engine (seasons, ranks, cycles, psalter)
    │   ├── LiturgicalColor.swift     # GIRM liturgical color enum & metadata
    │   ├── LiturgicalCycle.swift     # Sunday (A/B/C) and Weekday (I/II) cycle evaluation
    │   ├── LiturgicalRank.swift      # Canonical feast precedence hierarchy
    │   └── LiturgicalSeason.swift    # Seasons (Advent, Christmas, Lent, Triduum, Easter, Ordinary)
    │
    ├── Data/                         # Data access, network, audio, and background services
    │   ├── AudioReadingPlayer.swift  # AVSpeechSynthesizer, background audio, lock screen art
    │   ├── BibleDatabase.swift       # Swift Actor querying bundled Douay-Rheims SQLite
    │   ├── EvangelizioService.swift  # REST service fetching online NAB Lectionary
    │   ├── GuidedRosaryBuilder.swift # Step sequencer for interactive bead-by-bead Rosary
    │   ├── LiturgicalCelebrationBlurbs.swift # Historical & theological feast summaries
    │   ├── NotificationManager.swift # Local push notifications for vigil alerts
    │   ├── PericoreIndex.swift       # Maps calendar dates & liturgical days to citations
    │   ├── PrayersRepository.swift   # Offline Catholic prayers repository (English + Latin)
    │   ├── PsalmResponseProvider.swift # Lectionary Responsorial Psalm antiphon database
    │   ├── ReadingsRepository.swift  # Cache coordinator (SwiftData → API → SQLite)
    │   ├── SaintsDatabase.swift      # Bundled saints database & commemorations
    │   └── VerseOfTheDayProvider.swift # Derives daily keynote scripture from readings
    │
    ├── Models/                       # Domain models
    │   ├── BibleVerse.swift          # Verse model for SQLite queries
    │   ├── CachedReading.swift       # SwiftData @Model for offline lectionary persistence
    │   ├── DailyReadings.swift       # Collection of readings for a single Mass
    │   ├── GuidedRosaryStep.swift    # Discrete bead/prayer step model
    │   ├── LiturgicalDay.swift       # Full metadata for a calendar day
    │   ├── Prayer.swift              # Traditional Catholic prayer model
    │   ├── Reading.swift             # Single Mass reading (First, Psalm, Gospel, etc.)
    │   ├── RosaryMystery.swift       # Joyful, Sorrowful, Glorious, Luminous mysteries
    │   ├── Saint.swift               # Hagiographical saint model
    │   └── VerseOfTheDay.swift       # Highlighted scripture model
    │
    ├── Theme/                        # Missal design system
    │   ├── AppTheme.swift            # Spacing, corner radii, shadows, semantic colors
    │   ├── LiturgicalColors.swift    # Seasonal color palettes, button backgrounds & contrast
    │   └── Typography.swift          # Missal New York serif font hierarchy & styles
    │
    ├── ViewModels/                   # UI state coordinators
    │   ├── CalendarViewModel.swift   # Month view pagination & date selection
    │   └── TodayViewModel.swift      # Today's readings, audio sync & pre-fetch triggers
    │
    ├── Views/                        # SwiftUI views
    │   ├── MainTabView.swift         # 4-tab bar (Today, Calendar, Prayers, Settings)
    │   ├── Today/                    # Today tab components
    │   │   ├── TodayView.swift       # Main scrolling devotional feed
    │   │   ├── VerseOfDayCard.swift  # Top hero scripture card
    │   │   ├── ReadingCard.swift     # Single Mass reading card
    │   │   ├── PsalmView.swift       # Responsorial Psalm with antiphon & stanza cues
    │   │   ├── SaintOfDayCard.swift  # Commemorated saint card
    │   │   └── AudioMiniPlayerBar.swift # Persistent floating audio playback bar
    │   ├── Calendar/                 # Calendar tab
    │   │   ├── CalendarView.swift    # Monthly grid with liturgical dots
    │   │   ├── CalendarDayCell.swift # Individual date cell with selection highlight
    │   │   └── DateReadingsView.swift # Full-screen readings for selected date
    │   ├── Prayers/                  # Prayers tab
    │   │   ├── PrayersView.swift     # Category filter pills, search & Rosary hero
    │   │   ├── PrayerDetailView.swift # Missal reader with Latin/English & speech
    │   │   ├── RosaryDetailView.swift # Mysteries & "How to Pray" dual-mode container
    │   │   ├── HowToPrayRosaryView.swift # 6-step beginner tutorial & bead anatomy
    │   │   └── GuidedRosaryView.swift # Interactive bead-by-bead prayer companion
    │   ├── Reading/                  # Dedicated scripture reader
    │   │   └── ReadingDetailView.swift # Distraction-free full-screen scripture view
    │   └── Settings/                 # Settings tab
    │       └── SettingsView.swift    # Translation, audio voices, cache status, bookmarks
    │
    └── Resources/                    # Bundled offline assets
        ├── bible_drb.sqlite          # Complete Douay-Rheims Bible database (73 books)
        ├── lectionary.json           # Pericope index mapping liturgical days to citations
        ├── lectionary_dates.json     # Date-based mapping fallback
        └── saints.json               # Catholic hagiography database
```

---

## 6. Concurrency & Safety Model

DailyReadings compiles under **Swift 6 complete concurrency checking** (`SWIFT_STRICT_CONCURRENCY = complete`):
* **`@MainActor` Views & ViewModels**: All SwiftUI views and `@Observable` view models (`TodayViewModel`, `CalendarViewModel`, `AudioReadingPlayer`) are actor-isolated to `@MainActor` to prevent UI thread dataraces.
* **`BibleDatabase` Actor**: Isolated as a Swift `actor` to serialize SQLite connection access and avoid C-level thread conflicts on SQLite handles.
* **Audio Artwork Boundary**: `MPMediaItemArtwork(boundsSize:requestHandler:)` invokes its handler on background thread pools. To avoid actor isolation violations and runtime crashes (`_dispatch_assert_queue_fail`), artwork rendering logic is extracted into a `nonisolated` static helper.
* **Value Types & `Sendable`**: All data exchange structs (`Reading`, `LiturgicalDay`, `GuidedRosaryStep`, `Prayer`) strictly conform to `Sendable`.

---

## 7. Recommended Focus Areas for Claude AI Analysis

When analyzing DailyReadings, we recommend directing attention to the following areas:

1. **Liturgical Calendar Edge Cases**:
   * Review `Computus.swift`, `LiturgicalCalendar.swift`, and `FixedSolemnities.swift`.
   * Check edge cases such as the Annunciation (March 25) falling during Holy Week or the Easter Octave (transferred to the Monday after Divine Mercy Sunday).
   * Check Christmas season calculations when Epiphany is celebrated on Sunday (US norm) vs January 6 (traditional norm).
2. **Swift 6 Concurrency & Actor Handoffs**:
   * Audit closures and background tasks in `ReadingsRepository.swift`, `AudioReadingPlayer.swift`, and `BibleDatabase.swift` for any latent concurrency issues or redundant main-thread dispatching.
3. **Memory & Battery Efficiency in Background Audio**:
   * Review `AudioReadingPlayer.swift` during long recitations (e.g., continuous Mass readings or a 5-decade Rosary). Verify that `AVSpeechSynthesizer` instances and `UIBackgroundTaskIdentifier` tokens are deallocated cleanly without leaks.
4. **SwiftData Query Performance & Cache Pruning**:
   * Review `ReadingsRepository.swift` and `CachedReading.swift`. Assess whether index attributes (`@Attribute(.unique)`) and cleanup routines effectively prevent unbounded local storage growth over years of daily usage.
5. **UI Accessibility & Dynamic Type**:
   * Check whether `AppTheme.Typography` and custom font modifiers correctly scale with iOS Dynamic Type and support VoiceOver labels across custom controls (like the 10-dot Rosary bead tracker).
