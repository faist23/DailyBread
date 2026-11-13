# App Store Connect Store Listing Assets — DailyReadings

This document contains all verified text, metadata, keywords, URLs, and guidelines required for creating and submitting the App Store listing in App Store Connect.

---

## 1. App Information

| Field | Value | Character Limit / Requirement |
| :--- | :--- | :--- |
| **App Name** | `DailyReadings: Catholic Missal` | 30 characters (Exact: 29 characters) |
| **Alternative App Name** | `DailyReadings — Catholic Mass` | 30 characters (Exact: 30 characters) |
| **Subtitle** | `Catholic Daily Mass Readings` | 30 characters (Exact: 28 characters) |
| **Bundle ID** | `com.ridepro.DailyReadings` | Must match Xcode Target |
| **SKU** | `DAILYREADINGS_IOS_001` | Unique internal identifier |
| **Primary Category** | `Reference` (or `Books`) | App Store Category |
| **Secondary Category** | `Lifestyle` | App Store Category |
| **Content Rights** | Does not contain third-party content without permission | Confirmation in App Store Connect |
| **Age Rating** | `4+` | No objectionable or mature content |

---

## 2. Promotional Text & Description

### Promotional Text (170 characters max)
> Contemplative Catholic daily Mass readings, liturgical calendar, reverent audio recitation, and Holy Rosary companion. 100% offline capable with zero tracking.

*(Exact: 154 characters)*

### Full Marketing Description (4,000 characters max)
```markdown
Enter into daily prayer with DailyReadings, a contemplative Catholic companion for Mass readings, the Roman Liturgical Calendar, and traditional devotions.

Designed with missal-inspired New York serif typography, warm scripture paper backgrounds, and subtle gold liturgical accents, DailyReadings offers a reverent, distraction-free sanctuary for personal devotion, morning commutes, and Eucharistic preparation.

KEY FEATURES:

• DAILY MASS READINGS
Receive the complete readings for daily and Sunday Mass:
- First Reading
- Responsorial Psalm with liturgical antiphon response refrains
- Second Reading (Sundays and Solemnities)
- Gospel Acclamation
- Holy Gospel

• REVERENT AUDIO LECTOR
Listen hands-free to daily Mass readings recited in a reverent, dignified cadence. Supports uninterrupted background recitation, Apple Studio and neural voices, pace adjustments, lock screen controls, and dynamically illuminated missal artwork.

• 100% OFFLINE CAPABLE
Never lose access to scripture in church basements, airplanes, or rural retreats. DailyReadings includes a complete offline Computus liturgical calendar engine through 2031 and bundled Catholic Bible translations.

• TRUSTED CATHOLIC TRANSLATIONS
- World English Bible (Catholic Edition, WEB-C): Modern, clear public domain translation containing all 73 Catholic canonical books.
- Douay-Rheims (Challoner Revision, 1752): The venerable, traditional English translation from the Latin Vulgate. Fully offline.
- New American Bible (NAB/NABRE): Automatic 30-day pre-fetching and offline caching for US dioceses.

• CANONICAL LITURGICAL CALENDAR
- Automatically computes liturgical seasons: Advent, Christmas, Lent, Paschal Triduum, Easter, and Ordinary Time.
- Reflects canonical vestment colors: White/Gold, Violet, Green, Red, and Rose.
- Universal Norms for the Liturgical Year (UNLY §59) collision resolution and transferred solemnities.
- Holy Days of Obligation notifications and vigil banners with Canon Law abrogation rules.
- Support for Ascension Thursday provinces (Boston, Hartford, New York, Newark, Omaha, Philadelphia).

• HOLY ROSARY & NOVICE COMPANION
- Interactive bead-by-bead guided Rosary with 10-dot decade progress tracking and gentle haptics.
- Automated day-of-week mystery detection (Joyful, Luminous, Sorrowful, Glorious).
- Beginner tutorial explaining prayers, bead anatomy, and contemplative meditation advice.

• CATHOLIC TREASURY OF PRAYERS
Over 25 traditional prayers categorized by Daily Rhythm, Foundational, Marian, and Saints & Protection, featuring a side-by-side Latin and English toggle and bilingual audio recitation.

• COMPLETE PRIVACY & RESPECT
- No account or login required
- Zero advertisements, zero third-party tracking, zero data collection
- Adheres strictly to Apple's Privacy Manifest standards
```

---

## 3. App Store Search Keywords (100 characters max)

> `catholic,mass,readings,daily,lectionary,bible,missal,rosary,prayers,liturgical,calendar,gospel,usccb`

*(Exact: 92 characters, comma-separated, no spaces)*

---

## 4. Support & Marketing URLs

| URL Field | Target Address |
| :--- | :--- |
| **Support URL** | `https://github.com/faist23/DailyReadings/issues` |
| **Marketing URL** | `https://github.com/faist23/DailyReadings` |
| **Privacy Policy URL** | `https://github.com/faist23/DailyReadings/blob/main/PRIVACY.md` |

---

## 5. App Review Information & Notes for Reviewers

- **Sign-in Required:** `No` (The app is fully accessible without any user account, login, or subscription).
- **Contact Information:** `Craig Faist` / `cdfaist@yahoo.com`
- **Notes for App Reviewer:**
  > DailyReadings is a Catholic daily Mass readings and liturgical calendar application.
  >
  > 1. Offline Mode: The app includes a bundled local SQLite Catholic Bible database (Douay-Rheims) and an algorithmic Computus liturgical calendar, allowing 100% functionality without an active network connection.
  > 2. Audio Playback: The app uses `AVSpeechSynthesizer` and `AVAudioSession` (`.playback`, mode: `.spokenAudio`) to recite Mass readings hands-free. Background audio capability is declared in `Info.plist` under `UIBackgroundModes = ["audio"]` and integrates with `MPNowPlayingInfoCenter` and remote lock screen commands.
  > 3. Privacy Manifest: The application includes `PrivacyInfo.xcprivacy` declaring `NSPrivacyAccessedAPICategoryUserDefaults` under justification reason `CA92.1` for persisting user preferences (such as scripture font size, translation choice, and reminder alarms) locally on device. No tracking or third-party analytics SDKs are used.

---

## 6. App Store Screenshot Requirements

Screenshots must be provided for both required iPhone display sizes:

### 1. 6.7" Super Retina XDR (iPhone 16 Pro Max / 15 Pro Max)
- **Pixel Resolution:** `1290 x 2796` (portrait)
- **Format:** JPEG or PNG, 24-bit RGB, 72 dpi, no transparency.

### 2. 6.5" Super Retina HD (iPhone 11 Pro Max / XS Max)
- **Pixel Resolution:** `1242 x 2688` (portrait)
- **Format:** JPEG or PNG, 24-bit RGB, 72 dpi, no transparency.

### Recommended 6-Screenshot Sequence & Headlines

1. **Screenshot 1 — Today's Readings**
   - *View:* `TodayView` showing the illuminated Verse of the Day hero card, First Reading card, and liturgical gold header.
   - *Headline:* **Daily Catholic Mass Readings**
   - *Subline:* *Complete Lectionary scriptures for every day of the liturgical year.*

2. **Screenshot 2 — Responsorial Psalm & Antiphon**
   - *View:* `PsalmView` displaying the missal-styled red "℟." rubric, prominent antiphon banner, and double-spaced stanzas.
   - *Headline:* **Official Responsorial Psalms**
   - *Subline:* *Canonical antiphons and stanzas formatted for contemplative prayer.*

3. **Screenshot 3 — Reverent Audio Recitation**
   - *View:* Lock Screen Now Playing illuminated missal artwork with playback controls and floating Mini Player.
   - *Headline:* **Hands-Free Audio Recitation**
   - *Subline:* *Continuous spoken word playback with natural neural lector voices.*

4. **Screenshot 4 — Canonical Liturgical Calendar**
   - *View:* `CalendarView` displaying the monthly grid with liturgical color dots (White/Gold, Green, Violet, Red), feast rankings, and holy days.
   - *Headline:* **Roman Liturgical Calendar**
   - *Subline:* *Universal Norms precedence engine with Holy Day of Obligation alerts.*

5. **Screenshot 5 — Interactive Guided Rosary**
   - *View:* `GuidedRosaryView` displaying the 10-dot decade tracker, mystery meditation card, and scripture reflection.
   - *Headline:* **Interactive Holy Rosary**
   - *Subline:* *Bead-by-bead prayer companion with scripture reflections and haptics.*

6. **Screenshot 6 — Treasury of Catholic Prayers**
   - *View:* `PrayerDetailView` showing the Latin & English side-by-side toggle and bilingual audio recitation.
   - *Headline:* **Treasury of Catholic Prayers**
   - *Subline:* *Traditional devotions in Latin and English, available 100% offline.*
