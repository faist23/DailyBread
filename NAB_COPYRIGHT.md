# NAB Copyright and Translation Options

**Researched:** 2026-11-12
**Status:** research notes, not legal advice. Only a written answer from the rights holder settles this.

## Summary

DailyReadings cannot currently get permission to display New American Bible (NAB/NABRE) text. The rights holder requires a license for any app, free or paid, and has stopped granting digital permissions for the NABRE until its successor translation is published in 2027.

Fetching the text from Evangelizo instead of bundling it does not change this. The claim in `ARCHITECTURE.md` §4.2 that the online tier handles copyright "legally" is not supported by anything found.

## Who owns what

| Text | Owner |
| :--- | :--- |
| New American Bible, revised edition (NABRE) | Confraternity of Christian Doctrine (CCD), administered through the USCCB |
| Lectionary for Mass (US), including psalm responses as printed | CCD |
| Other Mass texts | International Commission on English in the Liturgy (ICEL) |
| Douay-Rheims (Challoner revision) | Public domain |

## What the USCCB policy says

From the USCCB New American Bible permissions page, read 2026-11-12:

- **Apps need a license.** "Digital applications for sale or for free distribution require a license and a royalty payment or permissions fee."
- **Digital licenses are closed.** "Given the anticipated 2027 publication of the Catholic American Bible, digital permissions are no longer being granted for the NABRE. Digital licensing for the Catholic American Bible is not yet open." The page links a waitlist form for Catholic American Bible (CAB) digital permissions.
- **Lectionary threshold.** Permission is required for any use over 5,000 words from the Lectionary, or any use that reprints more than 40% of the readings for a rite or season. A daily-readings app passes this within weeks.
- **NABRE threshold.** Under 5,000 words needs no permission in print, sound or eBook formats, if it is under 40% of a single Bible book and under 40% of the new work. Web and digital use is handled separately, under the rules above.
- **Audio.** "Permission may not be granted to podcast the complete NAB (or complete books of the NAB) or the daily or Sunday readings." Text-to-speech of NAB readings sits close to this.
- **RSS exemption.** No permission or fee is needed to display the daily readings RSS feed on a website that does not charge users. This covers websites, not apps.
- **Linking is free.** An older version of the policy states that no permission is needed to create an unframed link to the NAB or the readings as posted on usccb.org.
- **Text integrity.** Where use is permitted, text must be verbatim, verse structure preserved, and the CCD acknowledgment printed.

**Contact:** Associate Director, Permissions, CCD, 3211 Fourth Street NE, Washington, DC 20017-1194. Email `nabperm@usccb.org`, phone 202-541-3098.

## What Evangelizo offers

- No terms of use or developer documentation were found for `publication.evangelizo.ws`. It appears to be the private backend for Evangelizo's own website and apps.
- Evangelizo's documented route for third parties is the "Reader" feed, described as a way to put their content on an external website.
- Their legal notice is a privacy policy and says nothing about reuse of content.
- The API response itself carries the notice "Copyright © Confraternity of Christian Doctrine". Nothing found suggests Evangelizo can pass its NAB rights on to another app.
- The `AM` feed identifies itself as "English (Roman Ordinary calendar)". That is the universal calendar, not the US one, so its readings can differ from the app's USCCB calendar on days such as Epiphany and Ascension.

## Exposure in the current codebase

| Area | File | Issue |
| :--- | :--- | :--- |
| Online NAB fetch and display | `Data/EvangelizioService.swift` | Displays NAB text with no license |
| 30-day prefetch and cache | `Data/ReadingsRepository.swift`, `Models/CachedReading.swift` | Stores NAB text on device |
| Audio recitation of NAB readings | `Data/AudioReadingPlayer.swift` | Close to the podcast restriction |
| Bundled psalm refrains | `Data/PsalmResponseProvider.swift`, seed entries in `Data/PericoreIndex.swift` | Lectionary text shipped in the binary |
| Missing attribution | all reading views | The CCD notice in the API payload is never shown |
| Architecture claim | `ARCHITECTURE.md` §4.2 | States the online tier is the legal route |

Scripture citations (book, chapter, verse lists) are references rather than translated text and carry much lower risk than the readings themselves. This has not been confirmed with the rights holder.

## Recommended path for 1.0

1. Ship with public-domain text only, in app and in audio: WEB-C as the default, Douay-Rheims as the traditional option (see "Recommended translation setup" below).
2. Add a per-day link to the NAB readings on usccb.org. `lectionary_dates.json` already holds the `bible.usccb.org` URL for each date.
3. Remove the Evangelizo fetch, the 30-day prefetch and NAB audio.
4. Replace the bundled Lectionary refrains with refrains taken from the public-domain translation, or get them cleared.
5. Email `nabperm@usccb.org` describing the app, and join the CAB digital permissions waitlist.
6. Correct `ARCHITECTURE.md` §4.2 once the approach is decided.

## Free translations to use instead

| Translation | Licence | Style | Fit |
| :--- | :--- | :--- | :--- |
| **World English Bible, Catholic edition (WEB-C)** | Public domain; the name "World English Bible" is a trademark, so altered text must not use it | Modern American English, US spelling | Closest free match to the NAB register |
| Catholic Public Domain Version (CPDV) | Public domain | Modern English, literal from the Latin Vulgate | Reads closer to Douay-Rheims than to the NAB; its translator notes it is not Church-approved |
| Douay-Rheims (already bundled) | Public domain | 18th-century English | Traditional, not NAB-like |

Notes on WEB-C:

- It uses the Catholic book set and order, and includes the Greek additions to Esther and Daniel.
- It renders the divine name as "LORD" or "GOD", following Catholic liturgical practice.
- It uses Hebrew psalm numbering (Psalm 23 is "The LORD is my shepherd"), the same numbering the Lectionary citations use. The bundled Douay-Rheims uses Vulgate numbering, which is the cause of the wrong-psalm bug found in the audit.
- eBible.org publishes it in USFM, USFX, plain text and a VPL + SQL package, so building a SQLite file like `bible_drb.sqlite` is straightforward.
- It is a Protestant-origin translation (a revision of the 1901 American Standard Version) with no imprimatur. It is fine for private reading; it is not a liturgical text and the app should not present it as one.

Sample of the WEB-C register:

- Psalm 23:1: "The LORD is my shepherd; I shall lack nothing."
- Matthew 6:33: "But seek first God's Kingdom and his righteousness; and all these things will be given to you as well."

### Recommended translation setup

1. **WEB-C as the default modern translation**, replacing the NAB tier. It is bundled, so it works fully offline with no network fetch, prefetch or cache.
2. **Douay-Rheims kept as the traditional option.** It still needs the Hebrew-to-Vulgate psalm mapping and the chapter fixes for Joel and Malachi from the audit.
3. **A per-day "Read the NAB readings at USCCB" link** for users who want the liturgical text.
4. **Label the in-app text honestly**, for example "World English Bible (Catholic edition), public domain. Not the liturgical text read at Mass."
5. Revisit licensed text when Catholic American Bible digital licensing opens.

Modern Catholic translations that are **not** free: NABRE, RSV-CE and RSV-2CE, NRSV-CE, ESV-CE, Jerusalem and New Jerusalem Bible, Good News Catholic edition. All need a license from their publishers.

## Sources

- USCCB, New American Bible permissions: https://www.usccb.org/offices/new-american-bible/permissions
- USCCB, Permissions Policy (older page): https://www.usccb.org/es/node/48245
- USCCB, Guidelines for the publication of liturgical books: https://www.usccb.org/committees/divine-worship/policies/guidelines-for-the-publication-of-liturgical-books
- Evangelizo feeds and Reader: https://feed.evangelizo.org/
- Evangelizo Reader documentation: https://feed.evangelizo.org/v2/reader.php
- Daily Gospel legal notice: https://dailygospel.org/AM/legal-notice
- World English Bible (Catholic), eBible.org: https://ebible.org/eng-web-c/
- WEB-C details and downloads: https://ebible.org/find/details.php?id=eng-web-c
- Catholic Public Domain Version: https://sacredbible.org/
