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
    @State private var showAddedToast: Bool = false
    @State private var addedToastCount: Int = 0

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
                        HStack(spacing: 6) {
                            if let mg = exercise.muscleGroup { Text(mg).font(.footnote).foregroundStyle(.secondary) }
                            if let eq = exercise.equipment { Text(eq).font(.footnote).foregroundStyle(.secondary) }
                            if exercise.isBodyweight { Text("משקל גוף").font(.footnote).foregroundStyle(.secondary) }
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
                ExercisePickerSheet(onAdd: { items in
                    var addedCount = 0
                    for item in items {
                        let label = currentLabelTab.isEmpty ? plan.planType.workoutLabels.first : currentLabelTab
                        if !plan.exercises.contains(where: { $0.name.caseInsensitiveCompare(item.name) == .orderedSame && ($0.label ?? label) == label }) {
                            plan.exercises.append(Exercise(name: item.name, plannedSets: 3, plannedReps: 8, notes: nil, label: label, muscleGroup: item.bodyPart.rawValue, equipment: item.equipment, isBodyweight: item.isBodyweight))
                            addedCount += 1
                        }
                    }
                    activeSheet = nil
                    if addedCount > 0 { addedToastCount = addedCount; showAddedToast = true }
                })
            case .quickLibrary:
                ExercisePickerSheet(onAdd: { items in
                    var addedCount = 0
                    for item in items {
                        let label = currentLabelTab.isEmpty ? plan.planType.workoutLabels.first : currentLabelTab
                        if !plan.exercises.contains(where: { $0.name.caseInsensitiveCompare(item.name) == .orderedSame && ($0.label ?? label) == label }) {
                            plan.exercises.append(Exercise(name: item.name, plannedSets: 3, plannedReps: 8, notes: nil, label: label, muscleGroup: item.bodyPart.rawValue, equipment: item.equipment, isBodyweight: item.isBodyweight))
                            addedCount += 1
                        }
                    }
                    activeSheet = nil
                    if addedCount > 0 { addedToastCount = addedCount; showAddedToast = true }
                })
            }
        }
        .alert("הוספה", isPresented: $showAddedToast) {
            Button("סגור", role: .cancel) {}
        } message: {
            Text("נוספו \(addedToastCount) תרגילים")
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

// MARK: - Exercise Picker Sheet with filters and multi-select
struct ExercisePickerSheet: View {
    @State private var searchText: String = ""
    @State private var selectedBodyPart: ExerciseLibraryItem.BodyPart? = nil
    @State private var selectedEquipment: String? = nil
    @State private var favoritesOnly: Bool = false
    @State private var selection: Set<UUID> = []
    @AppStorage("favoriteExercises") private var favoriteNamesStore: String = ""
    @State private var showCreate: Bool = false

    var onAdd: ([ExerciseLibraryItem]) -> Void

    private var favoriteNames: Set<String> { Set(favoriteNamesStore.split(separator: "\n").map(String.init)) }

    private var equipments: [String] {
        let eqs = ExerciseLibrary.exercises.compactMap { $0.equipment }
        return Array(Set(eqs)).sorted()
    }

    private var filtered: [ExerciseLibraryItem] {
        ExerciseLibrary.exercises.filter { item in
            let matchBody = selectedBodyPart == nil || item.bodyPart == selectedBodyPart
            let matchEq = selectedEquipment == nil || item.equipment == selectedEquipment
            let matchFav = favoritesOnly == false || favoriteNames.contains(item.name)
            let matchSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
            return matchBody && matchEq && matchFav && matchSearch
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if !equipments.isEmpty || !ExerciseLibraryItem.BodyPart.allCases.isEmpty {
                    Section("פילטרים") {
                        Picker("קבוצת שריר", selection: Binding(get: { selectedBodyPart ?? .fullBody }, set: { selectedBodyPart = ($0 == .fullBody ? nil : $0) })) {
                            Text("הכל").tag(ExerciseLibraryItem.BodyPart.fullBody)
                            ForEach(ExerciseLibraryItem.BodyPart.allCases.filter { $0 != .fullBody }, id: \.self) { bp in
                                Text(bp.rawValue).tag(bp)
                            }
                        }
                        Picker("ציוד", selection: Binding(get: { selectedEquipment ?? "" }, set: { selectedEquipment = $0.isEmpty ? nil : $0 })) {
                            Text("הכל").tag("")
                            ForEach(equipments, id: \.self) { eq in Text(eq).tag(eq) }
                        }
                        Toggle("מועדפים", isOn: $favoritesOnly)
                    }
                }

                Section("תרגילים") {
                    ForEach(filtered) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                HStack(spacing: 6) {
                                    Text(item.bodyPart.rawValue).font(.footnote).foregroundStyle(.secondary)
                                    if let eq = item.equipment { Text(eq).font(.footnote).foregroundStyle(.secondary) }
                                    if item.isBodyweight { Text("משקל גוף").font(.footnote).foregroundStyle(.secondary) }
                                }
                            }
                            Spacer()
                            Button("הוסף") {
                                onAdd([item])
                            }
                            .buttonStyle(.bordered)
                            .tint(.accentColor)
                            Button(action: {
                                toggleFavorite(name: item.name)
                            }) {
                                Image(systemName: favoriteNames.contains(item.name) ? "star.fill" : "star")
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleSelect(id: item.id)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("בחר תרגילים")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("הוסף נבחרים") {
                        let picked = filtered.filter { selection.contains($0.id) }
                        if !picked.isEmpty { onAdd(picked) }
                    }
                    .disabled(selection.isEmpty)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("הוסף תרגיל חדש") { showCreate = true }
                }
            }
            .sheet(isPresented: $showCreate) {
                NewExerciseQuickView { newItem in
                    onAdd([newItem])
                }
            }
        }
    }

    private func toggleSelect(id: UUID) { if selection.contains(id) { selection.remove(id) } else { selection.insert(id) } }
    private func toggleFavorite(name: String) {
        var set = favoriteNames
        if set.contains(name) { set.remove(name) } else { set.insert(name) }
        favoriteNamesStore = set.sorted().joined(separator: "\n")
    }
}

// Quick create custom exercise
struct NewExerciseQuickView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var bodyPart: ExerciseLibraryItem.BodyPart = .fullBody
    @State private var equipment: String = ""
    @State private var isBodyweight: Bool = false
    var onCreate: (ExerciseLibraryItem) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("שם התרגיל", text: $name)
                Picker("קבוצת שריר", selection: $bodyPart) {
                    ForEach(ExerciseLibraryItem.BodyPart.allCases, id: \.self) { bp in
                        Text(bp.rawValue).tag(bp)
                    }
                }
                TextField("ציוד (אופציונלי)", text: $equipment)
                Toggle("משקל גוף", isOn: $isBodyweight)
            }
            .navigationTitle("תרגיל חדש")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("ביטול") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("הוסף") {
                        let item = ExerciseLibraryItem(name: name, bodyPart: bodyPart, equipment: equipment.isEmpty ? nil : equipment, isBodyweight: isBodyweight)
                        onCreate(item)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
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
    @State private var showAllLabels: Bool = false
    @State private var logActiveSheet: LogSheet?
    @State private var addedToastCount: Int = 0
    @State private var showAddedToast: Bool = false

    private enum LogSheet: String, Identifiable { case chooseExercises; var id: String { rawValue } }

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
                        Toggle("הצג הכל", isOn: $showAllLabels)
                    }
                    Section("אימון") {
                        let exercises = plan.exercises.filter { ex in
                            showAllLabels || selectedLabel.isEmpty ? true : ((ex.label ?? plan.planType.workoutLabels.first) == selectedLabel)
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
                    Button("בחר תרגילים") { logActiveSheet = .chooseExercises }
                    Button("אוטופיל מהאימון האחרון") { Task { await autofillFromLast(plan: plan) } }
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

    private func autofillFromLast(plan: WorkoutPlan) async {
        let targetName: String? = plan.name
        let targetLabel: String? = selectedLabel.isEmpty ? plan.planType.workoutLabels.first : selectedLabel
        var descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.planName == targetName && $0.workoutLabel == targetLabel }, sortBy: [SortDescriptor(\WorkoutSession.date, order: .reverse)])
        descriptor.fetchLimit = 1
        if let last = try? modelContext.fetch(descriptor).first {
            session.exerciseSessions = last.exerciseSessions.map { old in
                ExerciseSession(exerciseName: old.exerciseName, setLogs: old.setLogs.map { SetLog(reps: $0.reps, weight: $0.weight, rpe: $0.rpe, notes: $0.notes) })
            }
        } else {
            let exercises = plan.exercises.filter { ex in selectedLabel.isEmpty ? true : ((ex.label ?? plan.planType.workoutLabels.first) == selectedLabel) }
            session.exerciseSessions = exercises.map { ExerciseSession(exerciseName: $0.name, setLogs: []) }
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
