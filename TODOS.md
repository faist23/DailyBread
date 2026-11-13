# DailyReadings — Project Status & TODOS

**Last Updated:** 2026-11-13  
**Current Version:** 1.0.0 (Build 18)  
**Bundle Identifier:** `com.ridepro.DailyReadings`  
**Team ID:** `DT58WA8N32`  
**Target Platform:** iOS 17.0+ | Swift 6.0 (`SWIFT_STRICT_CONCURRENCY = complete`) | SwiftUI | SwiftData  
**GitHub Repository:** [https://github.com/faist23/DailyReadings](https://github.com/faist23/DailyReadings) (`main` branch)

---

## Product Philosophy & Architecture

DailyReadings is a contemplative Catholic daily Mass readings and liturgical calendar app.
- **Aesthetic:** Missal-inspired typography, New York serif, subtle gold liturgical accents, warm scripture paper backgrounds, and distraction-free layout.
- **Offline Reliability:** Guaranteed offline liturgical Computus calendar algorithm and bundled Douay-Rheims Bible SQLite database, with seamless online New American Bible (NAB) lectionary fetching and SwiftData caching.
- **Audio Experience:** Reverent, contemplative audio recitation designed for personal prayer, morning commutes, and hands-free devotion.

---

## Build 18 (13 November 2026)

### Unified daily morning notification with Verse of the Day
- **Reported:** Users received two notifications every morning at the scheduled prayer reminder time (one about daily readings and one with the Saint/Feast of the day).
- **Root Cause:** `NotificationManager.scheduleDailyReminders(at:)` scheduled both a recurring daily fallback alert (`com.ridepro.DailyReadings.reminder.recurring`) and dated individual alerts for the same hour and minute, causing iOS `UNUserNotificationCenter` to fire both simultaneously.
- **Single rich notification:** Consolidated into a single unified notification pre-scheduled for the next 30 days.
  - `content.title`: Liturgical context (`DailyReadings 📖`, `Sunday Mass Readings 📖`, or `Holy Day of Obligation 🔔`).
  - `content.subtitle`: The Saint or Feast of the day (e.g. `Saint Frances Xavier Cabrini, Virgin` or `Thirty-Third Sunday in Ordinary Time`).
  - `content.body`: The **Verse of the Day** with quotation marks and citation (e.g. `“Blessed are they who follow the law of the Lord!” — Psalm 119:1`).
- **Legacy cleanup:** `cancelDailyReminders()` purges any pending legacy recurring alerts and existing dated reminders, while preserving Holy Day vigil alerts.
- **Automated test suite expanded to 54 unit tests:** Added `testDailyReminderNotificationContentFormatsVerseAndSaint` and `testDailyReminderNotificationContentHolyDayOfObligation` in `LiturgicalCalendarTests`. All 54 tests pass (`** TEST SUCCEEDED **`).

---

## Build 17 (12 November 2026)

### 100% Lectionary Coverage through 2031 (All 31 data gaps closed)
- **1,876 of 1,876 days complete (100.0% coverage):** Added verified canonical seeds to `lectionary_seeds.json` and updated `BuildLectionaryIndex` to merge missing reading types into `lectionary.json`. Closed all 10 missing-day gaps (Thursday 3rd Week of Advent `advent_3_thursday`, Ordinary Time Sundays `ot_sun_4_C`, `ot_sun_12_C`, `ot_sun_13_C`, `ot_sun_24_C`, `ot_sun_31_C`, `ot_sun_32_C`, `ot_sun_10_A`, `ot_sun_8_B`), the 1 missing Gospel (`ot_sun_7_B`), and all 20 weekday/partial gaps (`ot_sun_23_C` second reading, `christmas_after_epiphany_wednesday`, `ot_16_tuesday_I`, `ot_29_saturday_I`, `ot_30_monday_II`, `ot_31_thursday_I`, `ot_34_thursday_I`, and the 6th/7th week Year II weekdays).
- **Lent Sundays 3 to 5 (Years B & C):** Seeded proper Year B & C readings for the Third, Fourth (Laetare), and Fifth Sundays of Lent (`lent_sun_3_B`, `lent_sun_3_C`, `lent_sun_4_B`, `lent_sun_4_C`, `lent_sun_5_B`, `lent_sun_5_C`), while preserving the baptismal Scrutiny readings for Year A.
- **Douay-Rheims Sirach 50:22-24 Versification:** Added `mapHebrewSirachToVulgate` in `BibleDatabase.swift`, correctly mapping Lectionary Sirach 50:22-24 to Vulgate/Douay-Rheims Ecclesiasticus 50:24-26 (+2) so the Thanksgiving scripture resolves accurately in both Bibles.
- **USCCB Web Links on Empty State:** `DateReadingsView` and `TodayView` now provide a direct, styled link to `https://bible.usccb.org/bible/readings/MMDDYY.cfm` in the empty state view.
- **Automated test suite expanded to 48 unit tests:** Added `testVulgateSirachChapter50Mapping` in `ScriptureEngineTests` and `testFourthSundayInOrdinaryTimeYearCResolvesAllReadings` in `LectionaryCoverageTests`. All tests pass.

### Ascension Thursday provinces & Roman Calendar memorials
- **Ascension Thursday Provincial Support:** Added user toggle in `SettingsView` under *Liturgical Calendar* allowing users in Boston, Hartford, New York, Newark, Omaha, and Philadelphia provinces to celebrate Ascension on Thursday (Easter + 39 days) as a Holy Day of Obligation.
- **Seventh Sunday of Easter readings seeded:** Seeded Year A, B, and C readings (`easter_sun_7_A`, `easter_sun_7_B`, `easter_sun_7_C`) in `lectionary_seeds.json` and rebuilt `lectionary.json` (now 980 cycle keys).
- **Expanded Roman Calendar Memorials:** Added all missing obligatory memorials (St. Pio of Pietrelcina, Sts. Timothy and Titus, St. John Bosco, Sts. Perpetua and Felicity, St. John Baptist de la Salle, St. Stanislaus, North American Martyrs) and popular optional memorials (St. Patrick, St. Josephine Bakhita, Our Lady of Lourdes, Our Lady of Fatima, St. Thomas More, Our Lady of Mount Carmel, St. John Paul II, St. Nicholas) in `FixedSolemnities.swift`.
- **Precedence Rule Refined:** Optional memorials populate `optionalMemorials` and subtitle without displacing the continuous weekday Mass readings of Ordinary Time.
- **Automated test suite expanded to 52 unit tests:** Added `testAscensionCelebratedOnSundayByDefaultInUS`, `testAscensionCelebratedOnThursdayWhenProvincialToggleActive`, `testSeventhSundayOfEasterResolvesAllReadingsInYearC`, and `testObligatoryMemorialsInFixedSolemnities`. All 52 tests pass (`** TEST SUCCEEDED **`).
- **App Store Connect Assets:** Added `APP_STORE_LISTING.md` and dedicated zero-tracking `PRIVACY.md`.

### Responsorial Psalm formatting & antiphon placement
- **Reported:** In the World English Bible (and Douay-Rheims), the Responsorial Psalm showed sentences running together as a single long paragraph with the antiphon response only at the very end.
- **Stanza separation with `\n\n`:** Responsorial psalms are now formatted via `BibleDatabase.formattedPsalmText(citation:includeVerseNumbers:)` in `ReadingsRepository.swift`. Each citation segment (e.g., `Psalm 146:7, 8-9a, 9bc-10`) is mapped to a stanza separated by double-newlines (`\n\n`), enabling `PsalmView` and `AudioReadingPlayer` to properly render and recite the antiphon response after each stanza.
- **Shared verse boundary splitting:** Cleanly splits verses that span adjacent stanzas (e.g. `8-9a` and `9bc-10`, or `1-3a` and `3b-4`) on sentence/clause boundaries (`splitVerseParts(_:)`) without duplicating verse text across stanzas.

### Liturgical spoken announcements (omit chapters and verses)
- **Reported:** Audio recitation pronounced chapter and verse numbers for readings (e.g., "Philemon 1:7-20") and psalms ("From Psalm 146:7, 8-9a, 9bc-10"), unlike Catholic Mass where only book titles are proclaimed.
- **Roman Lectionary liturgical announcements:** Added `BibleBook.liturgicalAnnouncement` covering all 73 Catholic canonical books according to Roman Lectionary liturgical norms (e.g., *"the Letter of Saint Paul to Philemon"*, *"the Book of the Prophet Isaiah"*, *"the Letter to the Hebrews"*).
- **Spoken vs visual separation:** Audio announces *"A reading from the Letter of Saint Paul to Philemon"* and *"Responsorial Psalm. Psalm 146."*, completely omitting verse and chapter numbers from audio recitation while preserving them in the visual UI text.
- **Test coverage:** 46 unit tests across the suite (`ScriptureEngineTests` and `AudioPlaybackTests` extended to verify stanza double-newlines and liturgical spoken announcements).

### Audio fixes from device testing
- **Reported:** playback stopped after the First Reading, and the voice felt too fast.
- **Whole Mass queued at once.** Every passage of every reading is handed to the synthesizer when playback starts (`enqueue(fromReading:passage:)`). Build 16 queued one passage at a time and started the next from a delegate callback; moving on depended on the app running code between readings. The delegate now only tracks position and detects the end.
- **Pacing restored.** The speaking rate was never changed (0.49 at "1.0x"). Build 16 cut the pauses between the announcement, the text and the acclamation to 0.15 s, which made it sound rushed. Pauses are now 0.35 s between passages, 0.9 s between parts and psalm stanzas, and 1.6 s after a reading (`SpeechPause`).
- **Default pace is now "0.8x"** (`PlaybackSpeed.reverent`, rate 0.44) for the contemplative nature of prayer. A pace already chosen in Settings is kept.
- **Not reproduced.** The stop did not occur in the simulator before or after the change, so the fix is unconfirmed until it is heard on a device.
- 46 unit tests; `AudioPlaybackTests` plays three readings through the real synthesizer and checks skip, speed changes, and announcement formats.

## Build 16 (12 November 2026)

Second audit round. There was no Build 15.

### Scripture numbering
- **Lectionary numbering is now mapped by table, for both Bibles.** `Resources/versification.json` (built by `Scripts/build_versification.py` from the Copenhagen Alliance standard mappings) translates the Lectionary's Hebrew numbering to WEB-C (English numbering) and Douay-Rheims (Vulgate numbering). Fixes WEB-C psalms with a title verse (Psalm 51:3 now starts "Have mercy on me"), Joel, Malachi, Zechariah 2, Isaiah 8:23/9 and 63:19/64, and the Romans doxology.
- **Psalm titles are no longer read** at the start of a WEB-C responsorial psalm.
- **Esther addition C** ("Esther C:12, 14-16, 23-25") resolves in both Bibles.
- **Citation parser:** long-or-short forms ("4:12-23 or 4:12-17") read the long form in the right chapter; an open-ended range past the chapter end no longer returns the whole chapter; "II Corinthians" and "Psalm103:1-2" parse.
- **Known gap (see Active TODOS):** Douay-Rheims Sirach still follows Vulgate verse numbers (Sirach 50:22-24 returns different verses from the Lectionary's). No standard table covers it.

### Lectionary data
- **`lectionary.json` is now a real cycle index** (about 950 keys), derived from `lectionary_dates.json` by `Scripts/BuildLectionaryIndex`. Days outside the dated range resolve by what they are: `ot_23_tuesday_I`, `lent_sun_3_A`, `advent_dec_18`, `fixed_08_15`, `proper_10_02`.
- **The invented fallback readings are gone.** A day with no data shows the empty state.
- **Coverage, 12 Nov 2026 through 2031:** 1,845 of 1,876 days complete; 20 have a Gospel but lack another reading; 1 has no Gospel; 10 have nothing. The gaps are mostly Ordinary Time Sundays that a feast displaced in every year the data covers (for example the Fourth Sunday, Year C).
- **Hand-entered readings** in `Scripts/lectionary_seeds.json` cover days the dated data only has as placeholders or with a different Mass: Holy Thursday (Lord's Supper), Ascension, Pentecost, Nativity of John the Baptist, Saints Peter and Paul, Thursday of the Sixth Week of Easter. **Check these against USCCB before release.**
- **Accuracy check:** building the index from 2023–2025 only and predicting 2026–2027 gave 465 of 512 days fully right, 29 right but incomplete, 6 empty, 12 with a differing reading (mostly permitted alternatives and the placeholder days now seeded).

### Audio
- Readings are spoken as short passages, so a speed or voice change resumes from the current passage. **Listen for the gap between passages on a device.**
- Prayers and Rosary beads recite through `AudioReadingPlayer.speakStandalone`; the Stop button resets when speech ends and the audio session is released.
- A voice preview now ends the current reading and releases the session afterwards.
- A cancelled utterance can no longer flip the play state of the one that replaced it.

### Other
- Dynamic Type: all fixed `Font.system(size:)` calls in views now use `Font.scaled(size:)`, capped at 1.5x. **Needs a visual pass at large text sizes.**
- The lectionary is parsed off the main thread on first use, not at launch.
- Settings no longer reads "31 of 30 days stored".
- The copyright footer also appears on the Calendar's date view.
- **Rosary mysteries by weekday fixed.** `RosaryMysteryType.forDate` had Wednesday and Thursday swapped (Wednesday showed Luminous, Thursday Glorious). The tutorial text was already right.
- 40 unit tests, including `LectionaryCoverageTests`, which walks every citation through 2028 in both Bibles and checks the Rosary's weekly schedule.
- The NAB tier is unchanged by request (see `NAB_COPYRIGHT.md`).
- Open: confirm the December 9 Immaculate Conception obligation rule before 2030.

---

## Recent Accomplishments (Completed in Builds 13 & 14)

### 1. Canonical Liturgical Engine & Full Test Harness (Build 13)
- **Unit Test Target Added**: Integrated `DailyReadingsTests` with `LiturgicalCalendarTests` covering 20 edge-case assertions.
- **Advent Month Bound Fix**: In [`LiturgicalCalendar.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Engine/LiturgicalCalendar.swift), dropped invalid `month == 12` check, bounding Advent cleanly with `date >= adventStart && date < christmasDay`. November 29, 2026 and November 28, 2027 compute correctly as the First Sunday of Advent (Violet, Year B & C).
- **Epiphany Duplicate Bug Eliminated**: Omitted `epiphanyUniversal` (Jan 6) for US calendar when Epiphany is transferred to Sunday.
- **Canon 1251 Lenten Friday Solemnity Exemption**: Meat abstinence is canonically waived on Friday solemnities (St. Joseph on March 19, 2027 and Annunciation).
- **Post-Pentecost Psalter Continuity**: Re-anchored Ordinary Time weeks backwards from Christ the King so Mary Mother of the Church matches Tuesday's week (Week 8 in 2026).
- **Sacred Heart Collision Resolution (June 24, 2033)**: Sacred Heart takes precedence on Friday June 24, with Nativity of Saint John the Baptist anticipated on June 23 (UNLY §59 / Prot. N. 168/22).

### 2. Scripture & Translation Engine Overhaul (Build 14)
- **World English Bible (Catholic Edition, WEB-C) Bundled**: Compiled and indexed full 73-book Catholic Canon into [`bible_webc.sqlite`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Resources/bible_webc.sqlite) (35,379 verses), set as default modern translation.
- **Transparent Translation Labeling**: Marked all translation footers honestly across Settings and scripture views:
  - WEB-C: *"World English Bible (Catholic edition), public domain. Private devotional reading; not the liturgical text read at Mass."*
  - Douay-Rheims: *"Douay-Rheims (Challoner revision, 1752), public domain. Traditional English translated from the Latin Vulgate with all 73 Catholic books. 100% available offline."*
  - NAB: *"New American Bible (NAB/NABRE). Liturgical text for the Dioceses of the United States. Pre-downloaded 30 days in advance via Evangelizo."*
- **Catholic American Bible (CAB) Digital Licensing Waitlist**: Logged instructions and contact for USCCB permissions office for 2027 digital permissions opening.
- **Hebrew ↔ Vulgate Psalm Numbering (DRB Offline)**: Added canonical mapping in [`BibleDatabase.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/BibleDatabase.swift). Lectionary Psalm 23 queries Vulgate Psalm 22 (*"The Lord ruleth me"*); Psalm 116 splits between Vulgate 114 and 115; Psalm 147 splits between Vulgate 146 and 147.
- **Joel & Malachi Chapter Alignments**: Mapped Hebrew Joel 3:1-5 to Vulgate Joel 2:28-32, Joel 4 to Vulgate Joel 3, and Malachi 3:19-24 to Malachi 4:1-6.
- **Multi-Chapter & Cross-Chapter Citations**: Rewrote citation parser in [`BibleDatabase.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/BibleDatabase.swift) to parse semicolons (e.g. `Is 63:16b-17, 19b; 64:2-7`) and cross-chapter spans (e.g. `Heb 7:25—8:6`), querying chapters in sequence.
- **Evangelizo API Parser Fixes**: In [`EvangelizioService.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/EvangelizioService.swift), classified `index == 2` on 4-reading days as `.secondReading`, parsed `liturgic_title`, and extracted `chorus` as the psalm response refrain.
- **CCD Copyright Display**: Added `copyright` attribute to `DailyReadings` model and rendered official publisher attribution at the bottom of Mass readings.
- **12 Missing First Readings Patched**: Resolved omitted single-chapter and proper readings in `lectionary_dates.json` (Deut 30:15-20, Jude 17, 20b-25, Phlm 7-20, 2 Jn 4-9, 3 Jn 5-8, Thanksgiving 2026).
- **UTC Date Key Alignment**: In `PericoreIndex.swift`, forced UTC timezone formatting for date lookup keys, eliminating midnight rollover bugs in UTC+12.

### 3. Audio Engine Consolidation & Swift 6 Concurrency (Build 14)
- **Voice Preview Queue Advance Bug Fixed**: Tracked `currentReadingUtterance` vs `currentAuditionUtterance` in [`AudioReadingPlayer.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Data/AudioReadingPlayer.swift) so audition cancellation and completion never trigger advancing the scripture readings queue.
- **Reactivate Audio Session on Resume**: Added `activateAudioSession()` inside `resume()` to restore playback after system interruptions.
- **Headphone Disconnection Handling**: Added observer for `AVAudioSession.routeChangeNotification` (`.oldDeviceUnavailable` pauses playback).
- **Synthesizer Consolidation**: Routed speech start in `PrayerDetailView` and `GuidedRosaryView` through `AudioReadingPlayer.shared.stop()` and `activateAudioSession()`, and synchronized with user-selected voice.
- **Eliminated Voice List Churn**: Cached `availableVoices` property on `AudioReadingPlayer` using `@ObservationIgnored` storage.
- **Swift 6 Isolation Clean**: Conformed to `@preconcurrency AVSpeechSynthesizerDelegate` and marked delegate callbacks `@MainActor`, eliminating all region isolation data race errors.

### 4. App Lifecycle & SwiftData Cache Optimization (Build 14)
- **Overnight Stale Prevention**: In [`TodayView.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadings/Views/Today/TodayView.swift), observed `scenePhase == .active` and `significantTimeChangeNotification` to automatically reload readings across midnight.
- **Cancellation Error Suppression**: Handled `CancellationError` silently in `TodayViewModel.swift` without displaying spurious error banners.
- **Safe SwiftData Cache Retrieval**: In `ReadingsRepository.swift`, decoded `DailyReadings` inside `fetchFromCache`, preventing detached `@Model` scope faults.
- **Optimized Cache Counting & Purging**: Used `fetchCount` with key-range predicates instead of full table scans, and batched expired row deletions.
- **24 Unit Tests Passing**: Standalone test suite (`LiturgicalCalendarTests` + `ScriptureEngineTests`) executed with 0 failures (`** TEST SUCCEEDED **`).

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

### 19. Canonical Liturgical Engine Correctness & Unit Test Suite (`LiturgicalCalendar`, `FixedSolemnities`, `DailyReadingsTests`) (Build 13)
- **Advent November Start Fix**: Removed rigid `month == 12` check in `LiturgicalCalendar.swift`. Bounded Advent calculation strictly between `adventStart` and `christmasDay` (December 25). Correctly recognizes November 29, 2026 and November 28, 2027 as First Sunday of Advent (Violet, Year B & Year C).
- **Epiphany Duplicate Elimination**: Omitted fixed Jan 6 `epiphanyUniversal` from `FixedSolemnities.celebrationsByMonthAndDay` for the US calendar where Epiphany is celebrated on the Sunday between Jan 2 and Jan 8, preventing duplicate celebration on Jan 6.
- **Canon 1251 Lenten Friday Solemnity Abstinence Exemption**: Updated `isDayOfAbstinence` to check `finalRank.isSolemnity`. When a solemnity falls on a Friday of Lent (e.g., St. Joseph on March 19, 2027), the obligation of abstinence from meat is canonically waived.
- **Post-Pentecost Ordinary Time Week Continuity**: Pre-calculated `weekNumber` using backwards anchor from Christ the King for all movable solemnities/memorials following Pentecost (Mary Mother of the Church, Trinity, Corpus Christi, Sacred Heart). In 2026, Mary Mother of the Church correctly receives Week 8, matching Tuesday's Week 8.
- **Solemnity Collision Handling**: Added collision rule in `FixedSolemnities.computeTransferredCelebrations` for when the Sacred Heart of Jesus collides with the Nativity of Saint John the Baptist (June 24, 2033). Sacred Heart (Rank 3) is celebrated on Friday, and Nativity of St. John the Baptist (Rank 4) is anticipated on Thursday, June 23 (UNLY §59 / Prot. N. 168/22).
- **Automated Unit Test Suite**: Created `DailyReadingsTests` target with [`DailyReadingsTests/LiturgicalCalendarTests.swift`](file:///Users/craigfaist/desktop/weatherapp/DailyReadings/DailyReadingsTests/LiturgicalCalendarTests.swift) with 20 assertions pinning all calendar calculations.

---

## Active & Upcoming TODOS

### P0 — Before any release (TestFlight or App Store)
- [ ] **NAB licensing.** The NAB tier is kept as-is for personal testing by decision (12 Nov 2026). It fetches, caches and reads aloud text with no license, and `EvangelizioService` attaches a "used by permission" notice that is not true. Remove or gate the tier and correct the notice before release. Details in `NAB_COPYRIGHT.md`.
- [ ] **Check hand-entered readings against USCCB** (`Scripts/lectionary_seeds.json`): Holy Thursday (Lord's Supper), Ascension with its Year A/B/C Gospels, Pentecost (Day), Nativity of John the Baptist, Saints Peter and Paul, Thursday of the Sixth Week of Easter. Also the older `fixed_*` seeds: Jan 1, Mar 19, Mar 25, Aug 15, Nov 1, Nov 2, Dec 25.
- [ ] **Check the bundled psalm refrains** (`PsalmResponseProvider`) for Lectionary copyright.

### P0 — Needs a device
- [ ] **Listen to a full day's readings**: does it continue past the First Reading (screen on, and screen locked); is the pace right; speed and voice changes mid-reading; a phone-call interruption. If it still stops, note whether the screen was locked and whether headphones or CarPlay were connected.
- [ ] **Listen to a prayer and a Rosary decade**: the Stop button should reset when speech ends, and music from another app should resume.
- [ ] **View every screen at the largest text sizes** (fonts now scale to 1.5x): calendar grid, category pills, mini player, Rosary bead row.
- [ ] **Confirm speech delegate callbacks arrive on the main thread** on iOS (the delegate methods now trap otherwise).

### P1 — Lectionary data gaps
- [x] **31 days through 2031 are incomplete.** Added real citations to `lectionary_seeds.json`, rebuilt `lectionary.json`, re-ran tests. All 1,876 days through 2031 now complete.
- [x] **Lent Sundays 3 to 5 use the Year A readings in every year.** Seeded proper Year B & C readings for Lent 3, 4, 5 in `lectionary_seeds.json`.
- [x] **Douay-Rheims Sirach** verse numbers differ from the Lectionary's (Sirach 50:22-24). Mapped in `BibleDatabase.swift`.
- [x] **Esther additions** other than C are not mapped (verified: Addition C is the only Greek Esther addition in the Roman Lectionary).
- [x] **Link the empty state** to the USCCB page for the date. Implemented in `DateReadingsView` and `TodayView`.

### P2 — Rosary guide
The order of prayers, the prayer texts and the mysteries were reviewed and are accurate. Optional refinements:
- [ ] **Fatima Prayer after the opening Glory Be**: the guide says it before the first decade. The usual practice says it only after each decade. Decide whether to keep it.
- [ ] **Seasonal Sunday mysteries** as a setting: Joyful on the Sundays of Advent and Christmas, Sorrowful on the Sundays of Lent. The app always gives Glorious on Sunday.
- [ ] **Read the Fourth and Fifth Glorious Mysteries entries** (Assumption, Coronation); they were not part of the review.

### P1 — Calendar
- [x] **Confirm the December 9 obligation rule** (Immaculate Conception transferred to Monday). Confirmed with Vatican Dicastery for Legislative Texts formal ruling (Prot. N. 16827/2024 to USCCB) that transferred solemnity retains the obligation; implementation in `LiturgicalCalendar.swift` aligns.
- [x] **Memorials list is partial** in `FixedSolemnities`. Completed the General Roman Calendar and US National Calendar obligatory memorials (e.g. St. Pio of Pietrelcina on Sep 23, Sts. Timothy and Titus on Jan 26, St. John Bosco on Jan 31, Sts. Perpetua and Felicity on Mar 7, St. Stanislaus on Apr 11, St. John Baptist de la Salle on Apr 7, North American Martyrs on Oct 19) and popular optional memorials (St. Patrick, St. Josephine Bakhita, Our Lady of Lourdes, Our Lady of Fatima, St. Thomas More, Our Lady of Mount Carmel, St. John Paul II, St. Nicholas). Precedence rule refined so optional memorials do not displace Ordinary Time weekday readings while populating `optionalMemorials` and subtitles.
- [x] **Ascension Thursday provinces** are not supported. Implemented full support for ecclesiastical provinces of Boston, Hartford, New York, Newark, Omaha, and Philadelphia. Added user toggle in `SettingsView` under *Liturgical Calendar*, wired `LiturgicalCalendar` with dynamic `ascensionOnThursday` evaluation, seeded Seventh Sunday of Easter (`easter_sun_7_A`, `easter_sun_7_B`, `easter_sun_7_C`) in `lectionary_seeds.json`, rebuilt `lectionary.json` (980 keys), and added unit test coverage in `LiturgicalCalendarTests`.

### P1 — App Store Submission & TestFlight Monitoring
- [x] **Bump build version to 1.0.0 (Build 18)** for TestFlight beta testing.
- [x] **App Store Connect Store Listing**:
  - Prepared `APP_STORE_LISTING.md` with verified App Name (29 chars), Subtitle (28 chars), Promotional text (154 chars), complete marketing description, keyword string (92 chars), review notes, and 6-slide screenshot specifications.
  - Added dedicated zero-tracking privacy policy document in `PRIVACY.md`.

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
