//
//  ActiveWorkoutView.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    let workout: NextWorkout?
    let onComplete: () -> Void
    
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
    
    @State private var currentWeight: Double = 0.0
    @State private var currentReps: Int = 0
    
    @Query private var settingsList: [AppSettings]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    private var settings: AppSettings { settingsList.first ?? AppSettings() }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if workout != nil {
                    VStack(spacing: 0) {
                        // Header with timer
                        workoutHeaderView
                        
                        // Main content
                        ScrollView {
                            VStack(spacing: 16) {
                                // Current exercise
                                currentExerciseCard
                                
                                // Exercise list
                                exerciseListView
                            }
                            .padding(16)
                        }
                        
                        // Rest timer overlay
                        if showRestTimer {
                            restTimerOverlay
                        }
                        
                        // Bottom action bar
                        bottomActionBar
                    }
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
        }
        .navigationBarHidden(true)
        .onAppear {
            startWorkoutSession()
            initializeCurrentExerciseValues()
        }
        .onDisappear {
            stopWorkoutTimer()
        }
    }
    
    private var workoutHeaderView: some View {
        VStack(spacing: 0) {
            // Top bar with controls
            HStack {
                Button(action: { completeWorkout() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("סיום")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.red)
                    .cornerRadius(20)
                }
                
                Spacer()
                
                Button(action: { pauseWorkout() }) {
                    HStack(spacing: 6) {
                        Image(systemName: workoutTimer != nil ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text(workoutTimer != nil ? "השהה" : "המשך")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.orange)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Workout info and timer
            VStack(spacing: 12) {
                Text(workout?.label ?? "אימון")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                // Large timer display
                Text(formatTime(elapsedSeconds))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(16)
                
                // Progress indicator
                VStack(spacing: 8) {
                    HStack {
                        Text("התקדמות")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(currentExerciseIndex + 1)/\(workout?.exercises.count ?? 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                    
                    ProgressView(value: Double(currentExerciseIndex + 1), total: Double(workout?.exercises.count ?? 1))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background {
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground),
                    Color(.secondarySystemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.separator),
            alignment: .bottom
        )
    }
    
    private var currentExerciseCard: some View {
        Group {
            if let workout = workout, currentExerciseIndex < workout.exercises.count {
                let exercise = workout.exercises[currentExerciseIndex]
                
                VStack(spacing: 0) {
                    // Exercise header
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("תרגיל נוכחי")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(exercise.name)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            // Exercise counter with modern design
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(.blue.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    
                                    VStack(spacing: 2) {
                                        Text("\(currentExerciseIndex + 1)")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundStyle(.blue)
                                        
                                        Text("\(workout.exercises.count)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Text("מתוך")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        // Exercise details
                        if exercise.plannedSets > 0 {
                            HStack(spacing: 8) {
                                ExerciseInfoChip(
                                    value: "\(exercise.plannedSets)",
                                    label: "סטים",
                                    icon: "number.circle.fill",
                                    color: .green
                                )
                                
                                if let plannedReps = exercise.plannedReps, plannedReps > 0 {
                                    ExerciseInfoChip(
                                        value: "\(plannedReps)",
                                        label: "חזרות",
                                        icon: "repeat.circle.fill",
                                        color: .blue
                                    )
                                }
                                
                                if let isBodyweight = exercise.isBodyweight, isBodyweight {
                                    ExerciseInfoChip(
                                        value: "גוף",
                                        label: "משקל",
                                        icon: "figure.strengthtraining.traditional",
                                        color: .orange
                                    )
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                    .background(.white.opacity(0.5))
                    
                    Divider()
                    
                    // Quick set logging section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("רישום סט")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        enhancedQuickSetLoggingView(for: exercise)
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: { previousExercise() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("קודם")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray5))
                                .foregroundStyle(.primary)
                                .cornerRadius(12)
                            }
                            .disabled(currentExerciseIndex == 0)
                            
                            Button(action: { nextExercise() }) {
                                HStack(spacing: 8) {
                                    Text("הבא")
                                        .fontWeight(.semibold)
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(20)
                }
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    private func enhancedQuickSetLoggingView(for exercise: Exercise) -> some View {
        VStack(spacing: 16) {
            // Set entry row
            HStack(spacing: 12) {
                // Weight input
                VStack(alignment: .leading, spacing: 6) {
                    Text("משקל (ק״ג)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        TextField("0", value: $currentWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        // Quick weight adjustment buttons
                        VStack(spacing: 4) {
                            Button(action: {
                                let increment = settings.weightIncrementKg
                                currentWeight += increment
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.blue)
                                    .frame(width: 28, height: 28)
                                    .background(.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                let increment = settings.weightIncrementKg
                                currentWeight = max(0, currentWeight - increment)
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.red)
                                    .frame(width: 28, height: 28)
                                    .background(.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Reps input
                VStack(alignment: .leading, spacing: 6) {
                    Text("חזרות")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        TextField("0", value: $currentReps, format: .number)
                            .keyboardType(.numberPad)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        // Quick reps adjustment buttons
                        VStack(spacing: 4) {
                            Button(action: {
                                currentReps += 1
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.green)
                                    .frame(width: 28, height: 28)
                                    .background(.green.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                currentReps = max(0, currentReps - 1)
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.orange)
                                    .frame(width: 28, height: 28)
                                    .background(.orange.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            // Add set button
            Button(action: { logSet(for: exercise) }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("הוסף סט")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: false)
        }
    }
    
    private func quickSetLoggingView(for exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("לוג סט מהיר")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Quick set entry similar to WorkoutComponents but simplified
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("משקל")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        TextField("0", value: .constant(0.0), format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        
                        Text("ק״ג")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("חזרות")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    TextField("0", value: .constant(exercise.plannedReps ?? 0), format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                }
                
                Spacer()
                
                Button("הוסף סט") {
                    logSet(for: exercise)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }
    
    private var indexedExercises: [(Int, Exercise)] {
        workout?.exercises.enumerated().map { ($0, $1) } ?? []
    }
    
    private var exerciseListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("תרגילי האימון")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(indexedExercises, id: \.1.id) { index, exercise in
                    HStack {
                        // Exercise number
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(width: 24, height: 24)
                            .background(index == currentExerciseIndex ? .blue : .gray.opacity(0.3))
                            .foregroundStyle(index == currentExerciseIndex ? .white : .secondary)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            if exercise.plannedSets > 0 {
                                Text("\(exercise.plannedSets) סטים")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if index < currentExerciseIndex {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if index == currentExerciseIndex {
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        currentExerciseIndex = index
                    }
                }
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var restTimerOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "timer")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.blue)
                    
                    Text("זמן מנוחה")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                
                // Large circular timer
                ZStack {
                    Circle()
                        .stroke(.blue.opacity(0.2), lineWidth: 8)
                        .frame(width: 180, height: 180)
                    
                    Circle()
                        .trim(from: 0, to: Double(restSecondsRemaining) / Double(settings.defaultRestSeconds))
                        .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: restSecondsRemaining)
                    
                    VStack(spacing: 4) {
                        Text(formatTime(restSecondsRemaining))
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(.blue)
                        
                        Text("נותרו")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(spacing: 16) {
                    Button(action: { skipRest() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("דלג")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white.opacity(0.9))
                        .foregroundStyle(.primary)
                        .cornerRadius(16)
                    }
                    
                    Button(action: { addRestTime(30) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("+30 שניות")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                Button(action: { completeWorkout() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("סיום אימון")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.red)
                    .cornerRadius(16)
                }
                
                Button(action: { startRestTimer() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "timer.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("מנוחה")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .padding(20)
        }
        .background(.regularMaterial)
    }
    
    // MARK: - Functions
    
    private func startWorkoutSession() {
        guard let workout = workout else { return }
        
        let session = WorkoutSession(
            date: Date(),
            planName: workout.plan.name,
            workoutLabel: workout.label,
            isCompleted: false
        )
        
        modelContext.insert(session)
        currentSession = session
        
        // Start workout timer
        workoutStartTime = Date()
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds = Int(Date().timeIntervalSince(workoutStartTime))
        }
    }
    
    private func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
        restTimer?.invalidate()
        restTimer = nil
    }
    
    private func logSet(for exercise: Exercise) {
        guard let session = currentSession else { 
            print("❌ No current session when trying to log set")
            return 
        }
        
        // Validate that we have valid values
        guard currentReps > 0 else {
            print("❌ Invalid reps: \(currentReps)")
            return
        }
        
        print("✅ Logging set for \(exercise.name): \(currentWeight)kg x \(currentReps) reps")
        
        // Find or create ExerciseSession for this exercise
        var exerciseSession = session.exerciseSessions.first { $0.exerciseName == exercise.name }
        
        if exerciseSession == nil {
            exerciseSession = ExerciseSession(exerciseName: exercise.name, setLogs: [])
            session.exerciseSessions.append(exerciseSession!)
            print("✅ Created new ExerciseSession for \(exercise.name)")
        }
        
        // Create and add SetLog
        let setLog = SetLog(
            reps: currentReps,
            weight: currentWeight,
            rpe: nil,
            notes: nil,
            restSeconds: settings.defaultRestSeconds,
            isWarmup: false
        )
        
        exerciseSession!.setLogs.append(setLog)
        print("✅ Added set log. Total sets for \(exercise.name): \(exerciseSession!.setLogs.count)")
        
        // Save to context
        do {
            try modelContext.save()
            print("✅ Successfully saved to context")
        } catch {
            print("❌ Failed to save: \(error)")
        }
        
        // Add rest timer after logging a set
        startRestTimer()
    }
    
    private func nextExercise() {
        guard let workout = workout else { return }
        
        if currentExerciseIndex < workout.exercises.count - 1 {
            currentExerciseIndex += 1
            initializeCurrentExerciseValues()
        }
    }
    
    private func previousExercise() {
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            initializeCurrentExerciseValues()
        }
    }
    
    private func initializeCurrentExerciseValues() {
        guard let workout = workout,
              currentExerciseIndex < workout.exercises.count else { return }
        
        let exercise = workout.exercises[currentExerciseIndex]
        
        // Initialize with planned values or defaults
        currentReps = exercise.plannedReps ?? 8
        
        // Try to get the last weight used for this exercise, or use a sensible default
        let lastWeight = getLastWeightForExercise(exercise.name)
        currentWeight = lastWeight > 0 ? lastWeight : (exercise.isBodyweight == true ? 0.0 : 20.0)
    }
    
    private func getLastWeightForExercise(_ exerciseName: String) -> Double {
        // Look through recent sessions to find the last weight used for this exercise
        for session in sessions {
            for exerciseSession in session.exerciseSessions {
                if exerciseSession.exerciseName == exerciseName {
                    if let lastSet = exerciseSession.setLogs.last {
                        return lastSet.weight
                    }
                }
            }
        }
        return 0.0
    }
    
    private func startRestTimer() {
        restSecondsRemaining = settings.defaultRestSeconds
        showRestTimer = true
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if restSecondsRemaining > 0 {
                restSecondsRemaining -= 1
            } else {
                skipRest()
            }
        }
    }
    
    private func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        showRestTimer = false
        restSecondsRemaining = 0
    }
    
    private func addRestTime(_ seconds: Int) {
        restSecondsRemaining += seconds
    }
    
    private func pauseWorkout() {
        if workoutTimer != nil {
            stopWorkoutTimer()
        } else {
            // Resume
            workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                elapsedSeconds += 1
            }
        }
    }
    
    private func completeWorkout() {
        currentSession?.isCompleted = true
        currentSession?.durationSeconds = elapsedSeconds
        
        try? modelContext.save()
        
        stopWorkoutTimer()
        onComplete()
        dismiss()
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct ExerciseInfoChip: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ActiveWorkoutView(
        workout: NextWorkout(
            plan: WorkoutPlan(name: "Push/Pull/Legs", planType: .abc),
            label: "A",
            exercises: [],
            day: "Sunday"
        ),
        onComplete: {}
    )
    .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}