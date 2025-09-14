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

struct DayChip: View {
    let day: PlannedDay
    let isSelected: Bool
    
    init(day: PlannedDay, isSelected: Bool = false) {
        self.day = day
        self.isSelected = isSelected
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(dayAbbreviation(day.weekday))
                .font(.caption2)
                .fontWeight(.semibold)
            
            if !day.label.isEmpty {
                Text(day.label)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, AppTheme.s8)
        .padding(.vertical, 4)
        .background(isSelected ? AppTheme.accent : AppTheme.accent.opacity(0.1))
        .foregroundStyle(isSelected ? .white : AppTheme.accent)
        .cornerRadius(8)
        .frame(minWidth: 28)
    }
    
    private func dayAbbreviation(_ weekday: Int) -> String {
        let dayNames = ["א׳", "ב׳", "ג׳", "ד׳", "ה׳", "ו׳", "ש׳"]
        let index = max(1, min(7, weekday)) - 1
        return dayNames[index]
    }
}