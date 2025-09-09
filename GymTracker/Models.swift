//
//  Models.swift
//  GymTracker
//
//  Data models for Workout plans, sessions and settings
//

import Foundation
import SwiftData

@Model
final class WorkoutPlan {
    var name: String
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]
    var planTypeRaw: String
    var schedule: [PlannedDay]

    var planType: PlanType {
        get { PlanType(rawValue: planTypeRaw) ?? .fullBody }
        set { planTypeRaw = newValue.rawValue }
    }

    init(name: String, exercises: [Exercise] = [], planType: PlanType = .fullBody, schedule: [PlannedDay] = []) {
        self.name = name
        self.exercises = exercises
        self.planTypeRaw = planType.rawValue
        self.schedule = schedule
    }
}

enum PlanType: String, Codable, CaseIterable {
    case fullBody = "Full Body"
    case ab = "AB"
    case abc = "ABC"

    var workoutLabels: [String] {
        switch self {
        case .fullBody: return ["Full"]
        case .ab: return ["A", "B"]
        case .abc: return ["A", "B", "C"]
        }
    }
}

struct PlannedDay: Codable, Hashable {
    var weekday: Int // 1=Sun ... 7=Sat (Calendar current.weekday)
    var label: String // One of PlanType.workoutLabels
}

@Model
final class Exercise {
    var name: String
    var plannedSets: Int
    var plannedReps: Int?
    var notes: String?
    var label: String?

    init(name: String, plannedSets: Int, plannedReps: Int? = nil, notes: String? = nil, label: String? = nil) {
        self.name = name
        self.plannedSets = plannedSets
        self.plannedReps = plannedReps
        self.notes = notes
        self.label = label
    }
}

@Model
final class WorkoutSession {
    var date: Date
    var planName: String?
    var workoutLabel: String?
    @Relationship(deleteRule: .cascade) var exerciseSessions: [ExerciseSession]

    init(date: Date = Date(), planName: String? = nil, workoutLabel: String? = nil, exerciseSessions: [ExerciseSession] = []) {
        self.date = date
        self.planName = planName
        self.workoutLabel = workoutLabel
        self.exerciseSessions = exerciseSessions
    }
}

@Model
final class ExerciseSession {
    var exerciseName: String
    @Relationship(deleteRule: .cascade) var setLogs: [SetLog]

    init(exerciseName: String, setLogs: [SetLog] = []) {
        self.exerciseName = exerciseName
        self.setLogs = setLogs
    }
}

@Model
final class SetLog {
    var reps: Int
    var weight: Double
    var rpe: Double?
    var notes: String?

    init(reps: Int, weight: Double, rpe: Double? = nil, notes: String? = nil) {
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.notes = notes
    }
}

@Model
final class AppSettings {
    enum WeightUnit: String, Codable, CaseIterable {
        case kg
        case lb
    }

    var weightUnitRaw: String

    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
        set { weightUnitRaw = newValue.rawValue }
    }

    init(weightUnit: WeightUnit = .kg) {
        self.weightUnitRaw = weightUnit.rawValue
    }
}

// MARK: - Unit helpers
extension AppSettings.WeightUnit {
    var symbol: String { self == .kg ? "ק" + "" + "ג" : "lb" }
    func toDisplay(fromKg valueKg: Double) -> Double { self == .kg ? valueKg : valueKg * 2.2046226218 }
    func toKg(fromDisplay value: Double) -> Double { self == .kg ? value : value / 2.2046226218 }
}


