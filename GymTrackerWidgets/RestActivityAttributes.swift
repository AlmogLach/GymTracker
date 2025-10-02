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
        var isRest: Bool
        var exerciseName: String?
        var remainingSeconds: Int?
        var startedAt: Date
        var endsAt: Date
        var setsCompleted: Int?
        var setsPlanned: Int?
        var elapsedWorkoutSeconds: Int
        
        public init(
            isRest: Bool,
            exerciseName: String?,
            remainingSeconds: Int? = nil,
            startedAt: Date,
            endsAt: Date,
            setsCompleted: Int? = nil,
            setsPlanned: Int? = nil,
            elapsedWorkoutSeconds: Int
        ) {
            self.isRest = isRest
            self.exerciseName = exerciseName
            self.remainingSeconds = remainingSeconds
            self.startedAt = startedAt
            self.endsAt = endsAt
            self.setsCompleted = setsCompleted
            self.setsPlanned = setsPlanned
            self.elapsedWorkoutSeconds = elapsedWorkoutSeconds
        }
    }
    var workoutLabel: String?
    
    public init(workoutLabel: String?) {
        self.workoutLabel = workoutLabel
    }
}
