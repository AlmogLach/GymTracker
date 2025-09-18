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
    @State private var schedule: Set<Int> = []
    @State private var labelForDay: [Int: String] = [:]

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
                                // Update existing labels for new plan type cycling
                                updateWorkoutLabelsForCycling()
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
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("לוח זמנים")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                Spacer()
                
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if planType == .fullBody {
                    Text("בחר את הימים בהם תרצה להתאמן")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("בחר ימים - האימונים יוקצו אוטומטית בסיבוב \(planType.workoutLabels.joined(separator: " → "))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("הסיבוב ימשיך בין השבועות - אם שבוע מסתיים ב-\(planType.workoutLabels.last ?? ""), השבוע הבא מתחיל ב-\(planType.workoutLabels.first ?? "")")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.top, 4)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(1...7, id: \.self) { day in
                    ModernDayChip(
                        day: day,
                        isSelected: schedule.contains(day),
                        planType: planType,
                        selectedLabel: labelForDay[day],
                        onToggle: { toggleDay(day) },
                        onLabelChange: { label in
                            labelForDay[day] = label
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
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
                        
                        ForEach(schedule.sorted(), id: \.self) { day in
                            HStack {
                                Text("• \(weekdayName(day))")
                                    .font(.caption)
                                
                                if let label = labelForDay[day] {
                                    Text("- \(label)")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                                
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
    
    private func toggleDay(_ day: Int) {
        if schedule.contains(day) {
            schedule.remove(day)
            labelForDay.removeValue(forKey: day)
        } else {
            schedule.insert(day)
            if labelForDay[day] == nil {
                labelForDay[day] = getNextWorkoutLabel(for: day)
            }
        }
        // Recalculate all labels to maintain proper cycling
        updateWorkoutLabelsForCycling()
    }
    
    private func getNextWorkoutLabel(for day: Int) -> String {
        if planType == .fullBody {
            return planType.workoutLabels.first ?? ""
        }
        
        // For AB and ABC plans, cycle through labels based on chronological order
        let sortedDays = schedule.sorted()
        guard let dayIndex = sortedDays.firstIndex(of: day) else {
            return planType.workoutLabels.first ?? ""
        }
        
        let labelIndex = dayIndex % planType.workoutLabels.count
        return planType.workoutLabels[labelIndex]
    }
    
    private func updateWorkoutLabelsForCycling() {
        // Only cycle for AB and ABC plans
        guard planType != .fullBody else { return }
        
        let sortedDays = schedule.sorted()
        for (index, day) in sortedDays.enumerated() {
            let labelIndex = index % planType.workoutLabels.count
            labelForDay[day] = planType.workoutLabels[labelIndex]
        }
    }
    
    private func savePlan() {
        let days = schedule.sorted().map { day in 
            PlannedDay(weekday: day, label: labelForDay[day] ?? planType.workoutLabels.first ?? "") 
        }
        let plan = WorkoutPlan(name: name, planType: planType, schedule: days)
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

#Preview {
    NewPlanSheet()
        .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}
