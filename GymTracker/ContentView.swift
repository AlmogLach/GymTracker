//
//  ContentView.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("לוח", systemImage: "clock.badge.checkmark") }

            PlansView()
                .tabItem { Label("תוכניות", systemImage: "list.bullet.rectangle") }

            WorkoutLogView()
                .tabItem { Label("לוג אימון", systemImage: "dumbbell") }

            ProgressViewScreen()
                .tabItem { Label("סטטיסטיקות", systemImage: "chart.bar.xaxis") }

            SettingsView()
                .tabItem { Label("הגדרות", systemImage: "gearshape") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}
