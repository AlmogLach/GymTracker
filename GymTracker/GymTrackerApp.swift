//
//  GymTrackerApp.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

@main
struct GymTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutPlan.self,
            Exercise.self,
            WorkoutSession.self,
            ExerciseSession.self,
            SetLog.self,
            AppSettings.self,
        ])
        var modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        modelConfiguration.url = URL(fileURLWithPath: "default_v2.store", relativeTo: URL.applicationSupportDirectory)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
