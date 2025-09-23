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
            // LOCK SCREEN - Enhanced professional version
            VStack(spacing: 16) {
                // Header with app branding
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("GymTracker")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                if context.state.remainingSeconds > 0 {
                    // Rest timer section
                    VStack(spacing: 12) {
                        Text("מנוחה")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(context.state.exerciseName ?? "תרגיל הבא")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        // Timer with circular progress
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(context.state.remainingSeconds) / CGFloat(120)) // Assuming 2 min default
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            
                            Text(timerInterval: context.state.startedAt...context.state.endsAt)
                                .font(.title2)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(.white)
                        }
                        
                        // Control buttons
                        HStack(spacing: 12) {
                            Link("דלג", destination: URL(string: "gymtracker://rest/skip")!)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.8))
                                .clipShape(Capsule())
                            
                            Link("עצור", destination: URL(string: "gymtracker://rest/stop")!)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Capsule())
                            
                            Link("+1 דק׳", destination: URL(string: "gymtracker://rest/addminute")!)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.8))
                                .clipShape(Capsule())
                        }
                    }
                } else {
                    // Workout in progress section
                    VStack(spacing: 12) {
                        Text("אימון פעיל")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(context.state.exerciseName ?? "תרגיל נוכחי")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        // Workout controls
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Link("הוסף סט", destination: URL(string: "gymtracker://workout/logset")!)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.8))
                                    .clipShape(Capsule())
                                
                                Link("תרגיל הבא", destination: URL(string: "gymtracker://workout/nextexercise")!)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.8))
                                    .clipShape(Capsule())
                            }
                            
                            HStack(spacing: 12) {
                                Link("מנוחה", destination: URL(string: "gymtracker://workout/startrest")!)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.8))
                                    .clipShape(Capsule())
                                
                                Link("סיים", destination: URL(string: "gymtracker://workout/finish")!)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.8))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(20)
            .activityBackgroundTint(Color.black.opacity(0.9))
            .activitySystemActionForegroundColor(.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Text(context.state.exerciseName ?? "אימון")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.remainingSeconds > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(timerInterval: context.state.startedAt...context.state.endsAt)
                                .font(.headline)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(.white)
                            
                            Text("מנוחה")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                            
                            Text("פעיל")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.remainingSeconds > 0 {
                        // Rest timer controls
                        HStack(spacing: 16) {
                            Link("דלג", destination: URL(string: "gymtracker://rest/skip")!)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .clipShape(Capsule())
                            
                            Link("עצור", destination: URL(string: "gymtracker://rest/stop")!)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.2))
                                .clipShape(Capsule())
                            
                            Link("+1 דק׳", destination: URL(string: "gymtracker://rest/addminute")!)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    } else {
                        // Workout session controls
                        VStack(spacing: 8) {
                            HStack(spacing: 16) {
                                Link("הוסף סט", destination: URL(string: "gymtracker://workout/logset")!)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.2))
                                    .clipShape(Capsule())
                                
                                Link("תרגיל הבא", destination: URL(string: "gymtracker://workout/nextexercise")!)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            
                            HStack(spacing: 16) {
                                Link("מנוחה", destination: URL(string: "gymtracker://workout/startrest")!)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.2))
                                    .clipShape(Capsule())
                                
                                Link("סיים", destination: URL(string: "gymtracker://workout/finish")!)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.remainingSeconds > 0 ? "timer" : "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundColor(.white)
            } compactTrailing: {
                if context.state.remainingSeconds > 0 {
                    Text(timerInterval: context.state.startedAt...context.state.endsAt)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } minimal: {
                Image(systemName: context.state.remainingSeconds > 0 ? "timer" : "figure.strengthtraining.traditional")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
}
