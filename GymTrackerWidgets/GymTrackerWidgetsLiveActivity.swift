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
            // LOCK SCREEN - Professional gym tracker design
            VStack(spacing: 20) {
                // Professional header
                HStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GymTracker")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(context.attributes.workoutLabel ?? "אימון")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                if context.state.remainingSeconds > 0 {
                    // Rest timer - Professional design
                    VStack(spacing: 16) {
                        Text("מנוחה")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(context.state.exerciseName ?? "תרגיל הבא")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        
                        // Professional timer with progress ring
                        ZStack {
                            // Background ring
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 6)
                                .frame(width: 120, height: 120)
                            
                            // Progress ring
                            Circle()
                                .trim(from: 0, to: CGFloat(context.state.remainingSeconds) / CGFloat(120))
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1), value: context.state.remainingSeconds)
                            
                            // Timer text
                            VStack(spacing: 2) {
                                Text(timerInterval: context.state.startedAt...context.state.endsAt)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                    .foregroundColor(.white)
                                
                                Text("דקות")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // Professional control buttons
                        HStack(spacing: 12) {
                            Link(destination: URL(string: "gymtracker://rest/skip")!) {
                                VStack(spacing: 4) {
                                    Image(systemName: "forward.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    Text("דלג")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 60, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.8))
                                )
                            }
                            
                            Link(destination: URL(string: "gymtracker://rest/stop")!) {
                                VStack(spacing: 4) {
                                    Image(systemName: "stop.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    Text("עצור")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 60, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.8))
                                )
                            }
                            
                            Link(destination: URL(string: "gymtracker://rest/addminute")!) {
                                VStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                    Text("+1 דק׳")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 60, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green.opacity(0.8))
                                )
                            }
                        }
                    }
                } else {
                    // Workout in progress - Professional design
                    VStack(spacing: 16) {
                        Text("אימון פעיל")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(context.state.exerciseName ?? "תרגיל נוכחי")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        
                        // Professional workout controls
                        VStack(spacing: 12) {
                            // Primary actions
                            HStack(spacing: 12) {
                                Link(destination: URL(string: "gymtracker://workout/logset")!) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                        Text("הוסף סט")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 70, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.green.opacity(0.8))
                                    )
                                }
                                
                                Link(destination: URL(string: "gymtracker://workout/nextexercise")!) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                        Text("הבא")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 70, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.8))
                                    )
                                }
                            }
                            
                            // Secondary actions
                            HStack(spacing: 12) {
                                Link(destination: URL(string: "gymtracker://workout/startrest")!) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "timer")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                        Text("מנוחה")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 70, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.orange.opacity(0.8))
                                    )
                                }
                                
                                Link(destination: URL(string: "gymtracker://workout/finish")!) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                        Text("סיים")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 70, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.red.opacity(0.8))
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.9),
                                Color.black.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .activityBackgroundTint(Color.clear)
            .activitySystemActionForegroundColor(.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.8))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.exerciseName ?? "אימון")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(context.attributes.workoutLabel ?? "")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.remainingSeconds > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
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
                        VStack(alignment: .trailing, spacing: 4) {
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
                        // Rest timer controls - Professional design
                        HStack(spacing: 16) {
                            Link(destination: URL(string: "gymtracker://rest/skip")!) {
                                VStack(spacing: 2) {
                                    Image(systemName: "forward.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Text("דלג")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 50, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.8))
                                )
                            }
                            
                            Link(destination: URL(string: "gymtracker://rest/stop")!) {
                                VStack(spacing: 2) {
                                    Image(systemName: "stop.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Text("עצור")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 50, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.8))
                                )
                            }
                            
                            Link(destination: URL(string: "gymtracker://rest/addminute")!) {
                                VStack(spacing: 2) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Text("+1 דק׳")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 50, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.green.opacity(0.8))
                                )
                            }
                        }
                    } else {
                        // Workout session controls - Professional design
                        VStack(spacing: 8) {
                            HStack(spacing: 16) {
                                Link(destination: URL(string: "gymtracker://workout/logset")!) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        Text("הוסף סט")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 60, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.green.opacity(0.8))
                                    )
                                }
                                
                                Link(destination: URL(string: "gymtracker://workout/nextexercise")!) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        Text("הבא")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 60, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.8))
                                    )
                                }
                            }
                            
                            HStack(spacing: 16) {
                                Link(destination: URL(string: "gymtracker://workout/startrest")!) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "timer")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        Text("מנוחה")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 60, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.8))
                                    )
                                }
                                
                                Link(destination: URL(string: "gymtracker://workout/finish")!) {
                                    VStack(spacing: 2) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        Text("סיים")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 60, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.red.opacity(0.8))
                                    )
                                }
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
