//
//  WorkoutEditView.swift
//  GymTracker
//
//  Enhanced Workout Edit View with Better Navigation and UX
//

import SwiftUI
import SwiftData

struct WorkoutEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    @Query private var plans: [WorkoutPlan]
    
    @State private var selectedSegment: EditSegment = .history
    @State private var showNewWorkoutSheet = false
    @State private var editingSession: WorkoutSession?
    @State private var searchText = ""
    @State private var selectedFilter: SessionFilter = .all
    @State private var showFilters = false
    
    
    @State private var notes = ""
    @State private var showPlanPicker = false
    @State private var showNewPlanSheet = false
    @State private var showActiveWorkout = false
    @State private var nextWorkout: NextWorkout?
    
    private enum EditSegment: String, CaseIterable {
        case history = "היסטוריה"
        case analytics = "ניתוח"
        
        var icon: String {
            switch self {
            case .history: return "clock.arrow.circlepath"
            case .analytics: return "chart.bar.xaxis"
            }
        }
    }
    
    enum SessionFilter: String, CaseIterable {
        case all = "הכל"
        case completed = "הושלמו"
        case incomplete = "לא הושלמו"
        case thisWeek = "השבוע"
        case thisMonth = "החודש"
    }
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Enhanced header with search
                headerSection
                
                // Custom segmented control
                segmentedControl
                
                // Content based on selection
                switch selectedSegment {
                case .history:
                    workoutHistoryView
                case .analytics:
                    workoutAnalyticsView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showNewWorkoutSheet) {
            NewWorkoutSheet()
        }
        .sheet(item: $editingSession) { session in
            WorkoutSessionEditSheet(session: session)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.s16) {
            // Title and actions
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("אימונים")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("ניהול אימונים ותבניות")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: AppTheme.s12) {
                    Button(action: { showFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                    }
                    
                    Button(action: { showNewWorkoutSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            
            // Search bar
            if selectedSegment == .history {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("חפש אימונים...", text: $searchText)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(AppTheme.s12)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, AppTheme.s16)
        .padding(.top, AppTheme.s8)
    }
    
    // MARK: - Segmented Control
    
    private var segmentedControl: some View {
        HStack(spacing: 0) {
                    ForEach(EditSegment.allCases, id: \.self) { segment in
                        Button(action: { 
                                selectedSegment = segment
                }) {
                    VStack(spacing: 4) {
                                    Image(systemName: segment.icon)
                            .font(.system(size: 16, weight: .medium))
                                
                                Text(segment.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            }
                    .foregroundStyle(selectedSegment == segment ? AppTheme.accent : .secondary)
                            .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.s12)
                            .background(
                        selectedSegment == segment ? AppTheme.accent.opacity(0.1) : Color.clear
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, AppTheme.s16)
    }
    
    // MARK: - Workout History View
    
    private var workoutHistoryView: some View {
        ScrollView {
            VStack(spacing: AppTheme.s16) {
                // Sessions list
                LazyVStack(spacing: AppTheme.s12) {
                    ForEach(filteredSessions) { session in
                        WorkoutSessionCard(
                                session: session,
                                onEdit: { editingSession = session },
                            onDuplicate: { duplicateSession(session) },
                                onDelete: { deleteSession(session) }
                            )
                    }
                }
            }
            .padding(.horizontal, AppTheme.s16)
            .padding(.bottom, 100)
        }
    }
    
    
    // MARK: - Workout Analytics View
    
    private var workoutAnalyticsView: some View {
        ScrollView {
            VStack(spacing: AppTheme.s16) {
                // Analytics overview
                analyticsOverviewSection
                
                // Progress charts
                progressChartsSection
                
                // Exercise analysis
                exerciseAnalysisSection
            }
            .padding(.horizontal, AppTheme.s16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Progress Insights Section
    
    private var progressInsightsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("תובנות התקדמות")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: AppTheme.s8) {
                ProgressInsightRow(
                    icon: "arrow.up.circle.fill",
                    title: "התקדמות השבוע",
                    value: String(format: "+%.1f%%", averageImprovement),
                    color: AppTheme.success
                )
                
                ProgressInsightRow(
                    icon: "dumbbell.fill",
                    title: "תרגילים שונים",
                    value: "\(uniqueExercises) תרגילים",
                    color: AppTheme.accent
                )
                
                ProgressInsightRow(
                    icon: "list.number",
                    title: "סטים השבוע",
                    value: "\(thisWeekSets) סטים",
                    color: AppTheme.warning
                )
                
                ProgressInsightRow(
                    icon: "trophy.fill",
                    title: "שיאים אישיים",
                    value: "\(personalRecords) תרגילים",
                    color: AppTheme.error
                )
            }
        }
        .appCard()
    }
    
    // MARK: - History Stats Section
    
    private var historyStatsSection: some View {
        VStack(spacing: AppTheme.s16) {
            // Main workout stats
            HStack(spacing: AppTheme.s12) {
                StatCard(
                    title: "סה״כ אימונים",
                    value: "\(sessions.count)",
                    icon: "figure.strengthtraining.traditional",
                    color: AppTheme.accent
                )
                
                StatCard(
                    title: "הושלמו",
                    value: "\(completedSessions)",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.success
                )
                
                StatCard(
                    title: "השבוע",
                    value: "\(thisWeekSessions)",
                    icon: "calendar.badge.checkmark",
                    color: AppTheme.warning
                )
            }
            
            // Progress metrics
            HStack(spacing: AppTheme.s12) {
                StatCard(
                    title: "תרגילים שונים",
                    value: "\(uniqueExercises)",
                    icon: "dumbbell.fill",
                    color: AppTheme.info
                )
                
                StatCard(
                    title: "שיאים אישיים",
                    value: "\(personalRecords)",
                    icon: "trophy.fill",
                    color: AppTheme.error
                )
                
                StatCard(
                    title: "עקביות",
                    value: String(format: "%.0f%%", workoutConsistency),
                    icon: "chart.line.uptrend.xyaxis",
                    color: AppTheme.success
                )
            }
        }
    }
    
    
    
    
    
    
    
    // MARK: - Analytics Overview Section
    
    private var analyticsOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            Text("סקירה כללית")
                .font(.headline)
                .fontWeight(.bold)
            
            // Main analytics cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
            ], spacing: AppTheme.s12) {
                AnalyticsCard(
                    title: "זמן ממוצע",
                    value: averageWorkoutDuration,
                    subtitle: "לכל אימון",
                    icon: "clock.fill",
                    color: AppTheme.accent
                )
                
                AnalyticsCard(
                    title: "עקביות",
                    value: String(format: "%.0f%%", workoutConsistency),
                    subtitle: "ב-30 יום האחרונים",
                    icon: "calendar.badge.checkmark",
                    color: AppTheme.success
                )
                
                AnalyticsCard(
                    title: "תרגילים שונים",
                    value: "\(uniqueExercises)",
                    subtitle: "תרגילים",
                    icon: "dumbbell.fill",
                    color: AppTheme.warning
                )
                
                AnalyticsCard(
                    title: "שיאים אישיים",
                    value: "\(personalRecords)",
                    subtitle: "תרגילים",
                    icon: "trophy.fill",
                    color: AppTheme.error
                )
            }
            
            // Weekly progress metrics
            VStack(alignment: .leading, spacing: AppTheme.s12) {
                Text("התקדמות השבוע")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.s8) {
                    ProgressMetricCard(
                        title: "סטים השבוע",
                        value: "\(thisWeekSets)",
                        icon: "list.number",
                        color: AppTheme.accent
                    )
                    
                    ProgressMetricCard(
                        title: "שיפור ממוצע",
                        value: String(format: "+%.1f%%", averageImprovement),
                        icon: "arrow.up.circle.fill",
                        color: AppTheme.success
                    )
                    
                    ProgressMetricCard(
                        title: "אימונים השבוע",
                        value: "\(thisWeekSessions)",
                        icon: "calendar.badge.checkmark",
                        color: AppTheme.warning
                    )
                }
            }
        }
        .appCard()
    }
    
    // MARK: - Progress Charts Section
    
    private var progressChartsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("גרפי התקדמות")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("תכונה זו תגיע בקרוב")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(AppTheme.s24)
        }
        .appCard()
    }
    
    // MARK: - Exercise Analysis Section
    
    private var exerciseAnalysisSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("ניתוח תרגילים")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("תכונה זו תגיע בקרוב")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(AppTheme.s24)
        }
        .appCard()
    }
    
    // MARK: - Computed Properties
    
    private var filteredSessions: [WorkoutSession] {
        var filtered = sessions
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { session in
                session.workoutLabel?.localizedCaseInsensitiveContains(searchText) == true ||
                session.planName?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Filter by selected filter
        switch selectedFilter {
        case .all:
            break
        case .completed:
            filtered = filtered.filter { $0.isCompleted == true }
        case .incomplete:
            filtered = filtered.filter { $0.isCompleted != true }
        case .thisWeek:
            let calendar = Calendar.current
            filtered = filtered.filter { session in
                calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: Date())
            }
        case .thisMonth:
            let calendar = Calendar.current
            filtered = filtered.filter { session in
                calendar.dateInterval(of: .month, for: session.date) == calendar.dateInterval(of: .month, for: Date())
            }
        }
        
        return filtered
    }
    
    private var completedSessions: Int {
        sessions.filter { $0.isCompleted == true }.count
    }
    
    private var thisWeekSessions: Int {
        let calendar = Calendar.current
        return sessions.filter { session in
            calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: Date())
        }.count
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
    
    
    
    private var personalRecords: Int {
        // Count exercises where user achieved new max weight
        let exerciseMaxWeights = sessions.flatMap { $0.exerciseSessions }
            .reduce(into: [String: Double]()) { result, exerciseSession in
                let maxWeight = exerciseSession.setLogs.map { $0.weight }.max() ?? 0
                let currentMax = result[exerciseSession.exerciseName] ?? 0
                result[exerciseSession.exerciseName] = max(currentMax, maxWeight)
            }
        
        // This is a simplified version - in reality you'd compare with historical data
        return exerciseMaxWeights.count
    }
    
    private var workoutConsistency: Double {
        let calendar = Calendar.current
        let last30Days = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let recentSessions = sessions.filter { $0.date >= last30Days && ($0.isCompleted ?? false) }
        let expectedWorkouts = 30.0 / 3.0 // Assuming 3 workouts per week
        
        return min(100.0, (Double(recentSessions.count) / expectedWorkouts) * 100.0)
    }
    
    private var uniqueExercises: Int {
        let allExercises = sessions.flatMap { $0.exerciseSessions }.map { $0.exerciseName }
        return Set(allExercises).count
    }
    
    private var thisWeekSets: Int {
        let calendar = Calendar.current
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: Date()) ?? DateInterval()
        
        return sessions.filter { session in
            thisWeek.contains(session.date) && (session.isCompleted ?? false)
        }.flatMap { $0.exerciseSessions }.flatMap { $0.setLogs }.count
    }
    
    private var averageImprovement: Double {
        // Calculate improvement by comparing recent sessions with older ones
        let calendar = Calendar.current
        let last14Days = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let previous14Days = calendar.date(byAdding: .day, value: -28, to: Date()) ?? Date()
        
        let recentSessions = sessions.filter { $0.date >= last14Days && ($0.isCompleted ?? false) }
        let previousSessions = sessions.filter { 
            $0.date >= previous14Days && $0.date < last14Days && ($0.isCompleted ?? false)
        }
        
        guard !recentSessions.isEmpty && !previousSessions.isEmpty else { return 0.0 }
        
        let recentAvgWeight = recentSessions.flatMap { $0.exerciseSessions }
            .flatMap { $0.setLogs }.map { $0.weight }.reduce(0, +) / Double(recentSessions.flatMap { $0.exerciseSessions }.flatMap { $0.setLogs }.count)
        
        let previousAvgWeight = previousSessions.flatMap { $0.exerciseSessions }
            .flatMap { $0.setLogs }.map { $0.weight }.reduce(0, +) / Double(previousSessions.flatMap { $0.exerciseSessions }.flatMap { $0.setLogs }.count)
        
        guard previousAvgWeight > 0 else { return 0.0 }
        return ((recentAvgWeight - previousAvgWeight) / previousAvgWeight) * 100.0
    }
    
    
    
    // MARK: - Helper Functions
    
    // MARK: - Actions
    
    private func duplicateSession(_ session: WorkoutSession) {
        let newSession = WorkoutSession(
            date: Date(),
            planName: session.planName,
            workoutLabel: session.workoutLabel,
            durationSeconds: nil,
            notes: session.notes,
            isCompleted: false,
            exerciseSessions: session.exerciseSessions.map { exerciseSession in
                ExerciseSession(exerciseName: exerciseSession.exerciseName, setLogs: [])
            }
        )
        modelContext.insert(newSession)
    }
    
    private func deleteSession(_ session: WorkoutSession) {
            modelContext.delete(session)
    }
}

// MARK: - Supporting Views and Models

struct WorkoutSessionCard: View {
    let session: WorkoutSession
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.workoutLabel ?? session.planName ?? "אימון ללא שם")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                        Text(session.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(session.isCompleted == true ? .green : .orange)
                    .frame(width: 12, height: 12)
            }
            
            // Session details
            HStack(spacing: AppTheme.s16) {
                DetailItem(
                                    title: "תרגילים",
                                    value: "\(session.exerciseSessions.count)",
                    icon: "dumbbell"
                )
                
                DetailItem(
                    title: "זמן",
                    value: formatDuration(session.durationSeconds),
                    icon: "clock"
                )
                
                DetailItem(
                                    title: "סטים",
                    value: "\(totalSets)",
                    icon: "list.number"
                )
            }
            
            // Actions
            HStack(spacing: AppTheme.s12) {
                Button("ערוך", action: onEdit)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                
                Button("שכפל", action: onDuplicate)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                
                Spacer()
                
                Button("מחק", action: onDelete)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundStyle(.red)
            }
        }
        .padding(AppTheme.s16)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
    
    private var totalSets: Int {
        session.exerciseSessions.reduce(0) { $0 + $1.setLogs.count }
    }
    
    private func formatDuration(_ seconds: Int?) -> String {
        guard let seconds = seconds else { return "לא ידוע" }
        let minutes = seconds / 60
        return "\(minutes) דק׳"
    }
}

struct DetailItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}






struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.s8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s12)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}

struct ProgressMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.s6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s8)
        .background(AppTheme.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ProgressInsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.s12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.primary)
                
                Text(value)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            
            Spacer()
        }
        .padding(AppTheme.s12)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct NewWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    
    @State private var selectedPlan: WorkoutPlan?
    @State private var workoutLabel = "A"
    @State private var notes = ""
    @State private var showPlanPicker = false
    @State private var showNewPlanSheet = false
    @State private var selectedDate = Date()
    @State private var createdSession: WorkoutSession?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s24) {
                    // Header
                    VStack(spacing: AppTheme.s16) {
                Text("צור אימון חדש")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("בחר תוכנית אימון והתחל אימון חדש")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Plan selection
                    VStack(alignment: .leading, spacing: AppTheme.s12) {
                        Text("בחר תוכנית")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        if let selectedPlan = selectedPlan {
                            SelectedPlanCard(plan: selectedPlan) {
                                showPlanPicker = true
                            }
                        } else {
                            VStack(spacing: AppTheme.s12) {
                                Button(action: { showPlanPicker = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(AppTheme.accent)
                                        
                                        Text("בחר תוכנית אימון")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.backward")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondary)
                                    }
                                    .padding(AppTheme.s16)
                                    .background(AppTheme.secondaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
                                }
                                .buttonStyle(.plain)
                                
                                if plans.isEmpty {
                                    EmptyStateView(
                                        iconSystemName: "list.bullet.rectangle",
                                        title: "אין תוכניות",
                                        message: "צור תוכנית חדשה כדי להתחיל",
                                        buttonTitle: "צור תוכנית"
                                    ) {
                                        showNewPlanSheet = true
                                    }
                                }
                            }
                        }
                    }
                    
                    // Workout details
                    if selectedPlan != nil {
                        VStack(alignment: .leading, spacing: AppTheme.s12) {
                            Text("פרטי האימון")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            VStack(spacing: AppTheme.s16) {
                                // Workout label selection
                                VStack(alignment: .leading, spacing: AppTheme.s8) {
                                    Text("תגית אימון")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(AppTheme.primary)
                                    
                                    if let plan = selectedPlan {
                                        let labels = plan.planType.workoutLabels
                                        if labels.count > 1 {
                                            HStack(spacing: AppTheme.s8) {
                                                ForEach(labels, id: \.self) { label in
                                                    Button(action: { workoutLabel = label }) {
                                                        Text(label)
                                                            .font(.subheadline)
                                                            .fontWeight(.semibold)
                                                            .padding(.vertical, AppTheme.s8)
                                                            .padding(.horizontal, AppTheme.s12)
                                                            .background(workoutLabel == label ? AppTheme.accent.opacity(0.2) : AppTheme.cardBG)
                                                            .foregroundStyle(workoutLabel == label ? AppTheme.accent : .primary)
                                                            .clipShape(Capsule())
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                        } else if let only = labels.first {
                                            Text(only)
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundStyle(AppTheme.accent)
                                        }
                                    }
                                }

                                // Date picker
                                VStack(alignment: .leading, spacing: AppTheme.s8) {
                                    Text("תאריך האימון")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(AppTheme.primary)
                                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                                
                                // Notes
                                VStack(alignment: .leading, spacing: AppTheme.s8) {
                                    Text("הערות")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(AppTheme.primary)
                                    
                                    TextField("הוסף הערות לאימון...", text: $notes, axis: .vertical)
                                    .multilineTextAlignment(.trailing)
                                        .textFieldStyle(.roundedBorder)
                                        .lineLimit(3...6)
                                }
                            }
                        }
                    }
                
                Spacer()
            }
                .padding(AppTheme.s24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("צור אימון") {
                        createLoggedWorkout()
                    }
                    .disabled(selectedPlan == nil)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showPlanPicker) {
            PlanPickerSheet(selectedPlan: $selectedPlan)
        }
        .sheet(isPresented: $showNewPlanSheet) {
            NewPlanSheet()
        }
        .sheet(item: $createdSession) { session in
            WorkoutSessionEditSheet(session: session)
        }
        .onChange(of: selectedPlan) { _, newValue in
            guard let plan = newValue else { return }
            workoutLabel = plan.planType.workoutLabels.first ?? "A"
        }
    }
    
    private func createLoggedWorkout() {
        guard let plan = selectedPlan else { return }
        let labels = plan.planType.workoutLabels
        let label = workoutLabel.isEmpty ? (labels.first ?? "A") : workoutLabel
        let exercisesForLabel: [Exercise] = plan.planType == .fullBody
            ? plan.exercises
            : plan.exercises.filter { ($0.label ?? labels.first) == label }

        // Pre-seed exercise sessions with no sets
        let exerciseSessions = exercisesForLabel.map { ExerciseSession(exerciseName: $0.name, setLogs: []) }

        let session = WorkoutSession(
            date: selectedDate,
            planName: plan.name,
            workoutLabel: label,
            durationSeconds: nil,
            notes: notes.isEmpty ? nil : notes,
            isCompleted: true,
            exerciseSessions: exerciseSessions
        )
        modelContext.insert(session)
        try? modelContext.save()

        createdSession = session
    }
}

struct WorkoutSessionEditSheet: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    
    @State private var workoutLabel: String
    @State private var notes: String
    @State private var isCompleted: Bool
    @State private var showDeleteConfirmation = false
    @State private var selectedExercise: ExerciseSession?
    @State private var showAllExercises = false
    @State private var showReorderExercises = false
    @State private var durationMinutes: Int
    @State private var durationSeconds: Int
    
    init(session: WorkoutSession) {
        self.session = session
        self._workoutLabel = State(initialValue: session.workoutLabel ?? "A")
        self._notes = State(initialValue: session.notes ?? "")
        self._isCompleted = State(initialValue: session.isCompleted ?? false)
        
        let totalSeconds = session.durationSeconds ?? 0
        self._durationMinutes = State(initialValue: totalSeconds / 60)
        self._durationSeconds = State(initialValue: totalSeconds % 60)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s16) {
                    // Modern Header Section
                    VStack(spacing: AppTheme.s16) {
                        // Workout label circle and title
                        VStack(spacing: AppTheme.s12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle()
                                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 2)
                                    )
                                Text(currentWorkoutLabel)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.accent)
                            }

                            VStack(spacing: 4) {
                                Text("עריכת אימון")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.primary)

                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondary)

                                    Text(session.date, style: .date)
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.s24)
                    .background(AppTheme.screenBG)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                    
                    // Workout Details Card
                    VStack(alignment: .leading, spacing: AppTheme.s20) {
                        // Card header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("פרטי האימון")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.primary)

                                Text("הגדרות האימון הנוכחי")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondary)
                            }

                            Spacer()

                            Image(systemName: "gear")
                                .font(.title3)
                                .foregroundStyle(AppTheme.accent)
                        }

                        VStack(spacing: AppTheme.s20) {
                            // Modern Workout Label Selection
                            VStack(alignment: .leading, spacing: AppTheme.s12) {
                                HStack {
                                    Text("תגית אימון")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppTheme.primary)

                                    Spacer()

                                    Text("בחר את סוג האימון")
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondary)
                                }

                                if allowedLabels.count > 1 {
                                    HStack(spacing: AppTheme.s12) {
                                        ForEach(allowedLabels, id: \.self) { label in
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    workoutLabel = label
                                                }
                                            }) {
                                                VStack(spacing: 6) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(workoutLabel == label ? AppTheme.accent : AppTheme.cardBG)
                                                            .frame(width: 44, height: 44)
                                                            .overlay(
                                                                Circle()
                                                                    .stroke(workoutLabel == label ? AppTheme.accent : AppTheme.secondary.opacity(0.3), lineWidth: 1.5)
                                                            )

                                                        Text(label)
                                                            .font(.title3)
                                                            .fontWeight(.bold)
                                                            .foregroundStyle(workoutLabel == label ? .white : AppTheme.primary)
                                                    }

                                                    Text("אימון \(label)")
                                                        .font(.caption2)
                                                        .fontWeight(.medium)
                                                        .foregroundStyle(workoutLabel == label ? AppTheme.accent : AppTheme.secondary)
                                                }
                                                .frame(maxWidth: .infinity)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, AppTheme.s8)
                                } else {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.accent.opacity(0.1))
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Circle()
                                                        .stroke(AppTheme.accent, lineWidth: 1.5)
                                                )

                                            TextField("A", text: $workoutLabel)
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .multilineTextAlignment(.center)
                                                .foregroundStyle(AppTheme.accent)
                                                .frame(width: 30)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("תגית מותאמת")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(AppTheme.primary)

                                            Text("הזן תגית עבור האימון")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.secondary)
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, AppTheme.s8)
                                }
                            }
                            
                            // Modern Duration Input
                            VStack(alignment: .leading, spacing: AppTheme.s12) {
                                HStack {
                                    Text("זמן אימון")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppTheme.primary)

                                    Spacer()

                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.fill")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.warning)

                                        Text("מדידת זמן האימון")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondary)
                                    }
                                }

                                HStack(spacing: AppTheme.s20) {
                                    // Minutes control
                                    VStack(spacing: AppTheme.s8) {
                                        Text("דקות")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(AppTheme.secondary)

                                        HStack(spacing: AppTheme.s8) {
                                            Button(action: {
                                                if durationMinutes > 0 {
                                                    durationMinutes -= 1
                                                }
                                            }) {
                                                Image(systemName: "minus")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                    .frame(width: 28, height: 28)
                                                    .background(AppTheme.secondary)
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)

                                            Text("\(durationMinutes)")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundStyle(AppTheme.primary)
                                                .frame(width: 40)

                                            Button(action: {
                                                if durationMinutes < 300 {
                                                    durationMinutes += 1
                                                }
                                            }) {
                                                Image(systemName: "plus")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                    .frame(width: 28, height: 28)
                                                    .background(AppTheme.accent)
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }

                                    // Separator
                                    VStack {
                                        Text(":")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(AppTheme.secondary)
                                            .padding(.top, 20)
                                    }

                                    // Seconds control
                                    VStack(spacing: AppTheme.s8) {
                                        Text("שניות")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(AppTheme.secondary)

                                        HStack(spacing: AppTheme.s8) {
                                            Button(action: {
                                                if durationSeconds > 0 {
                                                    durationSeconds -= 1
                                                }
                                            }) {
                                                Image(systemName: "minus")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                    .frame(width: 28, height: 28)
                                                    .background(AppTheme.secondary)
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)

                                            Text("\(durationSeconds)")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundStyle(AppTheme.primary)
                                                .frame(width: 40)

                                            Button(action: {
                                                if durationSeconds < 59 {
                                                    durationSeconds += 1
                                                }
                                            }) {
                                                Image(systemName: "plus")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                    .frame(width: 28, height: 28)
                                                    .background(AppTheme.accent)
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(.vertical, AppTheme.s8)
                            }
                            
                            // Modern Completion Status
                            VStack(alignment: .leading, spacing: AppTheme.s12) {
                                HStack {
                                    Text("סטטוס האימון")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppTheme.primary)

                                    Spacer()

                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(isCompleted ? AppTheme.success : AppTheme.warning)
                                            .frame(width: 8, height: 8)

                                        Text(isCompleted ? "הושלם" : "בתהליך")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(isCompleted ? AppTheme.success : AppTheme.warning)
                                    }
                                }

                                HStack(spacing: AppTheme.s12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("אימון הושלם")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(AppTheme.primary)

                                        Text(isCompleted ? "האימון בוצע בהצלחה" : "סמן כאשר תסיים את האימון")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondary)
                                    }

                                    Spacer()

                                    Toggle("", isOn: $isCompleted)
                                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.accent))
                                        .scaleEffect(1.1)
                                }
                                .padding(.vertical, AppTheme.s8)
                            }

                            Divider()
                                .foregroundStyle(AppTheme.secondary.opacity(0.3))

                            // Modern Notes Input
                            VStack(alignment: .leading, spacing: AppTheme.s12) {
                                HStack {
                                    Text("הערות")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppTheme.primary)

                                    Spacer()

                                    HStack(spacing: 4) {
                                        Image(systemName: "note.text")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondary)

                                        Text("אופציונלי")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondary)
                                    }
                                }

                                VStack(alignment: .leading, spacing: AppTheme.s8) {
                                    TextField("הוסף הערות לאימון...", text: $notes, axis: .vertical)
                                        .multilineTextAlignment(.trailing)
                                        .lineLimit(3...6)
                                        .padding(AppTheme.s16)
                                        .background(AppTheme.background)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(notes.isEmpty ? AppTheme.secondary.opacity(0.3) : AppTheme.accent.opacity(0.5), lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    if !notes.isEmpty {
                                        HStack {
                                            Text("\(notes.count) תווים")
                                                .font(.caption2)
                                                .foregroundStyle(AppTheme.secondary)

                                            Spacer()

                                            Button("נקה") {
                                                notes = ""
                                            }
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.accent)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppTheme.s24)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // Exercises section with modern card style
                    VStack(alignment: .leading, spacing: AppTheme.s16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("תרגילים")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text("\(session.exerciseSessions.count) תרגילים באימון")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondary)
                            }

                            Spacer()

                            Button(action: { showReorderExercises = true }) {
                                HStack(spacing: 4) {
                                    Text("סדר תרגילים")
                                        .font(.caption)
                                        .fontWeight(.medium)

                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.caption2)
                                }
                                .foregroundStyle(AppTheme.accent)
                                .padding(.horizontal, AppTheme.s8)
                                .padding(.vertical, 4)
                                .background(AppTheme.accent.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            Button(action: { showAllExercises = true }) {
                                HStack(spacing: 4) {
                                    Text("הצג הכל")
                                        .font(.caption)
                                        .fontWeight(.medium)

                                    Image(systemName: "chevron.backward")
                                        .font(.caption2)
                                }
                                .foregroundStyle(AppTheme.accent)
                                .padding(.horizontal, AppTheme.s8)
                                .padding(.vertical, 4)
                                .background(AppTheme.accent.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        if session.exerciseSessions.isEmpty {
                            EmptyStateView(
                                iconSystemName: "dumbbell",
                                title: "אין תרגילים",
                                message: "אימון זה עדיין לא מכיל תרגילים",
                                buttonTitle: nil
                            ) {}
                            .padding(.vertical, AppTheme.s16)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: AppTheme.s12) {
                                ForEach(session.exerciseSessions, id: \.exerciseName) { exerciseSession in
                                    ExerciseSummaryCard(exerciseSession: exerciseSession) {
                                        selectedExercise = exerciseSession
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Session statistics with modern card style
                    VStack(alignment: .leading, spacing: AppTheme.s16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("סטטיסטיקות")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text("סיכום האימון")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondary)
                            }

                            Spacer()

                            // Quick completion indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(session.isCompleted == true ? AppTheme.success : AppTheme.warning)
                                    .frame(width: 8, height: 8)

                                Text(session.isCompleted == true ? "הושלם" : "בתהליך")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(session.isCompleted == true ? AppTheme.success : AppTheme.warning)
                            }
                            .padding(.horizontal, AppTheme.s8)
                            .padding(.vertical, 4)
                            .background((session.isCompleted == true ? AppTheme.success : AppTheme.warning).opacity(0.1))
                            .clipShape(Capsule())
                        }

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppTheme.s12) {
                            StatCard(
                                title: "תרגילים",
                                value: "\(session.exerciseSessions.count)",
                                icon: "dumbbell.fill",
                                color: AppTheme.accent
                            )

                            StatCard(
                                title: "סטים",
                                value: "\(totalSets)",
                                icon: "list.number",
                                color: AppTheme.success
                            )

                            StatCard(
                                title: "זמן",
                                value: formatDuration(session.durationSeconds),
                                icon: "clock.fill",
                                color: AppTheme.warning
                            )
                        }
                    }
                    .padding(20)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Modern Danger Zone
                    VStack(alignment: .leading, spacing: AppTheme.s16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("אזור מסוכן")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppTheme.error)

                                Text("פעולות בלתי הפיכות")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondary)
                            }

                            Spacer()

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(AppTheme.error)
                        }

                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack(spacing: AppTheme.s8) {
                                Image(systemName: "trash.fill")
                                    .font(.subheadline)

                                Text("מחק אימון")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.s12)
                            .background(AppTheme.error)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(AppTheme.s20)
                    .background(AppTheme.error.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.error.opacity(0.2), lineWidth: 1)
                    )
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, AppTheme.s16)
                .padding(.bottom, AppTheme.s24)
            }
            .background(AppTheme.screenBG)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.secondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") {
                        saveChanges()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
        }
        .background(AppTheme.screenBG)
        .alert("מחק אימון", isPresented: $showDeleteConfirmation) {
            Button("מחק", role: .destructive) {
                deleteSession()
            }
            Button("ביטול", role: .cancel) {}
        } message: {
            Text("האם אתה בטוח שברצונך למחוק את האימון? פעולה זו לא ניתנת לביטול.")
        }
        .sheet(item: $selectedExercise) { exercise in
            NewExerciseDetailsSheet(exerciseSession: exercise)
                .id(exercise.exerciseName)
        }
        .sheet(isPresented: $showAllExercises) {
            NewAllExercisesSheet(session: session)
        }
        .sheet(isPresented: $showReorderExercises) {
            ExerciseReorderSheet(session: session)
        }
    }

    private var allowedLabels: [String] {
        if let planName = session.planName,
           let plan = plans.first(where: { $0.name == planName }) {
            return plan.planType.workoutLabels
        }
        return ["A"]
    }

    private var currentWorkoutLabel: String {
        workoutLabel.isEmpty ? (allowedLabels.first ?? "A") : workoutLabel
    }
    
    private var totalSets: Int {
        session.exerciseSessions.reduce(0) { $0 + $1.setLogs.count }
    }
    
    private func formatDuration(_ seconds: Int?) -> String {
        guard let seconds = seconds else { return "לא ידוע" }
        let minutes = seconds / 60
        return "\(minutes) דק׳"
    }
    
    private func saveChanges() {
        session.workoutLabel = workoutLabel.isEmpty ? "A" : workoutLabel
        session.notes = notes.isEmpty ? nil : notes
        session.isCompleted = isCompleted
        session.durationSeconds = (durationMinutes * 60) + durationSeconds
        
        try? modelContext.save()
        dismiss()
    }
    
    private func deleteSession() {
        modelContext.delete(session)
        try? modelContext.save()
        dismiss()
    }
}

struct ExerciseReorderSheet: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @State private var items: [ExerciseSession] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(items, id: \.exerciseName) { ex in
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.secondary)
                        Text(ex.exerciseName)
                    }
                }
                .onMove(perform: onMove)
            }
            .navigationTitle("סדר תרגילים")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    EditButton()
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("שמור") {
                        applyOrder()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .onAppear {
                items = session.exerciseSessions
            }
        }
    }

    private func onMove(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    private func applyOrder() {
        session.exerciseSessions = items
    }
}


struct SelectedPlanCard: View {
    let plan: WorkoutPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.s12) {
                VStack(alignment: .leading, spacing: AppTheme.s4) {
                    Text(plan.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primary)
                    
                    Text("\(plan.exercises.count) תרגילים")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.backward")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            .padding(AppTheme.s16)
            .background(AppTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
        }
        .buttonStyle(.plain)
    }
}

struct PlanPickerSheet: View {
    @Binding var selectedPlan: WorkoutPlan?
    @Environment(\.dismiss) private var dismiss
    @Query private var plans: [WorkoutPlan]
    
    var body: some View {
        NavigationStack {
            List(plans) { plan in
                Button(action: {
                    selectedPlan = plan
                        dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundStyle(AppTheme.primary)
                            
                            Text("\(plan.exercises.count) תרגילים")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedPlan?.id == plan.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("בחר תוכנית")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
            }
        }
    }
}



struct ExerciseSummaryCard: View {
    let exerciseSession: ExerciseSession
    let onTap: () -> Void

    private var maxWeight: Double {
        exerciseSession.setLogs.map { $0.weight }.max() ?? 0
    }

    private var totalVolume: Double {
        exerciseSession.setLogs.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.s12) {
                // Header - Exercise name with clean typography
                HStack {
                    Text(exerciseSession.exerciseName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.backward")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                }

                // Main stats - Clean and prominent
                HStack(alignment: .top, spacing: AppTheme.s16) {
                    // Sets count
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(exerciseSession.setLogs.count)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)

                        Text("סטים")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Max weight (if available)
                    if maxWeight > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(String(format: "%.0f", maxWeight))")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)

                                Text("ק״ג")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }

                            Text("מקסימום")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Status indicator - Subtle at bottom
                HStack(spacing: 6) {
                    Circle()
                        .fill(exerciseSession.setLogs.isEmpty ? .orange : .green)
                        .frame(width: 8, height: 8)

                    Text(exerciseSession.setLogs.isEmpty ? "לא התחיל" : "הושלם")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(exerciseSession.setLogs.isEmpty ? .orange : .green)

                    Spacer()
                }
            }
            .padding(AppTheme.s16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        exerciseSession.setLogs.isEmpty ? Color(.separator) : Color.green.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseDetailsSheet: View {
    let exerciseSession: ExerciseSession
    @Environment(\.dismiss) private var dismiss

    private var totalVolume: Double {
        exerciseSession.setLogs.reduce(0) { total, setLog in
            total + (setLog.weight * Double(setLog.reps))
        }
    }

    private var averageRPE: Double {
        let rpeValues = exerciseSession.setLogs.compactMap { $0.rpe }
        guard !rpeValues.isEmpty else { return 0 }
        return rpeValues.reduce(0, +) / Double(rpeValues.count)
    }

    private var maxWeight: Double {
        exerciseSession.setLogs.map { $0.weight }.max() ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 16) {
                        // Exercise Icon
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(Color.blue)
                        }

                        // Exercise Name
                        Text(exerciseSession.exerciseName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        // Status Badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(exerciseSession.setLogs.isEmpty ? Color.orange : Color.green)
                                .frame(width: 8, height: 8)

                            Text(exerciseSession.setLogs.isEmpty ? "לא התחיל" : "הושלם")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(exerciseSession.setLogs.isEmpty ? Color.orange : Color.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background((exerciseSession.setLogs.isEmpty ? Color.orange : Color.green).opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        // Sets Count
                        VStack(spacing: 8) {
                            Text("\(exerciseSession.setLogs.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.blue)

                            Text("סטים")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Total Volume
                        VStack(spacing: 8) {
                            Text("\(Int(totalVolume))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.green)

                            Text("ק״ג נפח")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Average RPE
                        VStack(spacing: 8) {
                            Text(averageRPE > 0 ? String(format: "%.1f", averageRPE) : "-")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.orange)

                            Text("RPE ממוצע")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Sets List
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("סטים")
                                .font(.headline)
                                .fontWeight(.bold)

                            Spacer()

                            if !exerciseSession.setLogs.isEmpty {
                                Text("\(exerciseSession.setLogs.count) סטים")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }

                        if exerciseSession.setLogs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "list.number")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)

                                Text("אין סטים")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text("לא נרשמו סטים לתרגיל זה")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(exerciseSession.setLogs.enumerated()), id: \.offset) { index, setLog in
                                    HStack(spacing: 16) {
                                        // Set Number
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 32, height: 32)

                                            Text("\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                        }

                                        // Set Details
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                if setLog.weight > 0 {
                                                    Text("\(String(format: "%.1f", setLog.weight)) ק״ג")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                }

                                                if setLog.reps > 0 {
                                                    Text("× \(setLog.reps)")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }

                                            if let rpe = setLog.rpe, rpe > 0 {
                                                Text("RPE \(rpe)")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundStyle(Color.blue)
                                            }
                                        }

                                        Spacer()

                                        // Volume for this set
                                        if setLog.weight > 0 && setLog.reps > 0 {
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(String(format: "%.0f", setLog.weight * Double(setLog.reps)))
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)

                                                Text("ק״ג")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("פרטי תרגיל")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("סגור") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SetDetailRow: View {
    let setNumber: Int
    let reps: Int
    let weight: Double
    let rpe: Double

    private var setVolume: Int {
        Int(weight * Double(reps))
    }

    private var rpeColor: Color {
        switch rpe {
        case 0..<6: return AppTheme.success
        case 6..<8: return AppTheme.warning
        case 8...: return AppTheme.error
        default: return AppTheme.secondary
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.s12) {
            // Set number indicator
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 32, height: 32)

                Text("\(setNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.accent)
            }

            // Main set information
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(reps)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primary)

                    Text("חזרות")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)

                    Text("×")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                        .padding(.horizontal, 4)

                    Text("\(String(format: "%.1f", weight))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primary)

                    Text("ק״ג")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)

                    Spacer()
                }

                HStack(spacing: AppTheme.s8) {
                    // Volume indicator
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.info)

                        Text("\(setVolume) ק״ג נפח")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                    }

                    Spacer()

                    // RPE indicator with color coding
                    HStack(spacing: 4) {
                        Circle()
                            .fill(rpeColor)
                            .frame(width: 6, height: 6)

                        Text("RPE \(String(format: "%.1f", rpe))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(rpeColor)
                    }
                    .padding(.horizontal, AppTheme.s8)
                    .padding(.vertical, 4)
                    .background(rpeColor.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(AppTheme.s16)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.r16)
                .stroke(AppTheme.accent.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Supporting Components

struct RPECategoryCard: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.s6) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.s10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - All Exercises Sheet

struct AllExercisesSheet: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAllExercise: ExerciseSession?
    @State private var showAllExerciseDetails = false

    private var totalSets: Int {
        session.exerciseSessions.reduce(0) { $0 + $1.setLogs.count }
    }

    private var totalVolume: Double {
        session.exerciseSessions.reduce(0) { total, exerciseSession in
            total + exerciseSession.setLogs.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }

    private var completedExercises: Int {
        session.exerciseSessions.filter { !$0.setLogs.isEmpty }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s20) {
                    // Header Stats
                    VStack(spacing: AppTheme.s16) {
                        // Workout info
                        VStack(spacing: AppTheme.s8) {
                            Text("כל תרגילי האימון")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.primary)

                            Text(session.date, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondary)
                        }

                        // Quick stats
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppTheme.s12) {
                            StatCard(
                                title: "תרגילים",
                                value: "\(session.exerciseSessions.count)",
                                icon: "dumbbell.fill",
                                color: AppTheme.accent
                            )

                            StatCard(
                                title: "הושלמו",
                                value: "\(completedExercises)",
                                icon: "checkmark.circle.fill",
                                color: AppTheme.success
                            )

                            StatCard(
                                title: "סה״כ סטים",
                                value: "\(totalSets)",
                                icon: "list.number",
                                color: AppTheme.warning
                            )
                        }
                    }
                    .padding(AppTheme.s20)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // Exercises List
                    VStack(alignment: .leading, spacing: AppTheme.s16) {
                        HStack {
                            Text("רשימת תרגילים")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.primary)

                            Spacer()

                            // Progress indicator
                            HStack(spacing: 4) {
                                Text("\(completedExercises)/\(session.exerciseSessions.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.accent)
                            }
                            .padding(.horizontal, AppTheme.s8)
                            .padding(.vertical, 4)
                            .background(AppTheme.accent.opacity(0.1))
                            .clipShape(Capsule())
                        }

                        if session.exerciseSessions.isEmpty {
                            EmptyStateView(
                                iconSystemName: "dumbbell",
                                title: "אין תרגילים",
                                message: "אימון זה עדיין לא מכיל תרגילים",
                                buttonTitle: nil
                            ) {}
                            .padding(.vertical, AppTheme.s24)
                        } else {
                            LazyVStack(spacing: AppTheme.s12) {
                                ForEach(Array(session.exerciseSessions.enumerated()), id: \.offset) { index, exerciseSession in
                                    WorkoutExerciseRowCard(
                                        exerciseSession: exerciseSession,
                                        index: index + 1,
                                        onTap: {
                                            selectedAllExercise = exerciseSession
                                            showAllExerciseDetails = true
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(AppTheme.s20)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, AppTheme.s16)
                .padding(.bottom, AppTheme.s24)
            }
            .background(AppTheme.screenBG)
            .navigationTitle("תרגילי האימון")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("סגור") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.secondary)
                }
            }
        }
        .fullScreenCover(isPresented: $showAllExerciseDetails) {
            if let exercise = selectedAllExercise {
                NavigationStack {
                    ExerciseDetailsSheet(exerciseSession: exercise)
                        .onDisappear {
                            // Clear selection when sheet is dismissed
                            selectedAllExercise = nil
                        }
                }
            }
        }
    }
}

// MARK: - Exercise Row Card

struct WorkoutExerciseRowCard: View {
    let exerciseSession: ExerciseSession
    let index: Int
    let onTap: () -> Void

    private var totalVolume: Double {
        exerciseSession.setLogs.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    private var maxWeight: Double {
        exerciseSession.setLogs.map { $0.weight }.max() ?? 0
    }

    private var averageRPE: Double {
        guard !exerciseSession.setLogs.isEmpty else { return 0 }
        let totalRPE = exerciseSession.setLogs.reduce(0.0) { $0 + ($1.rpe ?? 0.0) }
        return totalRPE / Double(exerciseSession.setLogs.count)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.s16) {
                // Exercise number
                ZStack {
                    Circle()
                        .fill(exerciseSession.setLogs.isEmpty ? AppTheme.secondary.opacity(0.1) : AppTheme.accent.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Text("\(index)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(exerciseSession.setLogs.isEmpty ? AppTheme.secondary : AppTheme.accent)
                }

                // Exercise details
                VStack(alignment: .leading, spacing: AppTheme.s8) {
                    HStack {
                        Text(exerciseSession.exerciseName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.primary)
                            .lineLimit(2)

                        Spacer()

                        // Status badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(exerciseSession.setLogs.isEmpty ? AppTheme.warning : AppTheme.success)
                                .frame(width: 8, height: 8)

                            Text(exerciseSession.setLogs.isEmpty ? "לא התחיל" : "הושלם")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(exerciseSession.setLogs.isEmpty ? AppTheme.warning : AppTheme.success)
                        }
                    }

                    // Exercise stats
                    HStack(spacing: AppTheme.s16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("סטים")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.secondary)

                            Text("\(exerciseSession.setLogs.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.primary)
                        }

                        if maxWeight > 0 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("משקל מקס׳")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondary)

                                Text("\(String(format: "%.1f", maxWeight)) ק״ג")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }

                        if totalVolume > 0 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("נפח כולל")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondary)

                                Text("\(Int(totalVolume)) ק״ג")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppTheme.success)
                            }
                        }

                        if averageRPE > 0 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("RPE ממוצע")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondary)

                                Text("\(String(format: "%.1f", averageRPE))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppTheme.warning)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.backward")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                    }
                }
            }
            .padding(AppTheme.s16)
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        exerciseSession.setLogs.isEmpty ? AppTheme.secondary.opacity(0.2) : AppTheme.accent.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WorkoutEditView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}


