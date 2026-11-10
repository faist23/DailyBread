//
//  LiturgicalColor.swift
//  DailyReadings
//
//  Created for DailyReadings.
//  Copyright © 2026 DailyReadings. All rights reserved.
//

import SwiftUI

/// Represents the canonical liturgical colors prescribed by the General Instruction of the Roman Missal (GIRM 346).
///
/// Liturgical colors visually express the characteristic mystery of the Christian faith being celebrated,
/// or a sense of Christian life's passage through the course of the liturgical year.
public enum LiturgicalColor: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    /// White (and Gold): Signifies purity, joy, glory, and resurrection.
    /// Used in the seasons of Easter and Christmas; on celebrations of the Lord (other than His Passion);
    /// on celebrations of Mary, the angels, and saints who were not martyrs; All Saints; etc.
    case white

    /// Red: Signifies the fire of the Holy Spirit and the blood of Christ and martyrs.
    /// Used on Palm Sunday, Good Friday, Pentecost Sunday, celebrations of the Lord's Passion,
    /// and the feast days of the Apostles, Evangelists, and Martyrs.
    case red

    /// Green: Signifies hope, spiritual growth, and life.
    /// Used in Ordinary Time on days with no proper feast.
    case green

    /// Violet / Purple: Signifies penance, preparation, sorrow, and expectation.
    /// Used in Advent and Lent; may also be used in Masses for the Dead.
    case violet

    /// Rose: Signifies joyful anticipation in the midst of penitential seasons.
    /// May be used on Gaudete Sunday (Third Sunday of Advent) and Laetare Sunday (Fourth Sunday of Lent).
    case rose

    /// Black: Signifies solemn mourning and grief.
    /// May be used in Masses for the Dead and on All Souls' Day (Nov 2).
    case black

    // MARK: - Identifiable

    public var id: String {
        rawValue
    }

    // MARK: - Display Name

    /// The human-readable name of the liturgical color.
    public var displayName: String {
        switch self {
        case .white:
            return "White"
        case .red:
            return "Red"
        case .green:
            return "Green"
        case .violet:
            return "Violet"
        case .rose:
            return "Rose"
        case .black:
            return "Black"
        }
    }

    /// Theological meaning and occasions for use in the liturgy.
    public var meaning: String {
        switch self {
        case .white:
            return "Light, innocence, purity, joy, triumph, and glory; celebrating the Resurrection, Christmas, and non-martyred saints."
        case .red:
            return "Passion, blood, fire, God's love, and the Holy Spirit; celebrating martyrs, apostles, and Pentecost."
        case .green:
            return "The Holy Spirit, life eternal, hope, and spiritual renewal; celebrated during Ordinary Time."
        case .violet:
            return "Penance, humility, sorrow, and contemplative preparation; used in Advent and Lent."
        case .rose:
            return "Joy and rejoice amidst penitential seasons; used on Gaudete and Laetare Sundays."
        case .black:
            return "Mourning, grief, and praying for the departed; optionally used on All Souls' Day and funerals."
        }
    }

    // MARK: - SwiftUI Color Palette

    /// The primary SwiftUI color shade suited for liturgical display in user interfaces.
    /// Uses rich, traditional church vestment tones.
    public var swiftUIColor: Color {
        switch self {
        case .white:
            // Warm ivory / creamy gold-white with high readability
            return Color(red: 0.96, green: 0.95, blue: 0.92)
        case .red:
            // Rich rubrical crimson / deep scarlet
            return Color(red: 0.77, green: 0.12, blue: 0.16)
        case .green:
            // Dignified liturgical emerald / forest green
            return Color(red: 0.12, green: 0.52, blue: 0.31)
        case .violet:
            // Deep royal imperial purple / liturgical violet
            return Color(red: 0.44, green: 0.16, blue: 0.56)
        case .rose:
            // Warm antique liturgical rose (subtle dusty pink/rose)
            return Color(red: 0.84, green: 0.46, blue: 0.58)
        case .black:
            // Dignified charcoal liturgical black
            return Color(red: 0.16, green: 0.16, blue: 0.18)
        }
    }

    /// A secondary accent shade for borders, highlights, and gradients.
    public var accentColor: Color {
        switch self {
        case .white:
            // Liturgical burnished gold accent
            return Color(red: 0.85, green: 0.73, blue: 0.38)
        case .red:
            return Color(red: 0.95, green: 0.28, blue: 0.30)
        case .green:
            return Color(red: 0.25, green: 0.68, blue: 0.44)
        case .violet:
            return Color(red: 0.62, green: 0.33, blue: 0.76)
        case .rose:
            return Color(red: 0.94, green: 0.63, blue: 0.72)
        case .black:
            return Color(red: 0.38, green: 0.38, blue: 0.42)
        }
    }

    /// Text color providing maximum contrast when displayed on a badge or banner of this liturgical color.
    public var onSurfaceTextColor: Color {
        switch self {
        case .white:
            return Color(red: 0.18, green: 0.16, blue: 0.14)
        case .red, .green, .violet, .black:
            return .white
        case .rose:
            return Color(red: 0.22, green: 0.10, blue: 0.14)
        }
    }

    /// Hex color string for web, CSS, or serialization.
    public var hexString: String {
        switch self {
        case .white:
            return "#F5F2EB"
        case .red:
            return "#C41F29"
        case .green:
            return "#1F854F"
        case .violet:
            return "#70298F"
        case .rose:
            return "#D67694"
        case .black:
            return "#29292E"
        }
    }

    /// Appropriate SF Symbol icon representing this color or celebration.
    public var symbolIconName: String {
        switch self {
        case .white:
            return "sun.max.fill"
        case .red:
            return "flame.fill"
        case .green:
            return "leaf.fill"
        case .violet:
            return "cross.fill"
        case .rose:
            return "sparkles"
        case .black:
            return "moon.fill"
        }
    }
}
