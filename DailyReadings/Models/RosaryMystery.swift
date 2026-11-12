//
//  RosaryMystery.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import Foundation

/// The four sets of Mysteries of the Most Holy Rosary.
public enum RosaryMysteryType: String, CaseIterable, Identifiable, Sendable {
    case joyful = "Joyful Mysteries"
    case sorrowful = "Sorrowful Mysteries"
    case glorious = "Glorious Mysteries"
    case luminous = "Luminous Mysteries"
    
    public var id: String { rawValue }
    
    /// Traditional days of the week assigned by the Church and Pope St. John Paul II.
    public var traditionalDays: String {
        switch self {
        case .joyful: return "Mondays & Saturdays"
        case .sorrowful: return "Tuesdays & Fridays"
        case .glorious: return "Wednesdays & Sundays"
        case .luminous: return "Thursdays"
        }
    }
    
    /// Determines the appropriate mystery set for a given calendar date.
    public static func forDate(_ date: Date = .now) -> RosaryMysteryType {
        let weekday = Calendar.current.component(.weekday, from: date)
        // 1 = Sunday, 2 = Monday, 3 = Tuesday, 4 = Wednesday, 5 = Thursday, 6 = Friday, 7 = Saturday
        switch weekday {
        case 2, 7: // Monday, Saturday
            return .joyful
        case 3, 6: // Tuesday, Friday
            return .sorrowful
        case 5: // Thursday
            return .luminous
        case 1, 4: // Sunday, Wednesday
            return .glorious
        default:
            return .joyful
        }
    }
}

/// A single decade of the Holy Rosary.
public struct RosaryDecade: Identifiable, Sendable {
    public let id: Int
    public let number: String
    public let title: String
    public let fruitOfMystery: String
    public let scriptureRef: String
    public let meditation: String
    
    public init(
        number: String,
        title: String,
        fruitOfMystery: String,
        scriptureRef: String,
        meditation: String
    ) {
        self.id = Int(number.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)) ?? 1
        self.number = number
        self.title = title
        self.fruitOfMystery = fruitOfMystery
        self.scriptureRef = scriptureRef
        self.meditation = meditation
    }
}
