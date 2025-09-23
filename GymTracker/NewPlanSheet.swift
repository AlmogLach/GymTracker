//
//  NewPlanSheet.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

struct NewPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name: String = ""
    @State private var planType: PlanType = .fullBody
    @State private var schedule: [PlannedDay] = []
    @State private var currentEditingDay = "Full"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Welcome header
                    welcomeHeaderCard
                    
                    // Plan info section
                    modernPlanInfoSection
                    
                    // Plan type selection
                    planTypeSelectionCard
                    
                    // Schedule section 
                    modernScheduleSection
                    
                    // Preview section
                    if !schedule.isEmpty {
                        planPreviewCard
                    }
                }
                .padding(16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("תוכנית חדשה")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { 
                    Button("ביטול") { 
                        dismiss() 
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("צור תוכנית") {
                        savePlan()
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private var welcomeHeaderCard: some View {
        VStack(spacing: 16) {
            // Icon and title
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 8) {
                Text("צור תוכנית אימון חדשה")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("הגדר את שם התוכנית, סוג האימון ולוח הזמנים")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var modernPlanInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("פרטי התוכנית")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                Spacer()
                
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("שם התוכנית")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    TextField("לדוגמה: תוכנית כוח עליון", text: $name)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 16))
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                }
                
                Text("הכנס שם תיאורי לתוכנית שיעזור לך לזהות אותה בעתיד")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var planTypeSelectionCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("סוג התוכנית")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                Spacer()
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(PlanType.allCases, id: \.self) { type in
                    PlanTypeOption(
                        type: type,
                        isSelected: planType == type,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                planType = type
                                currentEditingDay = planType.workoutLabels.first ?? "Full"
                                normalizeScheduleForPlanType()
                            }
                        }
                    )
                }
            }
            
            if planType != .fullBody && !planType.workoutLabels.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("אימוני התוכנית")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(planType.workoutLabels, id: \.self) { label in
                            Text(label)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .cornerRadius(12)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var modernScheduleSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s20) {
            // Header
            VStack(alignment: .leading, spacing: AppTheme.s4) {
                Text("לוח זמנים")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)

                if planType == .fullBody {
                    Text("בחר את הימים בהם תרצה להתאמן")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("בחר ימים - האימונים יוקצו אוטומטית בסיבוב \(planType.workoutLabels.joined(separator: " → "))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Cycling explanation for split plans
            if planType != .fullBody && !schedule.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.s8) {
                    Text("סיבוב האימונים:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.info)

                    Text("השבועות ימשיכו את הסיבוב - אם שבוע מסתיים ב-\(planType.workoutLabels.last ?? ""), השבוע הבא מתחיל ב-\(planType.workoutLabels.first ?? "")")
                        .font(.caption)
                        .foregroundStyle(AppTheme.info)
                }
                .padding(AppTheme.s12)
                .background(AppTheme.info.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Weekday selector with cycling labels
            VStack(alignment: .leading, spacing: AppTheme.s12) {
                HStack {
                    Text("ימים בשבוע")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    // Selected days count
                    if !schedule.isEmpty {
                        HStack(spacing: AppTheme.s4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text("\(schedule.count) ימים")
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

                // Enhanced weekday grid with cycling labels
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppTheme.s10) {
                    ForEach(1...7, id: \.self) { weekday in
                        let isSelected = schedule.contains { $0.weekday == weekday }
                        let workoutLabel = schedule.first { $0.weekday == weekday }?.label

                        CyclingWeekdayButton(
                            weekday: weekday,
                            isSelected: isSelected,
                            workoutLabel: workoutLabel,
                            planType: planType,
                            onToggle: { toggleWeekday(weekday, for: "") }
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
        .onChange(of: planType) {
            currentEditingDay = planType.workoutLabels.first ?? "Full"
            normalizeScheduleForPlanType()
        }
    }
    
    private var planPreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("תצוגה מקדימה")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                Spacer()
                
                Image(systemName: "eye")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("שם התוכנית:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(name.isEmpty ? "לא הוגדר" : name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("סוג תוכנית:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(planType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("ימים בשבוע:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(schedule.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                if !schedule.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("לוח זמנים שבוע ראשון:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(schedule.sorted(by: { $0.weekday < $1.weekday }), id: \.weekday) { day in
                            HStack {
                                Text("• \(weekdayName(day.weekday))")
                                    .font(.caption)

                                Text("- \(day.label)")
                                    .font(.caption)
                                    .foregroundStyle(.blue)

                                Spacer()
                            }
                        }
                        
                        if planType != .fullBody && schedule.count > 0 {
                            Text("השבועות הבאים ימשיכו את הסיבוב מהמקום בו הופסק")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .italic()
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
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
    
    private func normalizeScheduleForPlanType() {
        // For Full Body, convert all to single label and deduplicate by weekday
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
        } else {
            // For A/B/C plans, apply proper cycling labels
            updateCyclingLabels()
        }

        // Make sure currentEditingDay is valid
        let allowed = Set(planType.workoutLabels)
        if !allowed.contains(currentEditingDay) {
            currentEditingDay = planType.workoutLabels.first ?? currentEditingDay
        }
    }

    private func savePlan() {
        normalizeScheduleForPlanType()
        let plan = WorkoutPlan(name: name, planType: planType, schedule: schedule)
        modelContext.insert(plan)
        dismiss()
    }
    
    private func weekdayName(_ day: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = max(1, min(7, day)) - 1
        return symbols[index]
    }
}

struct PlanTypeOption: View {
    let type: PlanType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? .blue.opacity(0.2) : .gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? .blue : .gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
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
            .padding(16)
            .background(isSelected ? .blue.opacity(0.05) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
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

struct ModernDayChip: View {
    let day: Int
    let isSelected: Bool
    let planType: PlanType
    let selectedLabel: String?
    let onToggle: () -> Void
    let onLabelChange: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? .blue.opacity(0.2) : .gray.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(isSelected ? .blue : .gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weekdayName(day))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text(isSelected ? "נבחר" : "לא נבחר")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(isSelected ? .blue.opacity(0.05) : Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? .blue : .clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            if isSelected && planType != .fullBody && !planType.workoutLabels.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("סוג אימון:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    // For AB/ABC plans, show the automatically assigned label
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        
                        Text(selectedLabel ?? planType.workoutLabels.first ?? "")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("אוטומטי")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 8)
            }
        }
    }
    
    private func weekdayName(_ day: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = max(1, min(7, day)) - 1
        return symbols[index]
    }
}

// MARK: - NewPlan Helper Components

struct NewPlanWorkoutTypeButton: View {
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

struct CyclingWeekdayButton: View {
    let weekday: Int
    let isSelected: Bool
    let workoutLabel: String?
    let planType: PlanType
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: AppTheme.s4) {
                Text(weekdaySymbol(weekday))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isSelected ? .white : .primary)

                if let label = workoutLabel, planType != .fullBody {
                    Text(label)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? .white.opacity(0.9) : AppTheme.accent)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            isSelected ?
                            .white.opacity(0.2) :
                            AppTheme.accent.opacity(0.1)
                        )
                        .clipShape(Capsule())
                } else if !isSelected {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 4, height: 4)
                }
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

#Preview {
    NewPlanSheet()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}
