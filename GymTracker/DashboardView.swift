import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var plans: [WorkoutPlan]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    @Query private var settingsList: [AppSettings]
    @State private var showNewPlanSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s16) {
                    nextWorkoutCard
                    lastWorkoutCard
                }
                .padding(.top, AppTheme.s16)
                .padding(.bottom, AppTheme.s24)
            }
            .background(AppTheme.screenBG)
            .navigationTitle("לוח")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showNewPlanSheet) {
            NewPlanSheet()
        }
    }
    
    private var headerView: some View {
        Text("לוח")
            .font(.largeTitle)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, AppTheme.s16)
    }
    
    private var nextWorkoutCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            Text("האימון הבא")
                .font(.headline)
                .fontWeight(.bold)
            
            if let nextPlan = getNextWorkoutPlan() {
                HStack {
                    Text(nextPlan.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if let todayLabel = getTodayWorkoutLabel(for: nextPlan) {
                        PillBadge(text: todayLabel, icon: "calendar")
                    }
                }
            } else {
                EmptyStateView(
                    iconSystemName: "calendar.badge.exclamationmark",
                    title: "אין תוכנית עדיין",
                    message: "צור תוכנית כדי לראות את האימון הבא.",
                    buttonTitle: "תוכנית חדשה"
                ) {
                    showNewPlanSheet = true
                }
            }
        }
        .appCard()
    }
    
    private var lastWorkoutCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            Text("האימון האחרון")
                .font(.headline)
                .fontWeight(.bold)
            
            if let lastSession = sessions.first {
                VStack(alignment: .leading, spacing: AppTheme.s8) {
                    Text(lastSession.planName ?? "ללא תוכנית")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(lastSession.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    PillBadge(text: "\(Int(displayVolume(for: lastSession))) \(unit.symbol)", icon: "chart.bar")
                }
            } else {
                EmptyStateView(
                    iconSystemName: "bolt.horizontal.circle",
                    title: "אין אימונים שמורים",
                    message: "כנס ללוג כדי להתחיל.",
                    buttonTitle: "פתח לוג אימון"
                ) {
                    // Navigate to log - this would need to be handled by parent
                }
            }
        }
        .appCard()
    }

    private var unit: AppSettings.WeightUnit { settingsList.first?.weightUnit ?? .kg }
    
    private func totalVolumeKg(for session: WorkoutSession) -> Double {
        session.exerciseSessions.flatMap { $0.setLogs }.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
    }
    
    private func displayVolume(for session: WorkoutSession) -> Double {
        unit.toDisplay(fromKg: totalVolumeKg(for: session))
    }
    
    private func getNextWorkoutPlan() -> WorkoutPlan? {
        return plans.sorted(by: { $0.name < $1.name }).first
    }
    
    private func getTodayWorkoutLabel(for plan: WorkoutPlan) -> String? {
        let today = Calendar.current.component(.weekday, from: Date())
        return plan.schedule.first { $0.weekday == today }?.label
    }
}


