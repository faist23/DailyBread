//
//  AppTheme.swift
//  DailyBread
//
//  Created for DailyBread Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// Defines the global design system for DailyBread.
///
/// Designed with a calm, contemplative Catholic aesthetic that draws inspiration
/// from traditional illuminated manuscripts, missals, and sacred scripture printing.
public enum AppTheme {
    
    // MARK: - Spacing
    
    /// Consistent spacing scale across the app.
    public enum Spacing {
        /// 4pt — Tight inline spacing, icon badges
        public static let xxsmall: CGFloat = 4
        /// 8pt — Small spacing between related items
        public static let small: CGFloat = 8
        /// 12pt — Compact element separation
        public static let compact: CGFloat = 12
        /// 16pt — Standard layout margin and card padding
        public static let medium: CGFloat = 16
        /// 24pt — Section spacing
        public static let large: CGFloat = 24
        /// 32pt — Major view block separation
        public static let xlarge: CGFloat = 32
        /// 48pt — Top/bottom screen breathing room
        public static let xxlarge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    /// Rounded corner radii evoking modern lectionary card presentation.
    public enum CornerRadius {
        /// 8pt — Chips, small badges
        public static let small: CGFloat = 8
        /// 12pt — Buttons, secondary cards
        public static let medium: CGFloat = 12
        /// 16pt — Reading cards, primary containers
        public static let large: CGFloat = 16
        /// 24pt — Hero banners, sheets
        public static let xlarge: CGFloat = 24
        /// Pill shape
        public static let pill: CGFloat = 999
    }
    
    // MARK: - Shadows
    
    /// Soft, subtle shadows designed for quiet contemplation.
    public enum Shadow {
        public static let card = ShadowStyle(
            color: Color.black.opacity(0.04),
            radius: 8,
            x: 0,
            y: 3
        )
        
        public static let subtle = ShadowStyle(
            color: Color.black.opacity(0.02),
            radius: 4,
            x: 0,
            y: 1
        )
        
        public static let elevated = ShadowStyle(
            color: Color.black.opacity(0.08),
            radius: 16,
            x: 0,
            y: 6
        )
        
        public struct ShadowStyle: Sendable {
            public let color: Color
            public let radius: CGFloat
            public let x: CGFloat
            public let y: CGFloat
        }
    }
    
    // MARK: - Colors
    
    /// Core semantic and missal colors.
    public enum Colors {
        /// Rubric / Missal red for psalm antiphon "℟." and liturgical rubrics
        public static let missalRed = Color(red: 180 / 255, green: 30 / 255, blue: 30 / 255)
        
        /// Sacred gold accent for solemnities and sacred highlights
        public static let solemnGold = Color(red: 205 / 255, green: 160 / 255, blue: 60 / 255)
        
        /// Warm scripture paper background tint (subtle cream in light, slate charcoal in dark)
        public static let scripturePaper = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 24 / 255, green: 24 / 255, blue: 27 / 255, alpha: 1.0)
                    : UIColor(red: 253 / 255, green: 252 / 255, blue: 248 / 255, alpha: 1.0)
            }
        )
        
        /// Background for card containers
        public static let cardBackground = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1.0)
                    : UIColor(red: 255 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1.0)
            }
        )
        
        /// Subtle card border stroke
        public static let cardBorder = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor.white.withAlphaComponent(0.08)
                    : UIColor.black.withAlphaComponent(0.06)
            }
        )
        
        /// App grouped background
        public static let groupedBackground = Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 18 / 255, green: 18 / 255, blue: 20 / 255, alpha: 1.0)
                    : UIColor(red: 247 / 255, green: 246 / 255, blue: 242 / 255, alpha: 1.0)
            }
        )
    }
}

// MARK: - Card Style Modifier

/// A custom ViewModifier that applies the contemplative DailyBread card appearance.
public struct ContemplativeCardModifier: ViewModifier {
    public var backgroundColor: Color?
    public var cornerRadius: CGFloat
    public var padding: CGFloat
    public var shadow: AppTheme.Shadow.ShadowStyle
    public var borderColor: Color?
    
    public init(
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = AppTheme.CornerRadius.large,
        padding: CGFloat = AppTheme.Spacing.medium,
        shadow: AppTheme.Shadow.ShadowStyle = AppTheme.Shadow.card,
        borderColor: Color? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadow = shadow
        self.borderColor = borderColor
    }
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor ?? AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor ?? AppTheme.Colors.cardBorder, lineWidth: 1)
            )
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// MARK: - View Extensions

public extension View {
    /// Applies the contemplative card style to this view.
    func cardStyle(
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat = AppTheme.CornerRadius.large,
        padding: CGFloat = AppTheme.Spacing.medium,
        borderColor: Color? = nil
    ) -> some View {
        modifier(ContemplativeCardModifier(
            backgroundColor: backgroundColor,
            cornerRadius: cornerRadius,
            padding: padding,
            shadow: AppTheme.Shadow.card,
            borderColor: borderColor
        ))
    }
    
    /// Adds a top liturgical stripe accent.
    func liturgicalStripe(color: Color, height: CGFloat = 4) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(color)
                .frame(height: height)
            self
        }
    }
    
    /// Triggers subtle haptic feedback for calm interaction.
    func liturgicalHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}
