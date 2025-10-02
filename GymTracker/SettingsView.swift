//
//  SettingsView.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]

    var settings: AppSettings {
        if let s = settingsList.first { return s }
        let s = AppSettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile section (placeholder)
                    profileSection
                    
                    // Units section
                    unitsSection
                    
                    // Workout settings
                    workoutSettingsSection
                    
                    // App info
                    aboutSection
                }
                .padding(16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("הגדרות")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var profileSection: some View {
        VStack(spacing: 16) {
            // Profile picture placeholder
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 4) {
                Text("משתמש GymTracker")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                
                Text("מוכן לאימון הבא")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("יחידות")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            SettingRow(
                icon: "scalemass.fill",
                title: "יחידות משקל",
                subtitle: settings.weightUnit == .kg ? "קילוגרם" : "פאונד",
                iconColor: .orange
            ) {
                Picker("יחידות משקל", selection: Binding(
                    get: { settings.weightUnit },
                    set: { settings.weightUnit = $0 }
                )) {
                    Text("קילוגרם (ק״ג)").tag(AppSettings.WeightUnit.kg)
                    Text("פאונד (lb)").tag(AppSettings.WeightUnit.lb)
                }
                .pickerStyle(.menu)
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var workoutSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("הגדרות אימון")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            VStack(spacing: 12) {
                SettingRow(
                    icon: "timer.circle.fill",
                    title: "זמן מנוחה ברירת מחדל",
                    subtitle: "\(settings.defaultRestSeconds) שניות",
                    iconColor: .blue
                ) {
                    Stepper(value: Binding(
                        get: { settings.defaultRestSeconds },
                        set: { settings.defaultRestSeconds = max(10, min(600, $0)) }
                    ), in: 10...600, step: 5) {
                        Text("\(settings.defaultRestSeconds) שניות")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                SettingRow(
                    icon: "arrow.up.circle.fill",
                    title: "מצב התקדמות אוטומטית",
                    subtitle: settings.autoProgressionMode == .percent ? "אחוזים" : "מחזור חזרות",
                    iconColor: .green
                ) {
                    Picker("מצב התקדמות", selection: Binding(
                        get: { settings.autoProgressionMode },
                        set: { settings.autoProgressionMode = $0 }
                    )) {
                        Text("אחוזים").tag(AppSettings.AutoProgressionMode.percent)
                        Text("מחזור חזרות").tag(AppSettings.AutoProgressionMode.repCycle)
                    }
                    .pickerStyle(.segmented)
                }
                
                if settings.autoProgressionMode == .percent {
                    SettingRow(
                        icon: "percent.circle.fill",
                        title: "אחוז התקדמות",
                        subtitle: "\(String(format: "%.1f", settings.autoProgressionPercent))%",
                        iconColor: .purple
                    ) {
                        Slider(value: Binding(
                            get: { settings.autoProgressionPercent },
                            set: { settings.autoProgressionPercent = max(0, min(20, $0)) }
                        ), in: 0...20, step: 0.5) {
                            Text("")
                        }
                        .tint(.purple)
                    }
                }
                
                SettingRow(
                    icon: "plus.minus.circle.fill",
                    title: "תוספת משקל (ק״ג)",
                    subtitle: "\(String(format: "%.1f", settings.weightIncrementKg)) ק״ג",
                    iconColor: .red
                ) {
                    HStack(spacing: 8) {
                        Button(action: { settings.weightIncrementKg = max(0.5, settings.weightIncrementKg - 0.5) }) {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                        }
                        Text("\(String(format: "%.1f", settings.weightIncrementKg)) ק" + "\"" + "ג")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 60)
                        Button(action: { settings.weightIncrementKg = min(10.0, settings.weightIncrementKg + 0.5) }) {
                            Image(systemName: "plus.circle.fill").foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("אודות האפליקציה")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            VStack(spacing: 12) {
                SettingRow(
                    icon: "dumbbell.fill",
                    title: "GymTracker",
                    subtitle: "אפליקציה לניהול אימוני כושר",
                    iconColor: .blue
                ) {
                    EmptyView()
                }
                
                SettingRow(
                    icon: "info.circle.fill",
                    title: "גרסה",
                    subtitle: "1.0.0",
                    iconColor: .gray
                ) {
                    EmptyView()
                }
                
                SettingRow(
                    icon: "heart.fill",
                    title: "פותח בישראל",
                    subtitle: "עם אהבה לכושר",
                    iconColor: .pink
                ) {
                    EmptyView()
                }
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct SettingRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: (() -> Content)?
    
    init(icon: String, title: String, subtitle: String, iconColor: Color, @ViewBuilder action: @escaping () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.action = action
    }
    
    init(icon: String, title: String, subtitle: String, iconColor: Color) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.action = nil
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let action = action {
                action()
            } else {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}
