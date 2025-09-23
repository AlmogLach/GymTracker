//
//  ActiveWorkoutView.swift
//  GymTracker
//
//  Enhanced Active Workout View with Modern UI
//
import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    let workout: NextWorkout?
    let onComplete: () -> Void
    let initialNotes: String?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentSession: WorkoutSession?
    @State private var workoutTimer: Timer?
    @State private var workoutStartTime = Date()
    @State private var elapsedSeconds = 0
    
    @State private var currentExerciseIndex = 0
    @State private var restTimer: Timer?
    @State private var restSecondsRemaining = 0
    @State private var showRestTimer = false
    @State private var restEndsAt: Date?
    
    @State private var currentWeight: Double = 0.0
    @State private var currentReps: Int = 0
    
    @Query private var settingsList: [AppSettings]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    private var settings: AppSettings { settingsList.first ?? AppSettings() }
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if workout != nil {
                    // Modern header section
                    headerSection
                        
                        // Main content
                        ScrollView {
                        VStack(spacing: AppTheme.s16) {
                            // Current exercise card
                                currentExerciseCard
                                
                            // Exercise progress
                            exerciseProgressCard

                            // All exercises list
                            exercisesListCard
                        }
                        .padding(.horizontal, AppTheme.s16)
                        .padding(.bottom, 100)
                        }
                        
                        // Rest timer overlay
                        if showRestTimer {
                            restTimerOverlay
                        }
                        
                        // Bottom action bar
                        bottomActionBar
                } else {
                    EmptyStateView(
                        iconSystemName: "calendar.badge.exclamationmark",
                        title: "אין אימון נבחר",
                        message: "חזור ובחר אימון מהלוח הראשי",
                        buttonTitle: "חזור"
                    ) {
                        dismiss()
                    }
                }
            }
            .background(AppTheme.screenBG)
            .navigationBarHidden(true)
        }
        .onAppear {
            startWorkoutSession()
            initializeCurrentExerciseValues()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                if showRestTimer, let endsAt = restEndsAt {
                    let remaining = Int(ceil(endsAt.timeIntervalSinceNow))
                    if remaining <= 0 {
                        stopRestTimer()
                    } else {
                        restSecondsRemaining = remaining
                        LiveActivityManager.shared.updateRemaining(remaining)
                        // Restart ticking timer if needed
                        if restTimer == nil {
                            restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                                if restSecondsRemaining > 0 {
                                    restSecondsRemaining -= 1
                                    LiveActivityManager.shared.updateRemaining(restSecondsRemaining)
                                } else {
                                    stopRestTimer()
                                }
                            }
                        }
                    }
                }
            case .background, .inactive:
                // Pause in-memory timer; remaining time is derived from restEndsAt on resume
                restTimer?.invalidate()
                restTimer = nil
            @unknown default:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .restSkipAction)) { _ in
            // Skip: immediately end rest and move to next exercise
            if showRestTimer {
                stopRestTimer()
                nextExercise()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .restStopAction)) { _ in
            if showRestTimer {
                stopRestTimer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextExerciseAction)) { _ in
            if !showRestTimer {
                nextExercise()
            }
        }
        .onDisappear {
            stopWorkoutTimer()
        }
    }
    
    // MARK: - Modern Views

    private var headerSection: some View {
        VStack(spacing: AppTheme.s16) {
            // Top navigation bar
            HStack {
                Button("ביטול") {
                    dismiss()
                }
                .foregroundStyle(AppTheme.secondary)
                
                Spacer()
                
                Text("אימון")
                    .font(.headline)
                    .fontWeight(.bold)
                        
                        Spacer()
                
                // Test Live Activity button (DEBUG ONLY)
                Button("🧪") {
                    LiveActivityManager.shared.testLiveActivity()
                }
                .foregroundStyle(.orange)
                .font(.title2)
                        
                Button("שמור") {
                    completeWorkout()
                }
                .foregroundStyle(AppTheme.accent)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, AppTheme.s16)

            // Workout info card
            workoutInfoCard
        }
        .padding(.top, AppTheme.s8)
        .background(AppTheme.cardBG)
    }

    private var workoutInfoCard: some View {
        VStack(spacing: AppTheme.s16) {
            // Workout icon and title
            VStack(spacing: AppTheme.s12) {
                                ZStack {
                                    Circle()
                        .fill(AppTheme.accent.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Text(workout?.label ?? "A")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }

                VStack(spacing: AppTheme.s4) {
                    Text("אימון")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Text(workout?.plan.name ?? "")
                        .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
            // Stats row
            HStack(spacing: AppTheme.s16) {
                StatTile(
                    value: formatTime(elapsedSeconds),
                    label: "זמן אימון",
                    icon: "stopwatch",
                    color: AppTheme.accent
                )

                StatTile(
                    value: "\(currentExerciseIndex + 1)/\(workout?.exercises.count ?? 1)",
                    label: "תרגילים",
                    icon: "list.number",
                    color: AppTheme.success
                )

                StatTile(
                    value: "\(getCurrentSetsCompleted())",
                    label: "סטים",
                    icon: "checkmark.circle",
                    color: AppTheme.warning
                )
            }
        }
        .padding(AppTheme.s20)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, AppTheme.s16)
    }

    private var currentExerciseCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            HStack {
                Text("תרגיל נוכחי")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                
                                Spacer()

                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(AppTheme.accent)
            }

            if let exercise = currentExercise {
                VStack(spacing: AppTheme.s16) {
                    // Exercise name
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.s4) {
                            Text(exercise.name)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                            if let muscleGroup = exercise.muscleGroup {
                                PillBadge(text: muscleGroup)
                            }
                        }

                        Spacer()
                    }

                    // Set input controls
                    exerciseInputControls
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var exerciseInputControls: some View {
        VStack(spacing: AppTheme.s16) {
            // Weight and reps input
            HStack(spacing: AppTheme.s16) {
                // Weight input
                VStack(alignment: .leading, spacing: AppTheme.s8) {
                    Text("משקל")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Button(action: { adjustWeight(-2.5) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(currentWeight > 0 ? AppTheme.accent : .gray)
                        }
                        .disabled(currentWeight <= 0)

                        TextField("0", value: $currentWeight, format: .number)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18, weight: .bold))
                            .multilineTextAlignment(.center)
                            .frame(width: 60)

                        Button(action: { adjustWeight(2.5) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }

                Spacer()
                
                // Reps input
                VStack(alignment: .leading, spacing: AppTheme.s8) {
                    Text("חזרות")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Button(action: { adjustReps(-1) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(currentReps > 0 ? AppTheme.accent : .gray)
                        }
                        .disabled(currentReps <= 0)

                        TextField("0", value: $currentReps, format: .number)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18, weight: .bold))
                            .multilineTextAlignment(.center)
                            .frame(width: 60)

                        Button(action: { adjustReps(1) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
            }
            .padding(AppTheme.s16)
            .background(AppTheme.screenBG)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Complete set button
            Button(action: addSet) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("הוסף סט")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.s12)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(currentReps == 0)
        }
    }

    private var exerciseProgressCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            HStack {
                Text("התקדמות")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Spacer()

                Button(action: nextExercise) {
                    HStack(spacing: AppTheme.s4) {
                        Text("תרגיל הבא")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.forward")
                            .font(.caption)
                    }
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, AppTheme.s12)
                    .padding(.vertical, AppTheme.s6)
                    .background(AppTheme.accent.opacity(0.1))
                    .clipShape(Capsule())
                }
                .disabled(currentExerciseIndex >= (workout?.exercises.count ?? 1) - 1)
            }

            // Exercise progress bar
            let totalExercises = max(1, workout?.exercises.count ?? 1)
            let clampedProgress = min(max(0, currentExerciseIndex + 1), totalExercises)
            ProgressView(value: Double(clampedProgress), total: Double(totalExercises))
                .tint(AppTheme.accent)
                .scaleEffect(y: 2)

            Text("\(currentExerciseIndex + 1) מתוך \(workout?.exercises.count ?? 1) תרגילים")
                            .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
        .padding(20)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var exercisesListCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            Text("תרגילים")
                .font(.system(size: 18, weight: .bold))

            if let exercises = workout?.exercises {
                VStack(spacing: AppTheme.s8) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseListItem(
                            exercise: exercise,
                            index: index,
                            isActive: index == currentExerciseIndex,
                            isCompleted: index < currentExerciseIndex,
                            onTap: { currentExerciseIndex = index }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var restTimerOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.s24) {
                Text("מנוחה")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("\(formatTime(restSecondsRemaining))")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.accent)

                HStack(spacing: AppTheme.s16) {
                    Button("דלג") {
                        stopRestTimer()
                    }
                    .buttonStyle(.bordered)

                    Button("הוסף דקה") {
                        restSecondsRemaining += 60
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(AppTheme.s32)
            .background(AppTheme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 20)
            .padding(.horizontal, AppTheme.s32)
        }
    }
    
    private var bottomActionBar: some View {
        HStack(spacing: AppTheme.s12) {
            Button("הפסק מנוחה") {
                startRestTimer()
            }
            .buttonStyle(.bordered)
            .disabled(showRestTimer)

            Button("סיים אימון") {
                completeWorkout()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AppTheme.s16)
        .padding(.vertical, AppTheme.s12)
        .background(AppTheme.cardBG)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
    }

    // MARK: - Supporting Components

    private var currentExercise: Exercise? {
        guard let workout = workout,
              currentExerciseIndex < workout.exercises.count else { return nil }
        return workout.exercises[currentExerciseIndex]
    }
    // MARK: - Helper Functions

    private func getCurrentSetsCompleted() -> Int {
        guard let session = currentSession,
              let exerciseSession = session.exerciseSessions.first(where: { $0.exerciseName == currentExercise?.name }) else {
            return 0
        }
        return exerciseSession.setLogs.count
    }

    private func adjustWeight(_ delta: Double) {
        currentWeight = max(0, currentWeight + delta)
    }

    private func adjustReps(_ delta: Int) {
        currentReps = max(0, currentReps + delta)
    }

    private func addSet() {
        guard currentReps > 0,
              let exercise = currentExercise,
              let session = currentSession else { return }

        let setLog = SetLog(reps: currentReps, weight: currentWeight)

        if let existingExerciseSession = session.exerciseSessions.first(where: { $0.exerciseName == exercise.name }) {
            existingExerciseSession.setLogs.append(setLog)
        } else {
            let newExerciseSession = ExerciseSession(exerciseName: exercise.name, setLogs: [setLog])
            session.exerciseSessions.append(newExerciseSession)
        }

        try? modelContext.save()
        startRestTimer()
    }
    
    private func nextExercise() {
        guard let workout = workout,
              currentExerciseIndex < workout.exercises.count - 1 else { return }

        currentExerciseIndex += 1
        initializeCurrentExerciseValues()
    }
    
    private func startRestTimer() {
        restSecondsRemaining = settings.defaultRestSeconds
        showRestTimer = true
        restEndsAt = Date().addingTimeInterval(TimeInterval(restSecondsRemaining))
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if restSecondsRemaining > 0 {
                restSecondsRemaining -= 1
                LiveActivityManager.shared.updateRemaining(restSecondsRemaining)
            } else {
                stopRestTimer()
            }
        }
        // Schedule lock-screen notification for rest end
        NotificationManager.shared.cancelRestEndNotification()
        NotificationManager.shared.scheduleRestEndNotification(after: restSecondsRemaining, exerciseName: currentExercise?.name)
        LiveActivityManager.shared.startRest(durationSeconds: restSecondsRemaining, exerciseName: currentExercise?.name, workoutLabel: workout?.label)
        // Also show a persistent controls notification (for devices without Live Activities)
        NotificationManager.shared.scheduleRestControlsNotification(remaining: restSecondsRemaining, exerciseName: currentExercise?.name)
    }
    
    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        showRestTimer = false
        restEndsAt = nil
        NotificationManager.shared.cancelRestEndNotification()
        NotificationManager.shared.removeRestControlsNotification()
        LiveActivityManager.shared.endRest()
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    // MARK: - Legacy Functions (keeping existing workout logic)
    private func startWorkoutSession() {
        guard currentSession == nil else { return }

        let session = WorkoutSession(
            date: Date(),
            planName: workout?.plan.name,
            workoutLabel: workout?.label,
            notes: initialNotes
        )

        modelContext.insert(session)
        currentSession = session

        workoutStartTime = Date()
        startWorkoutTimer()

        try? modelContext.save()
    }

    private func startWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }
    
    private func pauseWorkout() {
        if workoutTimer != nil {
            stopWorkoutTimer()
        } else {
            startWorkoutTimer()
        }
    }
    
    private func completeWorkout() {
        currentSession?.isCompleted = true
        currentSession?.durationSeconds = elapsedSeconds
        
        try? modelContext.save()
        onComplete()
        dismiss()
    }
    
    private func initializeCurrentExerciseValues() {
        guard let exercise = currentExercise else { return }

        // Get last recorded weight/reps from previous sessions
        if let lastSession = sessions.first(where: { session in
            session.exerciseSessions.contains { $0.exerciseName == exercise.name }
        }),
        let lastExerciseSession = lastSession.exerciseSessions.first(where: { $0.exerciseName == exercise.name }),
        let lastSet = lastExerciseSession.setLogs.last {
            currentWeight = lastSet.weight
            currentReps = lastSet.reps
        } else {
            // Use planned values as defaults
            currentWeight = 0.0
            currentReps = exercise.plannedReps ?? 8
        }
    }
}

struct ExerciseListItem: View {
    let exercise: Exercise
    let index: Int
    let isActive: Bool
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.s12) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.success)
                    } else if isActive {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: AppTheme.s4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isActive ? AppTheme.accent : .primary)

                    HStack(spacing: AppTheme.s8) {
                        Text("\(exercise.plannedSets) סטים")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let reps = exercise.plannedReps {
                            Text("• \(reps) חזרות")
                                .font(.caption)
                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if isActive {
                    Image(systemName: "chevron.forward")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(.vertical, AppTheme.s12)
            .padding(.horizontal, AppTheme.s16)
            .background(isActive ? AppTheme.accent.opacity(0.05) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        if isCompleted {
            return AppTheme.success
        } else if isActive {
            return AppTheme.accent
        } else {
            return .secondary
        }
    }
}
