//
//  GymTrackerWidgetsLiveActivity.swift
//  GymTrackerWidgets
//
//  Created by almog lachiany on 23/09/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 16.1, *)
struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            // LOCK SCREEN - Simple version
            VStack(spacing: 12) {
                Text("Gym Tracker")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(context.state.exerciseName ?? "Rest")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                if context.state.remainingSeconds > 0 {
                    Text(timerInterval: context.state.startedAt...context.state.endsAt)
                        .font(.title2)
                        .monospacedDigit()
                        .foregroundColor(.white)
                    
                    // Rest timer buttons
                    HStack(spacing: 16) {
                        Link("Skip", destination: URL(string: "gymtracker://rest/skip")!)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        
                        Link("Stop", destination: URL(string: "gymtracker://rest/stop")!)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        
                        Link("+1min", destination: URL(string: "gymtracker://rest/addminute")!)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                } else {
                    Text("Workout in Progress")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Workout session buttons
                    VStack(spacing: 8) {
                        HStack(spacing: 16) {
                            Link("Log Set", destination: URL(string: "gymtracker://workout/logset")!)
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            
                            Link("Next Ex", destination: URL(string: "gymtracker://workout/nextexercise")!)
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                        HStack(spacing: 16) {
                            Link("Rest", destination: URL(string: "gymtracker://workout/startrest")!)
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            
                            Link("Finish", destination: URL(string: "gymtracker://workout/finish")!)
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }
                }
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
                    if context.state.remainingSeconds > 0 {
                        Text(timerInterval: context.state.startedAt...context.state.endsAt)
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundColor(.white)
                    } else {
                        Text("In Progress")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.remainingSeconds > 0 {
                        // Rest timer controls
                        HStack(spacing: 12) {
                            Link("Skip", destination: URL(string: "gymtracker://rest/skip")!)
                                .font(.caption)
                                .foregroundStyle(.blue)
                            
                            Link("Stop", destination: URL(string: "gymtracker://rest/stop")!)
                                .font(.caption)
                                .foregroundStyle(.blue)
                            
                            Link("+1min", destination: URL(string: "gymtracker://rest/addminute")!)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    } else {
                        // Workout session controls
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Link("Log Set", destination: URL(string: "gymtracker://workout/logset")!)
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                
                                Link("Next Ex", destination: URL(string: "gymtracker://workout/nextexercise")!)
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            HStack(spacing: 12) {
                                Link("Rest", destination: URL(string: "gymtracker://workout/startrest")!)
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                
                                Link("Finish", destination: URL(string: "gymtracker://workout/finish")!)
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.white)
            } compactTrailing: {
                if context.state.remainingSeconds > 0 {
                    Text(timerInterval: context.state.startedAt...context.state.endsAt)
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.white)
                }
            } minimal: {
                if context.state.remainingSeconds > 0 {
                    Image(systemName: "timer")
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.white)
                }
            }
        }
    }
}