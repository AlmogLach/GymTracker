//
//  WorkoutSessions.swift
//  GymTracker
//
//  Workout session-related views and components
//

import SwiftUI
import SwiftData

// MARK: - Session Views

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

struct NewWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    
    @State private var selectedPlan: WorkoutPlan?
    @State private var workoutLabel = "A"
    @State private var notes = ""
    @State private var showPlanPicker = false
    
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
                        }
                    }
                    
                    // Workout details
                    if selectedPlan != nil {
                        VStack(alignment: .leading, spacing: AppTheme.s12) {
                            Text("פרטי האימון")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            VStack(spacing: AppTheme.s16) {
                                // Workout label
                                VStack(alignment: .leading, spacing: AppTheme.s8) {
                                    Text("תגית אימון")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(AppTheme.primary)
                                    
                                    if selectedPlan?.planType == .fullBody {
                                        Text("Full")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(AppTheme.accent)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(AppTheme.s16)
                                            .background(AppTheme.accent.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        Picker("תגית אימון", selection: $workoutLabel) {
                                            ForEach(selectedPlan?.planType.workoutLabels ?? ["A"], id: \.self) { label in
                                                Text(label).tag(label)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                    }
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
                    
                    Spacer(minLength: 100)
                }
                .padding(AppTheme.s20)
            }
            .navigationTitle("אימון חדש")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("צור") {
                        createWorkout()
                    }
                    .disabled(selectedPlan == nil)
                }
            }
        }
        .sheet(isPresented: $showPlanPicker) {
            PlanPickerSheet(
                plans: plans,
                selectedPlan: $selectedPlan,
                onDismiss: { showPlanPicker = false }
            )
        }
    }
    
    private func createWorkout() {
        guard let plan = selectedPlan else { return }
        
        let session = WorkoutSession(
            date: Date(),
            planName: plan.name,
            workoutLabel: workoutLabel
        )
        
        modelContext.insert(session)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error creating workout: \(error)")
        }
    }
}

struct WorkoutSessionEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    
    let session: WorkoutSession
    @State private var workoutLabel: String
    @State private var notes: String
    @State private var duration: String
    @State private var showPlanPicker = false
    @State private var selectedPlan: WorkoutPlan?
    
    init(session: WorkoutSession) {
        self.session = session
        self._workoutLabel = State(initialValue: session.workoutLabel ?? "A")
        self._notes = State(initialValue: session.notes ?? "")
        self._duration = State(initialValue: session.durationSeconds.map { "\($0 / 60)" } ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s24) {
                    // Header card
                    VStack(spacing: AppTheme.s16) {
                        HStack {
                            // Workout label circle
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                
                                Text(workoutLabel)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.s4) {
                                Text("עריכת אימון")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(session.date, style: .date)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(AppTheme.s20)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    
                    // Workout Details card
                    VStack(alignment: .leading, spacing: AppTheme.s16) {
                        Text("פרטי האימון")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: AppTheme.s16) {
                            // Workout label
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("תגית אימון")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.primary)
                                
                                if selectedPlan?.planType == .fullBody {
                                    Text("Full")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(AppTheme.accent)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(AppTheme.s16)
                                        .background(AppTheme.accent.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    Picker("תגית אימון", selection: $workoutLabel) {
                                        ForEach(selectedPlan?.planType.workoutLabels ?? ["A"], id: \.self) { label in
                                            Text(label).tag(label)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                            
                            // Duration
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("זמן אימון (דקות)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.primary)
                                
                                TextField("זמן", text: $duration)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
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
                    .padding(AppTheme.s20)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    
                    Spacer(minLength: 100)
                }
                .padding(AppTheme.s20)
            }
            .navigationTitle("עריכת אימון")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") {
                        saveChanges()
                    }
                }
            }
        }
        .onAppear {
            selectedPlan = plans.first { $0.name == session.planName }
        }
    }
    
    private func saveChanges() {
        session.workoutLabel = workoutLabel
        session.notes = notes.isEmpty ? nil : notes
        
        if let durationInt = Int(duration) {
            session.durationSeconds = durationInt * 60
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving workout: \(error)")
        }
    }
}

struct ExerciseSummaryCard: View {
    let exerciseSession: ExerciseSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            HStack {
                Text(exerciseSession.exerciseName)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(exerciseSession.setLogs.count) סטים")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label("\(exerciseSession.setLogs.count)", systemImage: "list.number")
                Spacer()
                Label("\(exerciseSession.setLogs.count) סטים", systemImage: "checkmark.circle")
            }
            .font(.caption2)
            .foregroundStyle(AppTheme.secondary)
        }
        .padding(AppTheme.s12)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ExerciseDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSession
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s16) {
                    // Session header
                    VStack(spacing: AppTheme.s12) {
                        Text(session.workoutLabel ?? session.planName ?? "אימון")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(session.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(AppTheme.s20)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Statistics
                    statisticsSection
                    
                    // Exercise details
                    VStack(alignment: .leading, spacing: AppTheme.s16) {
                        Text("פרטי תרגילים")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        ForEach(session.exerciseSessions, id: \.exerciseName) { exerciseSession in
                            ExerciseSummaryCard(exerciseSession: exerciseSession)
                        }
                    }
                    .padding(AppTheme.s20)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, AppTheme.s20)
                .padding(.bottom, 100)
            }
            .navigationTitle("פרטי תרגיל")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("סגור") { dismiss() }
                }
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            Text("סטטיסטיקות")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.s12) {
                StatCard(
                    title: "סטים",
                    value: "\(exerciseSession.setLogs.count)",
                    icon: "list.number",
                    color: AppTheme.accent
                )
                
                StatCard(
                    title: "סטים הושלמו",
                    value: "\(exerciseSession.setLogs.count)",
                    icon: "scalemass",
                    color: AppTheme.success
                )
                
                StatCard(
                    title: "RPE ממוצע",
                    value: String(format: "%.1f", averageRPE),
                    icon: "chart.bar",
                    color: AppTheme.warning
                )
            }
        }
        .padding(AppTheme.s20)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var averageRPE: Double {
        let rpeValues = session.exerciseSessions.flatMap { $0.setLogs }.compactMap { $0.rpe }
        guard !rpeValues.isEmpty else { return 0.0 }
        return rpeValues.reduce(0, +) / Double(rpeValues.count)
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
    
    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(reps) חזרות × \(weight, specifier: "%.1f") ק״ג")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("RPE: \(rpe, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            
            Spacer()
            
            Text("\(reps) חזרות")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.success)
        }
        .padding(AppTheme.s12)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
