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
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save duplicated plan: \(error)")
        }
    }

    private func deletePlan(_ plan: WorkoutPlan) {
        modelContext.delete(plan)
        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to delete plan: \(error)")
        }
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
        case .abcd: return .purple
        case .abcde: return .pink
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
    @State private var showReorderExercises = false
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
        NavigationStack { mainContent }
            .sheet(isPresented: $showAddExercise) { addExerciseSheet }
            .sheet(isPresented: $showExerciseLibrary) { exerciseLibrarySheet }
            .sheet(isPresented: $showReorderExercises) { reorderSheet }
            .sheet(item: $editingExercise) { exercise in exerciseEditSheet(exercise) }
            .alert("מחיקת תרגיל", isPresented: $showDeleteConfirmation) {
                Button("מחק", role: .destructive) { deleteSelectedExercise() }
                Button("ביטול", role: .cancel) { exerciseToDelete = nil }
            } message: { Text("האם אתה בטוח שברצונך למחוק את התרגיל '\(exerciseToDelete?.name ?? "")'?") }
    }

    private var mainContent: some View {
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
    }

    // MARK: - Sheet Builders
    private var addExerciseSheet: some View {
        AddExerciseSheet { exercise in
            if planType == .fullBody {
                exercise.label = planType.workoutLabels.first
            } else {
                exercise.label = selectedExerciseLabel
            }
            exercises.append(exercise)
        }
    }

    private var exerciseLibrarySheet: some View {
        ExerciseLibrarySheet { exercise in
            let newExercise = Exercise(
                name: exercise.name,
                plannedSets: 3,
                plannedReps: 8,
                muscleGroup: exercise.bodyPart.rawValue,
                equipment: exercise.equipment,
                isBodyweight: exercise.isBodyweight
            )
            newExercise.label = planType == .fullBody ? planType.workoutLabels.first : selectedExerciseLabel
            let label = newExercise.label ?? planType.workoutLabels.first ?? ""
            let currentMax = exercises.filter { ($0.label ?? label) == label }.map { $0.orderIndex ?? 0 }.max() ?? -1
            newExercise.orderIndex = currentMax + 1
            exercises.append(newExercise)
        }
    }

    private var reorderSheet: some View {
        PlanExercisesReorderSheet(
            planType: planType,
            labels: planType.workoutLabels,
            exercises: exercises,
            onSave: { newOrder in
                var counters: [String: Int] = [:]
                let stamped = newOrder
                for idx in stamped.indices {
                    let label = stamped[idx].label ?? planType.workoutLabels.first ?? ""
                    let next = (counters[label] ?? 0)
                    stamped[idx].orderIndex = next
                    counters[label] = next + 1
                }
                exercises = stamped
            }
        )
    }

    private func exerciseEditSheet(_ exercise: Exercise) -> some View {
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

    private func deleteSelectedExercise() {
        if let exercise = exerciseToDelete,
           let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
            exercises.remove(at: index)
        }
        exerciseToDelete = nil
    }

    private var headerSection: some View {
        VStack(spacing: AppTheme.s20) {
            // Plan Icon with gradient background
            ZStack {
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Plan Info
            VStack(spacing: AppTheme.s8) {
                Text(planName.isEmpty ? "עריכת תוכנית" : planName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                HStack(spacing: AppTheme.s12) {
                    // Plan Type Badge
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.caption)
                        Text(planType.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(Color.blue)
                    .clipShape(Capsule())

                    // Exercises Count Badge
                    HStack(spacing: 6) {
                        Image(systemName: "dumbbell.fill")
                            .font(.caption)
                        Text("\(exercises.count) תרגילים")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .foregroundStyle(Color.green)
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s24)
        .background(
            LinearGradient(
                colors: [Color(.secondarySystemBackground), Color(.tertiarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(EditTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: AppTheme.s8) {
                        // Icon with background
                        ZStack {
                            Circle()
                                .fill(selectedTab == tab ? tab.color : Color.clear)
                                .frame(width: 40, height: 40)

                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(selectedTab == tab ? .white : .secondary)
                        }

                        // Tab Label
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selectedTab == tab ? tab.color : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.s12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedTab == tab ? tab.color.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppTheme.s16)
        .padding(.vertical, AppTheme.s16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal, AppTheme.s16)
        .padding(.bottom, AppTheme.s8)
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
            // Fixed toolbar with proper spacing
            VStack(spacing: 0) {
                exerciseToolbar
                    .padding(.horizontal, AppTheme.s16)
                    .padding(.vertical, AppTheme.s12)
                    .background(AppTheme.screenBG)

                Divider()
                    .background(Color(.separator))
            }

            // Scrollable content
            if exercises.isEmpty {
                emptyExercisesView
            } else {
                ScrollView {
                    if planType == .fullBody {
                        exercisesList
                            .padding(.top, AppTheme.s16)
                    } else {
                        segmentedExerciseLists
                            .padding(.top, AppTheme.s16)
                    }
                }
                .background(AppTheme.screenBG)
        .sheet(isPresented: $showReorderExercises) {
            PlanExercisesReorderSheet(
                planType: planType,
                labels: planType.workoutLabels,
                exercises: exercises,
                onSave: { newOrder in
                    // עדכון אינדקסי סדר לפי המיקום החדש בכל תווית
                    var counters: [String: Int] = [:]
                    let stamped = newOrder
                    for idx in stamped.indices {
                        let label = stamped[idx].label ?? planType.workoutLabels.first ?? ""
                        let next = counters[label] ?? 0
                        stamped[idx].orderIndex = next
                        counters[label] = next + 1
                    }
                    exercises = stamped
                }
            )
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
            // Header with icon
            HStack {
                HStack(spacing: AppTheme.s12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)

                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.blue)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("פרטי התוכנית")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("שם וסוג התוכנית")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            // Plan Name Field
            VStack(alignment: .leading, spacing: AppTheme.s12) {
                HStack {
                    Text("שם התוכנית")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    if !planName.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(Color.green)

                            Text("תקין")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.green)
                        }
                    }
                }

                TextField("הזן שם לתוכנית...", text: $planName)
                    .font(.system(size: 16, weight: .medium))
                    .padding(AppTheme.s16)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(planName.isEmpty ? Color.red.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(AppTheme.s20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var planTypeCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s20) {
            // Header with icon
            HStack {
                HStack(spacing: AppTheme.s12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 40, height: 40)

                        Image(systemName: "target")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("סוג התוכנית")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("בחר את סגנון האימון המתאים")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            // Plan Type Options
            VStack(spacing: AppTheme.s12) {
                ForEach(PlanType.allCases, id: \.self) { type in
                    ModernPlanTypeRow(
                        type: type,
                        isSelected: planType == type,
                        onSelect: { planType = type }
                    )
                }
            }
        }
        .padding(AppTheme.s20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var exerciseToolbar: some View {
        HStack {
            Text("תרגילים (\(exercises.count))")
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Spacer()

            Button(action: { showReorderExercises = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("סדר")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

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
        LazyVStack(spacing: AppTheme.s24) {
            ForEach(planType.workoutLabels, id: \.self) { label in
                VStack(alignment: .leading, spacing: AppTheme.s16) {
                    // Section Header
                    HStack {
                        HStack(spacing: AppTheme.s8) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accent.opacity(0.1))
                                    .frame(width: 32, height: 32)

                                Text(label)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.accent)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("אימון \(label)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.primary)

                                Text("\(exercises.filter { ($0.label ?? planType.workoutLabels.first) == label }.count) תרגילים")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.s20)
                    .padding(.vertical, AppTheme.s12)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Exercise Cards
                    LazyVStack(spacing: AppTheme.s12) {
                        ForEach(exercises.filter { ($0.label ?? planType.workoutLabels.first) == label }) { exercise in
                            ModernExerciseRowCard(
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

            // Bottom spacing
            Spacer(minLength: 100)
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
        LazyVStack(spacing: AppTheme.s12) {
            ForEach(exercises) { exercise in
                ModernExerciseRowCard(
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

    // MARK: - Reorder Sheet for Plan Exercises
    struct PlanExercisesReorderSheet: View {
        let planType: PlanType
        let labels: [String]
        @State var exercises: [Exercise]
        let onSave: ([Exercise]) -> Void
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                List {
                    ForEach(sectionedExercises.keys.sorted(by: labelSort), id: \.self) { label in
                        Section(header: Text(sectionTitle(for: label))) {
                    ForEach(sectionedExercises[label] ?? []) { exercise in
                                HStack {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundStyle(.secondary)
                                    Text(exercise.name)
                                    Spacer()
                                    if let reps = exercise.plannedReps {
                                        Text("\(exercise.plannedSets)×\(reps)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("\(exercise.plannedSets) סטים")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .onMove { from, to in
                                move(in: label, from: from, to: to)
                            }
                        }
                    }
                }
                .environment(\ .editMode, .constant(.active))
                .navigationTitle("סידור תרגילים")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("ביטול") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("שמור") {
                            onSave(exercises)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }

        private var sectionedExercises: [String: [Exercise]] {
            Dictionary(grouping: exercises) { ex in ex.label ?? labels.first ?? "" }
        }

        private func labelSort(_ a: String, _ b: String) -> Bool {
            guard planType != .fullBody else { return true }
            let ai = labels.firstIndex(of: a) ?? 0
            let bi = labels.firstIndex(of: b) ?? 0
            return ai < bi
        }

        private func sectionTitle(for label: String) -> String {
            planType == .fullBody ? "תרגילים" : "אימון \(label)"
        }

        private func move(in label: String, from source: IndexSet, to destination: Int) {
            var group = sectionedExercises[label] ?? []
            group.move(fromOffsets: source, toOffset: destination)

            var new: [Exercise] = []
            for currentLabel in sectionedExercises.keys.sorted(by: labelSort) {
                if currentLabel == label {
                    new.append(contentsOf: group)
                } else {
                    new.append(contentsOf: sectionedExercises[currentLabel] ?? [])
                }
            }
            exercises = new
        }
    }

    private var scheduleInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s20) {
            // Header with icon
            HStack {
                HStack(spacing: AppTheme.s12) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.1))
                            .frame(width: 40, height: 40)

                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.purple)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("לוח זמנים")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("תכנן את ימי האימון")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Schedule Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(schedule.isEmpty ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)

                    Text(schedule.isEmpty ? "לא מוגדר" : "\(schedule.count) ימים")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(schedule.isEmpty ? Color.orange : Color.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background((schedule.isEmpty ? Color.orange : Color.green).opacity(0.1))
                .clipShape(Capsule())
            }

            // Schedule Description
            VStack(alignment: .leading, spacing: AppTheme.s8) {
                if schedule.isEmpty {
                    Text("📅 לא הוגדר לוח זמנים")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text("הוסף ימי אימון לתוכנית כדי ליצור לוח זמנים מסודר")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("✅ לוח זמנים פעיל")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text("התוכנית כוללת \(schedule.count) ימי אימון בשבוע")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(AppTheme.s20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var scheduleDisplayCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s20) {
            // Header with status
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.s4) {
                    Text("ימי אימון")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)

                    HStack(spacing: AppTheme.s8) {
                        Circle()
                            .fill(schedule.isEmpty ? AppTheme.warning : AppTheme.success)
                            .frame(width: 8, height: 8)

                        Text(schedule.isEmpty ? "לא הוגדרו ימי אימון" : "\(schedule.count) ימי אימון")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(schedule.isEmpty ? AppTheme.warning : AppTheme.success)
                    }
                }

                Spacer()

                // Schedule type badge
                if !schedule.isEmpty {
                    let uniqueLabels = Set(schedule.map { $0.label }).count
                    HStack(spacing: AppTheme.s4) {
                        Image(systemName: uniqueLabels > 1 ? "rectangle.3.group" : "rectangle")
                            .font(.caption)
                        Text(uniqueLabels > 1 ? "מחולק" : "מלא")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, AppTheme.s8)
                    .padding(.vertical, 4)
                    .background(AppTheme.info.opacity(0.1))
                    .foregroundStyle(AppTheme.info)
                    .clipShape(Capsule())
                }
            }

            if schedule.isEmpty {
                // Empty state
                VStack(spacing: AppTheme.s12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.warning.opacity(0.6))

                    Text("טרם הוגדרו ימי אימון")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.s24)
            } else {
                // Days grid with enhanced styling
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppTheme.s12) {
                    ForEach(schedule, id: \.weekday) { day in
                        ScheduleDayChip(day: day)
                    }
                }
            }
        }
        .padding(AppTheme.s24)
        .background(
            LinearGradient(
                colors: [
                    Color(.secondarySystemBackground),
                    Color(.secondarySystemBackground).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }

    private var scheduleEditor: some View {
        VStack(alignment: .leading, spacing: AppTheme.s20) {
            // Header
            VStack(alignment: .leading, spacing: AppTheme.s4) {
                Text("עריכת לוח זמנים")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)

                Text("בחר אימון וימים בשבוע")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Workout type selector with modern design
            VStack(alignment: .leading, spacing: AppTheme.s12) {
                Text("סוג אימון")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.s8) {
                        ForEach(planType.workoutLabels, id: \.self) { label in
                            ModernWorkoutTypeButton(
                                label: label,
                                isSelected: currentEditingDay == label,
                                onSelect: { currentEditingDay = label }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            // Weekday selector with modern design
            VStack(alignment: .leading, spacing: AppTheme.s12) {
                HStack {
                    Text("ימים בשבוע")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    // Selected days count
                    let selectedCount = schedule.filter { $0.label == currentEditingDay }.count
                    if selectedCount > 0 {
                        HStack(spacing: AppTheme.s4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text("\(selectedCount) ימים")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, AppTheme.s8)
                        .padding(.vertical, 4)
                        .background(AppTheme.accent.opacity(0.1))
                        .foregroundStyle(AppTheme.accent)
                        .clipShape(Capsule())
                    }
                }

                // Enhanced weekday grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppTheme.s10) {
                    ForEach(1...7, id: \.self) { weekday in
                        let selected = isWeekdaySelected(weekday, for: currentEditingDay)
                        ModernWeekdayButton(
                            weekday: weekday,
                            isSelected: selected,
                            onToggle: { toggleWeekday(weekday, for: currentEditingDay) }
                        )
                    }
                }
            }
        }
        .padding(AppTheme.s24)
        .background(
            LinearGradient(
                colors: [
                    Color(.secondarySystemBackground),
                    Color(.secondarySystemBackground).opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }

    private func isWeekdaySelected(_ weekday: Int, for label: String) -> Bool {
        schedule.contains(where: { $0.weekday == weekday && $0.label == label })
    }

    private func toggleWeekday(_ weekday: Int, for label: String) {
        if let index = schedule.firstIndex(where: { $0.weekday == weekday }) {
            // Remove existing day regardless of label
            schedule.remove(at: index)
        } else {
            // Add new day with proper cycling label
            let correctLabel = getCorrectLabelForDay(weekday)
            schedule.append(PlannedDay(weekday: weekday, label: correctLabel))
        }
        // Update all labels after any change
        updateCyclingLabels()
    }

    private func getCorrectLabelForDay(_ weekday: Int) -> String {
        if planType == .fullBody {
            return planType.workoutLabels.first ?? "Full"
        }

        // For A/B/C plans, determine position in cycle
        let sortedDays = schedule.map { $0.weekday }.sorted()

        // Find where this day should be inserted
        let insertPosition = sortedDays.filter { $0 < weekday }.count

        // Get the label based on cycle position
        let labelIndex = insertPosition % planType.workoutLabels.count
        return planType.workoutLabels[labelIndex]
    }

    private func updateCyclingLabels() {
        guard planType != .fullBody else { return }

        // Sort all days chronologically
        let sortedDays = schedule.sorted { $0.weekday < $1.weekday }

        // Update each day with correct cycling label
        for (index, day) in sortedDays.enumerated() {
            let labelIndex = index % planType.workoutLabels.count
            let correctLabel = planType.workoutLabels[labelIndex]

            if let scheduleIndex = schedule.firstIndex(where: { $0.weekday == day.weekday }) {
                schedule[scheduleIndex].label = correctLabel
            }
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
        // Stamp orderIndex by current array order per label, so start workout uses this order
        var counters: [String: Int] = [:]
        for idx in exercises.indices {
            let label = exercises[idx].label ?? planType.workoutLabels.first ?? ""
            let next = counters[label] ?? 0
            exercises[idx].orderIndex = next
            counters[label] = next + 1
        }
        plan.exercises = exercises
        plan.schedule = schedule

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save plan changes: \(error)")
        }
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

// MARK: - Modern Helper Components

struct ScheduleDayChip: View {
    let day: PlannedDay

    var body: some View {
        VStack(spacing: AppTheme.s4) {
            Text(weekdaySymbol(day.weekday))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            if !day.label.isEmpty {
                Text(day.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.accent.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.s10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
        )
    }

    private func weekdaySymbol(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "א׳"
        case 2: return "ב׳"
        case 3: return "ג׳"
        case 4: return "ד׳"
        case 5: return "ה׳"
        case 6: return "ו׳"
        case 7: return "ש׳"
        default: return "?"
        }
    }
}

struct ModernWorkoutTypeButton: View {
    let label: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .padding(.vertical, AppTheme.s10)
                .padding(.horizontal, AppTheme.s16)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accent.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            LinearGradient(
                                colors: [Color(.tertiarySystemBackground), Color(.tertiarySystemBackground)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? AppTheme.accent.opacity(0.3) : Color(.separator), lineWidth: 1)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .shadow(color: isSelected ? AppTheme.accent.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct ModernWeekdayButton: View {
    let weekday: Int
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: AppTheme.s4) {
                Text(weekdaySymbol(weekday))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isSelected ? .white : .primary)

                Circle()
                    .fill(isSelected ? .white.opacity(0.8) : AppTheme.accent.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .opacity(isSelected ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.s12)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [AppTheme.accent, AppTheme.accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color(.tertiarySystemBackground), Color(.tertiarySystemBackground)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accent.opacity(0.3) : Color(.separator).opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(color: isSelected ? AppTheme.accent.opacity(0.2) : .clear, radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
}

// MARK: - Helper Functions

private func planTypeDescription(_ type: PlanType) -> String {
    switch type {
    case .fullBody:
        return "אימון גוף מלא בכל פעם"
    case .ab:
        return "חלוקה לשני אימונים A ו-B"
    case .abc:
        return "חלוקה לשלושה אימונים A, B ו-C"
    case .abcd:
        return "חלוקה לארבעה אימונים A, B, C ו-D"
    case .abcde:
        return "חלוקה לחמישה אימונים A, B, C, D ו-E"
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

struct ModernPlanTypeRow: View {
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
}

struct ModernExerciseRowCard: View {
    let exercise: Exercise
    let onEdit: () -> Void
    let onDelete: () -> Void
    let labelSelector: LabelSelector?

    var body: some View {
        HStack(spacing: AppTheme.s16) {
            // Exercise Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.blue)
            }

            // Exercise Info
            VStack(alignment: .leading, spacing: AppTheme.s8) {
                // Exercise Name
                Text(exercise.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                // Exercise Details
                HStack(spacing: AppTheme.s12) {
                    // Sets & Reps
                    HStack(spacing: 4) {
                        Text("\(exercise.plannedSets)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.blue)

                        Text("סטים")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let reps = exercise.plannedReps {
                        HStack(spacing: 4) {
                            Text("\(reps)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.green)

                            Text("חזרות")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let muscleGroup = exercise.muscleGroup, !muscleGroup.isEmpty {
                        Text(muscleGroup)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .foregroundStyle(Color.orange)
                            .clipShape(Capsule())
                    }
                }

                // Label Selector (if available)
                if let selector = labelSelector {
                    Menu {
                        ForEach(selector.labels, id: \.self) { label in
                            Button(label) { selector.onSelect(label) }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.caption)
                            Text("אימון \(selector.selected)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(Color.blue)
                        .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Action Menu
            Menu {
                Button("ערוך", action: onEdit)
                Button("מחק", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Circle())
            }
        }
        .padding(AppTheme.s16)
        .background(Color(.secondarySystemBackground))
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