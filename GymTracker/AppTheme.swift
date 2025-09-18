//
//  AppTheme.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI

struct AppTheme {
    // Colors
    static let accent = Color.blue
    static let cardBG = Color(.secondarySystemBackground)
    static let screenBG = Color(.systemGroupedBackground)
    
    // Semantic colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // UI colors
    static let primary = Color.primary
    static let secondary = Color.secondary
    static let tertiary = Color(.tertiaryLabel)
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    // Spacing scale
    static let s4: CGFloat = 4
    static let s6: CGFloat = 6
    static let s8: CGFloat = 8
    static let s10: CGFloat = 10
    static let s12: CGFloat = 12
    static let s16: CGFloat = 16
    static let s20: CGFloat = 20
    static let s24: CGFloat = 24
    static let s32: CGFloat = 32
    
    // Radius
    static let r16: CGFloat = 16
}

// MARK: - Theme Preview

struct AppThemePreview: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.s24) {
                // Color palette
                VStack(alignment: .leading, spacing: AppTheme.s12) {
                    Text("צבעי הנושא")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppTheme.s12) {
                        ColorSwatch(name: "Accent", color: AppTheme.accent)
                        ColorSwatch(name: "Success", color: AppTheme.success)
                        ColorSwatch(name: "Warning", color: AppTheme.warning)
                        ColorSwatch(name: "Error", color: AppTheme.error)
                        ColorSwatch(name: "Card BG", color: AppTheme.cardBG)
                        ColorSwatch(name: "Screen BG", color: AppTheme.screenBG)
                    }
                }
                
                // Spacing scale
                VStack(alignment: .leading, spacing: AppTheme.s12) {
                    Text("סולם רווחים")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    VStack(spacing: AppTheme.s8) {
                        SpacingExample(size: AppTheme.s4, label: "s4 = 4pt")
                        SpacingExample(size: AppTheme.s6, label: "s6 = 6pt")
                        SpacingExample(size: AppTheme.s8, label: "s8 = 8pt")
                        SpacingExample(size: AppTheme.s10, label: "s10 = 10pt")
                        SpacingExample(size: AppTheme.s12, label: "s12 = 12pt")
                        SpacingExample(size: AppTheme.s16, label: "s16 = 16pt")
                        SpacingExample(size: AppTheme.s20, label: "s20 = 20pt")
                        SpacingExample(size: AppTheme.s24, label: "s24 = 24pt")
                        SpacingExample(size: AppTheme.s32, label: "s32 = 32pt")
                    }
                }
                
                // Radius examples
                VStack(alignment: .leading, spacing: AppTheme.s12) {
                    Text("רדיוס עגול")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    HStack(spacing: AppTheme.s16) {
                        RoundedRectangle(cornerRadius: AppTheme.r16)
                            .fill(AppTheme.accent)
                            .frame(width: 60, height: 40)
                            .overlay(
                                Text("r16")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)
                            )
                        
                        Text("רדיוס של 16 נקודות")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Theme in action
                VStack(alignment: .leading, spacing: AppTheme.s12) {
                    Text("הנושא בפעולה")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    VStack(spacing: AppTheme.s8) {
                        Text("כותרת הכרטיס")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("תוכן הכרטיס עם הטקסט הזה")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        Button("פעולה") {}
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                    .padding(AppTheme.s16)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
                }
            }
            .padding(AppTheme.s16)
        }
        .background(AppTheme.screenBG)
        .navigationTitle("נושא האפליקציה")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.s8) {
            RoundedRectangle(cornerRadius: AppTheme.r16)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.r16)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
            
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct SpacingExample: View {
    let size: CGFloat
    let label: String
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(AppTheme.accent)
                .frame(width: size, height: 20)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

// MARK: - Previews

#Preview("App Theme") {
    NavigationStack {
        AppThemePreview()
    }
}

#Preview("Color Swatches") {
    LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ], spacing: AppTheme.s12) {
        ColorSwatch(name: "Accent", color: AppTheme.accent)
        ColorSwatch(name: "Success", color: AppTheme.success)
        ColorSwatch(name: "Warning", color: AppTheme.warning)
        ColorSwatch(name: "Error", color: AppTheme.error)
        ColorSwatch(name: "Card BG", color: AppTheme.cardBG)
        ColorSwatch(name: "Screen BG", color: AppTheme.screenBG)
    }
    .padding()
}

#Preview("Spacing Scale") {
    VStack(spacing: AppTheme.s8) {
        SpacingExample(size: AppTheme.s4, label: "s4 = 4pt")
        SpacingExample(size: AppTheme.s6, label: "s6 = 6pt")
        SpacingExample(size: AppTheme.s8, label: "s8 = 8pt")
        SpacingExample(size: AppTheme.s10, label: "s10 = 10pt")
        SpacingExample(size: AppTheme.s12, label: "s12 = 12pt")
        SpacingExample(size: AppTheme.s16, label: "s16 = 16pt")
        SpacingExample(size: AppTheme.s20, label: "s20 = 20pt")
        SpacingExample(size: AppTheme.s24, label: "s24 = 24pt")
        SpacingExample(size: AppTheme.s32, label: "s32 = 32pt")
    }
    .padding()
}
