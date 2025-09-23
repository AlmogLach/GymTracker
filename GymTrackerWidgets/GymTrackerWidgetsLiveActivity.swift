//
//  GymTrackerWidgetsLiveActivity.swift
//  GymTrackerWidgets
//
//  Created by almog lachiany on 23/09/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            // LOCK SCREEN - Simple version
            VStack(spacing: 8) {
                Text("Gym Tracker")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(context.state.exerciseName ?? "Rest")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(timerInterval: context.state.startedAt...context.state.endsAt)
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundColor(.white)
            }
            .padding(16)
            .activityBackgroundTint(Color.blue.opacity(0.8))
            .activitySystemActionForegroundColor(.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.exerciseName ?? "Rest")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startedAt...context.state.endsAt)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Link("Skip", destination: URL(string: "gymtracker://rest/skip")!)
                        Link("Stop", destination: URL(string: "gymtracker://rest/stop")!)
                        Link("Next", destination: URL(string: "gymtracker://exercise/next")!)
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.white)
            } compactTrailing: {
                Text(timerInterval: context.state.startedAt...context.state.endsAt)
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.white)
            }
        }
    }
}