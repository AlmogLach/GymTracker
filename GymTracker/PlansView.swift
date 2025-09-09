//
//  PlansView.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

struct PlansView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    @State private var isPresentingNew = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s16) {
                    if plans.isEmpty {
                        EmptyStateView(
                            iconSystemName: "list.bullet.rectangle",
                            title: "אין תוכניות",
                            buttonTitle: "תוכנית חדשה"
                        ) {
                            isPresentingNew = true
                        }
                        .appCard()
                    } else {
                        ForEach(plans.sorted(by: { $0.name < $1.name })) { plan in
                            NavigationLink(destination: PlanDetailView(plan: plan)) {
                                PlanCard(
                                    name: plan.name,
                                    type: plan.planType,
                                    exerciseCount: plan.exercises.count,
                                    daysCount: plan.schedule.count
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.top, AppTheme.s16)
                .padding(.bottom, 100) // Space for safeAreaInset
            }
            .background(AppTheme.screenBG)
            .navigationTitle("תוכניות")
            .sheet(isPresented: $isPresentingNew) {
                NewPlanSheet()
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "תוכנית חדשה") {
                    isPresentingNew = true
                }
                .padding(.horizontal, AppTheme.s16)
                .padding(.bottom, AppTheme.s16)
                .background(AppTheme.screenBG)
            }
        }
    }
}

struct PlanCard: View {
    let name: String
    let type: PlanType
    let exerciseCount: Int
    let daysCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            HStack {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                PillBadge(text: type.rawValue)
            }
            
            HStack {
                PillBadge(text: "\(exerciseCount) תרגילים", icon: "dumbbell")
                
                Spacer()
                
                if daysCount > 0 {
                    PillBadge(text: "\(daysCount) ימים", icon: "calendar")
                }
            }
        }
        .appCard()
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
            planInfoSection
            exercisesSection
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
    
    private var planInfoSection: some View {
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
    }
    
    private var exercisesSection: some View {
        Section("תרגילים") {
            if !plan.planType.workoutLabels.isEmpty {
                workoutLabelPicker
            }
            
            exercisesList
            
            addExerciseForm
        }
    }
    
    private var workoutLabelPicker: some View {
        Picker("אימון", selection: $currentLabelTab) {
            ForEach(plan.planType.workoutLabels, id: \.self) { label in
                Text(label).tag(label)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var exercisesList: some View {
        let displayedExercises = plan.exercises.filter { ex in
            currentLabelTab.isEmpty ? true : ((ex.label ?? plan.planType.workoutLabels.first) == currentLabelTab)
        }
        
        return ForEach(displayedExercises, id: \.id) { exercise in
            ExerciseRowView(exercise: exercise)
        }
        .onDelete { offsets in
            plan.exercises.remove(atOffsets: offsets)
        }
    }
    
    private var addExerciseForm: some View {
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

    private func weekdayName(_ day: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = max(1, min(7, day)) - 1
        return symbols[index]
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
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
                if exercise.isBodyweight ?? false { Text("משקל גוף").font(.footnote).foregroundStyle(.secondary) }
            }
            if let n = exercise.notes, !n.isEmpty { Text(n).font(.footnote).foregroundStyle(.secondary) }
        }
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
