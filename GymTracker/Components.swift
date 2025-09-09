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
