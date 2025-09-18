//
//  ProgressViewScreen.swift
//  GymTracker
//
//  Enhanced Progress View with Real Charts and Analytics
//

import SwiftUI
import SwiftData
import Charts

struct ProgressViewScreen: View {
    @Query private var settingsList: [AppSettings]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    @Query private var plans: [WorkoutPlan]
    
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var selectedMetric: ProgressMetric = .workouts
    @State private var showGoalSetting = false
    
    var unit: AppSettings.WeightUnit { settingsList.first?.weightUnit ?? .kg }
    
    enum TimeFrame: String, CaseIterable {
        case week = "שבוע"
        case month = "חודש"
        case year = "שנה"
        case all = "הכל"
    }
    
    enum ProgressMetric: String, CaseIterable {
        case workouts = "אימונים"
        case volume = "נפח"
        case duration = "זמן"
        case exercises = "תרגילים"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s24) {
                    // Time period selector
                    timeFrameSelector
                    
                    // Key metrics overview
                    keyMetricsOverview
                    
                    // Progress chart
                    progressChartSection
                    
                    // Exercise progress
                    exerciseProgressSection
                    
                    // Goals and achievements
                    goalsAndAchievementsSection
                    
                    // Weekly comparison
                    weeklyComparisonSection
                }
                .padding(AppTheme.s16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("סטטיסטיקות")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showGoalSetting = true }) {
                        Image(systemName: "target")
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showGoalSetting) {
            GoalSettingSheet()
        }
    }
    
    // MARK: - Time Frame Selector
    
    private var timeFrameSelector: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("תקופת זמן")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: AppTheme.s8) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Button(action: {
                        selectedTimeframe = timeframe
                    }) {
                        Text(timeframe.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, AppTheme.s16)
                            .padding(.vertical, AppTheme.s8)
                            .background(
                                selectedTimeframe == timeframe ? AppTheme.accent : Color(.systemGray6),
                                in: Capsule()
                            )
                            .foregroundStyle(selectedTimeframe == timeframe ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appCard()
    }
    
    // MARK: - Key Metrics Overview
    
    private var keyMetricsOverview: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            Text("מדדים עיקריים")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.s12) {
                MetricCard(
                    title: "אימונים השבוע",
                    value: "\(thisWeekSessions)",
                    subtitle: "מתוך \(weeklyGoal) מטרה",
                    icon: "figure.strengthtraining.traditional",
                    color: .blue,
                    progress: Double(thisWeekSessions) / Double(weeklyGoal)
                )
                
                MetricCard(
                    title: "נפח השבוע",
                    value: String(format: "%.0f %@", totalVolumeThisWeek, unit.symbol),
                    subtitle: "עלייה של \(volumeIncrease)%",
                    icon: "chart.bar.fill",
                    color: .green,
                    progress: min(1.0, volumeIncrease / 100)
                )
                
                MetricCard(
                    title: "זמן ממוצע",
                    value: averageWorkoutDuration,
                    subtitle: "לכל אימון",
                    icon: "clock.fill",
                    color: .orange,
                    progress: nil
                )
                
                MetricCard(
                    title: "רצף ימים",
                    value: "\(currentStreak)",
                    subtitle: "ימים רצופים",
                    icon: "flame.fill",
                    color: .red,
                    progress: min(1.0, Double(currentStreak) / 30)
                )
            }
        }
        .appCard()
    }
    
    // MARK: - Progress Chart Section
    
    private var progressChartSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            HStack {
                Text("התקדמות")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Picker("מדד", selection: $selectedMetric) {
                    ForEach(ProgressMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.menu)
            }
            
            if !chartData.isEmpty {
                Chart(chartData) { dataPoint in
                    LineMark(
                        x: .value("תאריך", dataPoint.date),
                        y: .value("ערך", dataPoint.value)
                    )
                    .foregroundStyle(AppTheme.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("תאריך", dataPoint.date),
                        y: .value("ערך", dataPoint.value)
                    )
                    .foregroundStyle(AppTheme.accent.opacity(0.1))
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            } else {
                EmptyChartView()
            }
        }
        .appCard()
    }
    
    // MARK: - Exercise Progress Section
    
    private var exerciseProgressSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            Text("התקדמות תרגילים")
                .font(.headline)
                .fontWeight(.bold)
            
            if !topExercises.isEmpty {
                VStack(spacing: AppTheme.s12) {
                    ForEach(Array(topExercises.prefix(5).enumerated()), id: \.offset) { index, exercise in
                        ExerciseProgressRow(
                            exercise: exercise.name,
                            currentWeight: exercise.maxWeight,
                            previousWeight: exercise.previousMaxWeight,
                            unit: unit.symbol,
                            rank: index + 1
                        )
                    }
                }
            } else {
                EmptyStateView(
                    iconSystemName: "dumbbell",
                    title: "אין נתוני תרגילים",
                    message: "התחל אימונים כדי לראות התקדמות"
                )
            }
        }
        .appCard()
    }
    
    // MARK: - Goals and Achievements Section
    
    private var goalsAndAchievementsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            Text("יעדים והישגים")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.s12) {
                AchievementCard(
                    title: "אימון ראשון",
                    description: "השלם את האימון הראשון",
                    icon: "star.fill",
                    color: .yellow,
                    isUnlocked: !sessions.isEmpty
                )
                
                AchievementCard(
                    title: "שבוע מלא",
                    description: "אימון בכל יום בשבוע",
                    icon: "calendar.badge.checkmark",
                    color: .green,
                    isUnlocked: thisWeekSessions >= 7
                )
                
                AchievementCard(
                    title: "100 אימונים",
                    description: "השלם 100 אימונים",
                    icon: "trophy.fill",
                    color: .purple,
                    isUnlocked: sessions.count >= 100
                )
                
                AchievementCard(
                    title: "רצף של 30 יום",
                    description: "אימון רצוף למשך 30 יום",
                    icon: "flame.fill",
                    color: .red,
                    isUnlocked: currentStreak >= 30
                )
            }
        }
        .appCard()
    }
    
    // MARK: - Weekly Comparison Section
    
    private var weeklyComparisonSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            Text("השוואת שבועות")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: AppTheme.s16) {
                WeekComparisonCard(
                    title: "השבוע",
                    workouts: thisWeekSessions,
                    volume: totalVolumeThisWeek,
                    unit: unit.symbol,
                    isCurrent: true
                )
                
                WeekComparisonCard(
                    title: "השבוע שעבר",
                    workouts: lastWeekSessions,
                    volume: totalVolumeLastWeek,
                    unit: unit.symbol,
                    isCurrent: false
                )
            }
        }
        .appCard()
    }
    
    // MARK: - Computed Properties
    
    private var thisWeekSessions: Int {
        let calendar = Calendar.current
        return sessions.filter { session in
            calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: Date())
        }.count
    }
    
    private var lastWeekSessions: Int {
        let calendar = Calendar.current
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return sessions.filter { session in
            calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: lastWeek)
        }.count
    }
    
    private var totalVolumeThisWeek: Double {
        let calendar = Calendar.current
        let thisWeekSessions = sessions.filter { session in
            calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: Date())
        }

        let totalKg = thisWeekSessions.reduce(0.0) { total, session in
            let sessionVolume = session.exerciseSessions.reduce(0.0) { sessionTotal, exerciseSession in
                let exerciseVolume = exerciseSession.setLogs.reduce(0.0) { setTotal, setLog in
                    setTotal + (Double(setLog.reps) * setLog.weight)
                }
                return sessionTotal + exerciseVolume
            }
            return total + sessionVolume
        }
        return unit.toDisplay(fromKg: totalKg)
    }
    
    private var totalVolumeLastWeek: Double {
        let calendar = Calendar.current
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        let lastWeekSessions = sessions.filter { session in
            calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: lastWeek)
        }

        let totalKg = lastWeekSessions.reduce(0.0) { total, session in
            let sessionVolume = session.exerciseSessions.reduce(0.0) { sessionTotal, exerciseSession in
                let exerciseVolume = exerciseSession.setLogs.reduce(0.0) { setTotal, setLog in
                    setTotal + (Double(setLog.reps) * setLog.weight)
                }
                return sessionTotal + exerciseVolume
            }
            return total + sessionVolume
        }
        return unit.toDisplay(fromKg: totalKg)
    }
    
    private var averageWorkoutDuration: String {
        let completedSessions = sessions.filter { $0.isCompleted ?? false }
        guard !completedSessions.isEmpty else { return "0 דק׳" }
        
        let totalDuration = completedSessions.compactMap { $0.durationSeconds }.reduce(0, +)
        guard totalDuration > 0 else { return "0 דק׳" }
        
        let avgDuration = Double(totalDuration) / Double(completedSessions.count)
        let minutes = Int(avgDuration / 60)
        return "\(minutes) דק׳"
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        while true {
            let hasWorkout = sessions.contains { session in
                let sessionDate = calendar.startOfDay(for: session.date)
                return sessionDate == currentDate && (session.isCompleted ?? false)
            }
            
            if hasWorkout {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var weeklyGoal: Int { 5 } // Default weekly goal
    
    private var volumeIncrease: Double {
        guard totalVolumeLastWeek > 0 else { return 0 }
        return ((totalVolumeThisWeek - totalVolumeLastWeek) / totalVolumeLastWeek) * 100
    }
    
    private var chartData: [ChartDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate: Date
        
        switch selectedTimeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        case .all:
            startDate = sessions.last?.date ?? endDate
        }
        
        let filteredSessions = sessions.filter { $0.date >= startDate && $0.date <= endDate }
        
        return filteredSessions.map { session in
            let value: Double
            switch selectedMetric {
            case .workouts:
                value = 1
            case .volume:
                value = session.exerciseSessions.flatMap { $0.setLogs }.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
            case .duration:
                value = Double(session.durationSeconds ?? 0) / 60 // Convert to minutes
            case .exercises:
                value = Double(session.exerciseSessions.count)
            }
            
            return ChartDataPoint(date: session.date, value: value)
        }
    }
    
    private var topExercises: [ExerciseProgress] {
        let exerciseData = Dictionary(grouping: sessions.flatMap { session in
            session.exerciseSessions.flatMap { exerciseSession in
                exerciseSession.setLogs.map { setLog in
                    (exerciseSession.exerciseName, setLog.weight)
                }
            }
        }, by: { $0.0 })
        
        return exerciseData.compactMap { (exerciseName, weights) in
            guard let maxWeight = weights.map(\.1).max() else { return nil }
            let previousMaxWeight = weights.map(\.1).sorted(by: >).dropFirst().first ?? 0
            
            return ExerciseProgress(
                name: exerciseName,
                maxWeight: maxWeight,
                previousMaxWeight: previousMaxWeight
            )
        }.sorted { $0.maxWeight > $1.maxWeight }
    }
}

// MARK: - Supporting Views

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ExerciseProgress {
    let name: String
    let maxWeight: Double
    let previousMaxWeight: Double
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
                
                if let progress = progress {
                    CircularProgressView(progress: progress, color: color)
                        .frame(width: 30, height: 30)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(AppTheme.s12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct ExerciseProgressRow: View {
    let exercise: String
    let currentWeight: Double
    let previousWeight: Double
    let unit: String
    let rank: Int
    
    private var improvement: Double {
        guard previousWeight > 0 else { return 0 }
        return ((currentWeight - previousWeight) / previousWeight) * 100
    }
    
    var body: some View {
        HStack(spacing: AppTheme.s12) {
            // Rank
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(AppTheme.accent, in: Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(currentWeight, specifier: "%.1f") \(unit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if improvement > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                    Text("+\(improvement, specifier: "%.0f")%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.green)
            }
        }
        .padding(AppTheme.s12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AchievementCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.s8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isUnlocked ? color : .gray)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.s12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

struct WeekComparisonCard: View {
    let title: String
    let workouts: Int
    let volume: Double
    let unit: String
    let isCurrent: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.s8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isCurrent ? AppTheme.accent : .primary)
            
            Text("\(workouts)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("אימונים")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(volume, specifier: "%.0f") \(unit)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s12)
        .background(isCurrent ? AppTheme.accent.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.r16)
                .stroke(isCurrent ? AppTheme.accent : Color.clear, lineWidth: 1)
        )
    }
}

struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: AppTheme.s12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("אין נתונים להצגה")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
    }
}

struct GoalSettingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weeklyGoal: Int = 5
    @State private var volumeGoal: Double = 1000
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.s24) {
                Text("הגדר יעדים")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: AppTheme.s16) {
                    VStack(alignment: .leading, spacing: AppTheme.s8) {
                        Text("יעד שבועי")
                            .font(.headline)
                        
                        Stepper("\(weeklyGoal) אימונים בשבוע", value: $weeklyGoal, in: 1...14)
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.s8) {
                        Text("יעד נפח")
                            .font(.headline)
                        
                        HStack {
                            TextField("נפח", value: $volumeGoal, format: .number)
                                .textFieldStyle(.roundedBorder)
                            Text("ק״ג")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button("שמור יעדים") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding(AppTheme.s24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProgressViewScreen()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}