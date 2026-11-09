//
//  SaintOfDayCard.swift
//  DailyBread
//
//  Created for DailyBread Catholic Daily Readings App.
//  iOS 17+ | Swift 6+
//

import SwiftUI

/// A contemplative card displaying the Saint of the Day.
///
/// Features a liturgical candle icon, feast title, biography with smooth "Read more" expansion,
/// and patronage badges.
public struct SaintOfDayCard: View {
    
    // MARK: - Properties
    
    public let saint: Saint
    public var liturgicalColor: LiturgicalColor = .green
    
    @State private var isExpanded: Bool = false
    
    // MARK: - Initialization
    
    public init(saint: Saint, liturgicalColor: LiturgicalColor = .green) {
        self.saint = saint
        self.liturgicalColor = liturgicalColor
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header: Icon + Name + Title
            headerSection
            
            // Biography Section (with Truncation / Expansion)
            biographySection
            
            // Patronages (if available)
            if let patronages = saint.patronages, !patronages.isEmpty {
                patronagesSection(patronages: patronages)
            }
        }
        .cardStyle(
            backgroundColor: AppTheme.Colors.cardBackground,
            cornerRadius: AppTheme.CornerRadius.large,
            padding: AppTheme.Spacing.medium
        )
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            // Sacred Candle Icon
            ZStack {
                Circle()
                    .fill(liturgicalColor.swiftUIColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.Colors.solemnGold)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(headerBadgeTitle)
                    .readingTitleStyle(tintColor: liturgicalColor.swiftUIColor)
                
                Text(saint.name)
                    .font(.system(size: 19, weight: .bold, design: .serif))
                    .foregroundStyle(Color.primary)
                
                if let title = saint.title, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 14, weight: .medium, design: .serif).italic())
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Dynamic Badge Title
    
    private var headerBadgeTitle: String {
        let nameLower = saint.name.lowercased()
        let titleLower = (saint.title ?? "").lowercased()
        
        // Respect the classic "SAINT OF THE DAY" specifically for All Saints
        if nameLower.contains("all saints") {
            return "SAINT OF THE DAY"
        } else if nameLower.contains("solemnity") || titleLower.contains("solemnity") {
            return "SOLEMNITY OF THE DAY"
        } else if nameLower.contains("feast") || titleLower.contains("feast") || nameLower.contains("dedication") || nameLower.contains("presentation") || nameLower.contains("transfiguration") || nameLower.contains("exaltation") || nameLower.contains("baptism") {
            return "FEAST OF THE DAY"
        } else if nameLower.contains("commemoration") || nameLower.contains("ash wednesday") || nameLower.contains("good friday") || nameLower.contains("holy saturday") || nameLower.contains("holy thursday") {
            return "COMMEMORATION OF THE DAY"
        } else {
            return "SAINT OF THE DAY"
        }
    }
    
    // MARK: - Biography Section
    
    private var biographySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(saint.biography.trimmingCharacters(in: .whitespacesAndNewlines))
                .saintBioStyle()
                .lineLimit(isExpanded ? nil : 4)
                .animation(.easeInOut(duration: 0.25), value: isExpanded)
            
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Show Less" : "Read More")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(liturgicalColor.swiftUIColor)
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Patronages
    
    private func patronagesSection(patronages: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PATRON OF")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.secondary.opacity(0.8))
                .tracking(1.0)
            
            FlowLayout(spacing: 6) {
                ForEach(patronages, id: \.self) { patronage in
                    Text(patronage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.primary.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Flow Layout Helper for Patronage Tags

fileprivate struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height = currentY + rowHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
