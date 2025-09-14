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
                VStack(spacing: 16) {
                    if plans.isEmpty {
                        EmptyStateView(
                            iconSystemName: "list.bullet.rectangle",
                            title: "אין תוכניות אימון",
                            message: "צור תוכנית אימון ראשונה כדי להתחיל",
                            buttonTitle: "צור תוכנית חדשה"
                        ) {
                            isPresentingNew = true
                        }
                        .padding(32)
                    } else {
                        // Plans grid
                        LazyVStack(spacing: 12) {
                            ForEach(plans.sorted(by: { $0.name < $1.name })) { plan in
                                NavigationLink(destination: PlanDetailView(plan: plan)) {
                                    ModernPlanCard(plan: plan)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(16)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("תוכניות")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresentingNew = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $isPresentingNew) {
                NewPlanSheet()
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    
                    Button(action: { isPresentingNew = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("תוכנית חדשה")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue)
                        .cornerRadius(16)
                    }
                    .padding(20)
                }
                .background(.regularMaterial)
            }
        }
    }
}

struct ModernPlanCard: View {
    let plan: WorkoutPlan
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Text(plan.planType.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                }
                
                // Stats chips
                HStack(spacing: 8) {
                    StatChip(
                        value: "\(plan.exercises.count)",
                        label: "תרגילים",
                        icon: "list.bullet",
                        color: .green
                    )
                    
                    if plan.schedule.count > 0 {
                        StatChip(
                            value: "\(plan.schedule.count)",
                            label: "ימים",
                            icon: "calendar",
                            color: .orange
                        )
                    }
                    
                    Spacer()
                    
                    // Arrow indicator
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .background(.white.opacity(0.5))
            
            Divider()
            
            // Schedule preview (if available)
            if !plan.schedule.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("לוח זמנים")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 6) {
                        ForEach(plan.schedule.sorted(by: { $0.weekday < $1.weekday }), id: \.weekday) { day in
                            DayChip(day: day, isSelected: false)
                        }
                        
                        Spacer()
                    }
                }
                .padding(20)
            }
        }
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct StatChip: View {
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

struct PlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
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
    @State private var editingExercise: Exercise?
    @State private var showDeleteConfirmation = false

    private enum ActiveSheet: String, Identifiable { 
        case chooseLibrary, quickLibrary
        var id: String { rawValue } 
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    modernPlanInfoCard
                    modernExercisesCard
                }
                .padding(16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(plan.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("מחק תוכנית", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("הוסף תרגיל") {
                        activeSheet = .chooseLibrary
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("מחיקת תוכנית", isPresented: $showDeleteConfirmation) {
                Button("מחק תוכנית", role: .destructive) {
                    modelContext.delete(plan)
                    dismiss()
                }
                Button("ביטול", role: .cancel) {}
            } message: {
                Text("האם אתה בטוח שברצונך למחוק את התוכנית '\(plan.name)'? פעולה זו לא ניתנת לביטול.")
            }
        }
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
        .sheet(item: Binding<Exercise?>(
            get: { editingExercise },
            set: { editingExercise = $0 }
        )) { exercise in
            ExerciseEditSheet(
                exercise: exercise,
                onSave: { updatedExercise in
                    if let index = plan.exercises.firstIndex(where: { $0.id == updatedExercise.id }) {
                        plan.exercises[index] = updatedExercise
                    }
                    editingExercise = nil
                },
                onCancel: {
                    editingExercise = nil
                }
            )
        }
        .onAppear {
            if currentLabelTab.isEmpty { currentLabelTab = plan.planType.workoutLabels.first ?? "" }
        }
    }
    
    private var modernPlanInfoCard: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("פרטי התוכנית")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        TextField("שם התוכנית", text: $plan.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .textFieldStyle(.plain)
                    }
                    
                    Spacer()
                    
                    // Plan type indicator
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "list.bullet.rectangle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                }
                
                // Plan type and stats
                HStack(spacing: 12) {
                    StatChip(
                        value: plan.planType.rawValue,
                        label: "סוג",
                        icon: "tag.fill",
                        color: .blue
                    )
                    
                    StatChip(
                        value: "\(plan.exercises.count)",
                        label: "תרגילים",
                        icon: "dumbbell",
                        color: .green
                    )
                    
                    if !plan.schedule.isEmpty {
                        StatChip(
                            value: "\(plan.schedule.count)",
                            label: "ימים",
                            icon: "calendar",
                            color: .orange
                        )
                    }
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(.white.opacity(0.5))
            
            // Schedule section (if exists)
            if !plan.schedule.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("לוח זמנים")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        ForEach(plan.schedule.sorted(by: { $0.weekday < $1.weekday }), id: \.self) { day in
                            DayChip(day: day, isSelected: false)
                        }
                        
                        Spacer()
                    }
                }
                .padding(20)
            }
        }
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var modernExercisesCard: some View {
        VStack(spacing: 0) {
            // Header with workout tabs
            if !plan.planType.workoutLabels.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("תרגילי האימון")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    // Modern segmented control
                    modernWorkoutLabelPicker
                    
                    HStack {
                        StatChip(
                            value: "\(filteredExercises.count)",
                            label: "תרגילים ב\(currentLabelTab)",
                            icon: "dumbbell",
                            color: .blue
                        )
                        
                        Spacer()
                    }
                }
                .padding(20)
                .background(.white.opacity(0.5))
                
                Divider()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("תרגילי האימון")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .padding(20)
                .background(.white.opacity(0.5))
                
                Divider()
            }
            
            // Exercises list
            VStack(spacing: 12) {
                if filteredExercises.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        
                        Text("אין תרגילים")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("הוסף תרגילים מהכפתור למעלה")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 32)
                } else {
                    ForEach(filteredExercises, id: \.id) { exercise in
                        ModernExerciseRow(
                            exercise: exercise,
                            onEdit: {
                                editingExercise = exercise
                            }
                        )
                    }
                    .onDelete(perform: deleteExercises)
                }
            }
            .padding(20)
        }
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var modernWorkoutLabelPicker: some View {
        HStack(spacing: 0) {
            ForEach(plan.planType.workoutLabels, id: \.self) { label in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentLabelTab = label
                    }
                }) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(currentLabelTab == label ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(currentLabelTab == label ? .blue : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func deleteExercises(offsets: IndexSet) {
        let exercisesToDelete = filteredExercises.enumerated().compactMap { index, exercise in
            offsets.contains(index) ? exercise : nil
        }
        
        withAnimation {
            for exercise in exercisesToDelete {
                if let planIndex = plan.exercises.firstIndex(where: { $0.id == exercise.id }) {
                    plan.exercises.remove(at: planIndex)
                }
            }
        }
    }
    
    private var filteredExercises: [Exercise] {
        plan.exercises.filter { ex in
            currentLabelTab.isEmpty ? true : ((ex.label ?? plan.planType.workoutLabels.first) == currentLabelTab)
        }
    }
    
    private var exercisesList: some View {
        ForEach(filteredExercises, id: \.id) { exercise in
            ModernExerciseRow(
                exercise: exercise,
                onEdit: {
                    editingExercise = exercise
                }
            )
        }
        .onDelete { offsets in
            let exercisesToDelete = filteredExercises.enumerated().compactMap { index, exercise in
                offsets.contains(index) ? exercise : nil
            }
            for exercise in exercisesToDelete {
                if let planIndex = plan.exercises.firstIndex(where: { $0.id == exercise.id }) {
                    plan.exercises.remove(at: planIndex)
                }
            }
        }
    }
    
    private var bottomActionBar: some View {
        VStack(spacing: AppTheme.s8) {
            Divider()
            
            HStack(spacing: AppTheme.s8) {
                Button(action: {
                    activeSheet = .chooseLibrary
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.caption)
                        Text("בחר")
                            .font(.subheadline)
                    }
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                if !currentLabelTab.isEmpty {
                    Button(action: {
                        activeSheet = .quickLibrary
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                                .font(.caption)
                            Text("הוסף מתרגילים מוכרים ל-\(currentLabelTab)")
                                .font(.subheadline)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
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

struct ModernExerciseRow: View {
    let exercise: Exercise
    let onEdit: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.s12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Text("סטים: \(exercise.plannedSets)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let reps = exercise.plannedReps {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text("חזרות: \(reps)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let lbl = exercise.label, !lbl.isEmpty {
                        Text("(\(lbl))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
                
                HStack(spacing: 6) {
                    if let mg = exercise.muscleGroup {
                        PillBadge(text: mg)
                    }
                    if let eq = exercise.equipment {
                        PillBadge(text: eq)
                    }
                    if exercise.isBodyweight ?? false {
                        PillBadge(text: "משקל גוף", icon: "figure.strengthtraining.traditional")
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            HStack(spacing: AppTheme.s8) {
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text("ערוך")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                
                Menu {
                    Button("מחיקה", role: .destructive) {
                        // Delete functionality handled by onDelete in parent
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
        }
        .padding(.vertical, AppTheme.s8)
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


