# Privacy Policy for DailyReadings

**Last Updated:** November 12, 2026

DailyReadings ("we", "our", or "the app") is committed to protecting your privacy. This Privacy Policy describes how your information is handled when you use the DailyReadings iOS application.

---

## 1. Zero Personal Data Collection

- **No Account Required:** You do not need to create an account, log in, or provide an email address, phone number, or password to use DailyReadings.
- **No Analytics or Trackers:** DailyReadings contains no third-party tracking frameworks, advertising SDKs, marketing cookies, or user telemetry.
- **No Location Tracking:** We never request, access, or track your physical location or GPS coordinates.

---

## 2. On-Device Storage & Local Preferences

All app settings, preferences, and personal prayer progress are stored strictly on your local device:
- **`UserDefaults`:** Used solely to persist your local reading preferences (such as your chosen scripture translation, font size, line spacing, selected lector voice, and prayer notification times) in full compliance with Apple's `NSPrivacyAccessedAPICategoryUserDefaults` (justification reason `CA92.1`).
- **Devotional Bookmarks:** Passages you bookmark are saved locally on your device via SwiftData and are never transmitted to any external server.

---

## 3. Network Usage

DailyReadings is designed to function 100% offline using bundled Catholic scripture databases and a canonical Computus liturgical algorithm.
- **Online Mass Readings Fetching:** When the New American Bible (NAB) translation is selected, the app connects directly to Evangelizo or official liturgical feeds solely to download the daily Mass scriptures for your personal devotion. No personal identifiers or device telemetry are sent with these requests.
- **Offline Cache:** Downloaded readings are cached locally on your device for up to 90 days so you can pray uninterrupted in church basements, airplanes, or areas with poor cellular service.

---

## 4. Background Audio & Now Playing

The app utilizes Apple's standard system `AVAudioSession` and `MPNowPlayingInfoCenter` to recite Mass readings hands-free during prayer, commutes, or devotion. Audio playback is processed entirely on-device by iOS speech synthesis and system media controls.

---

## 5. Children's Privacy

DailyReadings does not collect personal information from anyone, including children under the age of 13. The app is rated 4+ and contains no objectionable content.

---

## 6. Open Source & Transparency

Our code and privacy disclosures are open and transparent. If you have questions regarding this policy or the application, you can reach out via our GitHub repository:  
[https://github.com/faist23/DailyReadings](https://github.com/faist23/DailyReadings)
