//
//  Typography.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Typography system for DailyReadings.
///
/// Features New York (serif) for sacred scripture readings to evoke a contemplative
/// missal/lectionary feel, and San Francisco for clean, legible modern UI elements.
/// Fully supports Dynamic Type and relative scaling.
public enum AppTypography {
    
    // MARK: - Scaled Font Constructors
    
    /// Returns the serif New York font for scripture readings with scalable sizing.
    public static func scriptureBodyFont(size: CGFloat = 18, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .serif)
    }
    
    /// Returns the responsorial psalm response font.
    public static func scripturePsalmResponseFont(size: CGFloat = 17) -> Font {
        Font.system(size: size, weight: .semibold, design: .serif).italic()
    }
    
    /// Returns the reading title font (e.g., "FIRST READING", "GOSPEL").
    public static func readingTitleFont(size: CGFloat = 13) -> Font {
        Font.system(size: size, weight: .bold, design: .default).smallCaps()
    }
    
    /// Returns the scripture citation font (e.g., "Wisdom 3:1-9").
    public static func readingCitationFont(size: CGFloat = 15) -> Font {
        Font.system(size: size, weight: .medium, design: .serif).italic()
    }
    
    /// Returns the liturgical feast/day title font.
    public static func liturgicalTitleFont(size: CGFloat = 20) -> Font {
        Font.system(size: size, weight: .bold, design: .default).smallCaps()
    }
    
    /// Returns the saint biography font.
    public static func saintBioFont(size: CGFloat = 15) -> Font {
        Font.system(size: size, weight: .regular, design: .serif)
    }
}

// MARK: - Font Extensions

public extension Font {
    /// Scripture body text in New York (serif).
    static var scriptureBody: Font {
        Font.system(.body, design: .serif)
    }
    
    /// Scaled scripture body text in New York (serif) with user-defined base size.
    static func scriptureBody(size: CGFloat) -> Font {
        AppTypography.scriptureBodyFont(size: size)
    }
    
    /// Responsorial Psalm response / antiphon text in bold italic serif.
    static var scripturePsalmResponse: Font {
        Font.system(.subheadline, design: .serif).weight(.semibold).italic()
    }
    
    /// Responsorial Psalm response font alias.
    static var scripturePsalmResponseFont: Font {
        scripturePsalmResponse
    }

    /// Scaled psalm response font function.
    static func scripturePsalmResponseFont(size: CGFloat = 17) -> Font {
        AppTypography.scripturePsalmResponseFont(size: size)
    }
    
    /// Reading header label (e.g., "FIRST READING", "GOSPEL") in small caps.
    static var readingTitle: Font {
        Font.system(.caption, design: .default).weight(.bold).smallCaps()
    }
    
    /// Scripture citation reference (e.g. "Wisdom 3:1-9") in italic serif.
    static var readingCitation: Font {
        Font.system(.subheadline, design: .serif).italic()
    }
    
    /// Liturgical day title in prominent small caps.
    static var liturgicalTitle: Font {
        Font.system(.title3, design: .default).weight(.bold).smallCaps()
    }
    
    /// Saint biography and contemplative description text in serif.
    static var saintBio: Font {
        Font.system(.callout, design: .serif)
    }
}

// MARK: - View Modifiers with Dynamic Type and Spacing

/// Applies missal-inspired scripture body formatting with generous line height for contemplation.
public struct ScriptureBodyStyle: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    public var userSize: CGFloat
    public var lineSpacingMultiplier: CGFloat
    
    public init(userSize: CGFloat = 18, lineSpacingMultiplier: CGFloat = 7) {
        self.userSize = userSize
        self.lineSpacingMultiplier = lineSpacingMultiplier
    }
    
    public func body(content: Content) -> some View {
        content
            .font(.scriptureBody(size: userSize))
            .lineSpacing(lineSpacingMultiplier)
            .foregroundStyle(Color.primary)
    }
}

/// Formats responsorial psalm response text with liturgical antiphon styling.
public struct ScripturePsalmResponseStyle: ViewModifier {
    public var tintColor: Color?
    
    public init(tintColor: Color? = nil) {
        self.tintColor = tintColor
    }
    
    public func body(content: Content) -> some View {
        content
            .font(.scripturePsalmResponse)
            .foregroundStyle(tintColor ?? AppTheme.Colors.missalRed)
            .lineSpacing(4)
    }
}

/// Formats reading headers ("FIRST READING", "GOSPEL", etc.) in crisp small caps.
public struct ReadingTitleStyle: ViewModifier {
    public var tintColor: Color?
    
    public init(tintColor: Color? = nil) {
        self.tintColor = tintColor
    }
    
    public func body(content: Content) -> some View {
        content
            .font(.readingTitle)
            .foregroundStyle(tintColor ?? Color.secondary)
            .tracking(1.2)
    }
}

/// Formats scripture citations ("Romans 8:14-17") in gentle italic serif.
public struct ReadingCitationStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.readingCitation)
            .foregroundStyle(Color.secondary)
    }
}

/// Formats liturgical titles with solemnity and dignity.
public struct LiturgicalTitleStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.liturgicalTitle)
            .foregroundStyle(Color.primary)
            .tracking(0.8)
    }
}

/// Formats saint biography text with warm serif readability.
public struct SaintBioStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.saintBio)
            .foregroundStyle(Color.primary.opacity(0.88))
            .lineSpacing(5)
    }
}

// MARK: - View Convenience Extensions

public extension View {
    /// Formats scripture body text with generous line spacing and New York serif.
    func scriptureBodyStyle(fontSize: CGFloat = 18, lineSpacing: CGFloat = 7) -> some View {
        modifier(ScriptureBodyStyle(userSize: fontSize, lineSpacingMultiplier: lineSpacing))
    }
    
    /// Formats responsorial psalm responses with rubric highlighting.
    func scripturePsalmResponseStyle(tintColor: Color? = nil) -> some View {
        modifier(ScripturePsalmResponseStyle(tintColor: tintColor))
    }
    
    /// Formats reading category headers in small caps.
    func readingTitleStyle(tintColor: Color? = nil) -> some View {
        modifier(ReadingTitleStyle(tintColor: tintColor))
    }
    
    /// Formats scripture citations in italic serif.
    func readingCitationStyle() -> some View {
        modifier(ReadingCitationStyle())
    }
    
    /// Formats liturgical day titles with dignity and small caps.
    func liturgicalTitleStyle() -> some View {
        modifier(LiturgicalTitleStyle())
    }
    
    /// Formats saint biography descriptions.
    func saintBioStyle() -> some View {
        modifier(SaintBioStyle())
    }
}
