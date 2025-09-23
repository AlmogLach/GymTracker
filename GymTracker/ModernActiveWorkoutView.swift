//
//  ModernActiveWorkoutView.swift
//  GymTracker
//
//  Modern, friendly, and intuitive workout interface
//
import SwiftUI
import SwiftData

struct ModernActiveWorkoutView: View {
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
    @State private var hasWorkoutLiveActivity = false
    
    @State private var currentWeight: Double = 0.0
    @State private var currentReps: Int = 0
    
    @State private var showingFinishConfirmation = false
    @State private var showingExerciseDetails = false
    
    @Query private var settingsList: [AppSettings]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    private var settings: AppSettings { settingsList.first ?? AppSettings() }
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.15, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    modernHeaderSection
                    currentExerciseHeroCard
                    quickStatsRow
                    setLoggingSection
                    exerciseProgressSection
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            
            // Rest timer overlay
            if showRestTimer {
                modernRestTimerOverlay
            }
            
            // Floating action button
            VStack {
                Spacer()
                floatingActionButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startWorkoutSession()
            initializeCurrentExerciseValues()
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhaseChange(phase)
        }
        .onReceive(NotificationCenter.default.publisher(for: .restSkipAction)) { _ in
            handleRestSkip()
        }
        .onReceive(NotificationCenter.default.publisher(for: .restStopAction)) { _ in
            handleRestStop()
        }
        .onReceive(NotificationCenter.default.publisher(for: .restAddMinuteAction)) { _ in
            handleRestAddMinute()
        }
        .onReceive(NotificationCenter.default.publisher(for: .nextExerciseAction)) { _ in
            handleNextExercise()
        }
        .onReceive(NotificationCenter.default.publisher(for: .logSetAction)) { _ in
            handleLogSet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .startRestAction)) { _ in
            handleStartRest()
        }
        .onReceive(NotificationCenter.default.publisher(for: .finishWorkoutAction)) { _ in
            handleFinishWorkout()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            handleUserDefaultsChange()
        }
        .confirmationDialog("סיים אימון", isPresented: $showingFinishConfirmation) {
            Button("כן, סיים", role: .destructive) {
                completeWorkout()
            }
            Button("ביטול", role: .cancel) { }
        } message: {
            Text("האם אתה בטוח שברצונך לסיים את האימון?")
        }
    }
    
    // MARK: - Modern UI Components
    
    private var modernHeaderSection: some View {
        VStack(spacing: 16) {
            // Top navigation
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                        Text("חזור")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Button(action: { showingFinishConfirmation = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("סיים")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                }
            }
            
            // Workout title card
            HStack(spacing: 16) {
                // Workout icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Text(workout?.label.first?.uppercased() ?? "A")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout?.plan.name ?? "אימון")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("יום אימון")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private var currentExerciseHeroCard: some View {
        VStack(spacing: 20) {
            // Exercise header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("תרגיל נוכחי")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(currentExercise?.name ?? "אין תרגיל")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: { showingExerciseDetails = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Exercise progress
            VStack(spacing: 12) {
                HStack {
                    Text("סטים")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("\(getCurrentSetsCompleted())/\(currentExercise?.plannedSets ?? 0)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ProgressView(value: Double(min(getCurrentSetsCompleted(), currentExercise?.plannedSets ?? 1)), total: Double(currentExercise?.plannedSets ?? 1))
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accent))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showingExerciseDetails) {
            ExerciseDetailSheet(exercise: currentExercise)
        }
    }
    
    private var quickStatsRow: some View {
        HStack(spacing: 16) {
            QuickStatCard(
                icon: "stopwatch",
                value: formatTime(elapsedSeconds),
                label: "זמן",
                color: AppTheme.accent
            )
            
            QuickStatCard(
                icon: "list.number",
                value: "\(currentExerciseIndex + 1)/\(workout?.exercises.count ?? 1)",
                label: "תרגילים",
                color: .green
            )
            
            QuickStatCard(
                icon: "checkmark.circle",
                value: "\(getTotalSetsCompleted())",
                label: "סטים",
                color: .orange
            )
        }
    }
    
    private var setLoggingSection: some View {
        VStack(spacing: 20) {
            // Section header
            HStack {
                Text("רישום סט")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("סט \(getCurrentSetsCompleted() + 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            // Weight and reps controls
            VStack(spacing: 16) {
                // Weight control
                HStack {
                    Text("משקל")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: { adjustWeight(-2.5) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        
                        Text("\(String(format: "%.1f", currentWeight)) ק\"ג")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 100)
                        
                        Button(action: { adjustWeight(2.5) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green.opacity(0.8))
                        }
                    }
                }
                
                // Reps control
                HStack {
                    Text("חזרות")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: { adjustReps(-1) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        
                        Text("\(currentReps)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 100)
                        
                        Button(action: { adjustReps(1) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green.opacity(0.8))
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private var exerciseProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("תרגילים באימון")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { nextExercise() }) {
                    HStack(spacing: 6) {
                        Text("הבא")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(AppTheme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array((workout?.exercises ?? []).enumerated()), id: \.offset) { index, exercise in
                    ModernExerciseRow(
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
    
    private var floatingActionButton: some View {
        HStack(spacing: 16) {
            // Rest button
            Button(action: { startRestTimer() }) {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .semibold))
                    Text("מנוחה")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.8))
                .clipShape(Capsule())
            }
            .disabled(showRestTimer)
            .opacity(showRestTimer ? 0.5 : 1.0)
            
            // Log set button
            Button(action: { addSet() }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("הוסף סט")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accent.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .disabled(currentReps <= 0)
            .opacity(currentReps <= 0 ? 0.5 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var modernRestTimerOverlay: some View {
        ZStack {
            // Enhanced background with blur effect
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .background(.ultraThinMaterial, in: Rectangle())
            
            VStack(spacing: 32) {
                // Header with exercise info
                VStack(spacing: 12) {
                    Text("מנוחה")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    if let exercise = currentExercise {
                        Text("תרגיל הבא: \(exercise.name)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                // Main timer display with enhanced styling
                VStack(spacing: 20) {
                    // Circular progress indicator
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 8)
                            .frame(width: 200, height: 200)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: CGFloat(restSecondsRemaining) / CGFloat(settings.defaultRestSeconds))
                            .stroke(
                                LinearGradient(
                                    colors: [AppTheme.accent, AppTheme.accent.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: restSecondsRemaining)
                        
                        // Timer text
                        VStack(spacing: 4) {
                            Text(formatTime(restSecondsRemaining))
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            Text("דקות")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                // Enhanced control buttons
                VStack(spacing: 16) {
                    // Primary action buttons
                    HStack(spacing: 16) {
                        // Stop button
                        Button(action: { stopRestTimer() }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.9))
                                        .frame(width: 60, height: 60)
                                        .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("עצור")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // Skip button
                        Button(action: { stopRestTimer(); nextExercise() }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accent)
                                        .frame(width: 60, height: 60)
                                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("דלג")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Add time button
                    Button(action: { 
                        restSecondsRemaining += 60
                        restEndsAt = Date().addingTimeInterval(TimeInterval(restSecondsRemaining))
                        LiveActivityManager.shared.updateRemaining(restSecondsRemaining)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("הוסף דקה")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.8))
                                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.8),
                                Color.black.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Helper Views
    
    private var currentExercise: Exercise? {
        guard let workout = workout,
              currentExerciseIndex < workout.exercises.count else { return nil }
        return workout.exercises[currentExerciseIndex]
    }
    
    private func getCurrentSetsCompleted() -> Int {
        guard let session = currentSession,
              let exerciseSession = session.exerciseSessions.first(where: { $0.exerciseName == currentExercise?.name }) else {
            return 0
        }
        return exerciseSession.setLogs.count
    }
    
    private func getTotalSetsCompleted() -> Int {
        guard let session = currentSession else { return 0 }
        return session.exerciseSessions.reduce(0) { $0 + $1.setLogs.count }
    }
    
    // MARK: - Actions
    
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
        print("⏰ Starting rest timer with \(settings.defaultRestSeconds) seconds")
        
        restSecondsRemaining = settings.defaultRestSeconds
        showRestTimer = true
        restEndsAt = Date().addingTimeInterval(TimeInterval(restSecondsRemaining))
        
        // Start local timer
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.restSecondsRemaining > 0 {
                self.restSecondsRemaining -= 1
                LiveActivityManager.shared.updateRemaining(self.restSecondsRemaining)
            } else {
                self.stopRestTimer()
            }
        }
        
        // Start Live Activity
        LiveActivityManager.shared.startRest(
            durationSeconds: restSecondsRemaining, 
            exerciseName: currentExercise?.name, 
            workoutLabel: workout?.label
        )
        
        print("✅ Rest timer started successfully")
    }
    
    private func stopRestTimer() {
        print("⏰ Stopping rest timer")
        
        restTimer?.invalidate()
        restTimer = nil
        showRestTimer = false
        restEndsAt = nil
        
        // End Live Activity
        LiveActivityManager.shared.endRest()
        
        print("✅ Rest timer stopped successfully")
    }
    
    private func completeWorkout() {
        currentSession?.isCompleted = true
        currentSession?.durationSeconds = elapsedSeconds
        try? modelContext.save()
        onComplete()
        dismiss()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func initializeCurrentExerciseValues() {
        guard let exercise = currentExercise else { return }
        
        if let lastSession = sessions.first(where: { session in
            session.exerciseSessions.contains { $0.exerciseName == exercise.name }
        }),
        let lastExerciseSession = lastSession.exerciseSessions.first(where: { $0.exerciseName == exercise.name }),
        let lastSet = lastExerciseSession.setLogs.last {
            currentWeight = lastSet.weight
            currentReps = lastSet.reps
        } else {
            currentWeight = 0.0
            currentReps = exercise.plannedReps ?? 8
        }
    }
    
    // MARK: - Notification Handlers
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        print("🔄 Scene phase changed to: \(phase)")
        
        switch phase {
        case .active:
            print("📱 App became active")
            
            // Only end Live Activities if we're not in a rest timer
            if currentSession != nil && !showRestTimer {
                print("🏋️ Workout session active, ending Live Activities")
                LiveActivityManager.shared.endRest()
                hasWorkoutLiveActivity = false
            }
            
            // Handle rest timer restoration
            if showRestTimer, let endsAt = restEndsAt {
                let remaining = Int(ceil(endsAt.timeIntervalSinceNow))
                print("⏰ Rest timer restoration: \(remaining) seconds remaining")
                
                if remaining <= 0 {
                    print("⏰ Rest timer expired while in background")
                    stopRestTimer()
                } else {
                    restSecondsRemaining = remaining
                    LiveActivityManager.shared.updateRemaining(remaining)
                    
                    // Restart the local timer
                    restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        if self.restSecondsRemaining > 0 {
                            self.restSecondsRemaining -= 1
                            LiveActivityManager.shared.updateRemaining(self.restSecondsRemaining)
                        } else {
                            self.stopRestTimer()
                        }
                    }
                    print("⏰ Rest timer restarted with \(remaining) seconds")
                }
            }
            
            // Restart workout timer if needed
            if currentSession != nil && workoutTimer == nil {
                startWorkoutTimer()
                print("⏱️ Workout timer restarted")
            }
            
        case .background, .inactive:
            print("📱 App went to background/inactive")
            
            // Stop local timers to save battery
            restTimer?.invalidate()
            restTimer = nil
            workoutTimer?.invalidate()
            workoutTimer = nil
            
            // Start Live Activity for workout session if we have an active workout
            if currentSession != nil && !showRestTimer && !hasWorkoutLiveActivity {
                print("🏋️ Starting workout Live Activity")
                hasWorkoutLiveActivity = true
                
                // Small delay to ensure smooth transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Task {
                        await LiveActivityManager.shared.startWorkoutSession(
                            workoutLabel: self.workout?.label, 
                            exerciseName: self.currentExercise?.name
                        )
                    }
                }
            }
            
        @unknown default:
            print("⚠️ Unknown scene phase")
            break
        }
    }
    
    private func handleRestSkip() {
        if showRestTimer {
            stopRestTimer()
            nextExercise()
        }
    }
    
    private func handleRestStop() {
        if showRestTimer {
            stopRestTimer()
        }
    }
    
    private func handleRestAddMinute() {
        if showRestTimer {
            restSecondsRemaining += 60
            restEndsAt = Date().addingTimeInterval(TimeInterval(restSecondsRemaining))
            LiveActivityManager.shared.updateRemaining(restSecondsRemaining)
        }
    }
    
    private func handleNextExercise() {
        if !showRestTimer {
            nextExercise()
        }
    }
    
    private func handleLogSet() {
        addSet()
    }
    
    private func handleStartRest() {
        if !showRestTimer {
            startRestTimer()
        }
    }
    
    private func handleFinishWorkout() {
        completeWorkout()
    }
    
    private func handleUserDefaultsChange() {
        // Handle widget actions if needed
    }
    
    // MARK: - Legacy Functions
    
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
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ModernExerciseRow: View {
    let exercise: Exercise
    let index: Int
    let isActive: Bool
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                } else if isActive {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.accent)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if let muscleGroup = exercise.muscleGroup {
                    Text(muscleGroup)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? AppTheme.accent.opacity(0.2) : Color.white.opacity(0.05))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? AppTheme.accent.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private var statusColor: Color {
        if isCompleted { return .green }
        if isActive { return AppTheme.accent }
        return .white.opacity(0.3)
    }
}

struct ExerciseDetailSheet: View {
    let exercise: Exercise?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let exercise = exercise {
                        Text(exercise.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let muscleGroup = exercise.muscleGroup {
                            Text(muscleGroup)
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        
                        if let notes = exercise.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.body)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("פרטי תרגיל")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("סגור") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ModernActiveWorkoutView(
        workout: nil,
        onComplete: {},
        initialNotes: nil
    )
}
