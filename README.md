# DailyReadings 📖✝️

**DailyReadings** is a Catholic daily Mass readings and liturgical calendar app for iOS, crafted with SwiftUI and Swift 6. Designed with reverent, missal-inspired typography and quiet whitespace, DailyReadings offers a calm, contemplative reading environment for personal prayer and devotion.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg)
![SwiftData](https://img.shields.io/badge/Storage-SwiftData-green.svg)

---

## Features

- **Daily Mass Readings**:
  - First Reading, Responsorial Psalm with antiphon banner and stanza response cues, Second Reading (Sundays/Solemnities), Gospel Acclamation, and the Holy Gospel.
  - Multi-tier translation matrix:
    - **World English Bible (Catholic Edition, WEB-C)**: Default modern English translation (public domain, complete 73-book Catholic canon, offline SQLite).
    - **Douay-Rheims Bible (DRB)**: Traditional English translation (Challoner revision 1752, Latin Vulgate with Hebrew lectionary psalm mapping, offline SQLite).
    - **New American Bible (NAB/NABRE)**: Optional liturgical text for testing via Evangelizo online feed with 30-day SwiftData caching, CCD attribution, and direct USCCB readings links.
- **Liturgical Verse of the Day**:
  - Morning focus hero card anchored directly in the day's Mass readings (Gospel Acclamation, Gospel, or Psalm antiphon).
  - One-tap clipboard copy and native share actions.
- **Treasury of Catholic Prayers & Interactive Holy Rosary**:
  - Dedicated Prayers tab with categorized devotions: Daily Rhythm (Morning Offering, Angelus, Regina Caeli, Evening Examen, Compline), Foundational (Our Father, Hail Mary, Creeds), Marian, and Saints & Protection (St. Michael, Anima Christi, St. Francis).
  - Traditional Latin and English texts with side-by-side / toggle view.
  - Built-in text-to-speech recitation in both Latin and English.
  - **"How to Pray the Rosary" Tutorial**: Sequential 6-step beginner's guide, bead anatomy, weekly mystery rhythm, and contemplative spiritual advice.
  - **Interactive Bead-by-Bead Guided Companion**: Tap-to-advance prayer screen with active decade bead tracker (10 beads), scripture meditations, full prayer text in New York serif, gentle haptic feedback on each counted bead, and audio recitation.
  - Automatic day-of-week mystery detection (Joyful, Sorrowful, Glorious, Luminous) with scripture references and decade meditations.
- **Personal Devotions & Bookmarking**:
  - One-tap scripture passage bookmarks on all reading cards and detail views.
  - Dedicated Bookmarks collection screen in Settings with full-screen reading access.
- **Holy Days of Obligation Vigil Alerts**:
  - Canon Law and USCCB abrogation rule evaluation for non-Sunday obligations.
  - 7:00 PM evening vigil push notifications and prominent banners on Today's view.
- **Comprehensive Liturgical Engine**:
  - Full implementation of Meeus/Jones/Butcher Computus algorithm for movable feasts.
  - Conforms to the *Universal Norms for the Liturgical Year* and *Proper Calendar for the Dioceses of the United States of America* (USCCB).
  - Accurate season tracking (Advent, Christmas, Ordinary Time, Lent, Triduum, Easter), liturgical cycles (Sundays A/B/C, Weekdays I/II), psalter weeks, ranks, and holy days of obligation.
  - Dynamic liturgical vestment color tinting (White/Gold, Red, Green, Violet, Rose, Black).
- **Interactive Liturgical Calendar**:
  - Month-by-month calendar view with liturgical color dots and feast rankings.
  - Browse past and future daily readings with swipe gestures.
- **Saint of the Day**:
  - Daily saint commemorations with historical era, patronages, and biography (expanded view with liturgical context by default).
- **Reverent Audio Recitation**:
  - Continuous, sequential text-to-speech recitation of all Mass readings with proper liturgical announcements, responses, and acclamations.
  - Background audio playback using `AVAudioSession` (`.playback` / `.spokenAudio`) and `UIBackgroundModes` audio capability.
  - Lock Screen & Control Center Now Playing integration (`MPNowPlayingInfoCenter`, `MPRemoteCommandCenter`) with dynamic illuminated liturgical missal artwork matching vestment seasons.
  - Floating mini-player bar for uninterrupted devotional listening.
  - Natural, modern voice engine (Daniel British lectionary voice, Samantha, Ava, Moira, Karen) with support for Apple's high-definition Enhanced and Premium Studio neural voices.
  - In-app Voice Selector and Pacing control in Settings with live preview auditions.
- **Contemplative Reading Experience**:
  - New York serif typography on scripture paper tone.
  - Pinch-to-zoom and font sizing controls.
  - Full dark mode support.

---

## Architecture

- **Engine Layer**: `LiturgicalCalendar`, `Computus`, `LiturgicalSeason`, `LiturgicalRank`, `LiturgicalColor`, `FixedSolemnities`
- **Data Layer**:
  - `ReadingsRepository`: Multi-tier coordinator (WEB-C default offline → Douay-Rheims traditional offline → optional NAB online with SwiftData cache).
  - `VerseOfTheDayProvider`: Dynamically derives daily scripture focus from active Mass readings.
  - `PrayersRepository`: Offline treasury of categorized traditional prayers and Rosary decade meditations.
  - `PsalmResponseProvider`: Canonical Lectionary psalter response provider covering all 150 Psalms and Biblical Canticles.
  - `BookmarkManager`: Devotional scripture bookmarks coordinator with JSON persistence.
  - `BibleDatabase`: SQLite actor querying bundled Catholic Bibles (`bible_webc.sqlite` for WEB-C, `bible_drb.sqlite` for Douay-Rheims).
  - `PericoreIndex`: Maps liturgical days and calendar dates (2023–2027) to lectionary citations.
  - `SaintsDatabase`: Bundled saints database indexed by feast date.
- **UI Layer**: Modern iOS 17 `@Observable` view models (`TodayViewModel`, `CalendarViewModel`) and declarative SwiftUI views.

---

## Requirements

- iOS 17.0+
- Xcode 16.0+
- Swift 6.0+

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/faist23/DailyReadings.git
   cd DailyReadings
   ```

2. Open the Xcode project:
   ```bash
   open DailyReadings.xcodeproj
   ```

3. Select your target simulator (e.g. iPhone 16) and press **Run** (⌘R).
