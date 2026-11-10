//
//  LiturgicalColors.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Maps Catholic liturgical colors to SwiftUI colors with a calm, contemplative palette.
///
/// Each color is balanced to evoke sacred dignity without being jarring or overly bright.
/// Tints and gradients are provided for card backgrounds, badges, and header stripes.
public struct LiturgicalColors {
    
    // MARK: - Core Palette
    
    /// Warm, life-affirming liturgical green (Ordinary Time, spiritual growth).
    public static let green = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 58 / 255, green: 142 / 255, blue: 64 / 255, alpha: 1.0)
                : UIColor(red: 46 / 255, green: 125 / 255, blue: 50 / 255, alpha: 1.0)
        }
    )
    
    /// Rich, deep Roman purple/violet (Advent, Lent, penance and preparation).
    public static let violet = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 128 / 255, green: 64 / 255, blue: 154 / 255, alpha: 1.0)
                : UIColor(red: 92 / 255, green: 34 / 255, blue: 114 / 255, alpha: 1.0)
        }
    )
    
    /// Off-white / cream for backgrounds (Easter, Christmas, Solemnities of the Lord & Saints).
    public static let whiteBackground = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 36 / 255, green: 36 / 255, blue: 38 / 255, alpha: 1.0)
                : UIColor(red: 252 / 255, green: 250 / 255, blue: 245 / 255, alpha: 1.0)
        }
    )
    
    /// Pure radiant white for icons and highlights.
    public static let whiteIcon = Color.white
    
    /// Warm gold accent used alongside white for solemn feasts.
    public static let goldAccent = Color(red: 205 / 255, green: 155 / 255, blue: 50 / 255)
    
    /// Deep crimson red (Pentecost, Passion Sunday, Good Friday, Apostles & Martyrs).
    public static let red = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 198 / 255, green: 40 / 255, blue: 40 / 255, alpha: 1.0)
                : UIColor(red: 172 / 255, green: 28 / 255, blue: 28 / 255, alpha: 1.0)
        }
    )
    
    /// Warm rose/pink (Gaudete Sunday in Advent, Laetare Sunday in Lent).
    public static let rose = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 218 / 255, green: 124 / 255, blue: 146 / 255, alpha: 1.0)
                : UIColor(red: 198 / 255, green: 105 / 255, blue: 128 / 255, alpha: 1.0)
        }
    )
    
    /// Near-black / dark charcoal (All Souls' Day, Masses for the Dead).
    public static let black = Color(
        uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 45 / 255, green: 45 / 255, blue: 50 / 255, alpha: 1.0)
                : UIColor(red: 32 / 255, green: 32 / 255, blue: 36 / 255, alpha: 1.0)
        }
    )
    
    // MARK: - Background Tints
    
    /// Light background tint for card surfaces corresponding to each color.
    public static func cardBackgroundTint(for color: LiturgicalColor) -> Color {
        switch color {
        case .green:
            return green.opacity(0.06)
        case .violet:
            return violet.opacity(0.07)
        case .white:
            return goldAccent.opacity(0.05)
        case .red:
            return red.opacity(0.06)
        case .rose:
            return rose.opacity(0.07)
        case .black:
            return black.opacity(0.05)
        }
    }
    
    /// Badge background tint (soft pill background).
    public static func badgeBackgroundTint(for color: LiturgicalColor) -> Color {
        switch color {
        case .green:
            return green.opacity(0.12)
        case .violet:
            return violet.opacity(0.13)
        case .white:
            return goldAccent.opacity(0.12)
        case .red:
            return red.opacity(0.12)
        case .rose:
            return rose.opacity(0.13)
        case .black:
            return black.opacity(0.12)
        }
    }
}

// MARK: - LiturgicalColor Extension

public extension LiturgicalColor {
    /// Foreground accent color suitable for text, badges, borders, and UI highlights.
    /// Uses warm liturgical gold for white feasts to ensure optimal legibility and reverent beauty.
    var uiAccentColor: Color {
        switch self {
        case .white:
            return LiturgicalColors.goldAccent
        case .black:
            return Color.primary
        default:
            return swiftUIColor
        }
    }

    /// Icon color for display against colored backgrounds or headers.
    var iconColor: Color {
        switch self {
        case .white:
            return LiturgicalColors.whiteIcon
        default:
            return swiftUIColor
        }
    }
    
    /// A delicate background tint for cards, providing peaceful liturgical context.
    var cardBackgroundTint: Color {
        LiturgicalColors.cardBackgroundTint(for: self)
    }
    
    /// Pill / badge background color.
    var badgeBackground: Color {
        LiturgicalColors.badgeBackgroundTint(for: self)
    }
    
    /// Subtle border stroke color.
    var borderTint: Color {
        swiftUIColor.opacity(0.25)
    }
    
    /// Soft top gradient banner for headers.
    var bannerGradient: LinearGradient {
        LinearGradient(
            colors: [
                swiftUIColor.opacity(0.18),
                swiftUIColor.opacity(0.02),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
