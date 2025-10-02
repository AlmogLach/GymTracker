//
//  GymTrackerHomeWidgets.swift
//  GymTrackerWidgets
//
//  Home Screen Widgets for GymTracker
//

import WidgetKit
import SwiftUI

// MARK: - Widget Provider
struct GymTrackerProvider: TimelineProvider {
    func placeholder(in context: Context) -> GymTrackerEntry {
        GymTrackerEntry(
            date: Date(),
            todayWorkout: "חזה וטריצפס",
            isCompleted: false,
            totalVolume: 2500.0,
            workoutsThisWeek: 3,
            streakCount: 7,
            currentProgram: "ABC - שבוע 3, יום 2",
            weeklyData: [2, 3, 1, 4, 2, 3, 1],
            goalsProgress: [
                ("סקוואט", 95.0, 100.0),
                ("לחיצת חזה", 80.0, 100.0)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (GymTrackerEntry) -> ()) {
        let entry = GymTrackerEntry(
            date: Date(),
            todayWorkout: "חזה וטריצפס",
            isCompleted: false,
            totalVolume: 2500.0,
            workoutsThisWeek: 3,
            streakCount: 7,
            currentProgram: "ABC - שבוע 3, יום 2",
            weeklyData: [2, 3, 1, 4, 2, 3, 1],
            goalsProgress: [
                ("סקוואט", 95.0, 100.0),
                ("לחיצת חזה", 80.0, 100.0)
            ]
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GymTrackerEntry>) -> ()) {
        let currentDate = Date()
        let entry = GymTrackerEntry(
            date: currentDate,
            todayWorkout: "חזה וטריצפס",
            isCompleted: false,
            totalVolume: 2500.0,
            workoutsThisWeek: 3,
            streakCount: 7,
            currentProgram: "ABC - שבוע 3, יום 2",
            weeklyData: [2, 3, 1, 4, 2, 3, 1],
            goalsProgress: [
                ("סקוואט", 95.0, 100.0),
                ("לחיצת חזה", 80.0, 100.0)
            ]
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry
struct GymTrackerEntry: TimelineEntry {
    let date: Date
    let todayWorkout: String
    let isCompleted: Bool
    let totalVolume: Double
    let workoutsThisWeek: Int
    let streakCount: Int
    let currentProgram: String
    let weeklyData: [Int]
    let goalsProgress: [(String, Double, Double)] // (name, current, target)
}

// MARK: - Small Widget View
struct GymTrackerSmallWidgetView: View {
    var entry: GymTrackerProvider.Entry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                
                Spacer()
                
                if entry.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            
            VStack(spacing: 4) {
                Text(entry.todayWorkout)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if entry.isCompleted {
                    Text("הושלם ✅")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("\(Int(entry.totalVolume)) ק״ג")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                } else {
                    Text("התחל אימון")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(12)
    }
}

// MARK: - Medium Widget View
struct GymTrackerMediumWidgetView: View {
    var entry: GymTrackerProvider.Entry

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Today's workout
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("אימון היום")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.todayWorkout)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(entry.currentProgram)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                if entry.isCompleted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("הושלם - \(Int(entry.totalVolume)) ק״ג")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.green)
                    }
                } else {
                    Button("התחל אימון") {
                        // Open app to start workout
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            
            // Right side - Weekly stats
            VStack(alignment: .trailing, spacing: 8) {
                HStack {
                    Text("השבוע")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Text("\(entry.workoutsThisWeek)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("אימונים")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("\(entry.streakCount)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Text("ימי רצף")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Large Widget View
struct GymTrackerLargeWidgetView: View {
    var entry: GymTrackerProvider.Entry

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("GymTracker")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if entry.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                        Text("הושלם")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Today's workout section
            VStack(alignment: .leading, spacing: 8) {
                Text("אימון היום")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.todayWorkout)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(entry.currentProgram)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !entry.isCompleted {
                        Button("התחל") {
                            // Open app to start workout
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(10)
                    } else {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(Int(entry.totalVolume)) ק״ג")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text("נפח כולל")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Weekly chart
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("פעילות השבוע")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(entry.workoutsThisWeek) אימונים")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                // Simple bar chart
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        VStack(spacing: 2) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: 20, height: CGFloat(entry.weeklyData[index]) * 8)
                            
                            Text(["א", "ב", "ג", "ד", "ה", "ו", "ש"][index])
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 60)
            }
            
            // Goals progress
            VStack(alignment: .leading, spacing: 6) {
                Text("מטרות")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                ForEach(entry.goalsProgress, id: \.0) { goal in
                    HStack {
                        Text(goal.0)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(Int(goal.1))/\(Int(goal.2)) ק״ג")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.orange)
                                .frame(width: geometry.size.width * (goal.1 / goal.2), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
        }
        .padding(16)
    }
}
