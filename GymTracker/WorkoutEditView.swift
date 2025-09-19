//
//  WorkoutEditView.swift
//  GymTracker
//
//  Enhanced Workout Edit View with Better Navigation and UX
//

import SwiftUI
import SwiftData

struct WorkoutEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    @Query private var plans: [WorkoutPlan]
    
    @State private var selectedSegment: EditSegment = .history
    @State private var showNewWorkoutSheet = false
    @State private var editingSession: WorkoutSession?
    @State private var searchText = ""
    @State private var selectedFilter: SessionFilter = .all
    @State private var showFilters = false
    
    // Template-related states
    @State private var selectedTemplateCategory: TemplateCategory = .all
    @State private var showTemplateDetail = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var showCreateTemplate = false
    @State private var templateSearchText = ""
    
    private enum EditSegment: String, CaseIterable {
        case history = "היסטוריה"
        case templates = "תבניות"
        case analytics = "ניתוח"
        
        var icon: String {
            switch self {
            case .history: return "clock.arrow.circlepath"
            case .templates: return "doc.text"
            case .analytics: return "chart.bar.xaxis"
            }
        }
    }
    
    enum SessionFilter: String, CaseIterable {
        case all = "הכל"
        case completed = "הושלמו"
        case incomplete = "לא הושלמו"
        case thisWeek = "השבוע"
        case thisMonth = "החודש"
    }
    
    enum TemplateCategory: String, CaseIterable {
        case all = "הכל"
        case strength = "כוח"
        case hypertrophy = "היפרטרופיה"
        case endurance = "סיבולת"
        case bodyweight = "משקל גוף"
        case cardio = "קרדיו"
        case flexibility = "גמישות"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Enhanced header with search
                headerSection
                
                // Custom segmented control
                segmentedControl
                
                // Content based on selection
                switch selectedSegment {
                case .history:
                    workoutHistoryView
                case .templates:
                    workoutTemplatesView
                case .analytics:
                    workoutAnalyticsView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showNewWorkoutSheet) {
            NewWorkoutSheet()
        }
        .sheet(item: $editingSession) { session in
            WorkoutSessionEditSheet(session: session)
        }
        .sheet(isPresented: $showTemplateDetail) {
            if let template = selectedTemplate {
                TemplateDetailSheet(template: template, onUseTemplate: { useTemplate(template) })
            }
        }
        .sheet(isPresented: $showCreateTemplate) {
            CreateTemplateSheet()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.s16) {
            // Title and actions
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("אימונים")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("ניהול אימונים ותבניות")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: AppTheme.s12) {
                    if selectedSegment == .templates {
                        Button(action: { showCreateTemplate = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    
                    Button(action: { showFilters = true }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                    }
                    
                    Button(action: { showNewWorkoutSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            
            // Search bar
            if selectedSegment == .history {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("חפש אימונים...", text: $searchText)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(AppTheme.s12)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if selectedSegment == .templates {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("חפש תבניות...", text: $templateSearchText)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.plain)
                    
                    if !templateSearchText.isEmpty {
                        Button(action: { templateSearchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(AppTheme.s12)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, AppTheme.s16)
        .padding(.top, AppTheme.s8)
    }
    
    // MARK: - Segmented Control
    
    private var segmentedControl: some View {
        HStack(spacing: 0) {
                    ForEach(EditSegment.allCases, id: \.self) { segment in
                        Button(action: { 
                                selectedSegment = segment
                }) {
                    VStack(spacing: 4) {
                                    Image(systemName: segment.icon)
                            .font(.system(size: 16, weight: .medium))
                                
                                Text(segment.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            }
                    .foregroundStyle(selectedSegment == segment ? AppTheme.accent : .secondary)
                            .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.s12)
                            .background(
                        selectedSegment == segment ? AppTheme.accent.opacity(0.1) : Color.clear
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, AppTheme.s16)
    }
    
    // MARK: - Workout History View
    
    private var workoutHistoryView: some View {
        ScrollView {
            VStack(spacing: AppTheme.s16) {
                // Quick stats
                historyStatsSection
                
                // Progress insights
                progressInsightsSection
                
                // Sessions list
                LazyVStack(spacing: AppTheme.s12) {
                    ForEach(filteredSessions) { session in
                        WorkoutSessionCard(
                                session: session,
                                onEdit: { editingSession = session },
                            onDuplicate: { duplicateSession(session) },
                                onDelete: { deleteSession(session) }
                            )
                    }
                }
            }
            .padding(.horizontal, AppTheme.s16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Workout Templates View
    
    private var workoutTemplatesView: some View {
        ScrollView {
            VStack(spacing: AppTheme.s16) {
                // Template stats
                templateStatsSection
                
                // Category filter
                templateCategoryFilter
                
                // Featured templates
                featuredTemplatesSection
                
                // Category-based templates
                categoryTemplatesSection
                
                // Custom templates
                customTemplatesSection
                
                // Quick actions
                quickActionsSection
            }
            .padding(.horizontal, AppTheme.s16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Workout Analytics View
    
    private var workoutAnalyticsView: some View {
        ScrollView {
            VStack(spacing: AppTheme.s16) {
                // Analytics overview
                analyticsOverviewSection
                
                // Progress charts
                progressChartsSection
                
                // Exercise analysis
                exerciseAnalysisSection
            }
            .padding(.horizontal, AppTheme.s16)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Progress Insights Section
    
    private var progressInsightsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("תובנות התקדמות")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: AppTheme.s8) {
                ProgressInsightRow(
                    icon: "arrow.up.circle.fill",
                    title: "התקדמות השבוע",
                    value: String(format: "+%.1f%%", averageImprovement),
                    color: AppTheme.success
                )
                
                ProgressInsightRow(
                    icon: "dumbbell.fill",
                    title: "תרגילים שונים",
                    value: "\(uniqueExercises) תרגילים",
                    color: AppTheme.accent
                )
                
                ProgressInsightRow(
                    icon: "list.number",
                    title: "סטים השבוע",
                    value: "\(thisWeekSets) סטים",
                    color: AppTheme.warning
                )
                
                ProgressInsightRow(
                    icon: "trophy.fill",
                    title: "שיאים אישיים",
                    value: "\(personalRecords) תרגילים",
                    color: AppTheme.error
                )
            }
        }
        .appCard()
    }
    
    // MARK: - History Stats Section
    
    private var historyStatsSection: some View {
        VStack(spacing: AppTheme.s16) {
            // Main workout stats
            HStack(spacing: AppTheme.s12) {
                StatCard(
                    title: "סה״כ אימונים",
                    value: "\(sessions.count)",
                    icon: "figure.strengthtraining.traditional",
                    color: AppTheme.accent
                )
                
                StatCard(
                    title: "הושלמו",
                    value: "\(completedSessions)",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.success
                )
                
                StatCard(
                    title: "השבוע",
                    value: "\(thisWeekSessions)",
                    icon: "calendar.badge.checkmark",
                    color: AppTheme.warning
                )
            }
            
            // Progress metrics
            HStack(spacing: AppTheme.s12) {
                StatCard(
                    title: "תרגילים שונים",
                    value: "\(uniqueExercises)",
                    icon: "dumbbell.fill",
                    color: AppTheme.info
                )
                
                StatCard(
                    title: "שיאים אישיים",
                    value: "\(personalRecords)",
                    icon: "trophy.fill",
                    color: AppTheme.error
                )
                
                StatCard(
                    title: "עקביות",
                    value: String(format: "%.0f%%", workoutConsistency),
                    icon: "chart.line.uptrend.xyaxis",
                    color: AppTheme.success
                )
            }
        }
    }
    
    // MARK: - Template Stats Section
    
    private var templateStatsSection: some View {
        VStack(spacing: AppTheme.s12) {
            // Template overview
            HStack(spacing: AppTheme.s12) {
                StatCard(
                    title: "סה״כ תבניות",
                    value: "\(allTemplates.count)",
                    icon: "doc.text",
                    color: AppTheme.accent
                )
                
                StatCard(
                    title: "קטגוריות",
                    value: "\(TemplateCategory.allCases.count - 1)",
                    icon: "folder.fill",
                    color: AppTheme.success
                )
                
                StatCard(
                    title: "מותאמות",
                    value: "\(customTemplates.count)",
                    icon: "person.fill",
                    color: AppTheme.warning
                )
            }
            
            // Template usage stats
            HStack(spacing: AppTheme.s12) {
                StatCard(
                    title: "תבניות מומלצות",
                    value: "\(featuredTemplates.count)",
                    icon: "star.fill",
                    color: AppTheme.info
                )
                
                StatCard(
                    title: "תבניות קטגוריה",
                    value: "\(categoryTemplates.count)",
                    icon: "square.grid.2x2",
                    color: AppTheme.accent
                )
                
                StatCard(
                    title: "תבניות ריקות",
                    value: "\(customTemplates.isEmpty ? "כן" : "לא")",
                    icon: "exclamationmark.triangle.fill",
                    color: AppTheme.error
                )
            }
        }
    }
    
    // MARK: - Template Category Filter
    
    private var templateCategoryFilter: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("קטגוריות")
                .font(.headline)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.s8) {
                    ForEach(TemplateCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedTemplateCategory = category
                        }) {
                            HStack(spacing: AppTheme.s6) {
                                Image(systemName: categoryIcon(for: category))
                                    .font(.caption)
                                
                                Text(category.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, AppTheme.s12)
                            .padding(.vertical, AppTheme.s8)
                            .background(
                                selectedTemplateCategory == category ? AppTheme.accent : AppTheme.secondaryBackground,
                                in: Capsule()
                            )
                            .foregroundStyle(selectedTemplateCategory == category ? .white : AppTheme.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.s16)
            }
        }
        .appCard()
    }
    
    // MARK: - Featured Templates Section
    
    private var featuredTemplatesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            HStack {
                Text("תבניות מומלצות")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("הצג הכל") {
                    // Show all featured templates
                }
                .font(.caption)
                .foregroundStyle(AppTheme.accent)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.s16) {
                    ForEach(featuredTemplates, id: \.name) { template in
                        FeaturedTemplateCard(template: template) {
                            selectedTemplate = template
                            showTemplateDetail = true
                        }
                    }
                }
                .padding(.horizontal, AppTheme.s16)
            }
        }
        .appCard()
    }
    
    // MARK: - Category Templates Section
    
    private var categoryTemplatesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("תבניות \(selectedTemplateCategory.rawValue)")
                .font(.headline)
                .fontWeight(.bold)
            
            if filteredTemplates.isEmpty {
                EmptyStateView(
                    iconSystemName: "doc.text.magnifyingglass",
                    title: "אין תבניות בקטגוריה זו",
                    message: "נסה קטגוריה אחרת או צור תבנית חדשה",
                    buttonTitle: "צור תבנית"
                ) {
                    showCreateTemplate = true
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.s12) {
                    ForEach(filteredTemplates, id: \.name) { template in
                        TemplateGridCard(template: template) {
                            selectedTemplate = template
                            showTemplateDetail = true
                        }
                    }
                }
            }
        }
        .appCard()
    }
    
    // MARK: - Custom Templates Section
    
    private var customTemplatesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            HStack {
                Text("התבניות שלי")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showCreateTemplate = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accent)
                }
            }
            
            if customTemplates.isEmpty {
                    EmptyStateView(
                        iconSystemName: "doc.text",
                    title: "אין תבניות מותאמות",
                    message: "צור תבנית מותאמת אישית",
                    buttonTitle: "צור תבנית"
                ) {
                    showCreateTemplate = true
                }
                } else {
                LazyVStack(spacing: AppTheme.s12) {
                    ForEach(customTemplates) { template in
                        CustomTemplateCard(template: template) {
                            selectedTemplate = template
                            showTemplateDetail = true
                        }
                    }
                }
            }
        }
        .appCard()
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("פעולות מהירות")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.s12) {
                QuickActionCard(
                    title: "צור תבנית",
                    subtitle: "תבנית חדשה",
                    icon: "plus.circle.fill",
                    color: AppTheme.accent
                ) {
                    showCreateTemplate = true
                }
                
                QuickActionCard(
                    title: "ייבא תבנית",
                    subtitle: "מקובץ או קישור",
                    icon: "square.and.arrow.down.fill",
                    color: AppTheme.success
                ) {
                    // Import template
                }
                
                QuickActionCard(
                    title: "תבניות פופולריות",
                    subtitle: "מהקהילה",
                    icon: "star.fill",
                    color: AppTheme.warning
                ) {
                    // Show popular templates
                }
                
                QuickActionCard(
                    title: "הגדרות תבניות",
                    subtitle: "התאמה אישית",
                    icon: "gearshape.fill",
                    color: AppTheme.error
                ) {
                    // Template settings
                }
            }
        }
        .appCard()
    }
    
    // MARK: - Analytics Overview Section
    
    private var analyticsOverviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            Text("סקירה כללית")
                .font(.headline)
                .fontWeight(.bold)
            
            // Main analytics cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
            ], spacing: AppTheme.s12) {
                AnalyticsCard(
                    title: "זמן ממוצע",
                    value: averageWorkoutDuration,
                    subtitle: "לכל אימון",
                    icon: "clock.fill",
                    color: AppTheme.accent
                )
                
                AnalyticsCard(
                    title: "עקביות",
                    value: String(format: "%.0f%%", workoutConsistency),
                    subtitle: "ב-30 יום האחרונים",
                    icon: "calendar.badge.checkmark",
                    color: AppTheme.success
                )
                
                AnalyticsCard(
                    title: "תרגילים שונים",
                    value: "\(uniqueExercises)",
                    subtitle: "תרגילים",
                    icon: "dumbbell.fill",
                    color: AppTheme.warning
                )
                
                AnalyticsCard(
                    title: "שיאים אישיים",
                    value: "\(personalRecords)",
                    subtitle: "תרגילים",
                    icon: "trophy.fill",
                    color: AppTheme.error
                )
            }
            
            // Weekly progress metrics
            VStack(alignment: .leading, spacing: AppTheme.s12) {
                Text("התקדמות השבוע")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primary)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: AppTheme.s8) {
                    ProgressMetricCard(
                        title: "סטים השבוע",
                        value: "\(thisWeekSets)",
                        icon: "list.number",
                        color: AppTheme.accent
                    )
                    
                    ProgressMetricCard(
                        title: "שיפור ממוצע",
                        value: String(format: "+%.1f%%", averageImprovement),
                        icon: "arrow.up.circle.fill",
                        color: AppTheme.success
                    )
                    
                    ProgressMetricCard(
                        title: "אימונים השבוע",
                        value: "\(thisWeekSessions)",
                        icon: "calendar.badge.checkmark",
                        color: AppTheme.warning
                    )
                }
            }
        }
        .appCard()
    }
    
    // MARK: - Progress Charts Section
    
    private var progressChartsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("גרפי התקדמות")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("תכונה זו תגיע בקרוב")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(AppTheme.s24)
        }
        .appCard()
    }
    
    // MARK: - Exercise Analysis Section
    
    private var exerciseAnalysisSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            Text("ניתוח תרגילים")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("תכונה זו תגיע בקרוב")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(AppTheme.s24)
        }
        .appCard()
    }
    
    // MARK: - Computed Properties
    
    private var filteredSessions: [WorkoutSession] {
        var filtered = sessions
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { session in
                session.workoutLabel?.localizedCaseInsensitiveContains(searchText) == true ||
                session.planName?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Filter by selected filter
        switch selectedFilter {
        case .all:
            break
        case .completed:
            filtered = filtered.filter { $0.isCompleted == true }
        case .incomplete:
            filtered = filtered.filter { $0.isCompleted != true }
        case .thisWeek:
            let calendar = Calendar.current
            filtered = filtered.filter { session in
                calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: Date())
            }
        case .thisMonth:
            let calendar = Calendar.current
            filtered = filtered.filter { session in
                calendar.dateInterval(of: .month, for: session.date) == calendar.dateInterval(of: .month, for: Date())
            }
        }
        
        return filtered
    }
    
    private var completedSessions: Int {
        sessions.filter { $0.isCompleted == true }.count
    }
    
    private var thisWeekSessions: Int {
        let calendar = Calendar.current
        return sessions.filter { session in
            calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: Date())
        }.count
    }
    
    private var averageWorkoutDuration: String {
        let completedSessions = sessions.filter { $0.isCompleted ?? false }
        guard !completedSessions.isEmpty else { return "0 דק׳" }
        
        let totalDuration = completedSessions.compactMap { $0.durationSeconds }.reduce(0, +)
        guard totalDuration > 0 else { return "0 דק׳" }
        
        let avgDuration = Double(totalDuration) / Double(completedSessions.count)
        let minutes = Int(avgDuration / 60)
        return "\(minutes) דק׳"
    }
    
    
    
    private var personalRecords: Int {
        // Count exercises where user achieved new max weight
        let exerciseMaxWeights = sessions.flatMap { $0.exerciseSessions }
            .reduce(into: [String: Double]()) { result, exerciseSession in
                let maxWeight = exerciseSession.setLogs.map { $0.weight }.max() ?? 0
                let currentMax = result[exerciseSession.exerciseName] ?? 0
                result[exerciseSession.exerciseName] = max(currentMax, maxWeight)
            }
        
        // This is a simplified version - in reality you'd compare with historical data
        return exerciseMaxWeights.count
    }
    
    private var workoutConsistency: Double {
        let calendar = Calendar.current
        let last30Days = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let recentSessions = sessions.filter { $0.date >= last30Days && ($0.isCompleted ?? false) }
        let expectedWorkouts = 30.0 / 3.0 // Assuming 3 workouts per week
        
        return min(100.0, (Double(recentSessions.count) / expectedWorkouts) * 100.0)
    }
    
    private var uniqueExercises: Int {
        let allExercises = sessions.flatMap { $0.exerciseSessions }.map { $0.exerciseName }
        return Set(allExercises).count
    }
    
    private var thisWeekSets: Int {
        let calendar = Calendar.current
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: Date()) ?? DateInterval()
        
        return sessions.filter { session in
            thisWeek.contains(session.date) && (session.isCompleted ?? false)
        }.flatMap { $0.exerciseSessions }.flatMap { $0.setLogs }.count
    }
    
    private var averageImprovement: Double {
        // Calculate improvement by comparing recent sessions with older ones
        let calendar = Calendar.current
        let last14Days = calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let previous14Days = calendar.date(byAdding: .day, value: -28, to: Date()) ?? Date()
        
        let recentSessions = sessions.filter { $0.date >= last14Days && ($0.isCompleted ?? false) }
        let previousSessions = sessions.filter { 
            $0.date >= previous14Days && $0.date < last14Days && ($0.isCompleted ?? false)
        }
        
        guard !recentSessions.isEmpty && !previousSessions.isEmpty else { return 0.0 }
        
        let recentAvgWeight = recentSessions.flatMap { $0.exerciseSessions }
            .flatMap { $0.setLogs }.map { $0.weight }.reduce(0, +) / Double(recentSessions.flatMap { $0.exerciseSessions }.flatMap { $0.setLogs }.count)
        
        let previousAvgWeight = previousSessions.flatMap { $0.exerciseSessions }
            .flatMap { $0.setLogs }.map { $0.weight }.reduce(0, +) / Double(previousSessions.flatMap { $0.exerciseSessions }.flatMap { $0.setLogs }.count)
        
        guard previousAvgWeight > 0 else { return 0.0 }
        return ((recentAvgWeight - previousAvgWeight) / previousAvgWeight) * 100.0
    }
    
    
    private var allTemplates: [WorkoutTemplate] {
        featuredTemplates + categoryTemplates + customTemplates
    }
    
    private var featuredTemplates: [WorkoutTemplate] {
        [
            WorkoutTemplate(
                name: "Push/Pull/Legs",
                description: "תבנית פופולרית לפיתוח שריר",
                exercises: 12,
                duration: "60-90 דק׳",
                category: .hypertrophy,
                difficulty: .intermediate,
                isFeatured: true
            ),
            WorkoutTemplate(
                name: "5x5 Stronglifts",
                description: "תבנית לפיתוח כוח",
                exercises: 5,
                duration: "45-60 דק׳",
                category: .strength,
                difficulty: .beginner,
                isFeatured: true
            ),
            WorkoutTemplate(
                name: "Full Body HIIT",
                description: "אימון אינטנסיבי לכל הגוף",
                exercises: 8,
                duration: "30-45 דק׳",
                category: .cardio,
                difficulty: .advanced,
                isFeatured: true
            )
        ]
    }
    
    private var categoryTemplates: [WorkoutTemplate] {
        let templates = [
            WorkoutTemplate(
                name: "Upper/Lower Split",
                description: "תבנית מאוזנת לפיתוח כוח",
                exercises: 8,
                duration: "45-60 דק׳",
                category: .strength,
                difficulty: .intermediate,
                isFeatured: false
            ),
            WorkoutTemplate(
                name: "Bodyweight Basics",
                description: "תרגילי משקל גוף למתחילים",
                exercises: 6,
                duration: "30-45 דק׳",
                category: .bodyweight,
                difficulty: .beginner,
                isFeatured: false
            ),
            WorkoutTemplate(
                name: "Muscle Building",
                description: "תבנית להיפרטרופיה",
                exercises: 10,
                duration: "60-75 דק׳",
                category: .hypertrophy,
                difficulty: .intermediate,
                isFeatured: false
            ),
            WorkoutTemplate(
                name: "Cardio Blast",
                description: "אימון קרדיו אינטנסיבי",
                exercises: 6,
                duration: "25-35 דק׳",
                category: .cardio,
                difficulty: .advanced,
                isFeatured: false
            ),
            WorkoutTemplate(
                name: "Flexibility Flow",
                description: "תרגילי גמישות ויוגה",
                exercises: 8,
                duration: "40-50 דק׳",
                category: .flexibility,
                difficulty: .beginner,
                isFeatured: false
            )
        ]
        
        if selectedTemplateCategory == .all {
            return templates
        } else {
            return templates.filter { $0.category == selectedTemplateCategory }
        }
    }
    
    private var customTemplates: [WorkoutTemplate] {
        // Return user's custom templates
        []
    }
    
    private var filteredTemplates: [WorkoutTemplate] {
        var templates = categoryTemplates
        
        if !templateSearchText.isEmpty {
            templates = templates.filter { template in
                template.name.localizedCaseInsensitiveContains(templateSearchText) ||
                template.description.localizedCaseInsensitiveContains(templateSearchText)
            }
        }
        
        return templates
    }
    
    // MARK: - Helper Functions
    
    private func categoryIcon(for category: TemplateCategory) -> String {
        switch category {
        case .all: return "square.grid.2x2"
        case .strength: return "dumbbell.fill"
        case .hypertrophy: return "figure.strengthtraining.traditional"
        case .endurance: return "heart.fill"
        case .bodyweight: return "figure.walk"
        case .cardio: return "heart.circle.fill"
        case .flexibility: return "figure.yoga"
        }
    }
    
    private func useTemplate(_ template: WorkoutTemplate) {
        // Convert template to workout plan and start workout
        showTemplateDetail = false
        // Implementation would create a workout from template
    }
    
    // MARK: - Actions
    
    private func duplicateSession(_ session: WorkoutSession) {
        let newSession = WorkoutSession(
            date: Date(),
            planName: session.planName,
            workoutLabel: session.workoutLabel,
            durationSeconds: nil,
            notes: session.notes,
            isCompleted: false,
            exerciseSessions: session.exerciseSessions.map { exerciseSession in
                ExerciseSession(exerciseName: exerciseSession.exerciseName, setLogs: [])
            }
        )
        modelContext.insert(newSession)
    }
    
    private func deleteSession(_ session: WorkoutSession) {
            modelContext.delete(session)
    }
}

// MARK: - Supporting Views and Models

struct WorkoutTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let exercises: Int
    let duration: String
    let category: WorkoutEditView.TemplateCategory
    let difficulty: Difficulty
    let isFeatured: Bool
    
    enum Difficulty: String, CaseIterable {
        case beginner = "מתחיל"
        case intermediate = "בינוני"
        case advanced = "מתקדם"
        
        var color: Color {
            switch self {
            case .beginner: return AppTheme.success
            case .intermediate: return AppTheme.warning
            case .advanced: return AppTheme.error
            }
        }
    }
}

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

struct TemplateCategoryCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.s8) {
            Image(systemName: icon)
                        .font(.title2)
                .foregroundStyle(color)
            
            Text(title)
                .font(.subheadline)
                                .fontWeight(.bold)
                            
            Text(description)
                .font(.caption)
                        .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s16)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}

struct FeaturedTemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            // Header with badge
            HStack {
                Text("מומלץ")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.s8)
                    .padding(.vertical, AppTheme.s4)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.warning)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.s8) {
                Text(template.name)
                            .font(.headline)
                            .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primary)
                
                Text(template.description)
                            .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(template.exercises)", systemImage: "dumbbell")
                    Spacer()
                    Label(template.duration, systemImage: "clock")
                }
                .font(.caption2)
                .foregroundStyle(AppTheme.secondary)
            }
            
            Spacer()
            
            Button("השתמש בתבנית") {
                onTap()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.s8)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(AppTheme.s16)
        .frame(width: 200, height: 180)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct TemplateGridCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            HStack {
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primary)
                
                Spacer()
                
                Circle()
                    .fill(template.difficulty.color)
                    .frame(width: 8, height: 8)
            }
            
            Text(template.description)
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .lineLimit(2)
            
            HStack {
                Label("\(template.exercises)", systemImage: "dumbbell")
                Spacer()
                Label(template.duration, systemImage: "clock")
            }
            .font(.caption2)
            .foregroundStyle(AppTheme.secondary)
                
                    Button("השתמש") {
                onTap()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.s6)
            .background(AppTheme.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(AppTheme.s12)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}

struct CustomTemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.s12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
                    }
                    
                    Spacer()
            
            VStack(spacing: 4) {
                Text("\(template.exercises)")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("תרגילים")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondary)
            }
            
            Button(action: onTap) {
                Image(systemName: "chevron.forward")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(AppTheme.s16)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.s8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.s16)
            .background(AppTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
        }
        .buttonStyle(.plain)
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.s8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s12)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}

struct ProgressMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.s6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s8)
        .background(AppTheme.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ProgressInsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.s12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.primary)
                
                Text(value)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            
            Spacer()
        }
        .padding(AppTheme.s12)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                
                                    Image(systemName: "chevron.forward")
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
                                    
                                    TextField("A", text: $workoutLabel)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
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
                
                Spacer()
            }
                .padding(AppTheme.s24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("התחל אימון") {
                        startWorkout()
                    }
                    .disabled(selectedPlan == nil)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showPlanPicker) {
            PlanPickerSheet(selectedPlan: $selectedPlan)
        }
    }
    
    private func startWorkout() {
        guard let plan = selectedPlan else { return }
        
        let newSession = WorkoutSession(
            date: Date(),
            planName: plan.name,
            workoutLabel: workoutLabel.isEmpty ? "A" : workoutLabel,
            durationSeconds: nil,
            notes: notes.isEmpty ? nil : notes,
            isCompleted: false,
            exerciseSessions: plan.exercises.map { exercise in
                ExerciseSession(exerciseName: exercise.name, setLogs: [])
            }
        )
        
        modelContext.insert(newSession)
        dismiss()
    }
}

struct WorkoutSessionEditSheet: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    
    @State private var workoutLabel: String
    @State private var notes: String
    @State private var isCompleted: Bool
    @State private var showDeleteConfirmation = false
    @State private var showExerciseDetails = false
    @State private var selectedExercise: ExerciseSession?
    @State private var durationMinutes: Int
    @State private var durationSeconds: Int
    
    init(session: WorkoutSession) {
        self.session = session
        self._workoutLabel = State(initialValue: session.workoutLabel ?? "A")
        self._notes = State(initialValue: session.notes ?? "")
        self._isCompleted = State(initialValue: session.isCompleted ?? false)
        
        let totalSeconds = session.durationSeconds ?? 0
        self._durationMinutes = State(initialValue: totalSeconds / 60)
        self._durationSeconds = State(initialValue: totalSeconds % 60)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s24) {
                    // Header (modern card)
                    VStack(spacing: AppTheme.s12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accent.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Text(currentWorkoutLabel)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                        }
                        Text("עריכת אימון")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text(session.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.s24)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Workout details (card)
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
                                
                                if allowedLabels.count > 1 {
                                    HStack(spacing: AppTheme.s8) {
                                        ForEach(allowedLabels, id: \.self) { label in
                                            Button(action: { workoutLabel = label }) {
                                                Text(label)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .padding(.vertical, AppTheme.s8)
                                                    .padding(.horizontal, AppTheme.s12)
                                                    .background(workoutLabel == label ? AppTheme.accent.opacity(0.2) : AppTheme.cardBG)
                                                    .foregroundStyle(workoutLabel == label ? AppTheme.accent : .primary)
                                                    .clipShape(Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                } else {
                                    TextField("A", text: $workoutLabel)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            
                            // Duration
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("זמן אימון")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.primary)
                                
                                HStack(spacing: AppTheme.s16) {
                                    VStack {
                                        Text("דקות")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondary)
                                        Stepper(value: $durationMinutes, in: 0...300) {
                                            Text("\(durationMinutes)")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    
                                    Text(":")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    VStack {
                                        Text("שניות")
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondary)
                                        Stepper(value: $durationSeconds, in: 0...59) {
                                            Text("\(durationSeconds)")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                        }
                                    }
                                }
                            }
                            
                            // Completion status
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("סטטוס")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.primary)
                                
                                Toggle("אימון הושלם", isOn: $isCompleted)
                                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.accent))
                            }
                            
                            // Notes
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("הערות")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.primary)
                                
                                TextField("הוסף הערות לאימון...", text: $notes, axis: .vertical)
                                    .multilineTextAlignment(.trailing)
                                    .lineLimit(3...6)
                                    .padding(AppTheme.s12)
                                    .background(AppTheme.cardBG)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(20)
                    .background(AppTheme.cardBG)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    // Exercises section
                    VStack(alignment: .leading, spacing: AppTheme.s16) {
                        HStack {
                            Text("תרגילים")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button("הצג פרטים") {
                                showExerciseDetails = true
                            }
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppTheme.s8) {
                            ForEach(session.exerciseSessions, id: \.exerciseName) { exerciseSession in
                                ExerciseSummaryCard(exerciseSession: exerciseSession) {
                                    selectedExercise = exerciseSession
                                    showExerciseDetails = true
                                }
                            }
                        }
                    }
                    
                    // Session statistics
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
                                    title: "תרגילים",
                                    value: "\(session.exerciseSessions.count)",
                                icon: "dumbbell.fill",
                                color: AppTheme.accent
                                )
                                
                            StatCard(
                                    title: "סטים",
                                value: "\(totalSets)",
                                icon: "list.number",
                                color: AppTheme.success
                            )
                            
                            StatCard(
                                title: "זמן",
                                value: formatDuration(session.durationSeconds),
                                icon: "clock.fill",
                                color: AppTheme.warning
                            )
                        }
                    }
                    
                    // Danger zone
                    VStack(alignment: .leading, spacing: AppTheme.s12) {
                        Text("אזור מסוכן")
                                .font(.headline)
                                .fontWeight(.bold)
                            .foregroundStyle(AppTheme.error)
                        
                        Button("מחק אימון") {
                            showDeleteConfirmation = true
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(AppTheme.error)
                        .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                }
                .padding(AppTheme.s24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") { saveChanges() }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .background(AppTheme.screenBG)
        .alert("מחק אימון", isPresented: $showDeleteConfirmation) {
            Button("מחק", role: .destructive) {
                deleteSession()
            }
            Button("ביטול", role: .cancel) {}
        } message: {
            Text("האם אתה בטוח שברצונך למחוק את האימון? פעולה זו לא ניתנת לביטול.")
        }
        .sheet(isPresented: $showExerciseDetails) {
            if let exercise = selectedExercise {
                ExerciseDetailsSheet(exerciseSession: exercise)
            }
        }
    }

    private var allowedLabels: [String] {
        if let planName = session.planName,
           let plan = plans.first(where: { $0.name == planName }) {
            return plan.planType.workoutLabels
        }
        return ["A"]
    }

    private var currentWorkoutLabel: String {
        workoutLabel.isEmpty ? (allowedLabels.first ?? "A") : workoutLabel
    }
    
    private var totalSets: Int {
        session.exerciseSessions.reduce(0) { $0 + $1.setLogs.count }
    }
    
    private func formatDuration(_ seconds: Int?) -> String {
        guard let seconds = seconds else { return "לא ידוע" }
        let minutes = seconds / 60
        return "\(minutes) דק׳"
    }
    
    private func saveChanges() {
        session.workoutLabel = workoutLabel.isEmpty ? "A" : workoutLabel
        session.notes = notes.isEmpty ? nil : notes
        session.isCompleted = isCompleted
        session.durationSeconds = (durationMinutes * 60) + durationSeconds
        
        try? modelContext.save()
        dismiss()
    }
    
    private func deleteSession() {
        modelContext.delete(session)
        try? modelContext.save()
        dismiss()
    }
}

struct TemplateDetailSheet: View {
    let template: WorkoutTemplate
    let onUseTemplate: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s24) {
                    // Template header
                    VStack(spacing: AppTheme.s16) {
                        Text(template.name)
                            .font(.title)
                .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(template.description)
                            .font(.body)
                            .foregroundStyle(AppTheme.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: AppTheme.s16) {
                            Label("\(template.exercises) תרגילים", systemImage: "dumbbell")
                            Label(template.duration, systemImage: "clock")
                            Label(template.difficulty.rawValue, systemImage: "chart.bar")
                        }
                .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                    }
                    
                    // Template details
                    VStack(alignment: .leading, spacing: AppTheme.s16) {
                        Text("פרטי התבנית")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("תכונה זו תגיע בקרוב - כאן יוצגו התרגילים והסטים של התבנית")
                            .font(.body)
                            .foregroundStyle(AppTheme.secondary)
                    }
                    
                    Spacer()
                    
                    Button("השתמש בתבנית") {
                        onUseTemplate()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
        .frame(maxWidth: .infinity)
                }
                .padding(AppTheme.s24)
            }
            .navigationTitle("פרטי תבנית")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("סגור") { dismiss() }
                }
            }
        }
    }
}

struct SelectedPlanCard: View {
    let plan: WorkoutPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.s12) {
                VStack(alignment: .leading, spacing: AppTheme.s4) {
                    Text(plan.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primary)
                    
                    Text("\(plan.exercises.count) תרגילים")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.forward")
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

struct PlanPickerSheet: View {
    @Binding var selectedPlan: WorkoutPlan?
    @Environment(\.dismiss) private var dismiss
    @Query private var plans: [WorkoutPlan]
    
    var body: some View {
        NavigationStack {
            List(plans) { plan in
                Button(action: {
                    selectedPlan = plan
                        dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name)
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundStyle(AppTheme.primary)
                            
                            Text("\(plan.exercises.count) תרגילים")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedPlan?.id == plan.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("בחר תוכנית")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
            }
        }
    }
}

struct TemplatePreviewCard: View {
    let name: String
    let description: String
    let category: WorkoutEditView.TemplateCategory
    let difficulty: WorkoutTemplate.Difficulty
    let exercises: Int
    let duration: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            HStack {
                Text(name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primary)
                
                Spacer()
                
                Circle()
                    .fill(difficulty.color)
                    .frame(width: 8, height: 8)
            }
            
            Text(description)
                    .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .lineLimit(2)
            
            HStack {
                Label("\(exercises)", systemImage: "dumbbell")
                Spacer()
                Label(duration, systemImage: "clock")
            }
            .font(.caption2)
            .foregroundStyle(AppTheme.secondary)
        }
        .padding(AppTheme.s16)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}

struct CreateTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var templateName = ""
    @State private var templateDescription = ""
    @State private var selectedCategory: WorkoutEditView.TemplateCategory = .strength
    @State private var selectedDifficulty: WorkoutTemplate.Difficulty = .beginner
    @State private var estimatedDuration = "45-60 דק׳"
    @State private var exerciseCount = 8
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s24) {
                    // Header
                    VStack(spacing: AppTheme.s16) {
                        Text("צור תבנית חדשה")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("צור תבנית אימון מותאמת אישית")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Template details
                    VStack(alignment: .leading, spacing: AppTheme.s16) {
                        Text("פרטי התבנית")
                            .font(.headline)
                .fontWeight(.bold)
            
                        VStack(spacing: AppTheme.s16) {
                            // Template name
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("שם התבנית")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.primary)
                                
                                TextField("שם התבנית...", text: $templateName)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.headline)
                            }
                            
                            // Template description
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("תיאור")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.primary)
                                
                                TextField("תיאור התבנית...", text: $templateDescription, axis: .vertical)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(2...4)
                            }
                            
                            // Category selection
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("קטגוריה")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.primary)
                                
                                Picker("קטגוריה", selection: $selectedCategory) {
                                    ForEach(WorkoutEditView.TemplateCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                                        Text(category.rawValue).tag(category)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            // Difficulty selection
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("רמת קושי")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.primary)
                                
                                Picker("רמת קושי", selection: $selectedDifficulty) {
                                    ForEach(WorkoutTemplate.Difficulty.allCases, id: \.self) { difficulty in
                                        Text(difficulty.rawValue).tag(difficulty)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            // Exercise count
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("מספר תרגילים")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.primary)
                                
                                Stepper(value: $exerciseCount, in: 1...20) {
                                    Text("\(exerciseCount) תרגילים")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            // Estimated duration
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("זמן משוער")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppTheme.primary)
                                
                                TextField("זמן משוער...", text: $estimatedDuration)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    
                    // Template preview
                    VStack(alignment: .leading, spacing: AppTheme.s12) {
                        Text("תצוגה מקדימה")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        TemplatePreviewCard(
                            name: templateName.isEmpty ? "שם התבנית" : templateName,
                            description: templateDescription.isEmpty ? "תיאור התבנית" : templateDescription,
                            category: selectedCategory,
                            difficulty: selectedDifficulty,
                            exercises: exerciseCount,
                            duration: estimatedDuration
                        )
                    }
                    
                    Spacer()
                }
                .padding(AppTheme.s24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("צור תבנית") {
                        createTemplate()
                    }
                    .disabled(templateName.isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private func createTemplate() {
        // Create template logic would go here
        // For now, just dismiss
        dismiss()
    }
}

struct ExerciseSummaryCard: View {
    let exerciseSession: ExerciseSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.s8) {
                HStack {
            Text(exerciseSession.exerciseName)
                .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.forward")
                .font(.caption)
                        .foregroundStyle(AppTheme.secondary)
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
        .buttonStyle(.plain)
    }
}

struct ExerciseDetailsSheet: View {
    let exerciseSession: ExerciseSession
    @Environment(\.dismiss) private var dismiss
    
    private var totalVolume: Double {
        exerciseSession.setLogs.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
    
    private var averageRPE: Double {
        guard !exerciseSession.setLogs.isEmpty else { return 0 }
        let totalRPE = exerciseSession.setLogs.reduce(0.0) { total, setLog in
            total + (setLog.rpe ?? 0.0)
        }
        return totalRPE / Double(exerciseSession.setLogs.count)
    }
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.s16) {
            Text(exerciseSession.exerciseName)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("\(exerciseSession.setLogs.count) סטים")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondary)
        }
    }
    
    private var setsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            Text("סטים")
                .font(.headline)
                .fontWeight(.bold)
            
            if exerciseSession.setLogs.isEmpty {
                EmptyStateView(
                    iconSystemName: "list.number",
                    title: "אין סטים",
                    message: "לא נרשמו סטים לתרגיל זה",
                    buttonTitle: nil
                ) {}
            } else {
                LazyVStack(spacing: AppTheme.s8) {
                    ForEach(Array(exerciseSession.setLogs.enumerated()), id: \.offset) { index, setLog in
                        SetDetailRow(
                            setNumber: index + 1,
                            reps: setLog.reps,
                            weight: setLog.weight,
                            rpe: setLog.rpe ?? 0.0
                        )
                    }
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
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s24) {
                    headerSection
                    setsSection
                    statisticsSection
                    Spacer()
                }
                .padding(AppTheme.s24)
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

#Preview {
    WorkoutEditView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}


