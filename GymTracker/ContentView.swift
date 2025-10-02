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
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(onNavigateToHistory: {
                selectedTab = 2 // Navigate to workout edit tab (history section)
            })
                .tabItem {
                    Label("לוח", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            PlansView()
                .tabItem {
                    Label("תוכניות", systemImage: selectedTab == 1 ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                }
                .tag(1)

            WorkoutEditView()
                .tabItem {
                    Label("אימונים", systemImage: selectedTab == 2 ? "dumbbell.fill" : "dumbbell")
                }
                .tag(2)

            ProgressViewScreen()
                .tabItem {
                    Label("סטטיסטיקות", systemImage: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(3)

            ExportView()
                .tabItem {
                    Label("ייצוא", systemImage: selectedTab == 4 ? "tablecells.fill" : "tablecells")
                }
                .tag(4)

            SettingsView()
                .tabItem {
                    Label("הגדרות", systemImage: selectedTab == 5 ? "gearshape.fill" : "gearshape")
                }
                .tag(5)
        }
        .accentColor(AppTheme.accent)
        .onAppear {
            setupAppearance()
        }
    }
    
    private func setupAppearance() {
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Selected tab color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.accent)
        ]
        
        // Unselected tab color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}
