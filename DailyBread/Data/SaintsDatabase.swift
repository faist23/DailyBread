//
//  SaintsDatabase.swift
//  DailyBread
//
//  Created for DailyBread Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// Service for loading, indexing, and querying Catholic saints from the bundled `saints.json` database.
/// Provides fast, synchronous, thread-safe lookups by date, feast day, ID, and keyword.
public final class SaintsDatabase: Sendable {
    /// Shared singleton instance loaded from the main bundle.
    public static let shared = SaintsDatabase()

    /// All loaded saints in alphabetical or source order.
    public let allSaints: [Saint]
    /// Saints indexed by "MM-DD" feast day string (e.g. "11-02").
    private let saintsByFeastDate: [String: [Saint]]
    /// Saints indexed by unique identifier.
    private let saintsById: [String: Saint]

    /// Designated initializer. Loads saints from the specified bundle URL or bundled `saints.json`.
    /// Falls back to embedded prominent saints if the bundled file is missing.
    public init(customURL: URL? = nil) {
        let loadedSaints: [Saint]
        
        let url = customURL ?? Bundle.main.url(forResource: "saints", withExtension: "json")
        if let url, let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Saint].self, from: data) {
            loadedSaints = decoded
        } else {
            // Built-in foundational saints fallback
            loadedSaints = Self.seedSaints
        }

        self.allSaints = loadedSaints
        
        // Build indices
        var byDate: [String: [Saint]] = [:]
        var byId: [String: Saint] = [:]

        for saint in loadedSaints {
            let normalizedDate = Self.normalizeFeastDate(saint.feastDate)
            byDate[normalizedDate, default: []].append(saint)
            byId[saint.id] = saint
        }

        self.saintsByFeastDate = byDate
        self.saintsById = byId
    }

    // MARK: - Query APIs

    /// Returns the primary Saint commemorated on a specific calendar Date.
    public func saint(for date: Date) -> Saint? {
        let key = Self.feastDateKey(from: date)
        return saintsByFeastDate[key]?.first
    }

    /// Returns all saints commemorated on a specific calendar Date.
    public func saints(for date: Date) -> [Saint] {
        let key = Self.feastDateKey(from: date)
        return saintsByFeastDate[key] ?? []
    }

    /// Returns the primary saint for a specific month (1-12) and day (1-31).
    public func saint(forMonth month: Int, day: Int) -> Saint? {
        let key = String(format: "%02d-%02d", month, day)
        return saintsByFeastDate[key]?.first
    }

    /// Returns all saints for a specific month and day.
    public func saints(forMonth month: Int, day: Int) -> [Saint] {
        let key = String(format: "%02d-%02d", month, day)
        return saintsByFeastDate[key] ?? []
    }

    /// Looks up a saint by unique ID.
    public func saint(id: String) -> Saint? {
        saintsById[id]
    }

    /// Searches saints by name, title, or patronage.
    public func search(query: String) -> [Saint] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return allSaints }

        return allSaints.filter { saint in
            if saint.name.lowercased().contains(clean) { return true }
            if let title = saint.title, title.lowercased().contains(clean) { return true }
            if let patronages = saint.patronages, patronages.contains(where: { $0.lowercased().contains(clean) }) {
                return true
            }
            if saint.biography.lowercased().contains(clean) { return true }
            return false
        }
    }

    // MARK: - Helpers

    /// Converts a Gregorian Date into "MM-DD" format.
    public static func feastDateKey(from date: Date) -> String {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return String(format: "%02d-%02d", month, day)
    }

    /// Normalizes a feast date string to two-digit "MM-DD".
    private static func normalizeFeastDate(_ dateString: String) -> String {
        let parts = dateString.split(separator: "-")
        if parts.count == 2, let m = Int(parts[0]), let d = Int(parts[1]) {
            return String(format: "%02d-%02d", m, d)
        }
        return dateString
    }

    // MARK: - Embedded Seed Saints (Guaranteed Fallback)

    private static let seedSaints: [Saint] = [
        Saint(
            id: "all_souls",
            name: "The Commemoration of All the Faithful Departed (All Souls)",
            feastDate: "11-02",
            title: "Commemoration of the Universal Church",
            era: "11th Century (Abbey of Cluny)",
            biography: "The Church commemorates all who have died in the peace of Christ, offering prayers, alms, and the Holy Sacrifice of the Mass for the purification of souls in Purgatory so they may enter into the joy of the Heavenly Kingdom.",
            patronages: ["Holy Souls in Purgatory"],
            imageURL: nil
        ),
        Saint(
            id: "all_saints",
            name: "Solemnity of All Saints",
            feastDate: "11-01",
            title: "Solemnity",
            era: "Early Church",
            biography: "A solemn feast celebrating the communion of saints, honoring all holy men and women who have entered Heaven, recognized and unrecognized, who stand before the throne of God in eternal adoration.",
            patronages: ["The Church Triumphant"],
            imageURL: nil
        ),
        Saint(
            id: "augustine_hippo",
            name: "St. Augustine of Hippo",
            feastDate: "08-28",
            title: "Bishop and Doctor of the Church",
            era: "Early Church (354-430 AD)",
            biography: "Converted through the relentless prayers of his mother St. Monica, Augustine became Bishop of Hippo and one of the greatest theologians of the Latin Church, authoring the Confessions and The City of God.",
            patronages: ["Theologians", "Printers", "Brewers"],
            imageURL: nil
        ),
        Saint(
            id: "thomas_aquinas",
            name: "St. Thomas Aquinas",
            feastDate: "01-28",
            title: "Priest and Doctor of the Church (Doctor Angelicus)",
            era: "13th Century (1225-1274)",
            biography: "Dominican friar and master of scholastic philosophy, Thomas Aquinas harmonized faith and reason. His masterpiece, the Summa Theologiae, remains the bedrock of Catholic theology.",
            patronages: ["Academics", "Theologians", "Students", "Catholic Schools"],
            imageURL: nil
        ),
        Saint(
            id: "francis_assisi",
            name: "St. Francis of Assisi",
            feastDate: "10-04",
            title: "Religious Founder",
            era: "13th Century (1181-1226)",
            biography: "Renouncing his family's wealth, Francis embraced radical evangelical poverty, founded the Franciscan Order, received the sacred stigmata, and radiated Christ's peace to all of creation.",
            patronages: ["Ecology", "Animals", "Italy", "Peace"],
            imageURL: nil
        ),
        Saint(
            id: "joseph_spouse",
            name: "St. Joseph, Spouse of the Blessed Virgin Mary",
            feastDate: "03-19",
            title: "Patron of the Universal Church",
            era: "1st Century",
            biography: "The chaste spouse of Mary and foster father of Jesus Christ, St. Joseph was a righteous carpenter of Nazareth who quietly and faithfully protected the Holy Family.",
            patronages: ["Universal Church", "Fathers", "Workers", "A Happy Death"],
            imageURL: nil
        ),
        Saint(
            id: "therese_lisieux",
            name: "St. Thérèse of Lisieux",
            feastDate: "10-01",
            title: "Virgin and Doctor of the Church",
            era: "19th Century (1873-1897)",
            biography: "Carmelite nun known as the 'Little Flower,' she taught the 'Little Way' of spiritual childhood—seeking holiness through doing small, ordinary actions with extraordinary love for Jesus.",
            patronages: ["Missions", "Florists", "Pilots", "Tuberculosis patients"],
            imageURL: nil
        )
    ]
}
