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

// MARK: - Helper Functions
private func formatElapsedTime(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let secs = seconds % 60
    
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    } else {
        return String(format: "%d:%02d", minutes, secs)
    }
}

private func getExerciseIcon(_ exerciseName: String) -> String {
    let name = exerciseName.lowercased()
    if name.contains("סקוואט") || name.contains("squat") {
        return "figure.strengthtraining.traditional"
    } else if name.contains("לחיצה") || name.contains("press") || name.contains("bench") {
        return "figure.strengthtraining.functional"
    } else if name.contains("משיכה") || name.contains("pull") || name.contains("row") {
        return "figure.rower"
    } else if name.contains("דדליפט") || name.contains("deadlift") {
        return "figure.strengthtraining.traditional"
    } else if name.contains("פולאובר") || name.contains("pullover") {
        return "figure.strengthtraining.functional"
    } else {
        return "dumbbell.fill"
    }
}

@available(iOS 16.1, *)
struct RestLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestActivityAttributes.self) { context in
            // LOCK SCREEN - Professional gym tracker design
            VStack(spacing: 14) {
                // Professional header
                HStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GymTracker")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(context.attributes.workoutLabel ?? "אימון")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                // Consider rest state active if current time is before endsAt AND state indicates rest
                if context.state.isRest && Date() < context.state.endsAt {
                    // Ultra-compact rest timer design
                    VStack(spacing: 12) {
                        // Compact header
                        HStack(spacing: 8) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.orange)
                            
                            Text("מנוחה")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Next exercise preview
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.green)
                                
                                Text("הבא: \(context.state.exerciseName ?? "תרגיל הבא")")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        // Compact timer with small ring
                        HStack(spacing: 12) {
                            // Timer text
                            VStack(alignment: .leading, spacing: 2) {
                                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                                    Text(timerInterval: timeline.date...context.state.endsAt)
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundColor(.white)
                                }
                                
                                Text("דקות מנוחה")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Very small progress ring
                            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                                        .frame(width: 40, height: 40)

                                    let total = max(1.0, context.state.endsAt.timeIntervalSince(context.state.startedAt))
                                    let elapsed = max(0.0, timeline.date.timeIntervalSince(context.state.startedAt))
                                    let progress = max(0.0, min(1.0, elapsed / total))

                                    Circle()
                                        .trim(from: 0, to: progress)
                                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .frame(width: 40, height: 40)
                                        .rotationEffect(.degrees(-90))
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Compact control buttons - single row
                        HStack(spacing: 8) {
                            Link(destination: URL(string: "gymtracker://rest/skip")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text("דלג")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue)
                                )
                            }
                            
                            Link(destination: URL(string: "gymtracker://rest/stop")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text("עצור")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.red)
                                )
                            }
                            
                            Link(destination: URL(string: "gymtracker://rest/addminute")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text("+1")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.green)
                                )
                            }
                        }
                    }
                } else {
                    // Workout in progress - Enhanced actionable interface
                    VStack(spacing: 16) {
                        // Workout Overview Header
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                
                                Text("אימון פעיל")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Session timer
                                Text(formatElapsedTime(context.state.elapsedWorkoutSeconds))
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Current exercise with icon
                            HStack {
                                Image(systemName: getExerciseIcon(context.state.exerciseName ?? ""))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                
                                Text(context.state.exerciseName ?? "תרגיל נוכחי")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            // Progress indicator with visual bar
                            if let completed = context.state.setsCompleted, let planned = context.state.setsPlanned {
                                VStack(spacing: 4) {
                                    HStack {
                                        Text("סט \(completed) מתוך \(planned)")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Spacer()
                                        
                                        Text("\(Int(Double(completed) / Double(planned) * 100))%")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    // Visual progress bar
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.white.opacity(0.2))
                                                .frame(height: 6)
                                            
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.green, .blue],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: geometry.size.width * (Double(completed) / Double(planned)), height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                }
                            }
                        }

                        // Quick Actions - Context-aware
                        VStack(spacing: 12) {
                            // Primary action - Log Set (prominent)
                            Link(destination: URL(string: "gymtracker://workout/logset")!) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text("הוסף סט")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.green)
                                        .shadow(color: .green.opacity(0.4), radius: 6, y: 3)
                                )
                            }
                            
                            // Secondary actions row
                            HStack(spacing: 12) {
                                Link(destination: URL(string: "gymtracker://workout/startrest")!) {
                                    VStack(spacing: 3) {
                                        Image(systemName: "timer")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("מנוחה")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.orange)
                                            .shadow(color: .orange.opacity(0.3), radius: 4, y: 2)
                                    )
                                }
                                
                                Link(destination: URL(string: "gymtracker://workout/nextexercise")!) {
                                    VStack(spacing: 3) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("הבא")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.blue)
                                            .shadow(color: .blue.opacity(0.3), radius: 4, y: 2)
                                    )
                                }
                                
                                Link(destination: URL(string: "gymtracker://workout/finish")!) {
                                    VStack(spacing: 3) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("סיים")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.red)
                                            .shadow(color: .red.opacity(0.3), radius: 4, y: 2)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
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
                                .fill(Color.blue.opacity(0.9))
                                .frame(width: 28, height: 28)
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.exerciseName ?? "אימון")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(context.attributes.workoutLabel ?? "")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isRest && Date() < context.state.endsAt {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(timerInterval: context.state.startedAt...context.state.endsAt)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.white)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 6, height: 6)
                                Text("מנוחה")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                                    .tracking(0.5)
                            }
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 4) {
                            if let completed = context.state.setsCompleted, let planned = context.state.setsPlanned {
                                Text("\(completed)/\(planned)")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(.white)
                                Text("סטים")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                                    .tracking(0.5)
                            } else {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.green)
                                    .shadow(color: .green.opacity(0.5), radius: 2)
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 6, height: 6)
                                    Text("פעיל")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.7))
                                        .tracking(0.5)
                                }
                            }
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // Show rest controls ONLY when explicitly in rest mode
                    if context.state.isRest && Date() < context.state.endsAt {
                        // Rest timer controls - Apple Music style
                        HStack(spacing: 12) {
                            Link(destination: URL(string: "gymtracker://rest/skip")!) {
                                VStack(spacing: 3) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("דלג")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .frame(width: 44, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue.opacity(0.9))
                                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                                )
                            }
                            
                            Link(destination: URL(string: "gymtracker://rest/stop")!) {
                                VStack(spacing: 3) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("עצור")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .frame(width: 44, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.red.opacity(0.9))
                                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                                )
                            }
                            
                            Link(destination: URL(string: "gymtracker://rest/addminute")!) {
                                VStack(spacing: 3) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("+1 דק׳")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .frame(width: 44, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.green.opacity(0.9))
                                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                    } else {
                        // Workout mode - Log Set + Skip Rest
                        HStack(spacing: 12) {
                            Link(destination: URL(string: "gymtracker://workout/logset")!) {
                                VStack(spacing: 3) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("הוסף סט")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .frame(width: 52, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.green.opacity(0.9))
                                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                                )
                            }
                            
                            Link(destination: URL(string: "gymtracker://workout/startrest")!) {
                                VStack(spacing: 3) {
                                    Image(systemName: "timer")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("מנוחה")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                .frame(width: 52, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.orange.opacity(0.9))
                                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            } compactLeading: {
                if context.state.isRest && Date() < context.state.endsAt {
                    // Rest timer with progress indicator
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)
                        
                        Circle()
                            .trim(from: 0, to: 0.7) // Example progress
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "timer")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: getExerciseIcon(context.state.exerciseName ?? ""))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                if context.state.isRest && Date() < context.state.endsAt {
                    Text(timerInterval: Date()...context.state.endsAt)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                } else {
                    if let completed = context.state.setsCompleted, let planned = context.state.setsPlanned {
                        Text("\(completed)/\(planned)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            } minimal: {
                if context.state.isRest && Date() < context.state.endsAt {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: getExerciseIcon(context.state.exerciseName ?? ""))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
    }
}
