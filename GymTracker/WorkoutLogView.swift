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

    private enum LogSheet: String, Identifiable { case chooseExercises; var id: String { rawValue } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s16) {
                    planSelectionCard
                    
                    if selectedPlan == nil {
                        EmptyStateView(
                            iconSystemName: "dumbbell",
                            title: "בחר תוכנית כדי להתחיל לוג"
                        )
                        .appCard()
                    } else if let plan = selectedPlan {
                        exercisesCard(plan: plan)
                        actionsCard(plan: plan)
                    }
                }
                .padding(.top, AppTheme.s16)
                .padding(.bottom, 100) // Space for sticky footer
            }
            .background(AppTheme.screenBG)
            .navigationTitle("לוג אימון")
            .onChange(of: selectedPlan) { _, newValue in
                Task { await loadLastDefaults(for: newValue) }
            }
            .onChange(of: selectedLabel) { _, _ in
                Task { await loadLastDefaults(for: selectedPlan) }
            }
            .sheet(item: $logActiveSheet) { _ in
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
            }
            .alert("הוספה", isPresented: $showAddedToast) {
                Button("סגור", role: .cancel) {}
            } message: {
                Text("נוספו \(addedToastCount) תרגילים ללוג")
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "שמור אימון") {
                    if let plan = selectedPlan {
                        session.planName = plan.name
                        session.workoutLabel = selectedLabel.isEmpty ? plan.planType.workoutLabels.first : selectedLabel
                        modelContext.insert(session)
                        session = WorkoutSession()
                        lastDefaults = [:]
                        selectedLabel = ""
                    }
                }
                .disabled(session.exerciseSessions.isEmpty)
                .padding(.horizontal, AppTheme.s16)
                .padding(.bottom, AppTheme.s16)
                .background(AppTheme.screenBG)
            }
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
    
    private var planSelectionCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            Text("בחר תוכנית")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Button(action: {
                // TODO: Open plan selection sheet
            }) {
                HStack {
                    if let plan = selectedPlan {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(plan.planType.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("בחר תוכנית")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 56)
        }
        .appCard()
    }
    
    private func exercisesCard(plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            if !plan.planType.workoutLabels.isEmpty {
                Picker("אימון", selection: $selectedLabel) {
                    ForEach(plan.planType.workoutLabels, id: \.self) { label in
                        Text(label).tag(label)
                    }
                }
                .pickerStyle(.segmented)
                .padding(8)
                
                HStack {
                    PillBadge(text: "\(plan.exercises.count) תרגילים", icon: "dumbbell")
                    Spacer()
                    Button("הצג הכל") {
                        showAllLabels.toggle()
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
                }
            }
            
            let exercises = plan.exercises.filter { ex in
                showAllLabels || selectedLabel.isEmpty ? true : ((ex.label ?? plan.planType.workoutLabels.first) == selectedLabel)
            }
            
            if exercises.isEmpty {
                Text("אין תרגילים בתוכנית זו")
                    .foregroundStyle(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppTheme.s16)
            } else {
                ForEach(exercises, id: \.id) { exercise in
                    ExerciseLogRow(
                        exerciseName: exercise.name,
                        session: $session,
                        defaultReps: lastDefaults[exercise.name]?.reps,
                        defaultWeight: lastDefaults[exercise.name]?.weight,
                        defaultRPE: lastDefaults[exercise.name]?.rpe
                    )
                }
            }
        }
        .appCard()
    }
    
    private func actionsCard(plan: WorkoutPlan) -> some View {
        HStack(spacing: AppTheme.s8) {
            Button("בחר תרגילים") { logActiveSheet = .chooseExercises }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            
            Button("אוטופיל מהאימון האחרון") { Task { await smartAutofill(plan: plan) } }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
        }
        .appCard()
    }
}

struct ExerciseLogRow: View {
    let exerciseName: String
    @Binding var session: WorkoutSession
    @Query private var settingsList: [AppSettings]
    var defaultReps: Int?
    var defaultWeight: Double?
    var defaultRPE: Double?
    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var rpe: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            exerciseHeader
            exerciseInputRow
            
            if let idx = session.exerciseSessions.firstIndex(where: { $0.exerciseName == exerciseName }) {
                setsList(for: idx)
            }
        }
        .onAppear {
            if let d = defaultReps, reps.isEmpty { reps = String(d) }
            if let d = defaultWeight, weight.isEmpty { weight = String(displayWeight(d)) }
            if let d = defaultRPE, rpe.isEmpty { rpe = String(format: "%.1f", d) }
        }
    }
    
    private var exerciseHeader: some View {
        Text(exerciseName).font(.headline)
    }
    
    private var exerciseInputRow: some View {
        HStack(spacing: 8) {
            TextField("חזרות", text: $reps).keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 70)
            TextField("משקל (\(unit.symbol))", text: $weight).keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 120)
            TextField("RPE", text: $rpe).keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 80)
            Button {
                addSet()
            } label: { Label("הוסף", systemImage: "plus.circle.fill") }
            .disabled(Int(reps) == nil || Double(weight) == nil)
        }
        .padding(.bottom, 4)
    }
    
    private func setsList(for exerciseIdx: Int) -> some View {
        let sets = session.exerciseSessions[exerciseIdx].setLogs
        if sets.isEmpty {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(sets.enumerated()), id: \.offset) { entry in
                    SetRowView(
                        setIndex: entry.offset,
                        exerciseIdx: exerciseIdx,
                        session: $session,
                        unit: unit,
                        displayWeight: displayWeight,
                        weightStep: weightStep,
                        adjustWeight: adjustWeight
                    )
                }
                HStack(spacing: 12) {
                    Button { duplicateLastSet(at: exerciseIdx) } label: { Label("שכפל אחרון", systemImage: "doc.on.doc") }
                    Button(role: .destructive) { clearAllSets(at: exerciseIdx) } label: { Label("נקה הכל", systemImage: "trash") }
                }
                .padding(.top, 4)
            }
        )
    }

    private func addSet() {
        let newSet = SetLog(reps: Int(reps) ?? 0, weight: inputWeightKg(), rpe: Double(rpe))
        if let idx = session.exerciseSessions.firstIndex(where: { $0.exerciseName == exerciseName }) {
            session.exerciseSessions[idx].setLogs.append(newSet)
        } else {
            let exSession = ExerciseSession(exerciseName: exerciseName, setLogs: [newSet])
            session.exerciseSessions.append(exSession)
        }
        reps = ""; weight = ""; rpe = ""
    }

    private var unit: AppSettings.WeightUnit { settingsList.first?.weightUnit ?? .kg }
    private func displayWeight(_ kg: Double) -> Double { unit.toDisplay(fromKg: kg) }
    private func inputWeightKg() -> Double { unit.toKg(fromDisplay: Double(weight) ?? 0) }
    private var weightStep: Double { unit == .kg ? 2.5 : 5.0 }

    private func duplicateLastSet(at exerciseIdx: Int) {
        guard let last = session.exerciseSessions[exerciseIdx].setLogs.last else { return }
        session.exerciseSessions[exerciseIdx].setLogs.append(SetLog(reps: last.reps, weight: last.weight, rpe: last.rpe, notes: last.notes, restSeconds: last.restSeconds, isWarmup: last.isWarmup))
    }

    private func clearAllSets(at exerciseIdx: Int) {
        session.exerciseSessions[exerciseIdx].setLogs.removeAll()
    }

    private func adjustWeight(_ exerciseIdx: Int, _ setIndex: Int, delta: Double) {
        let unit = self.unit
        let currentKg = session.exerciseSessions[exerciseIdx].setLogs[setIndex].weight
        let newDisplay = unit.toDisplay(fromKg: currentKg) + delta
        let newKg = unit.toKg(fromDisplay: newDisplay)
        session.exerciseSessions[exerciseIdx].setLogs[setIndex].weight = max(0, newKg)
    }
}

struct SetRowView: View {
    let setIndex: Int
    let exerciseIdx: Int
    @Binding var session: WorkoutSession
    let unit: AppSettings.WeightUnit
    let displayWeight: (Double) -> Double
    let weightStep: Double
    let adjustWeight: (Int, Int, Double) -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Text("סט \(setIndex + 1)")
                .frame(width: 44, alignment: .leading)
            
            repsStepper
            
            weightControls
            
            rpeStepper
            
            warmupToggle
            
            deleteButton
        }
    }
    
    private var repsStepper: some View {
        let repsBinding = Binding<Int>(
            get: { session.exerciseSessions[exerciseIdx].setLogs[setIndex].reps },
            set: { session.exerciseSessions[exerciseIdx].setLogs[setIndex].reps = $0 }
        )
        
        return Stepper(value: repsBinding, in: 1...100) {
            Text("חזרות: \(session.exerciseSessions[exerciseIdx].setLogs[setIndex].reps)")
        }
        .frame(maxWidth: 170, alignment: .leading)
    }
    
    private var weightControls: some View {
        let displayW = Int(displayWeight(session.exerciseSessions[exerciseIdx].setLogs[setIndex].weight))
        
        return HStack(spacing: 6) {
            Text("משקל: \(displayW) \(unit.symbol)")
            Button { adjustWeight(exerciseIdx, setIndex, -weightStep) } label: { Image(systemName: "minus.circle") }
            Button { adjustWeight(exerciseIdx, setIndex, weightStep) } label: { Image(systemName: "plus.circle") }
        }
        .frame(maxWidth: 220, alignment: .leading)
    }
    
    private var rpeStepper: some View {
        let rpeHalfSteps = Binding<Int>(
            get: { Int(((session.exerciseSessions[exerciseIdx].setLogs[setIndex].rpe ?? 0) * 2).rounded()) },
            set: { session.exerciseSessions[exerciseIdx].setLogs[setIndex].rpe = Double($0) / 2.0 }
        )
        
        return Stepper(value: rpeHalfSteps, in: 0...20) {
            Text("RPE: \(String(format: "%.1f", session.exerciseSessions[exerciseIdx].setLogs[setIndex].rpe ?? 0))")
        }
    }
    
    private var warmupToggle: some View {
        Toggle("חימום", isOn: Binding(
            get: { session.exerciseSessions[exerciseIdx].setLogs[setIndex].isWarmup ?? false },
            set: { session.exerciseSessions[exerciseIdx].setLogs[setIndex].isWarmup = $0 }
        ))
        .toggleStyle(.switch)
        .frame(maxWidth: 100)
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            session.exerciseSessions[exerciseIdx].setLogs.remove(at: setIndex)
        } label: { Image(systemName: "trash") }
    }
}
