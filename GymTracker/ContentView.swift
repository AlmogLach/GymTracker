//
//  ContentView.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("לוח", systemImage: "speedometer") }

            PlansView()
                .tabItem { Label("תוכניות", systemImage: "list.bullet.rectangle") }

            WorkoutLogView()
                .tabItem { Label("לוג", systemImage: "dumbbell") }

            ProgressViewScreen()
                .tabItem { Label("סטטיסטיקות", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("הגדרות", systemImage: "gearshape") }
        }
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    @Query private var settingsList: [AppSettings]

    var body: some View {
        NavigationStack {
            List {
                Section("האימון הבא") {
                    if let next = plans.sorted(by: { $0.name < $1.name }).first {
                        Text(next.name)
                    } else {
                        Text("אין תוכניות עדיין")
                    }
                }
                Section("האימון האחרון") {
                    if let last = sessions.first {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(last.planName ?? "ללא תוכנית").font(.headline)
                            Text(last.date, style: .date)
                            Text("ווליום: \(Int(displayVolume(for: last))) \(unit.symbol)")
                        }
                    } else {
                        Text("אין נתונים")
                    }
                }
            }
            .navigationTitle("Dashboard")
        }
    }

    private var unit: AppSettings.WeightUnit { settingsList.first?.weightUnit ?? .kg }
    private func totalVolumeKg(for session: WorkoutSession) -> Double {
        session.exerciseSessions.flatMap { $0.setLogs }.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
    }
    private func displayVolume(for session: WorkoutSession) -> Double {
        unit.toDisplay(fromKg: totalVolumeKg(for: session))
    }
}

struct PlansView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]

    @State private var isPresentingNew = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(plans.sorted(by: { $0.name < $1.name })) { plan in
                    NavigationLink(plan.name) {
                        PlanDetailView(plan: plan)
                    }
                }
                .onDelete(perform: deletePlans)
            }
            .navigationTitle("תוכניות")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingNew = true
                    } label: { Label("הוסף", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $isPresentingNew) {
                PlanEditView()
            }
        }
    }

    private func deletePlans(offsets: IndexSet) {
        for index in offsets { modelContext.delete(plans.sorted(by: { $0.name < $1.name })[index]) }
    }
}

struct PlanDetailView: View {
    @Bindable var plan: WorkoutPlan
    @State private var newExerciseName: String = ""
    @State private var plannedSets: Int = 3
    @State private var plannedReps: Int = 8
    @State private var notes: String = ""
    @State private var selectedLabel: String = ""
    @State private var searchText = ""
    @State private var currentLabelTab: String = ""
    @State private var activeSheet: ActiveSheet?

    private enum ActiveSheet: String, Identifiable { case chooseLibrary, quickLibrary; var id: String { rawValue } }

    var body: some View {
        Form {
            Section("שם תוכנית") {
                TextField("שם", text: $plan.name)
                HStack {
                    Text("סוג:")
                    Text(plan.planType.rawValue)
                }
                if !plan.schedule.isEmpty {
                    VStack(alignment: .leading) {
                        Text("לו" + "" + "ז:")
                        ForEach(plan.schedule.sorted(by: { $0.weekday < $1.weekday }), id: \.self) { d in
                            Text("\(weekdayName(d.weekday)) – \(d.label)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("תרגילים") {
                if !plan.planType.workoutLabels.isEmpty {
                    Picker("אימון", selection: $currentLabelTab) {
                        ForEach(plan.planType.workoutLabels, id: \.self) { label in
                            Text(label).tag(label)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                let displayedExercises = plan.exercises.filter { ex in
                    currentLabelTab.isEmpty ? true : ((ex.label ?? plan.planType.workoutLabels.first) == currentLabelTab)
                }
                ForEach(displayedExercises) { exercise in
                    VStack(alignment: .leading) {
                        Text(exercise.name).font(.headline)
                        HStack {
                            Text("סטים: \(exercise.plannedSets)")
                            if let reps = exercise.plannedReps { Text("חזרות: \(reps)") }
                            if let lbl = exercise.label, !lbl.isEmpty { Text("(\(lbl))") }
                        }
                        if let n = exercise.notes, !n.isEmpty { Text(n).font(.footnote).foregroundStyle(.secondary) }
                    }
                }
                .onDelete { offsets in
                    plan.exercises.remove(atOffsets: offsets)
                }

                VStack(alignment: .leading) {
                    HStack {
                        TextField("שם התרגיל", text: $newExerciseName)
                        Button {
                            activeSheet = .chooseLibrary
                        } label: { Label("בחר", systemImage: "text.magnifyingglass") }
                    }
                    if !currentLabelTab.isEmpty {
                        Button {
                            activeSheet = .quickLibrary
                        } label: { Label("הוסף מתרגילים מוכרים ל-\(currentLabelTab)", systemImage: "plus.circle") }
                    }
                    Stepper("סטים: \(plannedSets)", value: $plannedSets, in: 1...10)
                    Stepper("חזרות: \(plannedReps)", value: $plannedReps, in: 1...20)
                    TextField("הערות", text: $notes)
                    Button("הוסף תרגיל") {
                        let ex = Exercise(name: newExerciseName, plannedSets: plannedSets, plannedReps: plannedReps, notes: notes.isEmpty ? nil : notes, label: currentLabelTab.isEmpty ? plan.planType.workoutLabels.first : currentLabelTab)
                        plan.exercises.append(ex)
                        newExerciseName = ""; plannedSets = 3; plannedReps = 8; notes = ""
                    }
                    .disabled(newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle(plan.name)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .chooseLibrary:
                ExercisePickerView(searchText: $searchText) { item in
                    newExerciseName = item.name
                    activeSheet = nil
                }
            case .quickLibrary:
                ExercisePickerView(searchText: $searchText) { item in
                    let ex = Exercise(name: item.name, plannedSets: 3, plannedReps: 8, notes: nil, label: currentLabelTab.isEmpty ? plan.planType.workoutLabels.first : currentLabelTab)
                    plan.exercises.append(ex)
                    activeSheet = nil
                }
            }
        }
        .onAppear {
            if currentLabelTab.isEmpty { currentLabelTab = plan.planType.workoutLabels.first ?? "" }
        }
    }

    private func weekdayName(_ day: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = max(1, min(7, day)) - 1
        return symbols[index]
    }
}

struct ExercisePickerView: View {
    @Binding var searchText: String
    var onPick: (ExerciseLibraryItem) -> Void

    private var filtered: [ExerciseLibraryItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return ExerciseLibrary.exercises }
        return ExerciseLibrary.exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.bodyPart.rawValue.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { item in
                    Button {
                        onPick(item)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                Text(item.bodyPart.rawValue)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let eq = item.equipment { Text(eq).font(.footnote).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("בחר תרגיל")
        }
    }
}

struct PlanEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name: String = ""
    @State private var planType: PlanType = .fullBody
    @State private var schedule: Set<Int> = []
    @State private var labelForDay: [Int: String] = [:]

    var body: some View {
        NavigationStack {
            Form {
                TextField("שם התוכנית", text: $name)
                Picker("סוג תוכנית", selection: $planType) {
                    ForEach(PlanType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                Section("ימים בשבוע") {
                    ForEach(1...7, id: \.self) { day in
                        Toggle(weekdayName(day), isOn: Binding(
                            get: { schedule.contains(day) },
                            set: { isOn in
                                if isOn {
                                    schedule.insert(day)
                                    if labelForDay[day] == nil { labelForDay[day] = planType.workoutLabels.first }
                                } else {
                                    schedule.remove(day)
                                    labelForDay.removeValue(forKey: day)
                                }
                            }
                        ))
                        if schedule.contains(day) {
                            Picker("אימון", selection: Binding(get: { labelForDay[day] ?? planType.workoutLabels.first ?? "" }, set: { labelForDay[day] = $0 })) {
                                ForEach(planType.workoutLabels, id: \.self) { label in
                                    Text(label).tag(label)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("תוכנית חדשה")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("ביטול") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") {
                        let days = schedule.sorted().map { day in PlannedDay(weekday: day, label: labelForDay[day] ?? planType.workoutLabels.first ?? "") }
                        let plan = WorkoutPlan(name: name, planType: planType, schedule: days)
                        modelContext.insert(plan)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func weekdayName(_ day: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = max(1, min(7, day)) - 1
        return symbols[index]
    }
}

struct WorkoutLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    @State private var selectedPlan: WorkoutPlan?
    @State private var session = WorkoutSession()
    @State private var lastDefaults: [String: (reps: Int, weight: Double, rpe: Double?)] = [:]
    @State private var selectedLabel: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("בחר תוכנית", selection: $selectedPlan) {
                    ForEach(plans.sorted(by: { $0.name < $1.name })) { plan in
                        Text(plan.name).tag(Optional(plan))
                    }
                }

                if let plan = selectedPlan {
                    if !plan.planType.workoutLabels.isEmpty {
                        Picker("אימון", selection: $selectedLabel) {
                            ForEach(plan.planType.workoutLabels, id: \.self) { label in
                                Text(label).tag(label)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("אימון") {
                        let exercises = plan.exercises.filter { ex in
                            selectedLabel.isEmpty ? true : ((ex.label ?? plan.planType.workoutLabels.first) == selectedLabel)
                        }
                        ForEach(exercises) { exercise in
                            ExerciseLogRow(
                                exerciseName: exercise.name,
                                session: $session,
                                defaultReps: lastDefaults[exercise.name]?.reps,
                                defaultWeight: lastDefaults[exercise.name]?.weight,
                                defaultRPE: lastDefaults[exercise.name]?.rpe
                            )
                        }
                    }
                    Button("שמור אימון") {
                        session.planName = plan.name
                        session.workoutLabel = selectedLabel.isEmpty ? plan.planType.workoutLabels.first : selectedLabel
                        modelContext.insert(session)
                        session = WorkoutSession()
                        lastDefaults = [:]
                        selectedLabel = ""
                    }
                } else {
                    Text("בחר תוכנית כדי להתחיל")
                }
            }
            .navigationTitle("לוג אימון")
            .onChange(of: selectedPlan) { _, newValue in
                Task { await loadLastDefaults(for: newValue) }
            }
            .onChange(of: selectedLabel) { _, _ in
                Task { await loadLastDefaults(for: selectedPlan) }
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
            Text(exerciseName).font(.headline)
            HStack {
                TextField("חזרות", text: $reps).keyboardType(.numberPad)
                TextField("משקל (\(unit.symbol))", text: $weight).keyboardType(.decimalPad)
                TextField("RPE", text: $rpe).keyboardType(.decimalPad)
                Button("הוסף") { addSet() }
                    .disabled(Int(reps) == nil || Double(weight) == nil)
            }
            if let idx = session.exerciseSessions.firstIndex(where: { $0.exerciseName == exerciseName }) {
                let sets = session.exerciseSessions[idx].setLogs
                if !sets.isEmpty {
                    ForEach(Array(sets.enumerated()), id: \.offset) { entry in
                        let set = entry.element
                        Text("סט \(entry.offset + 1): \(set.reps)x\(Int(displayWeight(set.weight))) \(unit.symbol)" + (set.rpe != nil ? " RPE \(String(format: "%.1f", set.rpe!))" : ""))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            if let d = defaultReps, reps.isEmpty { reps = String(d) }
            if let d = defaultWeight, weight.isEmpty { weight = String(displayWeight(d)) }
            if let d = defaultRPE, rpe.isEmpty { rpe = String(format: "%.1f", d) }
        }
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
}

struct ProgressViewScreen: View {
    @Query private var settingsList: [AppSettings]
    var unit: AppSettings.WeightUnit { settingsList.first?.weightUnit ?? .kg }

    var body: some View {
        NavigationStack {
            Text("גרפים וסטטיסטיקות - בשלב הבא (\(unit.symbol))")
                .navigationTitle("סטטיסטיקות")
        }
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]

    var settings: AppSettings {
        if let s = settingsList.first { return s }
        let s = AppSettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("יחידות משקל", selection: Binding(get: { settings.weightUnit }, set: { settings.weightUnit = $0 })) {
                    ForEach(AppSettings.WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                }
            }
            .navigationTitle("הגדרות")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}
