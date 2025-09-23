//
//  AppIntent.swift
//  GymTrackerWidgets
//
//  Created by almog lachiany on 23/09/2025.
//

import WidgetKit
import AppIntents
import Foundation

// MARK: - Notification Names
extension Notification.Name {
    static let restSkipAction = Notification.Name("rest_skip_action")
    static let restStopAction = Notification.Name("rest_stop_action")
    static let restAddMinuteAction = Notification.Name("rest_add_minute_action")
    static let nextExerciseAction = Notification.Name("next_exercise_action")
    static let logSetAction = Notification.Name("log_set_action")
    static let startRestAction = Notification.Name("start_rest_action")
    static let finishWorkoutAction = Notification.Name("finish_workout_action")
}

// MARK: - Rest Timer Intents

struct RestSkipIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Rest"
    static var description: IntentDescription = "Skip the current rest period"
    
    func perform() async throws -> some IntentResult {
        print("🔗 RestSkipIntent: Executing skip rest")
        
        // Use UserDefaults with App Group to communicate with main app
        let sharedDefaults = UserDefaults(suiteName: "group.com.gymtracker.shared")
        sharedDefaults?.set("rest_skip", forKey: "widget_action")
        sharedDefaults?.set(Date(), forKey: "widget_action_timestamp")
        
        // Also try posting notification
        NotificationCenter.default.post(name: .restSkipAction, object: nil)
        print("🔗 RestSkipIntent: Action sent via UserDefaults and notification")
        return .result()
    }
}

struct RestStopIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Rest"
    static var description: IntentDescription = "Stop the current rest timer"
    
    func perform() async throws -> some IntentResult {
        print("🔗 RestStopIntent: Executing stop rest")
        
        let sharedDefaults = UserDefaults(suiteName: "group.com.gymtracker.shared")
        sharedDefaults?.set("rest_stop", forKey: "widget_action")
        sharedDefaults?.set(Date(), forKey: "widget_action_timestamp")
        
        NotificationCenter.default.post(name: .restStopAction, object: nil)
        print("🔗 RestStopIntent: Action sent via UserDefaults and notification")
        return .result()
    }
}

struct RestAddMinuteIntent: AppIntent {
    static var title: LocalizedStringResource = "Add 1 Minute"
    static var description: IntentDescription = "Add 1 minute to rest timer"
    
    func perform() async throws -> some IntentResult {
        print("🔗 RestAddMinuteIntent: Executing add minute")
        
        let sharedDefaults = UserDefaults(suiteName: "group.com.gymtracker.shared")
        sharedDefaults?.set("rest_add_minute", forKey: "widget_action")
        sharedDefaults?.set(Date(), forKey: "widget_action_timestamp")
        
        NotificationCenter.default.post(name: .restAddMinuteAction, object: nil)
        print("🔗 RestAddMinuteIntent: Action sent via UserDefaults and notification")
        return .result()
    }
}

// MARK: - Workout Intents

struct LogSetIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Set"
    static var description: IntentDescription = "Log the current set"
    
    func perform() async throws -> some IntentResult {
        print("🔗 LogSetIntent: Executing log set")
        
        let sharedDefaults = UserDefaults(suiteName: "group.com.gymtracker.shared")
        sharedDefaults?.set("log_set", forKey: "widget_action")
        sharedDefaults?.set(Date(), forKey: "widget_action_timestamp")
        
        NotificationCenter.default.post(name: .logSetAction, object: nil)
        print("🔗 LogSetIntent: Action sent via UserDefaults and notification")
        return .result()
    }
}

struct NextExerciseIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Exercise"
    static var description: IntentDescription = "Move to next exercise"
    
    func perform() async throws -> some IntentResult {
        print("🔗 NextExerciseIntent: Executing next exercise")
        
        let sharedDefaults = UserDefaults(suiteName: "group.com.gymtracker.shared")
        sharedDefaults?.set("next_exercise", forKey: "widget_action")
        sharedDefaults?.set(Date(), forKey: "widget_action_timestamp")
        
        NotificationCenter.default.post(name: .nextExerciseAction, object: nil)
        print("🔗 NextExerciseIntent: Action sent via UserDefaults and notification")
        return .result()
    }
}

struct StartRestIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Rest"
    static var description: IntentDescription = "Start rest timer"
    
    func perform() async throws -> some IntentResult {
        print("🔗 StartRestIntent: Executing start rest")
        
        let sharedDefaults = UserDefaults(suiteName: "group.com.gymtracker.shared")
        sharedDefaults?.set("start_rest", forKey: "widget_action")
        sharedDefaults?.set(Date(), forKey: "widget_action_timestamp")
        
        NotificationCenter.default.post(name: .startRestAction, object: nil)
        print("🔗 StartRestIntent: Action sent via UserDefaults and notification")
        return .result()
    }
}

struct FinishWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Finish Workout"
    static var description: IntentDescription = "Complete the workout"
    
    func perform() async throws -> some IntentResult {
        print("🔗 FinishWorkoutIntent: Executing finish workout")
        
        let sharedDefaults = UserDefaults(suiteName: "group.com.gymtracker.shared")
        sharedDefaults?.set("finish_workout", forKey: "widget_action")
        sharedDefaults?.set(Date(), forKey: "widget_action_timestamp")
        
        NotificationCenter.default.post(name: .finishWorkoutAction, object: nil)
        print("🔗 FinishWorkoutIntent: Action sent via UserDefaults and notification")
        return .result()
    }
}
