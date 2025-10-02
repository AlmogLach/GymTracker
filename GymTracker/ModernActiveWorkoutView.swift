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
    @State private var restInitialSeconds = 0
    @State private var hasWorkoutLiveActivity = false
    
    @State private var currentWeight: Double = 0.0
    @State private var currentReps: Int = 0
    @State private var isWarmupSet: Bool = false
    @State private var didInitSetFields: Bool = false
    
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
            // Start Live Activity in workout mode when entering the screen
            LiveActivityManager.shared.startWorkout(
                exerciseName: currentExercise?.name,
                workoutLabel: workout?.label,
                elapsed: elapsedSeconds,
                setsCompleted: getCurrentSetsCompleted(),
                setsPlanned: currentExercise?.plannedSets
            )
        }
        .task {
            // Ensure state syncs after initial render/data hydration
            didInitSetFields = false
            initializeCurrentExerciseValues()
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhaseChange(phase)
        }
        .onChange(of: currentExerciseIndex) {
            didInitSetFields = false
            initializeCurrentExerciseValues()
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
                Button(action: { handleBack() }) {
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("אימון פעיל - \(workout?.label ?? "אימון")")
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
                
                Text("סט \(getCurrentSetsCompleted() + 1)" + (isWarmupSet ? " (חימום)" : ""))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            // Last set preview (like exercise info)
            if let last = latestLoggedSetForCurrentExercise() {
                HStack(spacing: 8) {
                    Text("אחרון:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(String(format: "%.1f", last.weight)) ק\"ג × \(last.reps)\(last.isWarmup == true ? " (חימום)" : "")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                    Spacer()
                }
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

                // Quick add chips
                HStack(spacing: 8) {
                    ForEach([2.5, 5.0, 10.0], id: \.self) { inc in
                        Button(action: { adjustWeight(inc) }) {
                            Text("+\(String(format: "%.1f", inc)) ק\"ג")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.accent.opacity(0.25))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
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
                        .accessibilityLabel("הפחת חזרות")
                        
                        Text("\(currentReps)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 100)
                            .accessibilityLabel("חזרות: \(currentReps)")
                        
                        Button(action: { adjustReps(1) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green.opacity(0.8))
                        }
                        .accessibilityLabel("הוסף חזרות")
                    }
                }

                // Warmup toggle
                HStack {
                    Text("חימום")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 60, alignment: .leading)

                    Spacer()

                    Toggle(isOn: $isWarmupSet) {
                        Text(isWarmupSet ? "סט חימום" : "סט עבודה")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isWarmupSet ? .orange : .white)
                    }
                    .tint(.orange)
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
                .accessibilityLabel("תרגיל הבא")
            }
            
            LazyVStack(spacing: 8) {
                ForEach(Array((workout?.exercises ?? []).enumerated()), id: \.offset) { index, exercise in
                    ModernExerciseRow(
                        exercise: exercise,
                        index: index,
                        isActive: index == currentExerciseIndex,
                        isCompleted: index < currentExerciseIndex,
                        onTap: {
                            currentExerciseIndex = index
                            initializeCurrentExerciseValues()
                            Task { @MainActor in
                                await LiveActivityManager.shared.updateWorkoutInfo(
                                    exerciseName: currentExercise?.name,
                                    setsCompleted: getCurrentSetsCompleted(),
                                    setsPlanned: currentExercise?.plannedSets,
                                    elapsed: elapsedSeconds
                                )
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var floatingActionButton: some View {
        HStack(spacing: 16) {
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
                            .trim(from: 0, to: CGFloat(restSecondsRemaining) / CGFloat(max(1, restInitialSeconds)))
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
                        .accessibilityLabel("עצור מנוחה")
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
                        .accessibilityLabel("דלג מנוחה ותרגיל הבא")
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
                    .accessibilityLabel("הוסף דקה למנוחה")
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
        return exerciseSession.setLogs.filter { !($0.isWarmup ?? false) }.count
    }
    
    private func getTotalSetsCompleted() -> Int {
        guard let session = currentSession else { return 0 }
        return session.exerciseSessions.reduce(0) { total, ex in
            total + ex.setLogs.filter { !($0.isWarmup ?? false) }.count
        }
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

        let setLog = SetLog(reps: currentReps, weight: currentWeight, isWarmup: isWarmupSet)

        if let existingExerciseSession = session.exerciseSessions.first(where: { $0.exerciseName == exercise.name }) {
            existingExerciseSession.setLogs.append(setLog)
        } else {
            let newExerciseSession = ExerciseSession(exerciseName: exercise.name, setLogs: [setLog])
            session.exerciseSessions.append(newExerciseSession)
        }

        // If this is a working set, auto-adjust plannedSets upward to match current working sets count
        if !isWarmupSet {
            if let ex = currentExercise,
               let exSession = session.exerciseSessions.first(where: { $0.exerciseName == ex.name }) {
                let workingCount = exSession.setLogs.filter { !($0.isWarmup ?? false) }.count
                if workingCount > ex.plannedSets {
                    ex.plannedSets = workingCount
                }
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save workout session: \(error)")
        }
        // Update Live Activity sets info
        Task { @MainActor in
            await LiveActivityManager.shared.updateWorkoutInfo(
                exerciseName: currentExercise?.name,
                setsCompleted: getCurrentSetsCompleted(),
                setsPlanned: currentExercise?.plannedSets,
                elapsed: elapsedSeconds
            )
        }

        // Update current values for next set (keep the same weight/reps for convenience)
        // Don't reset to 0 - user likely wants to continue with same values
        
        // Start rest: 60s for warmup, default for working set
        let duration = isWarmupSet ? 60 : settings.defaultRestSeconds
        startRestTimer(seconds: duration)
    }
    
    private func nextExercise() {
        guard let workout = workout,
              currentExerciseIndex < workout.exercises.count - 1 else { return }
        currentExerciseIndex += 1
        initializeCurrentExerciseValues()
        Task { @MainActor in
            await LiveActivityManager.shared.updateWorkoutInfo(
                exerciseName: currentExercise?.name,
                setsCompleted: getCurrentSetsCompleted(),
                setsPlanned: currentExercise?.plannedSets,
                elapsed: elapsedSeconds
            )
        }
    }
    
    private func startRestTimer(seconds: Int? = nil) {
        let target = seconds ?? settings.defaultRestSeconds
        print("⏰ Starting rest timer with \(target) seconds")
        
        restSecondsRemaining = target
        restInitialSeconds = target
        showRestTimer = true
        restEndsAt = Date().addingTimeInterval(TimeInterval(restSecondsRemaining))
        
        // Start local timer (invalidate any existing timer first)
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.restSecondsRemaining > 0 {
                self.restSecondsRemaining -= 1
                print("⏰ Rest timer: \(self.restSecondsRemaining) seconds remaining")
                LiveActivityManager.shared.updateRemaining(self.restSecondsRemaining)
            } else {
                print("⏰ Rest timer finished, updating to workout mode")
                self.restSecondsRemaining = 0
                LiveActivityManager.shared.updateRemaining(0)
                self.stopRestTimer()
            }
        }
        
        // Schedule audible alert when rest ends
        NotificationManager.shared.cancelRestEndNotification()
        NotificationManager.shared.scheduleRestEndNotification(after: restSecondsRemaining, exerciseName: currentExercise?.name)

        // Start Live Activity
        Task {
            await LiveActivityManager.shared.startRest(
                durationSeconds: restSecondsRemaining, 
                exerciseName: currentExercise?.name, 
                workoutLabel: workout?.label,
                setsCompleted: getCurrentSetsCompleted(),
                setsPlanned: currentExercise?.plannedSets
            )
        }
        
        print("✅ Rest timer started successfully")
    }
    
    private func stopRestTimer() {
        print("⏰ Stopping rest timer")
        
        restTimer?.invalidate()
        restTimer = nil
        showRestTimer = false
        restEndsAt = nil
        
        // Cancel pending rest-end alert
        NotificationManager.shared.cancelRestEndNotification()

        // Update Live Activity to workout mode
        Task { @MainActor in
            await LiveActivityManager.shared.updateWorkoutInfo(
                exerciseName: currentExercise?.name,
                setsCompleted: getCurrentSetsCompleted(),
                setsPlanned: currentExercise?.plannedSets,
                elapsed: elapsedSeconds
            )
        }
        
        print("✅ Rest timer stopped successfully")
    }
    
    private func completeWorkout() {
        // End any live activity first so the Lock Screen/Dynamic Island clears
        LiveActivityManager.shared.finishWorkout()
        currentSession?.isCompleted = true
        currentSession?.durationSeconds = elapsedSeconds
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save completed workout: \(error)")
        }
        onComplete()
        dismiss()
    }

    private func handleBack() {
        // End Live Activity but do not mark session as completed
        LiveActivityManager.shared.finishWorkout()
        workoutTimer?.invalidate()
        workoutTimer = nil
        restTimer?.invalidate()
        restTimer = nil
        // If nothing was logged, do not keep an empty workout session
        if getTotalSetsCompleted() == 0, let session = currentSession {
            modelContext.delete(session)
            do {
                try modelContext.save()
            } catch {
                print("❌ Failed to delete empty workout session: \(error)")
            }
        }
        dismiss()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func initializeCurrentExerciseValues() {
        guard let workout = workout else {
            print("🔍 initializeCurrentExerciseValues: No workout provided")
            return
        }
        
        guard let exercise = currentExercise else { 
            print("🔍 initializeCurrentExerciseValues: No current exercise (workout: \(workout.label), index: \(currentExerciseIndex), exercises: \(workout.exercises.count))")
            print("🔍 Plan: \(workout.plan.name), PlanType: \(workout.plan.planType)")
            print("🔍 All plan exercises: \(workout.plan.exercises.map { "\($0.name) (label: \($0.label ?? "nil"))" })")
            return 
        }
        
        print("🔍 initializeCurrentExerciseValues: Starting for '\(exercise.name)'")
        print("🔍 Exercise details: name='\(exercise.name)', label='\(exercise.label ?? "nil")', plannedSets=\(exercise.plannedSets), plannedReps=\(exercise.plannedReps ?? 0)")
        
        // 1) Prefer values from the current session
        if let current = currentSession,
           let currentExerciseSession = current.exerciseSessions.first(where: { $0.exerciseName == exercise.name }) {
            print("🔍 Found current exercise session with \(currentExerciseSession.setLogs.count) sets")
            
            if let lastWorking = currentExerciseSession.setLogs.last(where: { !($0.isWarmup ?? false) }) {
                print("🔍 Using last working set: \(lastWorking.weight)kg x \(lastWorking.reps)")
                currentWeight = lastWorking.weight
                currentReps = lastWorking.reps
                return
            }
            if let lastAny = currentExerciseSession.setLogs.last {
                print("🔍 Using last any set: \(lastAny.weight)kg x \(lastAny.reps)")
                currentWeight = lastAny.weight
                currentReps = lastAny.reps
                return
            }
        }

        // 2) Otherwise use the latest from history (prefer working set)
        if let last = latestLoggedSetForCurrentExercise() {
            print("🔍 Using latest from history: \(last.weight)kg x \(last.reps)")
            currentWeight = last.weight
            currentReps = last.reps
            return
        }

        // 3) Fallback to planned reps
        print("🔍 Using fallback: 0kg x \(exercise.plannedReps ?? 8)")
        currentWeight = 0.0
        currentReps = exercise.plannedReps ?? 8
    }

    private func latestLoggedSetForCurrentExercise() -> SetLog? {
        guard let name = currentExercise?.name else { 
            print("🔍 latestLoggedSetForCurrentExercise: No current exercise name")
            return nil 
        }
        
        print("🔍 latestLoggedSetForCurrentExercise: Looking for exercise '\(name)'")
        print("🔍 Available sessions: \(sessions.count)")
        
        // Try current @Query first
        if let lastSession = sessions.first(where: { session in
            session.exerciseSessions.contains { $0.exerciseName == name }
        }), let lastExerciseSession = lastSession.exerciseSessions.first(where: { $0.exerciseName == name }) {
            print("🔍 Found session with exercise: \(lastSession.date), sets: \(lastExerciseSession.setLogs.count)")
            let workingSet = lastExerciseSession.setLogs.last(where: { !($0.isWarmup ?? false) })
            let anySet = lastExerciseSession.setLogs.last
            print("🔍 Last working set: \(workingSet?.weight ?? 0)kg x \(workingSet?.reps ?? 0)")
            print("🔍 Last any set: \(anySet?.weight ?? 0)kg x \(anySet?.reps ?? 0)")
            return workingSet ?? anySet
        }
        
        print("🔍 No session found in @Query, trying direct fetch...")
        // Fallback to direct fetch to avoid race on first load
        do {
            let fetched = try modelContext.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
            print("🔍 Direct fetch found \(fetched.count) sessions")
            if let s = fetched.first(where: { $0.exerciseSessions.contains { $0.exerciseName == name } }),
               let ex = s.exerciseSessions.first(where: { $0.exerciseName == name }) {
                print("🔍 Found in direct fetch: \(s.date), sets: \(ex.setLogs.count)")
                let workingSet = ex.setLogs.last(where: { !($0.isWarmup ?? false) })
                let anySet = ex.setLogs.last
                print("🔍 Last working set: \(workingSet?.weight ?? 0)kg x \(workingSet?.reps ?? 0)")
                print("🔍 Last any set: \(anySet?.weight ?? 0)kg x \(anySet?.reps ?? 0)")
                return workingSet ?? anySet
            }
        } catch { 
            print("🔍 Direct fetch error: \(error)")
        }
        
        print("🔍 No logged sets found for exercise '\(name)'")
        return nil
    }
    
    // MARK: - Notification Handlers
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        print("🔄 Scene phase changed to: \(phase)")
        
        switch phase {
        case .active:
            print("📱 App became active")
            
            // Ensure Live Activity is in workout mode (not ended) when returning and not resting
            if currentSession != nil && !showRestTimer && !(currentSession?.isCompleted ?? false) {
                LiveActivityManager.shared.startWorkout(
                    exerciseName: currentExercise?.name,
                    workoutLabel: workout?.label,
                    elapsed: elapsedSeconds,
                    setsCompleted: getCurrentSetsCompleted(),
                    setsPlanned: currentExercise?.plannedSets
                )
            }

            // Ensure workout clock continues while app was backgrounded
            if currentSession != nil {
                elapsedSeconds = max(0, Int(Date().timeIntervalSince(workoutStartTime)))
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
                    
                    // Restart the local timer (invalidate any existing timer first)
                    restTimer?.invalidate()
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
            
            // Do not auto-start a workout Live Activity on background.
            // Live Activities will be shown only for explicit rest timers.
            
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
            restInitialSeconds += 60
            restEndsAt = Date().addingTimeInterval(TimeInterval(restSecondsRemaining))
            LiveActivityManager.shared.updateRemaining(restSecondsRemaining)
            NotificationManager.shared.cancelRestEndNotification()
            NotificationManager.shared.scheduleRestEndNotification(after: restSecondsRemaining, exerciseName: currentExercise?.name)
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
        LiveActivityManager.shared.finishWorkout()
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
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save new workout session: \(error)")
        }
    }
    
    private func startWorkoutTimer() {
        // Invalidate any existing timer first
        workoutTimer?.invalidate()
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

struct Chip: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct StatPill: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 34, height: 34)
                Image(systemName: icon).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline).fontWeight(.semibold)
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ExerciseDetailSheet: View {
    let exercise: Exercise?
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if let exercise = exercise {
                        // Header card
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.accent, AppTheme.accent.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                if let muscleGroup = exercise.muscleGroup, !muscleGroup.isEmpty {
                                    Text(muscleGroup)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                HStack(spacing: 6) {
                                    Chip(text: "סטים מתוכננים: \(exercise.plannedSets)", color: .blue)
                                    if let reps = exercise.plannedReps { Chip(text: "חזרות: \(reps)", color: .green) }
                                }
                            }

                            Spacer()

                            // Favorite toggle small
                            Button(action: { exercise.isFavorite = !(exercise.isFavorite ?? false) }) {
                                Image(systemName: (exercise.isFavorite ?? false) ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                                    .padding(10)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Stats row
                        if let stats = sessionStats(for: exercise) {
                            HStack(spacing: 12) {
                                StatPill(icon: "flame.fill", color: .orange, title: "חימום", value: "\(stats.warmups)")
                                StatPill(icon: "checkmark.circle.fill", color: .green, title: "עבודה", value: "\(stats.working)")
                                if let best = bestSet(for: exercise) {
                                    StatPill(icon: "trophy.fill", color: .yellow, title: "שיא", value: "\(Int(best.weight))×\(best.reps)")
                                }
                            }
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // Last session summary
                        if let last = lastSession(for: exercise) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("האימון האחרון")
                                        .font(.headline)
                                    Spacer()
                                    Text(last.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                LazyVStack(spacing: 8) {
                                    ForEach(Array(last.setLogs.enumerated()), id: \.offset) { idx, set in
                                        HStack {
                                            HStack(spacing: 6) {
                                                Text("#\(idx + 1)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                if set.isWarmup == true {
                                                    Chip(text: "חימום", color: .orange)
                                                }
                                            }
                                            Spacer()
                                            Text("\(String(format: "%.1f", set.weight)) ק\"ג × \(set.reps)")
                                                .font(.subheadline)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color(.tertiarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Personal best
                        if let best = bestSet(for: exercise) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().fill(Color.orange.opacity(0.15)).frame(width: 44, height: 44)
                                    Image(systemName: "trophy.fill").foregroundStyle(.orange)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("שיא אישי")
                                        .font(.headline)
                                    Text("\(String(format: "%.1f", best.weight)) ק\"ג × \(best.reps)")
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Notes
                        if let notes = exercise.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("הערות")
                                    .font(.headline)
                                Text(notes)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(14)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("פרטי תרגיל")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("סגור") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func sessionStats(for exercise: Exercise) -> (warmups: Int, working: Int)? {
        if let last = lastSession(for: exercise) {
            let warmups = last.setLogs.filter { $0.isWarmup == true }.count
            let working = last.setLogs.filter { !($0.isWarmup ?? false) }.count
            return (warmups, working)
        }
        return nil
    }
    private func lastSession(for exercise: Exercise) -> (date: Date, setLogs: [SetLog])? {
        for session in sessions {
            if let ex = session.exerciseSessions.first(where: { $0.exerciseName == exercise.name }), !ex.setLogs.isEmpty {
                return (session.date, ex.setLogs)
            }
        }
        return nil
    }
    
    private func bestSet(for exercise: Exercise) -> SetLog? {
        var best: SetLog? = nil
        for session in sessions {
            if let ex = session.exerciseSessions.first(where: { $0.exerciseName == exercise.name }) {
                for set in ex.setLogs where !(set.isWarmup ?? false) {
                    if let b = best {
                        if set.weight > b.weight { best = set }
                    } else {
                        best = set
                    }
                }
            }
        }
        return best
    }
}

#Preview {
    ModernActiveWorkoutView(
        workout: nil,
        onComplete: {},
        initialNotes: nil
    )
}
