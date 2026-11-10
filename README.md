# DailyReadings 📖✝️

**DailyReadings** is a Catholic daily Mass readings and liturgical calendar app for iOS, crafted with SwiftUI and Swift 6. Designed with reverent, missal-inspired typography and quiet whitespace, DailyReadings offers a calm, contemplative reading environment for personal prayer and devotion.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)
![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg)
![SwiftData](https://img.shields.io/badge/Storage-SwiftData-green.svg)

---

## Features

- **Daily Mass Readings**:
  - First Reading, Responsorial Psalm with antiphon cue, Second Reading (Sundays/Solemnities), Gospel Acclamation, and the Holy Gospel.
  - Multi-tier offline & online support: online New American Bible (NAB) via Evangelizo API, cached locally in SwiftData, with guaranteed full offline fallback to the complete Douay-Rheims Bible (DRB).
- **Comprehensive Liturgical Engine**:
  - Full implementation of Meeus/Jones/Butcher Computus algorithm for movable feasts.
  - Conforms to the *Universal Norms for the Liturgical Year* and *Proper Calendar for the Dioceses of the United States of America* (USCCB).
  - Accurate season tracking (Advent, Christmas, Ordinary Time, Lent, Triduum, Easter), liturgical cycles (Sundays A/B/C, Weekdays I/II), psalter weeks, ranks, and holy days of obligation.
  - Dynamic liturgical vestment color tinting (White/Gold, Red, Green, Violet, Rose, Black).
- **Interactive Liturgical Calendar**:
  - Month-by-month calendar view with liturgical color dots and feast rankings.
  - Browse past and future daily readings with swipe gestures.
- **Saint of the Day**:
  - Daily saint commemorations with historical era, patronages, and biography.
- **Contemplative Reading Experience**:
  - New York serif typography on scripture paper tone.
  - Pinch-to-zoom and font sizing controls.
  - Full dark mode support.

---

## Architecture

- **Engine Layer**: `LiturgicalCalendar`, `Computus`, `LiturgicalSeason`, `LiturgicalRank`, `LiturgicalColor`, `FixedSolemnities`
- **Data Layer**:
  - `ReadingsRepository`: Multi-tier coordinator (SwiftData cache → Evangelizo API → Douay-Rheims Bible).
  - `BibleDatabase`: SQLite actor querying the bundled Douay-Rheims Bible.
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
