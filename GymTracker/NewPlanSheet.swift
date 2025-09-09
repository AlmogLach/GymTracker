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
                VStack(spacing: AppTheme.s16) {
                    planInfoSection
                    scheduleSection
                }
                .padding(AppTheme.s16)
            }
            .background(AppTheme.screenBG)
            .navigationTitle("תוכנית חדשה")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { 
                    Button("ביטול") { dismiss() } 
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") {
                        savePlan()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private var planInfoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            Text("פרטי התוכנית")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: AppTheme.s12) {
                TextField("שם התוכנית", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                Picker("סוג תוכנית", selection: $planType) {
                    ForEach(PlanType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .appCard()
    }
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            Text("ימים בשבוע")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: AppTheme.s8) {
                ForEach(1...7, id: \.self) { day in
                    DayChipView(
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
        .appCard()
    }
    
    private func toggleDay(_ day: Int) {
        if schedule.contains(day) {
            schedule.remove(day)
            labelForDay.removeValue(forKey: day)
        } else {
            schedule.insert(day)
            if labelForDay[day] == nil {
                labelForDay[day] = planType.workoutLabels.first
            }
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
}

struct DayChipView: View {
    let day: Int
    let isSelected: Bool
    let planType: PlanType
    let selectedLabel: String?
    let onToggle: () -> Void
    let onLabelChange: (String) -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: onToggle) {
                Text(weekdayName(day))
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, AppTheme.s8)
                    .padding(.vertical, 4)
                    .background(isSelected ? AppTheme.accent : Color(.systemGray5))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isSelected && !planType.workoutLabels.isEmpty {
                Picker("אימון", selection: Binding(
                    get: { selectedLabel ?? planType.workoutLabels.first ?? "" },
                    set: onLabelChange
                )) {
                    ForEach(planType.workoutLabels, id: \.self) { label in
                        Text(label).tag(label)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption2)
            }
        }
    }
    
    private func weekdayName(_ day: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = max(1, min(7, day)) - 1
        return symbols[index]
    }
}
