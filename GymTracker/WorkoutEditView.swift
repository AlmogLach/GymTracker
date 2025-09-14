//
//  WorkoutEditView.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
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
    
    private enum EditSegment: String, CaseIterable {
        case history = "היסטוריה"
        case templates = "תבניות"
        
        var icon: String {
            switch self {
            case .history: return "clock.arrow.circlepath"
            case .templates: return "doc.text"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom segmented control
                segmentedControl
                
                // Content based on selection
                switch selectedSegment {
                case .history:
                    workoutHistoryView
                case .templates:
                    workoutTemplatesView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewWorkoutSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showNewWorkoutSheet) {
            NewWorkoutSheet()
        }
        .sheet(item: $editingSession) { session in
            EditWorkoutSheet(session: session)
        }
    }
    
    private var segmentedControl: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                // Modern segmented control with cards
                HStack(spacing: 12) {
                    ForEach(EditSegment.allCases, id: \.self) { segment in
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedSegment = segment
                            }
                        }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(selectedSegment == segment ? .blue.opacity(0.2) : .gray.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: segment.icon)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(selectedSegment == segment ? .blue : .secondary)
                                }
                                
                                Text(segment.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(selectedSegment == segment ? .blue : .primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedSegment == segment ? .blue.opacity(0.05) : Color(.tertiarySystemGroupedBackground))
                                    .stroke(selectedSegment == segment ? .blue : .clear, lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(selectedSegment == segment ? 0.08 : 0.05), radius: selectedSegment == segment ? 8 : 4, x: 0, y: selectedSegment == segment ? 4 : 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var workoutHistoryView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Stats overview
                if !sessions.isEmpty {
                    workoutStatsCard
                }
                
                if sessions.isEmpty {
                    EmptyStateView(
                        iconSystemName: "clock.arrow.circlepath",
                        title: "אין היסטוריית אימונים",
                        message: "האימונים שתשלים יופיעו כאן.\nהתחל אימון מהלוח כדי לראות את ההיסטוריה.",
                        buttonTitle: "לך ללוח"
                    ) {
                        // Navigate to dashboard to start workout - would need to be implemented
                    }
                    .padding(32)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("אימונים אחרונים")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .padding(.horizontal, 16)
                        
                        ForEach(sessions) { session in
                            WorkoutHistoryCard(
                                session: session,
                                onEdit: { editingSession = session },
                                onDelete: { deleteSession(session) }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 32)
        }
    }
    
    private var workoutStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("סטטיסטיקות")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
            }
            
            HStack(spacing: 16) {
                StatPill(
                    value: "\(sessions.count)",
                    label: "אימונים",
                    icon: "dumbbell.fill",
                    color: .blue
                )
                
                StatPill(
                    value: "\(completedSessions.count)",
                    label: "הושלמו",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatPill(
                    value: thisMonthSessions.formatted(),
                    label: "החודש",
                    icon: "calendar",
                    color: .orange
                )
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 16)
    }
    
    private var completedSessions: [WorkoutSession] {
        sessions.filter { $0.isCompleted == true }
    }
    
    private var thisMonthSessions: Int {
        let calendar = Calendar.current
        let now = Date()
        return sessions.filter { session in
            calendar.isDate(session.date, equalTo: now, toGranularity: .month)
        }.count
    }
    
    private var workoutTemplatesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if plans.isEmpty {
                    EmptyStateView(
                        iconSystemName: "doc.text",
                        title: "אין תבניות אימון",
                        message: "צור תוכניות אימון כדי להשתמש בהן כתבניות",
                        buttonTitle: "צור תוכנית"
                    ) {
                        // Navigate to plans view
                    }
                    .padding(32)
                } else {
                    ForEach(plans) { plan in
                        WorkoutTemplateCard(
                            plan: plan,
                            onUse: { useTemplate(plan) },
                            onEdit: { editTemplate(plan) }
                        )
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Functions
    
    private func deleteSession(_ session: WorkoutSession) {
        withAnimation {
            modelContext.delete(session)
            try? modelContext.save()
        }
    }
    
    private func useTemplate(_ plan: WorkoutPlan) {
        // Create new workout session from template
        showNewWorkoutSheet = true
    }
    
    private func editTemplate(_ plan: WorkoutPlan) {
        // Navigate to plan editing
    }
}

struct WorkoutHistoryCard: View {
    let session: WorkoutSession
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Query private var settingsList: [AppSettings]
    private var unit: AppSettings.WeightUnit { settingsList.first?.weightUnit ?? .kg }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.planName ?? "אימון ללא תוכנית")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    HStack(spacing: 8) {
                        Text(session.date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if let duration = session.durationSeconds {
                            Text("•")
                                .foregroundStyle(.secondary)
                            
                            Text("\(duration / 60) דק׳")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let isCompleted = session.isCompleted, isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                Menu {
                    Button("ערוך", action: onEdit)
                    Button("מחק", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Exercise summary
            if !session.exerciseSessions.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(session.exerciseSessions.prefix(4), id: \.exerciseName) { exerciseSession in
                        ExerciseSummaryChip(
                            name: exerciseSession.exerciseName,
                            sets: exerciseSession.setLogs.count,
                            totalVolume: exerciseSession.setLogs.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
                        )
                    }
                    
                    if session.exerciseSessions.count > 4 {
                        Text("+\(session.exerciseSessions.count - 4) עוד")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct WorkoutTemplateCard: View {
    let plan: WorkoutPlan
    let onUse: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    HStack(spacing: 8) {
                        PillBadge(text: plan.planType.rawValue, icon: "tag")
                        PillBadge(text: "\(plan.exercises.count) תרגילים", icon: "dumbbell")
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("השתמש") {
                        onUse()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("ערוך") {
                        onEdit()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // Schedule preview
            if !plan.schedule.isEmpty {
                HStack(spacing: 4) {
                    Text("לוח זמנים:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ForEach(plan.schedule.sorted(by: { $0.weekday < $1.weekday }), id: \.weekday) { day in
                        DayChip(day: day)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ExerciseSummaryChip: View {
    let name: String
    let sets: Int
    let totalVolume: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text("\(sets) סטים")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Sheet Views

struct NewWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("צור אימון חדש")
                    .font(.title2)
                    .padding()
                
                Spacer()
                
                Text("ממשק ליצירת אימון חדש")
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .navigationTitle("אימון חדש")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("שמור") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditWorkoutSheet: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var planName: String
    @State private var workoutLabel: String
    @State private var notes: String
    @State private var workoutDate: Date
    
    init(session: WorkoutSession) {
        self.session = session
        self._planName = State(initialValue: session.planName ?? "")
        self._workoutLabel = State(initialValue: session.workoutLabel ?? "")
        self._notes = State(initialValue: session.notes ?? "")
        self._workoutDate = State(initialValue: session.date)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic info section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("פרטי אימון")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("תאריך")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                DatePicker("", selection: $workoutDate, displayedComponents: [.date])
                                    .datePickerStyle(.compact)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("שם תוכנית")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("הכנס שם תוכנית", text: $planName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("תווית אימון")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("לדוגמה: Push, Pull, Legs", text: $workoutLabel)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    // Workout stats
                    if let duration = session.durationSeconds {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("סטטיסטיקות")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            HStack {
                                StatItem(
                                    title: "משך זמן",
                                    value: "\(duration / 60) דק׳",
                                    icon: "clock.fill"
                                )
                                
                                StatItem(
                                    title: "תרגילים",
                                    value: "\(session.exerciseSessions.count)",
                                    icon: "dumbbell.fill"
                                )
                                
                                StatItem(
                                    title: "סטים",
                                    value: "\(session.exerciseSessions.flatMap { $0.setLogs }.count)",
                                    icon: "number.circle.fill"
                                )
                            }
                        }
                        .padding(16)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(16)
                    }
                    
                    // Exercise sessions
                    if !session.exerciseSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("תרגילים")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            ForEach(session.exerciseSessions, id: \.exerciseName) { exerciseSession in
                                ExerciseSessionCard(exerciseSession: exerciseSession)
                            }
                        }
                    }
                    
                    // Notes section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("הערות")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        TextField("הוסף הערות על האימון", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .padding(16)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("עריכת אימון")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("ביטול") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("שמור") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        session.planName = planName.isEmpty ? nil : planName
        session.workoutLabel = workoutLabel.isEmpty ? nil : workoutLabel
        session.notes = notes.isEmpty ? nil : notes
        session.date = workoutDate
        
        try? modelContext.save()
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExerciseSessionCard: View {
    let exerciseSession: ExerciseSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exerciseSession.exerciseName)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if !exerciseSession.setLogs.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.fixed(80)),
                    GridItem(.fixed(80)),
                    GridItem(.fixed(60)),
                    GridItem(.flexible())
                ], spacing: 8) {
                    Text("סט").font(.caption2).foregroundStyle(.secondary)
                    Text("משקל").font(.caption2).foregroundStyle(.secondary)
                    Text("חזרות").font(.caption2).foregroundStyle(.secondary)
                    Text("RPE").font(.caption2).foregroundStyle(.secondary)
                    
                    ForEach(Array(exerciseSession.setLogs.enumerated()), id: \.offset) { index, setLog in
                        Text("\(index + 1)").font(.caption)
                        Text("\(setLog.weight.formatted(.number.precision(.fractionLength(1))))").font(.caption)
                        Text("\(setLog.reps)").font(.caption)
                        Text(setLog.rpe?.formatted(.number.precision(.fractionLength(1))) ?? "-").font(.caption)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    WorkoutEditView()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}