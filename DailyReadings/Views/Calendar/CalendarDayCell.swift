//
//  CalendarDayCell.swift
//  DailyReadings
//
//  Created for DailyReadings Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// An individual day cell in the Catholic liturgical calendar grid.
///
/// Displays the day of the month, a colored dot indicating the liturgical color,
/// visual rings for today and selected states, and bold styling for solemnities and feasts.
public struct CalendarDayCell: View {
    
    // MARK: - Properties
    
    public let date: Date
    public let liturgicalDay: LiturgicalDay?
    public let isToday: Bool
    public let isSelected: Bool
    public let onSelect: () -> Void
    
    // MARK: - Initialization
    
    public init(
        date: Date,
        liturgicalDay: LiturgicalDay?,
        isToday: Bool = false,
        isSelected: Bool = false,
        onSelect: @escaping () -> Void
    ) {
        self.date = date
        self.liturgicalDay = liturgicalDay
        self.isToday = isToday
        self.isSelected = isSelected
        self.onSelect = onSelect
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                // Day Number
                Text("\(dayNumber)")
                    .font(dayFont)
                    .foregroundStyle(dayTextColor)
                
                // Liturgical Color Dot / Solemnity Indicator
                liturgicalDot
            }
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(cellBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
            .overlay(cellBorder)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityDescription)
    }
    
    // MARK: - Visual Components
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    private var isMajorFeast: Bool {
        guard let day = liturgicalDay else { return false }
        return day.rank == .solemnity || day.rank == .feast || day.isHolyDayOfObligation
    }
    
    private var isWhiteDay: Bool {
        liturgicalDay?.color == .white
    }
    
    private var liturgicalColor: Color {
        liturgicalDay?.color.uiAccentColor ?? LiturgicalColors.green
    }
    
    private var dayFont: Font {
        if isToday || isSelected {
            return .scaled(size: 16, weight: .bold, design: .default)
        } else if isMajorFeast {
            return .scaled(size: 15, weight: .semibold, design: .default)
        } else {
            return .scaled(size: 15, weight: .regular, design: .default)
        }
    }
    
    private var dayTextColor: Color {
        if isSelected {
            return Color.white
        } else if isToday {
            return liturgicalColor
        } else {
            return Color.primary
        }
    }
    
    private var liturgicalDot: some View {
        let dotSize: CGFloat = isMajorFeast ? 7 : 5
        return Group {
            if isSelected {
                Circle()
                    .fill(Color.white)
                    .frame(width: 5, height: 5)
            } else if isWhiteDay {
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(LiturgicalColors.goldAccent, lineWidth: 1.2))
                    .frame(width: dotSize, height: dotSize)
            } else {
                Circle()
                    .fill(liturgicalColor)
                    .frame(width: dotSize, height: dotSize)
            }
        }
    }
    
    private var cellBackground: some View {
        Group {
            if isSelected {
                liturgicalColor
            } else if isToday {
                liturgicalColor.opacity(0.14)
            } else {
                Color.clear
            }
        }
    }
    
    @ViewBuilder
    private var cellBorder: some View {
        if isToday && !isSelected {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(liturgicalColor, lineWidth: 1.5)
        }
    }
    
    // MARK: - Accessibility
    
    private var accessibilityDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateString = formatter.string(from: date)
        let dayTitle = liturgicalDay?.title ?? ""
        let colorName = liturgicalDay?.color.displayName ?? ""
        return "\(dateString). \(dayTitle). Liturgical color: \(colorName)"
    }
}
