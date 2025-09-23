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
        
        // Clean up old database files
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        // Remove old database files
        let oldFiles = ["default_v2.store", "default_v4.store", "default_v5.store", "default_v6.store"]
        for fileName in oldFiles {
            let fileURL = documentsPath.appendingPathComponent(fileName)
            if fileManager.fileExists(atPath: fileURL.path) {
                try? fileManager.removeItem(at: fileURL)
                print("Removed old database file: \(fileName)")
            }
        }
        let modelConfiguration = ModelConfiguration(
            "gymtracker_fixed",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, try with a fresh database
            print("Migration failed, creating fresh database: \(error)")
            let freshConfiguration = ModelConfiguration(
                "gymtracker_backup",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            do {
                let container = try ModelContainer(for: schema, configurations: [freshConfiguration])
                // Create sample data in the fresh container
                GymTrackerApp.createSampleDataIfNeeded(container: container)
                return container
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.layoutDirection, .rightToLeft)
                .onAppear {
                    NotificationManager.shared.requestAuthorizationIfNeeded()
                    UIView.appearance().semanticContentAttribute = .forceRightToLeft
                    UILabel.appearance().semanticContentAttribute = .forceRightToLeft
                    UINavigationBar.appearance().semanticContentAttribute = .forceRightToLeft
                    UITabBar.appearance().semanticContentAttribute = .forceRightToLeft
                    UITableView.appearance().semanticContentAttribute = .forceRightToLeft
                    UICollectionView.appearance().semanticContentAttribute = .forceRightToLeft
                    UIScrollView.appearance().semanticContentAttribute = .forceRightToLeft
                    UITextField.appearance().textAlignment = .right
                    UITextView.appearance().textAlignment = .right
                    let context = sharedModelContainer.mainContext

                    // Fix any orphaned exercises and ensure proper relationships
                    do {
                        let allPlans = try context.fetch(FetchDescriptor<WorkoutPlan>())
                        let allExercises = try context.fetch(FetchDescriptor<Exercise>())
                        
                        print("Found \(allPlans.count) plans and \(allExercises.count) exercises")


                        // Fix plans and exercises that don't have proper IDs and relationships
                        for plan in allPlans {
                            if plan.id == nil {
                                plan.id = UUID()
                            }
                            for exercise in plan.exercises {
                                if exercise.workoutPlan == nil {
                                    exercise.workoutPlan = plan
                                }
                                if exercise.id == nil {
                                    exercise.id = UUID()
                                }
                            }
                        }

                        // Remove orphaned exercises that aren't in any plan
                        let exercisesInPlans = Set(allPlans.flatMap { $0.exercises.compactMap { $0.id } })
                        for exercise in allExercises {
                            if let exerciseId = exercise.id, !exercisesInPlans.contains(exerciseId) {
                                context.delete(exercise)
                            }
                        }

                        try context.save()

                        // Add sample data if no plans exist
                        if allPlans.isEmpty {
                            let samplePlan = WorkoutPlan(
                                name: "תוכנית בסיסית",
                                planType: .fullBody,
                                schedule: [
                                    PlannedDay(weekday: 1, label: "Full"),
                                    PlannedDay(weekday: 3, label: "Full"),
                                    PlannedDay(weekday: 5, label: "Full")
                                ]
                            )
                            // Ensure the plan has an ID
                            if samplePlan.id == nil {
                                samplePlan.id = UUID()
                            }
                            context.insert(samplePlan)

                            let sampleExercise = Exercise(
                                name: "סקוואט",
                                plannedSets: 3,
                                plannedReps: 10,
                                label: "Full",
                                workoutDay: nil
                            )
                            // Ensure the exercise has an ID
                            if sampleExercise.id == nil {
                                sampleExercise.id = UUID()
                            }
                            sampleExercise.workoutPlan = samplePlan
                            context.insert(sampleExercise)
                            samplePlan.exercises.append(sampleExercise)

                            try context.save()
                            print("Sample data created successfully")
                        }
                    } catch {
                        print("Error during data migration: \(error)")
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private static func createSampleDataIfNeeded(container: ModelContainer) {
        let context = container.mainContext
        do {
            let allPlans = try context.fetch(FetchDescriptor<WorkoutPlan>())
            if allPlans.isEmpty {
                let samplePlan = WorkoutPlan(
                    name: "תוכנית בסיסית",
                    planType: .fullBody,
                    schedule: [
                        PlannedDay(weekday: 1, label: "Full"),
                        PlannedDay(weekday: 3, label: "Full"),
                        PlannedDay(weekday: 5, label: "Full")
                    ]
                )
                if samplePlan.id == nil {
                    samplePlan.id = UUID()
                }
                context.insert(samplePlan)
                
                let sampleExercise = Exercise(
                    name: "סקוואט",
                    plannedSets: 3,
                    plannedReps: 10,
                    label: "Full",
                    workoutDay: nil
                )
                if sampleExercise.id == nil {
                    sampleExercise.id = UUID()
                }
                sampleExercise.workoutPlan = samplePlan
                context.insert(sampleExercise)
                samplePlan.exercises.append(sampleExercise)
                
                try context.save()
                print("Sample data created in fresh container")
            }
        } catch {
            print("Error creating sample data: \(error)")
        }
    }
}
