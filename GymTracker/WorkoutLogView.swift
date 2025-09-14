//
//  WorkoutLogView.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

struct WorkoutLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    @Query private var settingsList: [AppSettings]
    @State private var selectedPlan: WorkoutPlan?
    @State private var session = WorkoutSession()
    @State private var lastDefaults: [String: (reps: Int, weight: Double, rpe: Double?)] = [:]
    @State private var selectedLabel: String = ""
    @State private var showAllLabels: Bool = false
    @State private var logActiveSheet: LogSheet?
    @State private var addedToastCount: Int = 0
    @State private var showAddedToast: Bool = false

    private enum LogSheet: String, Identifiable { 
        case chooseExercises, choosePlan
        var id: String { rawValue } 
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    polishedPlanSelectionCard
                    
                    if selectedPlan == nil {
                        EmptyStateView(
                            iconSystemName: "dumbbell",
                            title: "בחר תוכנית כדי להתחיל לוג"
                        )
                        .padding(16)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    } else if let plan = selectedPlan {
                        polishedExercisesCard(plan: plan)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 120) // Space for sticky footer
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("לוג אימון")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: selectedPlan) { _, newValue in
                Task { await loadLastDefaults(for: newValue) }
            }
            .onChange(of: selectedLabel) { _, _ in
                Task { await loadLastDefaults(for: selectedPlan) }
            }
            .sheet(item: $logActiveSheet) { sheet in
                switch sheet {
                case .chooseExercises:
                    ExercisePickerSheet(onAdd: { items in
                        var added = 0
                        for item in items {
                            let name = item.name
                            if !session.exerciseSessions.contains(where: { $0.exerciseName.caseInsensitiveCompare(name) == .orderedSame }) {
                                session.exerciseSessions.append(ExerciseSession(exerciseName: name, setLogs: []))
                                added += 1
                            }
                        }
                        logActiveSheet = nil
                        if added > 0 { addedToastCount = added; showAddedToast = true }
                    })
                case .choosePlan:
                    PlanSelectionSheet(
                        plans: plans,
                        selectedPlan: $selectedPlan,
                        onDismiss: { 
                            logActiveSheet = nil 
                        }
                    )
                }
            }
            .alert("הוספה", isPresented: $showAddedToast) {
                Button("סגור", role: .cancel) {}
            } message: {
                Text("נוספו \(addedToastCount) תרגילים ללוג")
            }
            .safeAreaInset(edge: .bottom) {
                polishedStickyFooter
            }
        }
        .onTapGesture {
            // Dismiss keyboard on tap outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    private func loadLastDefaults(for plan: WorkoutPlan?) async {
        lastDefaults = [:]
        guard let plan else { return }
        let targetName: String? = plan.name
        let targetLabel: String? = selectedLabel.isEmpty ? plan.planType.workoutLabels.first : selectedLabel
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.planName == targetName && $0.workoutLabel == targetLabel }, sortBy: [SortDescriptor(\WorkoutSession.date, order: .reverse)])
        descriptor.fetchLimit = 1
        if let last = try? modelContext.fetch(descriptor).first {
            var dict: [String: (Int, Double, Double?)] = [:]
            for ex in last.exerciseSessions {
                if let lastSet = ex.setLogs.last {
                    dict[ex.exerciseName] = (lastSet.reps, lastSet.weight, lastSet.rpe)
                }
            }
            lastDefaults = dict
        }
    }

    private var appSettings: AppSettings { settingsList.first ?? AppSettings() }

    private func smartAutofill(plan: WorkoutPlan) async {
        let targetName: String? = plan.name
        let targetLabel: String? = selectedLabel.isEmpty ? plan.planType.workoutLabels.first : selectedLabel
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.planName == targetName && $0.workoutLabel == targetLabel }, sortBy: [SortDescriptor(\WorkoutSession.date, order: .reverse)])
        descriptor.fetchLimit = 3
        let history = (try? modelContext.fetch(descriptor)) ?? []

        let exercises = plan.exercises.filter { ex in selectedLabel.isEmpty ? true : ((ex.label ?? plan.planType.workoutLabels.first) == selectedLabel) }

        var newSessions: [ExerciseSession] = []
        for ex in exercises {
            let name = ex.name
            var recentSets: [SetLog] = []
            for s in history {
                if let exSes = s.exerciseSessions.first(where: { $0.exerciseName.caseInsensitiveCompare(name) == .orderedSame }) {
                    recentSets.append(contentsOf: exSes.setLogs)
                }
            }

            let defaultReps = ex.plannedReps ?? 8
            let repsMin = max(1, defaultReps - 2)
            let repsMax = defaultReps + 2
            let topSet: SetLog? = recentSets
                .filter { !($0.isWarmup ?? false) && $0.reps >= repsMin && $0.reps <= repsMax }
                .max(by: { $0.weight < $1.weight })

            let targetSets = max(1, ex.plannedSets)
            var generated: [SetLog] = []

            if let top = topSet {
                let isDumbbell = (ex.equipment ?? "").localizedCaseInsensitiveContains("דאמ") || (ex.equipment ?? "").localizedCaseInsensitiveContains("dumbbell")
                let next = computeNextTopSet(from: top, defaultReps: defaultReps, equipment: ex.equipment, isDumbbell: isDumbbell)
                generated.append(next)
                for _ in 1..<targetSets {
                    let backoffWeight = max(0, next.weight * 0.975)
                    generated.append(SetLog(reps: next.reps, weight: roundToIncrement(backoffWeight, equipment: ex.equipment, isDumbbell: isDumbbell), rpe: nil, notes: nil, restSeconds: appSettings.defaultRestSeconds, isWarmup: false))
                }
            } else {
                for _ in 0..<targetSets {
                    generated.append(SetLog(reps: defaultReps, weight: 0, rpe: nil, notes: nil, restSeconds: appSettings.defaultRestSeconds, isWarmup: false))
                }
            }

            newSessions.append(ExerciseSession(exerciseName: name, setLogs: generated))
        }

        session.exerciseSessions = newSessions
    }

    private func computeNextTopSet(from top: SetLog, defaultReps: Int, equipment: String?, isDumbbell: Bool) -> SetLog {
        switch appSettings.autoProgressionMode {
        case .percent:
            let progressed = top.weight * (1.0 + appSettings.autoProgressionPercent / 100.0)
            let rounded = roundToIncrement(progressed, equipment: equipment, isDumbbell: isDumbbell)
            return SetLog(reps: defaultReps, weight: rounded, rpe: top.rpe, notes: nil, restSeconds: appSettings.defaultRestSeconds, isWarmup: false)
        case .repCycle:
            let repsMin = max(1, defaultReps - 2)
            let repsMax = defaultReps + 2
            if top.reps < repsMax {
                let reps = min(repsMax, top.reps + 1)
                return SetLog(reps: reps, weight: top.weight, rpe: top.rpe, notes: nil, restSeconds: appSettings.defaultRestSeconds, isWarmup: false)
            } else {
                let incWeight = roundToIncrement(top.weight + increment(for: equipment, isDumbbell: isDumbbell), equipment: equipment, isDumbbell: isDumbbell)
                return SetLog(reps: repsMin, weight: incWeight, rpe: top.rpe, notes: nil, restSeconds: appSettings.defaultRestSeconds, isWarmup: false)
            }
        }
    }

    private func roundToIncrement(_ weight: Double, equipment: String?, isDumbbell: Bool) -> Double {
        let unit = appSettings.weightUnit
        let inc = increment(for: equipment, isDumbbell: isDumbbell)
        let display = unit.toDisplay(fromKg: weight)
        let roundedDisplay = (display / inc).rounded() * inc
        return unit.toKg(fromDisplay: roundedDisplay)
    }

    private func increment(for equipment: String?, isDumbbell: Bool) -> Double {
        let unit = appSettings.weightUnit
        if isDumbbell {
            return unit == .kg ? appSettings.dumbbellIncrementKg : appSettings.dumbbellIncrementLb
        } else {
            return unit == .kg ? appSettings.weightIncrementKg : appSettings.weightIncrementLb
        }
    }

    private func estimate1RM_Epley(weight: Double, reps: Int) -> Double { weight * (1.0 + Double(reps) / 30.0) }
    private func estimate1RM_Brzycki(weight: Double, reps: Int) -> Double { weight * 36.0 / (37.0 - Double(reps)) }

    // MARK: - Warmup Ramp (optional)
    private func addWarmupRamp(plan: WorkoutPlan) {
        let percents: [Double] = [0.40, 0.55, 0.70, 0.80, 0.90]
        let reps: [Int] = [8, 5, 3, 2, 1]
        let rest = max(45, min(60, appSettings.defaultRestSeconds))

        for i in 0..<session.exerciseSessions.count {
            let name = session.exerciseSessions[i].exerciseName
            guard let exercise = plan.exercises.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) else { continue }
            let isDumbbell = (exercise.equipment ?? "").localizedCaseInsensitiveContains("דאמ") || (exercise.equipment ?? "").localizedCaseInsensitiveContains("dumbbell")

            // Skip if warmups already exist
            if session.exerciseSessions[i].setLogs.contains(where: { $0.isWarmup ?? false }) { continue }

            // Need a target working set weight
            guard let firstWork = session.exerciseSessions[i].setLogs.first(where: { !($0.isWarmup ?? false) && $0.weight > 0 }) else { continue }
            let target = firstWork.weight

            var warmups: [SetLog] = []
            for (p, r) in zip(percents, reps) {
                let w = roundToIncrement(target * p, equipment: exercise.equipment, isDumbbell: isDumbbell)
                warmups.append(SetLog(reps: r, weight: w, rpe: nil, notes: nil, restSeconds: rest, isWarmup: true))
            }

            session.exerciseSessions[i].setLogs.insert(contentsOf: warmups, at: 0)
        }
    }
    
    private var polishedPlanSelectionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("בחר תוכנית")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Button(action: {
                logActiveSheet = .choosePlan
            }) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let plan = selectedPlan {
                            Text(plan.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            PillBadge(text: plan.planType.rawValue)
                        } else {
                            if plans.isEmpty {
                                Text("אין תוכניות זמינות")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("בחר תוכנית")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(minHeight: 72)
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func polishedExercisesCard(plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Full-width segmented control with padding
            if !plan.planType.workoutLabels.isEmpty {
                Picker("אימון", selection: $selectedLabel) {
                    ForEach(plan.planType.workoutLabels, id: \.self) { label in
                        Text(label).tag(label)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 8)
                
                // Info/actions row
                HStack {
                    PillBadge(text: "\(filteredExercises(for: plan).count) תרגילים", icon: "dumbbell")
                    
                    Spacer()
                    
                    ActionChip(title: "הצג הכל") {
                        showAllLabels.toggle()
                        hapticFeedback(.light)
                    }
                }
                .padding(.horizontal, 16)
                
                Divider()
                    .padding(.vertical, 4)
            }
            
            // Exercises using new ExerciseCard components
            let exercises = filteredExercises(for: plan)
            let _ = print("DEBUG: Filtered exercises count: \(exercises.count) for plan: \(plan.name)")
            let _ = print("DEBUG: Plan has \(plan.exercises.count) total exercises")
            let _ = print("DEBUG: Selected label: '\(selectedLabel)', showAllLabels: \(showAllLabels)")
            
            if exercises.isEmpty {
                EmptyStateView(
                    iconSystemName: "dumbbell",
                    title: "אין תרגילים בתוכנית זו",
                    message: "הוסף תרגילים מהספרייה או צור חדשים"
                )
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    ForEach(exercises, id: \.id) { exercise in
                        let _ = print("DEBUG: Rendering exercise: \(exercise.name)")
                        ExerciseCard(
                            exercise: exercise,
                            session: $session,
                            lastDefaults: lastDefaults[exercise.name],
                            weightUnit: appSettings.weightUnit,
                            weightStep: appSettings.weightUnit == .kg ? appSettings.weightIncrementKg : appSettings.weightIncrementLb,
                            onAddSet: {
                                addNewSet(for: exercise)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Bottom actions
            Divider()
                .padding(.vertical, 8)
            
            HStack(spacing: 8) {
                Button("בחר תרגילים") {
                    logActiveSheet = .chooseExercises
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("אוטופיל מהאימון האחרון") {
                    if let plan = selectedPlan {
                        Task { await smartAutofill(plan: plan) }
                    }
                    hapticFeedback(.medium)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func addNewSet(for exercise: Exercise) {
        print("DEBUG: Adding set for exercise: \(exercise.name)")
        
        // Ensure exercise session exists
        if !session.exerciseSessions.contains(where: { $0.exerciseName == exercise.name }) {
            let newExerciseSession = ExerciseSession(exerciseName: exercise.name, setLogs: [])
            session.exerciseSessions.append(newExerciseSession)
            print("DEBUG: Created new exercise session for \(exercise.name)")
        }
        
        guard let exerciseIdx = session.exerciseSessions.firstIndex(where: { $0.exerciseName == exercise.name }) else { 
            print("DEBUG: Failed to find exercise index for \(exercise.name)")
            return 
        }
        
        let newSet = SetLog(
            reps: lastDefaults[exercise.name]?.reps ?? exercise.plannedReps ?? 8,
            weight: lastDefaults[exercise.name]?.weight ?? 0,
            rpe: lastDefaults[exercise.name]?.rpe,
            restSeconds: 120,
            isWarmup: false
        )
        
        session.exerciseSessions[exerciseIdx].setLogs.append(newSet)
        print("DEBUG: Added set to \(exercise.name), now has \(session.exerciseSessions[exerciseIdx].setLogs.count) sets")
        hapticFeedback(.medium)
    }
    
    private func filteredExercises(for plan: WorkoutPlan) -> [Exercise] {
        plan.exercises.filter { ex in
            showAllLabels || selectedLabel.isEmpty ? true : ((ex.label ?? plan.planType.workoutLabels.first) == selectedLabel)
        }
    }
    
    private var polishedStickyFooter: some View {
        VStack(spacing: 8) {
            // Status bar
            HStack {
                Text("\(totalValidSets) סטים")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("·")
                    .foregroundStyle(.tertiary)
                
                Text("\(totalWorkoutVolume, specifier: "%.0f") \(appSettings.weightUnit.symbol)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if let plan = selectedPlan {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    
                    Text(selectedLabel.isEmpty ? plan.name : selectedLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Save button
            Button("שמור אימון") {
                if let plan = selectedPlan {
                    session.planName = plan.name
                    session.workoutLabel = selectedLabel.isEmpty ? plan.planType.workoutLabels.first : selectedLabel
                    session.isCompleted = true
                    session.notes = ""
                    modelContext.insert(session)
                    session = WorkoutSession()
                    lastDefaults = [:]
                    selectedLabel = ""
                    hapticFeedback(.success)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .disabled(totalValidSets == 0)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
    }
    
    private var totalWorkoutVolume: Double {
        session.exerciseSessions.flatMap { $0.setLogs }.reduce(0.0) { total, set in
            total + (Double(set.reps) * set.weight)
        }
    }
    
    private var totalValidSets: Int {
        session.exerciseSessions.flatMap { $0.setLogs }.filter { $0.reps > 0 && $0.weight >= 0 }.count
    }
    
    private func hapticFeedback(_ style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
    }
}

struct PlanSelectionSheet: View {
    let plans: [WorkoutPlan]
    @Binding var selectedPlan: WorkoutPlan?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(plans.sorted(by: { $0.name < $1.name })) { plan in
                    Button(action: {
                        selectedPlan = plan
                        onDismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(plan.planType.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedPlan?.id == plan.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("בחר תוכנית")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { onDismiss() }
                }
            }
        }
    }
}
