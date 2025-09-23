//
//  RestActivityAttributes.swift
//  GymTrackerWidgets
//
//  Created by almog lachiany on 23/09/2025.
//

import ActivityKit

@available(iOS 16.1, *)
struct RestActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var exerciseName: String?
        var startedAt: Date
        var endsAt: Date
    }
    var workoutLabel: String?
}
