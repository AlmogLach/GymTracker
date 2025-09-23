//
//  AppIntents.swift
//  GymTracker
//
//  Created by almog lachiany on 23/09/2025.
//

import AppIntents
import Foundation

// Note: Notification names are defined in NotificationManager.swift

// MARK: - Rest Timer Intents

struct RestSkipIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Rest"
    static var description: IntentDescription = "Skip the current rest period"
    
    func perform() async throws -> some IntentResult {
        print("🔗 RestSkipIntent: Executing skip rest")
        print("🔗 RestSkipIntent: About to post notification")
        NotificationCenter.default.post(name: .restSkipAction, object: nil)
        print("🔗 RestSkipIntent: Notification posted successfully")
        return .result()
    }
}

struct RestStopIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Rest"
    static var description: IntentDescription = "Stop the current rest timer"
    
    func perform() async throws -> some IntentResult {
        print("🔗 RestStopIntent: Executing stop rest")
        NotificationCenter.default.post(name: .restStopAction, object: nil)
        return .result()
    }
}

struct RestAddMinuteIntent: AppIntent {
    static var title: LocalizedStringResource = "Add 1 Minute"
    static var description: IntentDescription = "Add 1 minute to rest timer"
    
    func perform() async throws -> some IntentResult {
        print("🔗 RestAddMinuteIntent: Executing add minute")
        NotificationCenter.default.post(name: .restAddMinuteAction, object: nil)
        return .result()
    }
}

// MARK: - Workout Intents

struct LogSetIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Set"
    static var description: IntentDescription = "Log the current set"
    
    func perform() async throws -> some IntentResult {
        print("🔗 LogSetIntent: Executing log set")
        NotificationCenter.default.post(name: .logSetAction, object: nil)
        return .result()
    }
}

struct NextExerciseIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Exercise"
    static var description: IntentDescription = "Move to next exercise"
    
    func perform() async throws -> some IntentResult {
        print("🔗 NextExerciseIntent: Executing next exercise")
        NotificationCenter.default.post(name: .nextExerciseAction, object: nil)
        return .result()
    }
}

struct StartRestIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Rest"
    static var description: IntentDescription = "Start rest timer"
    
    func perform() async throws -> some IntentResult {
        print("🔗 StartRestIntent: Executing start rest")
        NotificationCenter.default.post(name: .startRestAction, object: nil)
        return .result()
    }
}

struct FinishWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Finish Workout"
    static var description: IntentDescription = "Complete the workout"
    
    func perform() async throws -> some IntentResult {
        print("🔗 FinishWorkoutIntent: Executing finish workout")
        NotificationCenter.default.post(name: .finishWorkoutAction, object: nil)
        return .result()
    }
}
