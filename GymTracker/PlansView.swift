import SwiftUI
import SwiftData

struct PlansView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WorkoutPlan.name, order: .forward)]) private var plans: [WorkoutPlan]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]

    @State private var isPresentingNew = false
    @State private var searchText = ""
    @State private var selectedFilter: PlanFilter = .all
    @State private var sortOption: SortOption = .name
    @State private var editingPlan: WorkoutPlan?

    enum PlanFilter: String, CaseIterable {
        case all = "הכל"
        case fullBody = "Full Body"
        case ab = "AB"
        case abc = "ABC"
    }

    enum SortOption: String, CaseIterable {
        case name = "שם"
        case recent = "לאחרונה"
        case usage = "שימוש"
        case exercises = "תרגילים"
    }

    private var filteredPlans: [WorkoutPlan] {
        var result = plans

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        switch selectedFilter {
        case .all: break
        case .fullBody: result = result.filter { $0.planTypeRaw == "Full Body" }
        case .ab: result = result.filter { $0.planTypeRaw == "AB" }
        case .abc: result = result.filter { $0.planTypeRaw == "ABC" }
        }

        switch sortOption {
        case .name: result.sort { $0.name < $1.name }
        case .recent: result.sort { $0.name > $1.name }
        case .usage: result.sort { getUsageCount($0) > getUsageCount($1) }
        case .exercises: result.sort { $0.exercises.count > $1.exercises.count }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchAndFilterSection

                if filteredPlans.isEmpty {
                    emptyStateView
                } else {
                    plansListView
                }
            }
            .navigationTitle("תוכניות")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("חדש") {
                        isPresentingNew = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $isPresentingNew) {
                NewPlanSheet()
            }
            .sheet(item: $editingPlan) { plan in
                EditPlanSheet(plan: plan)
            }
        }
    }

    private var searchAndFilterSection: some View {
        VStack(spacing: AppTheme.s12) {
            SearchBar(searchText: $searchText)
            FilterControls(
                selectedFilter: $selectedFilter,
                sortOption: $sortOption
            )
        }
        .padding(.horizontal, AppTheme.s16)
        .padding(.vertical, AppTheme.s12)
        .background(AppTheme.screenBG)
    }

    private var plansListView: some View {
            ScrollView {
            LazyVStack(spacing: AppTheme.s16) {
                statsSection

                ForEach(filteredPlans) { plan in
                    PlanCard(
                        plan: plan,
                        usageCount: getUsageCount(plan),
                        lastUsed: getLastUsed(plan),
                        onEdit: { editingPlan = plan },
                        onDuplicate: { duplicatePlan(plan) },
                        onDelete: { deletePlan(plan) }
                    )
                }
            }
            .padding(.horizontal, AppTheme.s16)
            .padding(.bottom, AppTheme.s20)
        }
    }

    private var statsSection: some View {
        VStack(spacing: AppTheme.s16) {
            HStack {
                Text("סטטיסטיקות")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppTheme.s12) {
                StatTile(
                    value: "\(plans.count)",
                    label: "סה\"כ תוכניות",
                    icon: "list.bullet.rectangle",
                    color: AppTheme.accent
                )
                StatTile(
                    value: "\(plans.filter { getUsageCount($0) > 0 }.count)",
                    label: "תוכניות פעילות",
                    icon: "chart.line.uptrend.xyaxis",
                    color: AppTheme.success
                )
                StatTile(
                    value: "\(getWeeklyUsage())",
                    label: "שימוש השבוע",
                    icon: "calendar",
                    color: AppTheme.warning
                )
            }
        }
        .padding(AppTheme.s16)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyStateView: some View {
                        EmptyStateView(
                            iconSystemName: "list.bullet.rectangle",
            title: "אין תוכניות",
            message: "צור תוכנית חדשה כדי להתחיל",
            buttonTitle: "צור תוכנית"
                        ) {
                            isPresentingNew = true
                        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func getUsageCount(_ plan: WorkoutPlan) -> Int {
        sessions.filter { $0.planName == plan.name }.count
    }

    private func getLastUsed(_ plan: WorkoutPlan) -> Date? {
        sessions.filter { $0.planName == plan.name }.first?.date
    }

    private func getWeeklyUsage() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { $0.date >= weekAgo }.count
    }

    private func duplicatePlan(_ plan: WorkoutPlan) {
        let newPlan = WorkoutPlan(
            name: "\(plan.name) (עותק)",
            exercises: plan.exercises,
            planType: plan.planType,
            schedule: plan.schedule
        )
        modelContext.insert(newPlan)
        try? modelContext.save()
    }

    private func deletePlan(_ plan: WorkoutPlan) {
        modelContext.delete(plan)
        try? modelContext.save()
    }
}

struct SearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("חיפוש תוכניות...", text: $searchText)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button("נקה") {
                    searchText = ""
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, AppTheme.s16)
        .padding(.vertical, AppTheme.s12)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FilterControls: View {
    @Binding var selectedFilter: PlansView.PlanFilter
    @Binding var sortOption: PlansView.SortOption

    var body: some View {
        HStack {
            Menu {
                ForEach(PlansView.PlanFilter.allCases, id: \.self) { filter in
                    Button(filter.rawValue) {
                        selectedFilter = filter
                    }
                }
            } label: {
                HStack {
                    Text(selectedFilter.rawValue)
                    Image(systemName: "chevron.down")
                }
                .foregroundStyle(AppTheme.accent)
            }

            Spacer()

            Menu {
                ForEach(PlansView.SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        sortOption = option
                    }
                }
            } label: {
                HStack {
                    Text(sortOption.rawValue)
                    Image(systemName: "chevron.down")
                }
                .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(.horizontal, AppTheme.s16)
    }
}

struct PlanCard: View {
    let plan: WorkoutPlan
    let usageCount: Int
    let lastUsed: Date?
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    private var planTypeColor: Color {
        switch plan.planType {
        case .fullBody: return AppTheme.accent
        case .ab: return AppTheme.success
        case .abc: return AppTheme.warning
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            contentSection
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [planTypeColor, planTypeColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: AppTheme.s8) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.s4) {
                        Text(plan.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        
                        Text(plan.planType.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, AppTheme.s8)
                            .padding(.vertical, AppTheme.s4)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button("ערוך", action: onEdit)
                        Button("שכפל", action: onDuplicate)
                        Button("מחק", role: .destructive, action: onDelete)
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.white)
                            .padding(AppTheme.s8)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }

                HStack {
                    StatItem(
                        icon: "dumbbell.fill",
                        value: "\(plan.exercises.count)",
                        label: "תרגילים"
                    )
                    Spacer()
                    StatItem(
                        icon: "chart.line.uptrend.xyaxis",
                        value: "\(usageCount)",
                        label: "שימושים"
                    )
                    Spacer()
                    StatItem(
                            icon: "calendar",
                        value: lastUsed?.formatted(date: .abbreviated, time: .omitted) ?? "לעולם לא",
                        label: "אחרון"
                    )
                }
                .foregroundStyle(.white.opacity(0.9))
            }
            .padding(AppTheme.s16)
        }
    }

    private var contentSection: some View {
        VStack(spacing: AppTheme.s12) {
            HStack {
                Text("תרגילים:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.secondary)
                    
                    Spacer()
                    
                Text("\(plan.exercises.count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.accent)
            }

            if !plan.exercises.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.s8) {
                        ForEach(plan.exercises.prefix(5)) { exercise in
                            PillBadge(text: exercise.name)
                        }

                        if plan.exercises.count > 5 {
                            Text("+\(plan.exercises.count - 5)")
                                .font(.caption)
                                .padding(.horizontal, AppTheme.s8)
                                .padding(.vertical, AppTheme.s4)
                                .background(AppTheme.secondary.opacity(0.1))
                                .foregroundStyle(AppTheme.secondary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, AppTheme.s16)
                }
            }

            if !plan.schedule.isEmpty {
                HStack {
                    Text("לוח זמנים:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.secondary)
                        
                        Spacer()

                    HStack(spacing: AppTheme.s4) {
                        ForEach(plan.schedule, id: \.weekday) { day in
                            DayChip(day: day)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.s16)
        .background(AppTheme.cardBG)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: AppTheme.s4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.caption2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

struct EditPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var planName: String
    @State private var planType: PlanType
    @State private var exercises: [Exercise]
    @State private var schedule: [PlannedDay]
    @State private var currentEditingDay: String = "A"
    @State private var selectedExerciseLabel: String = "A"
    @State private var selectedTab: EditTab = .details
    @State private var showAddExercise = false
    @State private var showExerciseLibrary = false
    @State private var editingExercise: Exercise?
    @State private var showDeleteConfirmation = false
    @State private var exerciseToDelete: Exercise?

    private let plan: WorkoutPlan

    enum EditTab: String, CaseIterable {
        case details = "פרטים"
        case exercises = "תרגילים"
        case schedule = "לוח זמנים"

        var icon: String {
            switch self {
            case .details: return "info.circle.fill"
            case .exercises: return "dumbbell.fill"
            case .schedule: return "calendar"
            }
        }

        var color: Color {
            switch self {
            case .details: return AppTheme.accent
            case .exercises: return AppTheme.success
            case .schedule: return AppTheme.warning
            }
        }
    }

    init(plan: WorkoutPlan) {
        self.plan = plan
        self._planName = State(initialValue: plan.name)
        self._planType = State(initialValue: plan.planType)
        self._exercises = State(initialValue: plan.exercises)
        self._schedule = State(initialValue: plan.schedule)
        self._selectedExerciseLabel = State(initialValue: plan.planType.workoutLabels.first ?? "A")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                tabBar
                selectedTabContent
            }
            .background(AppTheme.screenBG)
            .navigationTitle("עריכת תוכנית")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") { savePlan() }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                        .disabled(planName.isEmpty)
                }
            }
            .onChange(of: planType) { _, _ in
                normalizeScheduleForPlanType()
                normalizeExercisesForPlanType()
            }
            .onChange(of: planType) { _, newType in
                selectedExerciseLabel = newType.workoutLabels.first ?? selectedExerciseLabel
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseSheet { exercise in
                    // Set default label according to plan type
                    if planType == .fullBody {
                        exercise.label = planType.workoutLabels.first
                    } else {
                        exercise.label = selectedExerciseLabel
                    }
                    exercises.append(exercise)
                }
            }
            .sheet(isPresented: $showExerciseLibrary) {
                ExerciseLibrarySheet { exercise in
                    let newExercise = Exercise(
                        name: exercise.name,
                        plannedSets: 3,
                        plannedReps: 8,
                        muscleGroup: exercise.bodyPart.rawValue,
                        equipment: exercise.equipment,
                        isBodyweight: exercise.isBodyweight
                    )
                    // Default label by plan type / current selection
                    newExercise.label = planType == .fullBody ? planType.workoutLabels.first : selectedExerciseLabel
                    exercises.append(newExercise)
                }
            }
            .sheet(item: $editingExercise) { exercise in
            ExerciseEditSheet(
                exercise: exercise,
                onSave: { updatedExercise in
                        if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                            exercises[index] = updatedExercise
                    }
                    editingExercise = nil
                },
                    onCancel: { editingExercise = nil }
                )
            }
            .alert("מחיקת תרגיל", isPresented: $showDeleteConfirmation) {
                Button("מחק", role: .destructive) {
                    if let exercise = exerciseToDelete,
                       let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
                        exercises.remove(at: index)
                    }
                    exerciseToDelete = nil
                }
                Button("ביטול", role: .cancel) {
                    exerciseToDelete = nil
                }
            } message: {
                Text("האם אתה בטוח שברצונך למחוק את התרגיל '\(exerciseToDelete?.name ?? "")'?")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: AppTheme.s16) {
                    ZStack {
                        Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                        
                        Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(spacing: AppTheme.s8) {
                Text("עריכת תוכנית")
                    .font(.system(size: 22, weight: .bold, design: .rounded))

                Text("ערוך את פרטי התוכנית, תרגילים ולוח זמנים")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s24)
        .background(AppTheme.cardBG)
    }

    private var tabBar: some View {
        HStack(spacing: AppTheme.s8) {
            ForEach(EditTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: AppTheme.s8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.vertical, AppTheme.s12)
                    .padding(.horizontal, AppTheme.s16)
                    .background(selectedTab == tab ? tab.color.opacity(0.2) : Color.clear)
                    .foregroundStyle(selectedTab == tab ? tab.color : AppTheme.secondary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppTheme.s16)
        .padding(.vertical, AppTheme.s12)
        .background(AppTheme.cardBG)
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .details:
            detailsTab
        case .exercises:
            exercisesTab
        case .schedule:
            scheduleTab
        }
    }

    private var detailsTab: some View {
        ScrollView {
            VStack(spacing: AppTheme.s16) {
                planInfoCard
                planTypeCard
                Spacer(minLength: 100)
            }
            .padding(.horizontal, AppTheme.s16)
            .padding(.top, AppTheme.s16)
        }
    }

    private var exercisesTab: some View {
        VStack(spacing: 0) {
            exerciseToolbar

            if exercises.isEmpty {
                emptyExercisesView
            } else {
                if planType == .fullBody {
                    exercisesList
                } else {
                    segmentedExerciseLists
                }
            }
        }
    }

    private var scheduleTab: some View {
        ScrollView {
            VStack(spacing: AppTheme.s16) {
                scheduleInfoCard
                scheduleEditor
                if !schedule.isEmpty {
                    scheduleDisplayCard
                }
                Spacer(minLength: 100)
            }
            .padding(.horizontal, AppTheme.s16)
            .padding(.top, AppTheme.s16)
        }
    }

    private var planInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s20) {
            HStack {
                Text("פרטי התוכנית")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                Spacer()

                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: AppTheme.s8) {
                Text("שם התוכנית")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                TextField("שם התוכנית", text: $planName)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 16))
                    .padding(AppTheme.s16)
                    .background(AppTheme.cardBG)
                    .cornerRadius(16)
                    }
                }
                .padding(20)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var planTypeCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s20) {
            HStack {
                Text("סוג התוכנית")
                        .font(.system(size: 20, weight: .bold, design: .rounded))

                Spacer()

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
            }

            VStack(spacing: AppTheme.s12) {
                ForEach(PlanType.allCases, id: \.self) { type in
                    PlanTypeRow(
                        type: type,
                        isSelected: planType == type,
                        onSelect: { planType = type }
                    )
                }
                }
            }
            .padding(20)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var exerciseToolbar: some View {
        HStack {
            Text("תרגילים (\(exercises.count))")
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Spacer()

            if planType != .fullBody {
                // Quick selector for default label when adding exercises
                Menu {
                    ForEach(planType.workoutLabels, id: \.self) { label in
                        Button(label) { selectedExerciseLabel = label }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                        Text(selectedExerciseLabel)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent.opacity(0.1))
                    .foregroundStyle(AppTheme.accent)
                    .clipShape(Capsule())
                }
            }

            Menu {
                Button(action: { showAddExercise = true }) {
                    Label("תרגיל מותאם", systemImage: "plus")
                }
                Button(action: { showExerciseLibrary = true }) {
                    Label("מספריית התרגילים", systemImage: "book")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(AppTheme.s12)
                    .background(AppTheme.accent)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, AppTheme.s16)
        .padding(.vertical, AppTheme.s12)
        .background(AppTheme.cardBG)
    }

    // Show A/B/C segmented lists
    private var segmentedExerciseLists: some View {
        VStack(spacing: AppTheme.s16) {
            ForEach(planType.workoutLabels, id: \.self) { label in
                VStack(alignment: .leading, spacing: AppTheme.s8) {
                    HStack {
                        Text("אימון \(label)")
                            .font(.headline)
                        Spacer()
                    }
                    LazyVStack(spacing: AppTheme.s12) {
                        ForEach(exercises.filter { ($0.label ?? planType.workoutLabels.first) == label }) { exercise in
                            ExerciseRowCard(
                exercise: exercise,
                                onEdit: { editingExercise = exercise },
                                onDelete: {
                                    exerciseToDelete = exercise
                                    showDeleteConfirmation = true
                                },
                                labelSelector: LabelSelector(
                                    labels: planType.workoutLabels,
                                    selected: exercise.label ?? planType.workoutLabels.first ?? "A",
                                    onSelect: { new in
                                        if let idx = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                            exercises[idx].label = new
                                        }
                                    }
                                )
                            )
                        }
                    }
                }
                .padding(.horizontal, AppTheme.s16)
            }
            .padding(.bottom, 100)
        }
    }

    private var emptyExercisesView: some View {
        VStack(spacing: AppTheme.s24) {
            Spacer()

            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.accent)

        VStack(spacing: AppTheme.s8) {
                Text("אין תרגילים")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("הוסף תרגילים לתוכנית כדי להתחיל")
                            .font(.subheadline)
                    .foregroundStyle(AppTheme.secondary)
                    .multilineTextAlignment(.center)
                    }

            HStack(spacing: AppTheme.s12) {
                Button("תרגיל מותאם") {
                    showAddExercise = true
                }
                .buttonStyle(.bordered)

                Button("מספריית התרגילים") {
                    showExerciseLibrary = true
                    }
                    .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var exercisesList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.s12) {
                ForEach(exercises) { exercise in
                    ExerciseRowCard(
                        exercise: exercise,
                        onEdit: { editingExercise = exercise },
                        onDelete: {
                            exerciseToDelete = exercise
                            showDeleteConfirmation = true
                        },
                        labelSelector: planType == .fullBody ? nil : LabelSelector(
                            labels: planType.workoutLabels,
                            selected: exercise.label ?? planType.workoutLabels.first ?? "A",
                            onSelect: { new in
                                if let idx = exercises.firstIndex(where: { $0.id == exercise.id }) {
                                    exercises[idx].label = new
                                }
                            }
                        )
                    )
                }
            }
            .padding(.horizontal, AppTheme.s16)
            .padding(.bottom, 100)
        }
    }

    private var scheduleInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            HStack {
                Text("לוח זמנים")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                Spacer()

                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
            }
                    
            if schedule.isEmpty {
                Text("לא הוגדר לוח זמנים לתוכנית זו")
                    .font(.subheadline)
                            .foregroundStyle(.secondary)
            } else {
                Text("התוכנית מוגדרת עם \(schedule.count) ימי אימון בשבוע")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
        }
        .padding(20)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var scheduleDisplayCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            Text("ימי אימון")
                .font(.system(size: 18, weight: .bold))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppTheme.s12) {
                ForEach(schedule, id: \.weekday) { day in
                    DayChip(day: day)
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var scheduleEditor: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            HStack {
                Text("בחר אימון")
                    .font(.system(size: 16, weight: .semibold))
            Spacer()
            }
            
            // Pick which workout (A/B/C or Full) to edit
            HStack(spacing: AppTheme.s8) {
                ForEach(planType.workoutLabels, id: \.self) { label in
                    Button(action: { currentEditingDay = label }) {
                        Text(label)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.vertical, AppTheme.s8)
                            .padding(.horizontal, AppTheme.s12)
                            .background(currentEditingDay == label ? AppTheme.accent.opacity(0.2) : AppTheme.cardBG)
                            .foregroundStyle(currentEditingDay == label ? AppTheme.accent : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.s12) {
                Text("בחר ימים בשבוע")
                    .font(.system(size: 16, weight: .semibold))

                // Weekday chips
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppTheme.s8) {
                    ForEach(1...7, id: \.self) { weekday in
                        let selected = isWeekdaySelected(weekday, for: currentEditingDay)
                        Button(action: { toggleWeekday(weekday, for: currentEditingDay) }) {
                            Text(weekdaySymbol(weekday))
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.s8)
                                .background(selected ? AppTheme.accent : AppTheme.cardBG)
                                .foregroundStyle(selected ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private func isWeekdaySelected(_ weekday: Int, for label: String) -> Bool {
        schedule.contains(where: { $0.weekday == weekday && $0.label == label })
    }

    private func toggleWeekday(_ weekday: Int, for label: String) {
        if let index = schedule.firstIndex(where: { $0.weekday == weekday && $0.label == label }) {
            schedule.remove(at: index)
        } else {
            schedule.append(PlannedDay(weekday: weekday, label: label))
        }
    }

    private func weekdaySymbol(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "א"
        case 2: return "ב"
        case 3: return "ג"
        case 4: return "ד"
        case 5: return "ה"
        case 6: return "ו"
        case 7: return "ש"
        default: return "?"
        }
    }

    private func savePlan() {
        plan.name = planName
        plan.planType = planType
        // Ensure exercises labels and schedule are consistent with plan type
        normalizeExercisesForPlanType()
        normalizeScheduleForPlanType()
        plan.exercises = exercises
        plan.schedule = schedule

        try? modelContext.save()
        dismiss()
    }

    // Keep only labels that are valid for the plan type; assign default for missing
    private func normalizeExercisesForPlanType() {
        let valid = Set(planType.workoutLabels)
        for idx in exercises.indices {
            if planType == .fullBody {
                exercises[idx].label = planType.workoutLabels.first
            } else {
                if let label = exercises[idx].label, valid.contains(label) {
                    // keep
                } else {
                    exercises[idx].label = planType.workoutLabels.first
                }
            }
        }
    }

    // Ensure schedule only contains allowed labels for the selected plan type
    private func normalizeScheduleForPlanType() {
        let allowed = Set(planType.workoutLabels)
        // Filter out entries with labels not supported by the current plan type
        schedule = schedule.filter { allowed.contains($0.label) }

        // For Full Body, collapse all labels to the single label and deduplicate by weekday
        if planType == .fullBody, let full = planType.workoutLabels.first {
            var seen = Set<Int>()
            var result: [PlannedDay] = []
            for item in schedule {
                if !seen.contains(item.weekday) {
                    seen.insert(item.weekday)
                    result.append(PlannedDay(weekday: item.weekday, label: full))
                }
            }
            schedule = result
        }

        // Make sure currentEditingDay is valid
        if !allowed.contains(currentEditingDay) {
            currentEditingDay = planType.workoutLabels.first ?? currentEditingDay
        }
    }
}

struct PlanTypeRow: View {
    let type: PlanType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppTheme.s16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.accent.opacity(0.2) : .gray.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? AppTheme.accent : .gray)
                }

                VStack(alignment: .leading, spacing: AppTheme.s4) {
                    Text(type.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(planTypeDescription(type))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(AppTheme.s16)
            .background(isSelected ? AppTheme.accent.opacity(0.05) : AppTheme.cardBG)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppTheme.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func planTypeDescription(_ type: PlanType) -> String {
        switch type {
        case .fullBody:
            return "אימון גוף מלא בכל פעם"
        case .ab:
            return "חלוקה לשני אימונים A ו-B"
        case .abc:
            return "חלוקה לשלושה אימונים A, B ו-C"
        }
    }
}

struct ExerciseRowCard: View {
    let exercise: Exercise
    let onEdit: () -> Void
    let onDelete: () -> Void
    let labelSelector: LabelSelector?

    var body: some View {
        HStack(spacing: AppTheme.s16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 50, height: 50)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: AppTheme.s4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: AppTheme.s12) {
                    Text("\(exercise.plannedSets) סטים")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let reps = exercise.plannedReps {
                        Text("\(reps) חזרות")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let muscleGroup = exercise.muscleGroup {
                        PillBadge(text: muscleGroup)
                    }
                    
                    if let selector = labelSelector {
                        Menu {
                            ForEach(selector.labels, id: \.self) { label in
                                Button(label) { selector.onSelect(label) }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                Text(selector.selected)
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.accent.opacity(0.1))
                            .foregroundStyle(AppTheme.accent)
                            .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            Menu {
                Button("ערוך", action: onEdit)
                Button("מחק", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(AppTheme.s8)
                    .background(AppTheme.cardBG)
                    .clipShape(Circle())
            }
        }
        .padding(AppTheme.s16)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct LabelSelector {
    let labels: [String]
    let selected: String
    let onSelect: (String) -> Void
}

struct AddExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Exercise) -> Void

    @State private var name = ""
    @State private var sets = 3
    @State private var reps = 8
    @State private var muscleGroup = ""
    @State private var equipment = ""
    @State private var notes = ""
    @State private var isBodyweight = false

    var body: some View {
        NavigationStack {
            Form {
                Section("פרטי התרגיל") {
                TextField("שם התרגיל", text: $name)
                    TextField("קבוצת שריר", text: $muscleGroup)
                    TextField("ציוד", text: $equipment)
                    Toggle("תרגיל משקל גוף", isOn: $isBodyweight)
                }

                Section("הגדרות") {
                    Stepper("סטים: \(sets)", value: $sets, in: 1...10)
                    Stepper("חזרות: \(reps)", value: $reps, in: 1...50)
                }

                Section("הערות") {
                    TextField("הערות (אופציונלי)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("תרגיל חדש")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("הוסף") {
                        let exercise = Exercise(
                            name: name,
                            plannedSets: sets,
                            plannedReps: reps,
                            notes: notes.isEmpty ? nil : notes,
                            muscleGroup: muscleGroup.isEmpty ? nil : muscleGroup,
                            equipment: equipment.isEmpty ? nil : equipment,
                            isBodyweight: isBodyweight
                        )
                        onAdd(exercise)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct ExerciseLibrarySheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (ExerciseLibraryItem) -> Void

    @State private var searchText = ""
    @State private var selectedBodyPart: ExerciseLibraryItem.BodyPart? = nil

    private var filteredExercises: [ExerciseLibraryItem] {
        var exercises = ExerciseLibrary.exercises

        if let bodyPart = selectedBodyPart {
            exercises = exercises.filter { $0.bodyPart == bodyPart }
        }

        if !searchText.isEmpty {
            exercises = exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return exercises
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchAndFilterBar

                if filteredExercises.isEmpty {
                    EmptyStateView(
                        iconSystemName: "magnifyingglass",
                        title: "לא נמצאו תרגילים",
                        message: "נסה חיפוש אחר או בחר קטגוריה אחרת"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    exerciseList
                }
            }
            .navigationTitle("ספריית תרגילים")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
            }
        }
    }

    private var searchAndFilterBar: some View {
        VStack(spacing: AppTheme.s12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("חיפוש תרגילים...", text: $searchText)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button("נקה") { searchText = "" }
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, AppTheme.s16)
            .padding(.vertical, AppTheme.s12)
            .background(AppTheme.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.s8) {
                    FilterButton(
                        title: "הכל",
                        isSelected: selectedBodyPart == nil,
                        action: { selectedBodyPart = nil }
                    )

                    ForEach(ExerciseLibraryItem.BodyPart.allCases, id: \.self) { bodyPart in
                        FilterButton(
                            title: bodyPart.rawValue,
                            isSelected: selectedBodyPart == bodyPart,
                            action: { selectedBodyPart = bodyPart }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.s16)
            }
        }
        .padding(.vertical, AppTheme.s12)
        .background(AppTheme.cardBG)
    }

    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.s12) {
                ForEach(filteredExercises) { exercise in
                    ExerciseLibraryRow(exercise: exercise, onSelect: {
                        onSelect(exercise)
                        dismiss()
                    })
                }
            }
            .padding(.horizontal, AppTheme.s16)
            .padding(.bottom, 100)
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, AppTheme.s16)
                .padding(.vertical, AppTheme.s8)
                .background(isSelected ? AppTheme.accent : AppTheme.cardBG)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    PlansView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}