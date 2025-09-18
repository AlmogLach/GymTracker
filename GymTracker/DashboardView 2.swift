import SwiftUI
import SwiftData

struct NextWorkout {
    let plan: WorkoutPlan
    let label: String
    let exercises: [Exercise]
    let day: String
}

struct DashboardView: View {
    let onNavigateToHistory: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    @Query private var settingsList: [AppSettings]
    @State private var showNewPlanSheet = false
    @State private var showActiveWorkout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome header
                    welcomeHeader
                    
                    // Header stats row
                    statsOverviewCard
                    
                    // Main cards
                    nextWorkoutCard
                    lastWorkoutCard
                    
                    // Weekly overview
                    if !sessions.isEmpty {
                        weeklyProgressCard
                    }
                    
                    // Quick actions
                    quickActionsCard
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
                .padding(.horizontal, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("לוח")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showNewPlanSheet) {
            NewPlanSheet()
        }
        .fullScreenCover(isPresented: $showActiveWorkout) {
            ActiveWorkoutView(
                workout: getNextWorkout(),
                onComplete: {
                    showActiveWorkout = false
                }
            )
        }
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(currentDateText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // App logo
                if let _ = UIImage(named: "AppIcon") {
                    Image("AppIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                } else {
                    // Fallback to SF Symbol if app icon doesn't exist
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(AppTheme.accent.opacity(0.1))
                        )
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "בוקר טוב! 🌅"
        case 12..<17:
            return "צהריים טובים! ☀️"
        case 17..<21:
            return "אחר הצהריים טובים! 🌆"
        default:
            return "ערב טוב! 🌙"
        }
    }
    
    private var currentDateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "he")
        return formatter.string(from: Date())
    }
    
    // Header stats overview
    private var statsOverviewCard: some View {
        HStack(spacing: 12) {
            StatTile(
                value: "\(sessions.count)",
                label: "אימונים",
                icon: "figure.strengthtraining.traditional",
                color: .blue
            )
            
            StatTile(
                value: "\(plans.count)",
                label: "תוכניות",
                icon: "list.bullet.rectangle",
                color: .green
            )
            
            StatTile(
                value: thisWeekSessions.formatted(),
                label: "השבוע",
                icon: "calendar.badge.checkmark",
                color: .orange
            )
            
            StatTile(
                value: totalVolumeThisWeek.formatted(.number.precision(.fractionLength(0))),
                label: unit.symbol,
                icon: "chart.bar.fill",
                color: .purple
            )
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var nextWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(hasCompletedWorkoutToday ? "מצוין!" : "האימון הבא")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: hasCompletedWorkoutToday ? "checkmark.circle.fill" : "arrow.forward.circle.fill")
                    .font(.title2)
                    .foregroundStyle(hasCompletedWorkoutToday ? .green : .blue)
            }
            
            if hasCompletedWorkoutToday {
                // Show completion message
                VStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.yellow)
                    
                    Text("כל הכבוד!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("השלמת את האימון להיום")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if let todaysWorkout = getTodaysCompletedWorkout() {
                        VStack(spacing: 8) {
                            HStack {
                                PillBadge(text: todaysWorkout.workoutLabel ?? todaysWorkout.planName ?? "אימון", icon: "dumbbell")
                                
                                Spacer()
                            }
                            
                            Text("מחר: \(getNextWorkoutPreview())")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.vertical, 8)
            } else if let nextWorkout = getNextWorkout() {
                VStack(alignment: .leading, spacing: 8) {
                    Text(nextWorkout.label)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        PillBadge(text: nextWorkout.plan.name, icon: "list.bullet.rectangle")
                        PillBadge(text: "\(nextWorkout.exercises.count) תרגילים", icon: "dumbbell")
                        
                        Spacer()
                        
                        Text(nextWorkout.day)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(action: {
                        showActiveWorkout = true
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("התחל אימון")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    
                    Text("אין תוכנית מתוזמנת")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("צור תוכנית אימון או בחר תוכנית קיימת ללוג")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 8) {
                        Button("צור תוכנית") {
                            showNewPlanSheet = true
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("התחל אימון") {
                            showActiveWorkout = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var lastWorkoutCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            HStack {
                Text("האימון האחרון")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("הצג הכל") {
                    onNavigateToHistory()
                }
                .font(.caption)
                .foregroundStyle(AppTheme.accent)
            }
            
            if let lastSession = sessions.first {
                VStack(alignment: .leading, spacing: AppTheme.s12) {
                    // Workout header
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.s4) {
                            Text(lastSession.workoutLabel ?? lastSession.planName ?? "אימון ללא שם")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.primary)
                            
                            Text(lastSession.date, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondary)
                        }
                        
                        Spacer()
                        
                        // Status indicator
                        Circle()
                            .fill(lastSession.isCompleted == true ? AppTheme.success : AppTheme.warning)
                            .frame(width: 12, height: 12)
                    }
                    
                    // Workout stats
                    HStack(spacing: AppTheme.s16) {
                        StatItem(
                            icon: "dumbbell.fill",
                            value: "\(lastSession.exerciseSessions.count)",
                            label: "תרגילים"
                        )
                        
                        StatItem(
                            icon: "list.number",
                            value: "\(totalSets(for: lastSession))",
                            label: "סטים"
                        )
                        
                        StatItem(
                            icon: "chart.bar.fill",
                            value: "\(Int(displayVolume(for: lastSession))) \(unit.symbol)",
                            label: "נפח"
                        )
                    }
                    
                    // Duration if available
                    if let duration = lastSession.durationSeconds, duration > 0 {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.info)
                            
                            Text("זמן: \(duration / 60) דק׳")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondary)
                        }
                    }
                }
            } else {
                EmptyStateView(
                    iconSystemName: "bolt.horizontal.circle",
                    title: "אין אימונים שמורים",
                    message: "התחל אימון כדי להתחיל.",
                    buttonTitle: "התחל אימון"
                ) {
                    showActiveWorkout = true
                }
            }
        }
        .appCard()
    }

    private var unit: AppSettings.WeightUnit { settingsList.first?.weightUnit ?? .kg }
    
    private func totalSets(for session: WorkoutSession) -> Int {
        session.exerciseSessions.reduce(0) { $0 + $1.setLogs.count }
    }
    
    private var thisWeekSessions: Int {
        let calendar = Calendar.current
        return sessions.filter { session in
            calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: Date())
        }.count
    }
    
    private var totalVolumeThisWeek: Double {
        let calendar = Calendar.current
        let thisWeekSessions = sessions.filter { session in
            calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: Date())
        }
        let totalKg = thisWeekSessions.reduce(0.0) { total, session in
            total + totalVolumeKg(for: session)
        }
        return unit.toDisplay(fromKg: totalKg)
    }
    
    private func totalVolumeKg(for session: WorkoutSession) -> Double {
        session.exerciseSessions.flatMap { $0.setLogs }.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
    }
    
    private func displayVolume(for session: WorkoutSession) -> Double {
        unit.toDisplay(fromKg: totalVolumeKg(for: session))
    }
    
    private func getNextWorkout() -> NextWorkout? {
        let today = Calendar.current.component(.weekday, from: Date())
        
        // Find plans that have a scheduled workout for today
        for plan in plans.sorted(by: { $0.name < $1.name }) {
            if plan.schedule.contains(where: { $0.weekday == today }) {
                let nextLabel = getNextWorkoutLabel(for: plan)
                let exercises = plan.exercises.filter { ex in
                    (ex.label ?? plan.planType.workoutLabels.first) == nextLabel
                }
                
                return NextWorkout(
                    plan: plan,
                    label: nextLabel,
                    exercises: exercises,
                    day: weekdayName(today)
                )
            }
        }
        
        // If no workout scheduled for today, find the next upcoming workout
        for dayOffset in 1...7 {
            let targetDay = ((today - 1 + dayOffset) % 7) + 1
            for plan in plans.sorted(by: { $0.name < $1.name }) {
                if plan.schedule.contains(where: { $0.weekday == targetDay }) {
                    let nextLabel = getNextWorkoutLabel(for: plan)
                    let exercises = plan.exercises.filter { ex in
                        (ex.label ?? plan.planType.workoutLabels.first) == nextLabel
                    }
                    
                    return NextWorkout(
                        plan: plan,
                        label: nextLabel,
                        exercises: exercises,
                        day: weekdayName(targetDay)
                    )
                }
            }
        }
        
        return nil
    }
    
    private func getNextWorkoutLabel(for plan: WorkoutPlan) -> String {
        // For Full Body plans, always return the same label
        if plan.planType == .fullBody {
            return plan.planType.workoutLabels.first ?? ""
        }
        
        // For AB/ABC plans, find the last completed workout label and get the next one
        let planSessions = sessions.filter { $0.planName == plan.name && $0.isCompleted == true }
        
        // If no completed sessions yet, start with the first workout
        guard let lastSession = planSessions.first else {
            return plan.planType.workoutLabels.first ?? ""
        }
        
        // Get the label from the last completed session
        let lastWorkoutLabel = getWorkoutLabelFromSession(lastSession, plan: plan)
        
        // Find the next workout in the cycle
        guard let currentIndex = plan.planType.workoutLabels.firstIndex(of: lastWorkoutLabel) else {
            return plan.planType.workoutLabels.first ?? ""
        }
        
        let nextIndex = (currentIndex + 1) % plan.planType.workoutLabels.count
        return plan.planType.workoutLabels[nextIndex]
    }
    
    private func getWorkoutLabelFromSession(_ session: WorkoutSession, plan: WorkoutPlan) -> String {
        // Prefer the explicit workout label stored on the session
        if let label = session.workoutLabel, plan.planType.workoutLabels.contains(label) {
            return label
        }

        // Fallback: infer from the first exercise recorded in the session
        if let firstExerciseName = session.exerciseSessions.first?.exerciseName,
           let exercise = plan.exercises.first(where: { $0.name == firstExerciseName }),
           let inferred = exercise.label,
           plan.planType.workoutLabels.contains(inferred) {
            return inferred
        }

        // Final fallback: first label for the plan type
        return plan.planType.workoutLabels.first ?? ""
    }
    
    private func weekdayName(_ day: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = max(1, min(7, day)) - 1
        return symbols[index]
    }
    
    private var weeklyProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("התקדמות השבוע")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("אימונים השבוע")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(thisWeekSessions)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("נפח כולל")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(totalVolumeThisWeek.formatted(.number.precision(.fractionLength(0)))) \(unit.symbol)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                if let avgSession = averageSessionDuration {
                    HStack {
                        Text("זמן אימון ממוצע")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(avgSession)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("פעולות מהירות")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionTile(
                    title: "צור תוכנית",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showNewPlanSheet = true
                }
                
                QuickActionTile(
                    title: "התחל אימון",
                    icon: "play.circle.fill",
                    color: .green
                ) {
                    showActiveWorkout = true
                }
                
                QuickActionTile(
                    title: "הסטוריה",
                    icon: "clock.arrow.circlepath",
                    color: .orange
                ) {
                    onNavigateToHistory()
                }
                
                QuickActionTile(
                    title: "הגדרות",
                    icon: "gearshape.fill",
                    color: .purple
                ) {
                    // Navigate to settings
                }
            }
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var averageSessionDuration: String? {
        let completedSessions = sessions.filter { $0.isCompleted ?? false }
        guard !completedSessions.isEmpty else { return nil }
        
        let totalDuration = completedSessions.compactMap { $0.durationSeconds }.reduce(0, +)
        guard totalDuration > 0 else { return nil }
        
        let avgDuration = Double(totalDuration) / Double(completedSessions.count)
        let minutes = Int(avgDuration / 60)
        return "\(minutes) דק׳"
    }
    
    private var hasCompletedWorkoutToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return sessions.contains { session in
            let sessionDate = calendar.startOfDay(for: session.date)
            return sessionDate == today && (session.isCompleted ?? false)
        }
    }
    
    private func getTodaysCompletedWorkout() -> WorkoutSession? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return sessions.first { session in
            let sessionDate = calendar.startOfDay(for: session.date)
            return sessionDate == today && (session.isCompleted ?? false)
        }
    }
    
    private func getNextWorkoutPreview() -> String {
        // Find tomorrow's workout or the next scheduled workout
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowWeekday = Calendar.current.component(.weekday, from: tomorrow)
        
        // Check if there's a plan scheduled for tomorrow
        for plan in plans.sorted(by: { $0.name < $1.name }) {
            if plan.schedule.contains(where: { $0.weekday == tomorrowWeekday }) {
                let nextLabel = getNextWorkoutLabel(for: plan)
                return "אימון \(nextLabel)"
            }
        }
        
        // If not tomorrow, find the next upcoming workout
        for dayOffset in 2...8 {
            let futureDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
            let futureWeekday = Calendar.current.component(.weekday, from: futureDate)
            
            for plan in plans.sorted(by: { $0.name < $1.name }) {
                if plan.schedule.contains(where: { $0.weekday == futureWeekday }) {
                    let nextLabel = getNextWorkoutLabel(for: plan)
                    let dayName = weekdayName(futureWeekday)
                    return "\(dayName) - אימון \(nextLabel)"
                }
            }
        }
        
        return "אין אימון מתוכנן"
    }
}

struct QuickActionTile: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    DashboardView(onNavigateToHistory: {})
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}

