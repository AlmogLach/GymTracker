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
    var muscleGroup: String?
    var equipment: String?
    var isBodyweight: Bool
    var isFavorite: Bool

    init(name: String, plannedSets: Int, plannedReps: Int? = nil, notes: String? = nil, label: String? = nil, muscleGroup: String? = nil, equipment: String? = nil, isBodyweight: Bool = false, isFavorite: Bool = false) {
        self.name = name
        self.plannedSets = plannedSets
        self.plannedReps = plannedReps
        self.notes = notes
        self.label = label
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.isBodyweight = isBodyweight
        self.isFavorite = isFavorite
    }
}

@Model
final class WorkoutSession {
    var date: Date
    var planName: String?
    var workoutLabel: String?
    var durationSeconds: Int?
    var notes: String?
    var isCompleted: Bool
    @Relationship(deleteRule: .cascade) var exerciseSessions: [ExerciseSession]

    init(date: Date = Date(), planName: String? = nil, workoutLabel: String? = nil, durationSeconds: Int? = nil, notes: String? = nil, isCompleted: Bool = false, exerciseSessions: [ExerciseSession] = []) {
        self.date = date
        self.planName = planName
        self.workoutLabel = workoutLabel
        self.durationSeconds = durationSeconds
        self.notes = notes
        self.isCompleted = isCompleted
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
    var restSeconds: Int?
    var isWarmup: Bool

    init(reps: Int, weight: Double, rpe: Double? = nil, notes: String? = nil, restSeconds: Int? = nil, isWarmup: Bool = false) {
        self.reps = reps
        self.weight = weight
        self.rpe = rpe
        self.notes = notes
        self.restSeconds = restSeconds
        self.isWarmup = isWarmup
    }
}

@Model
final class AppSettings {
    enum WeightUnit: String, Codable, CaseIterable {
        case kg
        case lb
    }
    enum AutoProgressionMode: String, Codable, CaseIterable { case percent, repCycle }

    var weightUnitRaw: String

    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
        set { weightUnitRaw = newValue.rawValue }
    }

    // Rest and progression settings
    var defaultRestSeconds: Int
    var weightIncrementKg: Double
    var weightIncrementLb: Double
    var dumbbellIncrementKg: Double
    var dumbbellIncrementLb: Double
    var autoProgressionModeRaw: String
    var autoProgressionPercent: Double

    var autoProgressionMode: AutoProgressionMode {
        get { AutoProgressionMode(rawValue: autoProgressionModeRaw) ?? .percent }
        set { autoProgressionModeRaw = newValue.rawValue }
    }

    init(weightUnit: WeightUnit = .kg,
         defaultRestSeconds: Int = 120,
         weightIncrementKg: Double = 2.5,
         weightIncrementLb: Double = 5,
         dumbbellIncrementKg: Double = 1.0,
         dumbbellIncrementLb: Double = 2.5,
         autoProgressionMode: AutoProgressionMode = .percent,
         autoProgressionPercent: Double = 2.5) {
        self.weightUnitRaw = weightUnit.rawValue
        self.defaultRestSeconds = defaultRestSeconds
        self.weightIncrementKg = weightIncrementKg
        self.weightIncrementLb = weightIncrementLb
        self.dumbbellIncrementKg = dumbbellIncrementKg
        self.dumbbellIncrementLb = dumbbellIncrementLb
        self.autoProgressionModeRaw = autoProgressionMode.rawValue
        self.autoProgressionPercent = autoProgressionPercent
    }
}

// MARK: - Unit helpers
extension AppSettings.WeightUnit {
    var symbol: String { self == .kg ? "ק" + "" + "ג" : "lb" }
    func toDisplay(fromKg valueKg: Double) -> Double { self == .kg ? valueKg : valueKg * 2.2046226218 }
    func toKg(fromDisplay value: Double) -> Double { self == .kg ? value : value / 2.2046226218 }
}


