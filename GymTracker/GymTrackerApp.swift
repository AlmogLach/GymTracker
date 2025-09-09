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
        let modelConfiguration = ModelConfiguration(
            "default_v2",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Add sample data if none exists
                    let context = sharedModelContainer.mainContext
                    let plans = try? context.fetch(FetchDescriptor<WorkoutPlan>())
                    if plans?.isEmpty == true {
                        let samplePlan = WorkoutPlan(
                            name: "תוכנית בסיסית",
                            planType: .fullBody,
                            schedule: [
                                PlannedDay(weekday: 1, label: "Full"),
                                PlannedDay(weekday: 3, label: "Full"),
                                PlannedDay(weekday: 5, label: "Full")
                            ]
                        )
                        context.insert(samplePlan)
                        
                        let sampleExercise = Exercise(
                            name: "סקוואט",
                            plannedSets: 3,
                            plannedReps: 10,
                            label: "Full"
                        )
                        context.insert(sampleExercise)
                        samplePlan.exercises.append(sampleExercise)
                        
                        try? context.save()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
