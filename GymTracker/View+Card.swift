//
//  View+Card.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI

struct AppCardModifier: ViewModifier {
    let padding: CGFloat
    let style: CardStyle
    
    enum CardStyle {
        case standard
        case elevated
        case compact
        case accent
        case outlined
    }
    
    init(padding: CGFloat = AppTheme.s16, style: CardStyle = .standard) {
        self.padding = padding
        self.style = style
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(overlayView)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: shadowOffset.width,
                y: shadowOffset.height
            )
            .padding(.horizontal, horizontalPadding)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .standard:
            Color(.tertiarySystemGroupedBackground)
        case .elevated:
            Color(.secondarySystemGroupedBackground)
        case .compact:
            Color(.tertiarySystemGroupedBackground)
        case .accent:
            AppTheme.accent.opacity(0.05)
        case .outlined:
            Color(.secondarySystemGroupedBackground)
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if style == .outlined {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .compact: return 12
        default: return AppTheme.r16
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .elevated:
            return .black.opacity(0.1)
        case .accent:
            return AppTheme.accent.opacity(0.1)
        default:
            return .black.opacity(0.05)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .elevated: return 8
        case .accent: return 4
        default: return 2
        }
    }
    
    private var shadowOffset: CGSize {
        switch style {
        case .elevated: return CGSize(width: 0, height: 4)
        case .accent: return CGSize(width: 0, height: 2)
        default: return CGSize(width: 0, height: 1)
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .compact: return AppTheme.s8
        default: return AppTheme.s16
        }
    }
}

struct SectionHeaderModifier: ViewModifier {
    let title: String
    let subtitle: String?
    let trailing: AnyView?
    let style: HeaderStyle
    
    enum HeaderStyle {
        case standard
        case compact
        case accent
        case withIcon(String)
    }
    
    init(title: String, subtitle: String? = nil, style: HeaderStyle = .standard, trailing: (() -> AnyView)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.trailing = trailing?()
    }
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: subtitleSpacing) {
                    HStack(spacing: AppTheme.s8) {
                        if case .withIcon(let iconName) = style {
                            Image(systemName: iconName)
                                .font(.title3)
                                .foregroundStyle(iconColor)
                        }
                        
                Text(title)
                            .font(titleFont)
                    .fontWeight(.bold)
                            .foregroundStyle(titleColor)
                    }
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let trailing = trailing {
                    trailing
                }
            }
            
            content
        }
    }
    
    private var spacing: CGFloat {
        switch style {
        case .compact: return AppTheme.s8
        default: return AppTheme.s12
        }
    }
    
    private var subtitleSpacing: CGFloat {
        switch style {
        case .compact: return 2
        default: return 4
        }
    }
    
    private var titleFont: Font {
        switch style {
        case .compact: return .subheadline
        default: return .headline
        }
    }
    
    private var titleColor: Color {
        switch style {
        case .accent: return AppTheme.accent
        default: return .primary
        }
    }
    
    private var iconColor: Color {
        switch style {
        case .accent: return AppTheme.accent
        default: return .secondary
        }
    }
}

extension View {
    func appCard(padding: CGFloat = AppTheme.s16, style: AppCardModifier.CardStyle = .standard) -> some View {
        modifier(AppCardModifier(padding: padding, style: style))
    }
    
    func sectionHeader(_ title: String, subtitle: String? = nil, style: SectionHeaderModifier.HeaderStyle = .standard, trailing: (() -> AnyView)? = nil) -> some View {
        modifier(SectionHeaderModifier(title: title, subtitle: subtitle, style: style, trailing: trailing))
    }
    
    // Convenience methods for common styles
    func elevatedCard(padding: CGFloat = AppTheme.s16) -> some View {
        appCard(padding: padding, style: .elevated)
    }
    
    func compactCard(padding: CGFloat = AppTheme.s8) -> some View {
        appCard(padding: padding, style: .compact)
    }
    
    func accentCard(padding: CGFloat = AppTheme.s16) -> some View {
        appCard(padding: padding, style: .accent)
    }
    
    func outlinedCard(padding: CGFloat = AppTheme.s16) -> some View {
        appCard(padding: padding, style: .outlined)
    }
    
    func compactSectionHeader(_ title: String, trailing: (() -> AnyView)? = nil) -> some View {
        sectionHeader(title, style: .compact, trailing: trailing)
    }
    
    func accentSectionHeader(_ title: String, trailing: (() -> AnyView)? = nil) -> some View {
        sectionHeader(title, style: .accent, trailing: trailing)
    }
    
    func iconSectionHeader(_ title: String, icon: String, trailing: (() -> AnyView)? = nil) -> some View {
        sectionHeader(title, style: .withIcon(icon), trailing: trailing)
    }
}

// MARK: - Previews

#Preview("Card Styles Showcase") {
    ScrollView {
        VStack(spacing: AppTheme.s24) {
            // Standard Card
            VStack(spacing: AppTheme.s12) {
                Text("כרטיס סטנדרטי")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("כרטיס רגיל עם עיצוב בסיסי")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Button("פעולה") {}
                        .buttonStyle(.bordered)
                    
                    Button("פעולה ראשית") {}
                        .buttonStyle(.borderedProminent)
                }
            }
            .appCard()
            
            // Elevated Card
            VStack(spacing: AppTheme.s12) {
                Text("כרטיס מוגבה")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("כרטיס עם צל מוגבר ועיצוב בולט")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("4.8")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("דירוג גבוה")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .elevatedCard()
            
            // Compact Card
            VStack(spacing: AppTheme.s8) {
                Text("כרטיס קומפקטי")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("עיצוב קומפקטי לחיסכון במקום")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .compactCard()
            
            // Accent Card
            VStack(spacing: AppTheme.s12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                    Text("השלמת אימון")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Text("כל הכבוד! השלמת את האימון להיום")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .accentCard()
            
            // Outlined Card
            VStack(spacing: AppTheme.s12) {
                Text("כרטיס עם מסגרת")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("כרטיס עם מסגרת צבעונית")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .outlinedCard()
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Section Headers Showcase") {
    ScrollView {
        VStack(spacing: AppTheme.s24) {
            // Standard Section Header
            VStack(spacing: AppTheme.s12) {
                Text("תוכן הסקציה")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("פריט 1")
                    Spacer()
                    Text("ערך 1")
                }
                
                HStack {
                    Text("פריט 2")
                    Spacer()
                    Text("ערך 2")
                }
            }
            .sectionHeader("כותרת סטנדרטית") {
                AnyView(
                    Button("עוד") {}
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                )
            }
            .appCard()
            
            // Compact Section Header
            VStack(spacing: AppTheme.s8) {
                Text("תוכן קומפקטי")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .compactSectionHeader("כותרת קומפקטית")
            .compactCard()
            
            // Accent Section Header
            VStack(spacing: AppTheme.s12) {
                Text("תוכן עם דגש")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .accentSectionHeader("כותרת עם דגש")
            .appCard()
            
            // Icon Section Header
            VStack(spacing: AppTheme.s12) {
                Text("תוכן עם אייקון")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .iconSectionHeader("כותרת עם אייקון", icon: "figure.strengthtraining.traditional")
            .appCard()
            
            // Section Header with Subtitle
            VStack(spacing: AppTheme.s12) {
                Text("תוכן עם כותרת משנה")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .sectionHeader("כותרת ראשית", subtitle: "כותרת משנה עם הסבר נוסף")
            .appCard()
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Real World Examples") {
    ScrollView {
        VStack(spacing: AppTheme.s24) {
            // Workout Stats Card
            VStack(spacing: AppTheme.s12) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(.blue)
                    Text("סטטיסטיקות אימון")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                HStack(spacing: AppTheme.s16) {
                    VStack {
                        Text("5")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("אימונים")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        Text("3")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("תוכניות")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        Text("2")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("השבוע")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .elevatedCard()
            
            // Quick Action Card
            VStack(spacing: AppTheme.s12) {
                Text("פעולות מהירות")
                    .font(.headline)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.s12) {
                    Button(action: {}) {
                        VStack(spacing: AppTheme.s8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text("צור תוכנית")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.s12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {}) {
                        VStack(spacing: AppTheme.s8) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                            Text("התחל אימון")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.s12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .appCard()
            
            // Achievement Card
            VStack(spacing: AppTheme.s12) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("הישג חדש!")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Text("השלמת 10 אימונים ברצף")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Button("צפה בהישגים") {}
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .accentCard()
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
