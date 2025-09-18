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
                AppTheme.screenBG
                    .ignoresSafeArea()
                
                if workout != nil {
                    VStack(spacing: 0) {
                        // Enhanced header with timer
                        enhancedWorkoutHeaderView
                        
                        // Main content
                        ScrollView {
                            VStack(spacing: AppTheme.s16) {
                                // Current exercise card
                                enhancedCurrentExerciseCard
                                
                                // Exercise list
                                enhancedExerciseListView
                                
                                // Recent sets
                                recentSetsSection
                            }
                            .padding(AppTheme.s16)
                        }
                        
                        // Rest timer overlay
                        if showRestTimer {
                            enhancedRestTimerOverlay
                        }
                        
                        // Bottom action bar
                        enhancedBottomActionBar
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
    
    // MARK: - Enhanced Header View
    
    private var enhancedWorkoutHeaderView: some View {
        VStack(spacing: 0) {
            // Top control bar with improved design
            HStack {
                Button(action: { completeWorkout() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white, AppTheme.error)
                        .background(Circle().fill(.white))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Workout status indicator
                HStack(spacing: AppTheme.s8) {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 8, height: 8)
                        .scaleEffect(workoutTimer != nil ? 1.0 : 0.6)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: workoutTimer != nil)
                    
                    Text(workoutTimer != nil ? "פעיל" : "מושהה")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.secondary)
                }
                
                Spacer()
                
                Button(action: { pauseWorkout() }) {
                    Image(systemName: workoutTimer != nil ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(.horizontal, AppTheme.s24)
            .padding(.top, AppTheme.s20)
            
            // Main workout display with improved layout
            VStack(spacing: AppTheme.s24) {
                // Workout title with better hierarchy
                VStack(spacing: AppTheme.s8) {
                    HStack(spacing: AppTheme.s12) {
                        // Workout type badge
                        Text(workout?.label ?? "A")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(AppTheme.accent)
                                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("אימון \(workout?.label ?? "A")")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.primary)
                            
                            Text(workout?.plan.name ?? "")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Enhanced timer with circular progress
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.1), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    // Progress circle (optional - could show workout progress)
                    Circle()
                        .trim(from: 0, to: Double(currentExerciseIndex + 1) / Double(workout?.exercises.count ?? 1))
                        .stroke(AppTheme.accent.opacity(0.3), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: currentExerciseIndex)
                    
                    VStack(spacing: AppTheme.s4) {
                        Text(formatTime(elapsedSeconds))
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.accent)
                        
                        Text("זמן אימון")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.secondary)
                    }
                }
                
                // Compact progress indicator
                VStack(spacing: AppTheme.s8) {
                    HStack {
                        Text("תרגיל \(currentExerciseIndex + 1) מתוך \(workout?.exercises.count ?? 1)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.primary)
                        
                        Spacer()
                        
                        Text("\(Int((Double(currentExerciseIndex + 1) / Double(workout?.exercises.count ?? 1)) * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, AppTheme.s8)
                            .padding(.vertical, AppTheme.s4)
                            .background(AppTheme.accent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    ProgressView(value: Double(currentExerciseIndex + 1), total: Double(workout?.exercises.count ?? 1))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accent))
                        .scaleEffect(y: 1.5)
                        .animation(.easeInOut(duration: 0.3), value: currentExerciseIndex)
                }
            }
            .padding(.horizontal, AppTheme.s24)
            .padding(.bottom, AppTheme.s24)
        }
        .background {
            LinearGradient(
                colors: [
                    AppTheme.accent.opacity(0.03),
                    AppTheme.screenBG
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(AppTheme.accent.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    // MARK: - Enhanced Current Exercise Card
    
    private var enhancedCurrentExerciseCard: some View {
        Group {
            if let workout = workout, currentExerciseIndex < workout.exercises.count {
                let exercise = workout.exercises[currentExerciseIndex]
                
                VStack(spacing: 0) {
                    // Exercise header
                    VStack(spacing: AppTheme.s16) {
                        HStack {
                            VStack(alignment: .leading, spacing: AppTheme.s4) {
                                Text("תרגיל נוכחי")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.secondary)
                                    .textCase(.uppercase)
                                
                                Text(exercise.name)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            // Enhanced exercise counter
                            VStack(spacing: AppTheme.s4) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accent.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    
                                    VStack(spacing: 2) {
                                        Text("\(currentExerciseIndex + 1)")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundStyle(AppTheme.accent)
                                        
                                        Text("\(workout.exercises.count)")
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.secondary)
                                    }
                                }
                                
                                Text("מתוך")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondary)
                            }
                        }
                        
                        // Exercise details with enhanced chips
                        if exercise.plannedSets > 0 {
                            HStack(spacing: AppTheme.s8) {
                                EnhancedExerciseInfoChip(
                                    value: "\(exercise.plannedSets)",
                                    label: "סטים",
                                    icon: "number.circle.fill",
                                    color: AppTheme.accent
                                )
                                
                                if let plannedReps = exercise.plannedReps, plannedReps > 0 {
                                    EnhancedExerciseInfoChip(
                                        value: "\(plannedReps)",
                                        label: "חזרות",
                                        icon: "repeat.circle.fill",
                                        color: AppTheme.accent
                                    )
                                }
                                
                                if let isBodyweight = exercise.isBodyweight, isBodyweight {
                                    EnhancedExerciseInfoChip(
                                        value: "גוף",
                                        label: "משקל",
                                        icon: "figure.strengthtraining.traditional",
                                        color: AppTheme.accent
                                    )
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(AppTheme.s20)
                    .background(.white.opacity(0.5))
                    
                    Divider()
                    
                    // Enhanced set logging section
                    VStack(alignment: .leading, spacing: AppTheme.s16) {
                        Text("רישום סט")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        enhancedSetLoggingView(for: exercise)
                        
                        // Enhanced action buttons
                        HStack(spacing: AppTheme.s12) {
                            Button(action: { previousExercise() }) {
                                HStack(spacing: AppTheme.s8) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("קודם")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.s12)
                                .background(AppTheme.secondaryBackground)
                                .foregroundStyle(AppTheme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
                            }
                            .disabled(currentExerciseIndex == 0)
                            
                            Button(action: { nextExercise() }) {
                                HStack(spacing: AppTheme.s8) {
                                    Text("הבא")
                                        .fontWeight(.semibold)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.s12)
                                .background(AppTheme.accent)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
                            }
                        }
                    }
                    .padding(AppTheme.s20)
                }
                .background(AppTheme.tertiaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    // MARK: - Enhanced Set Logging View
    
    private func enhancedSetLoggingView(for exercise: Exercise) -> some View {
        VStack(spacing: AppTheme.s20) {
            // Modern input controls with improved design
            HStack(spacing: AppTheme.s16) {
                // Weight input section
                VStack(spacing: AppTheme.s10) {
                    HStack {
                        Image(systemName: "scalemass")
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                        
                        Text("משקל (ק״ג)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.primary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: AppTheme.s8) {
                        // Large weight display
                        ZStack {
                            RoundedRectangle(cornerRadius: AppTheme.r16)
                                .fill(AppTheme.tertiaryBackground)
                                .frame(height: 60)
                            
                            TextField("0", value: $currentWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppTheme.accent)
                        }
                        
                        // Compact adjustment buttons
                        HStack(spacing: AppTheme.s8) {
                            Button(action: {
                                let increment = settings.weightIncrementKg
                                currentWeight = max(0, currentWeight - increment)
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.primary)
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.secondaryBackground)
                                    .clipShape(Circle())
                            }
                            
                            Text("±\(settings.weightIncrementKg, specifier: "%.1f")")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.secondary)
                            
                            Button(action: {
                                let increment = settings.weightIncrementKg
                                currentWeight += increment
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.primary)
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.secondaryBackground)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                
                // Reps input section
                VStack(spacing: AppTheme.s10) {
                    HStack {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                        
                        Text("חזרות")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.primary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: AppTheme.s8) {
                        // Large reps display
                        ZStack {
                            RoundedRectangle(cornerRadius: AppTheme.r16)
                                .fill(AppTheme.tertiaryBackground)
                                .frame(height: 60)
                            
                            TextField("0", value: $currentReps, format: .number)
                                .keyboardType(.numberPad)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppTheme.accent)
                        }
                        
                        // Compact adjustment buttons
                        HStack(spacing: AppTheme.s8) {
                            Button(action: {
                                currentReps = max(0, currentReps - 1)
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.primary)
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.secondaryBackground)
                                    .clipShape(Circle())
                            }
                            
                            Text("±1")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.secondary)
                            
                            Button(action: {
                                currentReps += 1
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(AppTheme.primary)
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.secondaryBackground)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
            
            // Enhanced add set button with better visual design
            Button(action: { logSet(for: exercise) }) {
                HStack(spacing: AppTheme.s12) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    Text("הוסף סט")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    Spacer()
                    
                    // Current set preview
                    if currentWeight > 0 && currentReps > 0 {
                        Text("\(currentWeight, specifier: "%.1f")×\(currentReps)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.s16)
                .padding(.horizontal, AppTheme.s20)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.r16)
                        .fill(AppTheme.accent)
                        .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: false)
        }
    }
    
    // MARK: - Recent Sets Section
    
    private var recentSetsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("סטים אחרונים")
                .font(.headline)
                .fontWeight(.bold)
            
            if let session = currentSession,
               let workout = workout,
               currentExerciseIndex < workout.exercises.count {
                
                let exercise = workout.exercises[currentExerciseIndex]
                
                let exerciseSession = session.exerciseSessions.first { $0.exerciseName == exercise.name }
                
                if let exerciseSession = exerciseSession, !exerciseSession.setLogs.isEmpty {
                    VStack(spacing: AppTheme.s8) {
                        ForEach(Array(exerciseSession.setLogs.suffix(3).enumerated()), id: \.offset) { index, setLog in
                            HStack {
                                Text("\(exerciseSession.setLogs.count - (exerciseSession.setLogs.suffix(3).count - index - 1))")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 24, height: 24)
                                    .background(AppTheme.accent.opacity(0.1))
                                    .foregroundStyle(AppTheme.accent)
                                    .clipShape(Circle())
                                
                                Text("\(setLog.weight, specifier: "%.1f") ק״ג")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("×")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondary)
                                
                                Text("\(setLog.reps)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                if let rpe = setLog.rpe {
                                    Text("RPE \(rpe, specifier: "%.1f")")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, AppTheme.s8)
                                        .padding(.vertical, AppTheme.s4)
                                        .background(AppTheme.accent.opacity(0.1))
                                        .foregroundStyle(AppTheme.accent)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(AppTheme.s12)
                            .background(AppTheme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                } else {
                    Text("אין סטים רשומים עדיין")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(AppTheme.s24)
                }
            } else {
                Text("אין סטים רשומים עדיין")
                    .font(.subheadline)
                            .foregroundStyle(AppTheme.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(AppTheme.s24)
            }
        }
        .appCard()
    }
    
    // MARK: - Enhanced Exercise List View
    
    private var enhancedExerciseListView: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("אימון \(workout?.label ?? "A")")
                .font(.headline)
                .fontWeight(.bold)
            
            ForEach(indexedExercises, id: \.1.id) { index, exercise in
                HStack {
                    // Exercise number
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: 24, height: 24)
                        .background(index == currentExerciseIndex ? AppTheme.accent : AppTheme.secondary.opacity(0.3))
                        .foregroundStyle(index == currentExerciseIndex ? .white : AppTheme.secondary)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if exercise.plannedSets > 0 {
                            Text("\(exercise.plannedSets) סטים")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if index < currentExerciseIndex {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.accent)
                    } else if index == currentExerciseIndex {
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .padding(.vertical, AppTheme.s8)
                .contentShape(Rectangle())
                .onTapGesture {
                    currentExerciseIndex = index
                }
            }
        }
        .appCard()
    }
    
    // MARK: - Enhanced Rest Timer Overlay
    
    private var enhancedRestTimerOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.s24) {
                VStack(spacing: AppTheme.s12) {
                    Image(systemName: "timer")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                    
                    Text("זמן מנוחה")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primary)
                }
                
                // Enhanced circular timer
                ZStack {
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.2), lineWidth: 8)
                        .frame(width: 180, height: 180)
                    
                    Circle()
                        .trim(from: 0, to: Double(restSecondsRemaining) / Double(settings.defaultRestSeconds))
                        .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: restSecondsRemaining)
                    
                    VStack(spacing: AppTheme.s4) {
                        Text(formatTime(restSecondsRemaining))
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.accent)
                        
                        Text("נותרו")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                    }
                }
                
                HStack(spacing: AppTheme.s16) {
                    Button(action: { skipRest() }) {
                        HStack(spacing: AppTheme.s8) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("דלג")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.s16)
                        .background(.white.opacity(0.9))
                        .foregroundStyle(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
                    }
                    
                    Button(action: { addRestTime(30) }) {
                        HStack(spacing: AppTheme.s8) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("+30 שניות")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.s16)
                        .background(AppTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
                    }
                }
                .padding(.horizontal, AppTheme.s20)
            }
            .padding(AppTheme.s32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.r16))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
    
    // MARK: - Enhanced Bottom Action Bar
    
    private var enhancedBottomActionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(AppTheme.accent.opacity(0.1))
            
            VStack(spacing: AppTheme.s16) {
                // Quick action buttons in a more modern layout
                HStack(spacing: AppTheme.s12) {
                    // Rest timer button - now more prominent
                    Button(action: { startRestTimer() }) {
                        VStack(spacing: AppTheme.s6) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "timer")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                            
                            Text("מנוחה")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(AppTheme.primary)
                        }
                    }
                    
                    Spacer()
                    
                    // Exercise navigation
                    HStack(spacing: AppTheme.s8) {
                        Button(action: { previousExercise() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(currentExerciseIndex == 0 ? AppTheme.secondary : AppTheme.accent)
                                .frame(width: 40, height: 40)
                                .background(AppTheme.secondaryBackground)
                                .clipShape(Circle())
                        }
                        .disabled(currentExerciseIndex == 0)
                        
                        Button(action: { nextExercise() }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppTheme.accent)
                                .frame(width: 40, height: 40)
                                .background(AppTheme.accent.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                    
                    // Finish workout button - minimized
                    Button(action: { completeWorkout() }) {
                        VStack(spacing: AppTheme.s6) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.error.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(AppTheme.error)
                            }
                            
                            Text("סיום")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(AppTheme.primary)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.s24)
                .padding(.top, AppTheme.s16)
                
                // Workout progress summary
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("זמן: \(formatTime(elapsedSeconds))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.primary)
                        
                        Text("תרגיל \(currentExerciseIndex + 1)/\(workout?.exercises.count ?? 1)")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondary)
                    }
                    
                    Spacer()
                    
                    if let session = currentSession,
                       let workout = workout,
                       currentExerciseIndex < workout.exercises.count {
                        let exercise = workout.exercises[currentExerciseIndex]
                        let exerciseSession = session.exerciseSessions.first { $0.exerciseName == exercise.name }
                        let setsCompleted = exerciseSession?.setLogs.count ?? 0
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("סטים: \(setsCompleted)/\(exercise.plannedSets)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(AppTheme.primary)
                            
                            if setsCompleted > 0 {
                                Text("נפח: \(Int(exerciseSession?.setLogs.reduce(0) { $0 + ($1.weight * Double($1.reps)) } ?? 0)) ק״ג")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppTheme.s24)
                .padding(.bottom, AppTheme.s16)
            }
        }
        .background(.regularMaterial)
    }
    
    // MARK: - Computed Properties
    
    private var indexedExercises: [(Int, Exercise)] {
        workout?.exercises.enumerated().map { ($0, $1) } ?? []
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

// MARK: - Enhanced Exercise Info Chip

struct EnhancedExerciseInfoChip: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.s6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.primary)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.secondary)
        }
        .padding(.horizontal, AppTheme.s12)
        .padding(.vertical, AppTheme.s8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
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