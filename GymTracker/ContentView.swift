//
//  ContentView.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(onNavigateToHistory: {
                selectedTab = 2 // Navigate to workout edit tab (history section)
            })
                .tabItem { Label("לוח", systemImage: "clock.badge.checkmark") }
                .tag(0)

            PlansView()
                .tabItem { Label("תוכניות", systemImage: "list.bullet.rectangle") }
                .tag(1)

            WorkoutEditView()
                .tabItem { Label("עריכת אימונים", systemImage: "square.and.pencil") }
                .tag(2)

            ProgressViewScreen()
                .tabItem { Label("סטטיסטיקות", systemImage: "chart.bar.xaxis") }
                .tag(3)

            SettingsView()
                .tabItem { Label("הגדרות", systemImage: "gearshape") }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}
