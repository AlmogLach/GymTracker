//
//  Components.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI

struct PillBadge: View {
    let text: String
    let icon: String?
    
    init(text: String, icon: String? = nil) {
        self.text = text
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, AppTheme.s8)
        .padding(.vertical, 4)
        .background(AppTheme.accent.opacity(0.1))
        .foregroundStyle(AppTheme.accent)
        .cornerRadius(12)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
    }
}

struct EmptyStateView: View {
    let iconSystemName: String
    let title: String
    var message: String?
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppTheme.s12) {
            Image(systemName: iconSystemName)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityLabel(title)

            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(message)
            }

            if let buttonTitle = buttonTitle, let action = action {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, AppTheme.s8)
                    .accessibilityLabel(buttonTitle)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.s8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.s12)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DayChip: View {
    let day: PlannedDay
    let isSelected: Bool
    
    init(day: PlannedDay, isSelected: Bool = false) {
        self.day = day
        self.isSelected = isSelected
    }
    
    var body: some View {
        VStack(spacing: 3) {
            Text(dayAbbreviation(day.weekday))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .primary)
            
            if !day.label.isEmpty {
                Text(day.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? AppTheme.accent : Color(.secondarySystemGroupedBackground))
                .shadow(
                    color: isSelected ? AppTheme.accent.opacity(0.3) : .black.opacity(0.05),
                    radius: isSelected ? 4 : 2,
                    x: 0,
                    y: isSelected ? 2 : 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? AppTheme.accent.opacity(0.2) : Color(.separator),
                    lineWidth: isSelected ? 1 : 0.5
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .frame(minWidth: 36, minHeight: 36)
        .contentShape(Rectangle())
        .accessibilityLabel("\(dayAbbreviation(day.weekday))\(day.label.isEmpty ? "" : " - \(day.label)")")
        .accessibilityHint(isSelected ? "יום נבחר" : "יום לא נבחר")
    }
    
    private func dayAbbreviation(_ weekday: Int) -> String {
        let dayNames = ["א׳", "ב׳", "ג׳", "ד׳", "ה׳", "ו׳", "ש׳"]
        let index = max(1, min(7, weekday)) - 1
        return dayNames[index]
    }
}

// MARK: - Previews

#Preview("PillBadge") {
    VStack(spacing: 16) {
        PillBadge(text: "חזה")
        PillBadge(text: "משקל גוף", icon: "figure.strengthtraining.traditional")
        PillBadge(text: "A", icon: "dumbbell")
    }
    .padding()
}

#Preview("PrimaryButton") {
    PrimaryButton(title: "התחל אימון") {
        print("Button tapped")
    }
    .padding()
}

#Preview("EmptyStateView") {
    EmptyStateView(
        iconSystemName: "dumbbell",
        title: "אין תרגילים",
        message: "הוסף תרגילים כדי להתחיל",
        buttonTitle: "הוסף תרגיל"
    ) {
        print("Add exercise tapped")
    }
    .padding()
}

#Preview("StatTile") {
    HStack(spacing: 12) {
        StatTile(
            value: "5",
            label: "אימונים",
            icon: "figure.strengthtraining.traditional",
            color: .blue
        )
        StatTile(
            value: "3",
            label: "תוכניות",
            icon: "list.bullet.rectangle",
            color: .green
        )
    }
    .padding()
}

#Preview("StatCard") {
    HStack(spacing: 12) {
        StatCard(
            title: "אימונים השבוע",
            value: "5",
            icon: "figure.strengthtraining.traditional",
            color: .blue
        )
        StatCard(
            title: "תרגילים שונים",
            value: "12",
            icon: "dumbbell.fill",
            color: .green
        )
    }
    .padding()
}

#Preview("DayChip") {
    HStack(spacing: 8) {
        DayChip(day: PlannedDay(weekday: 1, label: "A"), isSelected: true)
        DayChip(day: PlannedDay(weekday: 3, label: "B"), isSelected: false)
        DayChip(day: PlannedDay(weekday: 5, label: "C"), isSelected: false)
    }
    .padding()
}