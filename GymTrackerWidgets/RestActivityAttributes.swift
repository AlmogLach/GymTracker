//
//  RestActivityAttributes.swift
//  GymTrackerWidgets
//
//  Created by almog lachiany on 23/09/2025.
//

import Foundation
import ActivityKit

@available(iOS 16.1, *)
struct RestActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var exerciseName: String?
        var startedAt: Date
        var endsAt: Date
        
        public init(remainingSeconds: Int, exerciseName: String?, startedAt: Date, endsAt: Date) {
            self.remainingSeconds = remainingSeconds
            self.exerciseName = exerciseName
            self.startedAt = startedAt
            self.endsAt = endsAt
        }
    }
    var workoutLabel: String?
    
    public init(workoutLabel: String?) {
        self.workoutLabel = workoutLabel
    }
}
