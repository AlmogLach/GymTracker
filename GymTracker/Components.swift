//
//  Components.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI

struct PillBadge: View {
    let text: String
    let icon: String?
    
    init(text: String, icon: String? = nil) {
        self.text = text
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, AppTheme.s8)
        .padding(.vertical, 4)
        .background(AppTheme.accent.opacity(0.1))
        .foregroundStyle(AppTheme.accent)
        .cornerRadius(12)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(title, action: action)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
    }
}

struct EmptyStateView: View {
    let iconSystemName: String
    let title: String
    var message: String?
    var buttonTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppTheme.s12) {
            Image(systemName: iconSystemName)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityLabel(title)

            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibilityLabel(message)
            }

            if let buttonTitle = buttonTitle, let action = action {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, AppTheme.s8)
                    .accessibilityLabel(buttonTitle)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.s8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.s12)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DayChip: View {
    let day: PlannedDay
    let isSelected: Bool
    
    init(day: PlannedDay, isSelected: Bool = false) {
        self.day = day
        self.isSelected = isSelected
    }
    
    var body: some View {
        VStack(spacing: 3) {
            Text(dayAbbreviation(day.weekday))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .primary)
            
            if !day.label.isEmpty {
                Text(day.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? AppTheme.accent : Color(.secondarySystemGroupedBackground))
                .shadow(
                    color: isSelected ? AppTheme.accent.opacity(0.3) : .black.opacity(0.05),
                    radius: isSelected ? 4 : 2,
                    x: 0,
                    y: isSelected ? 2 : 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? AppTheme.accent.opacity(0.2) : Color(.separator),
                    lineWidth: isSelected ? 1 : 0.5
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .frame(minWidth: 36, minHeight: 36)
        .contentShape(Rectangle())
        .accessibilityLabel("\(dayAbbreviation(day.weekday))\(day.label.isEmpty ? "" : " - \(day.label)")")
        .accessibilityHint(isSelected ? "יום נבחר" : "יום לא נבחר")
    }
    
    private func dayAbbreviation(_ weekday: Int) -> String {
        let dayNames = ["א׳", "ב׳", "ג׳", "ד׳", "ה׳", "ו׳", "ש׳"]
        let index = max(1, min(7, weekday)) - 1
        return dayNames[index]
    }
}

struct ExerciseEditRow: View {
    let exercise: Exercise
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    var body: some View {
        HStack(spacing: AppTheme.s12) {
            // Move buttons
            VStack(spacing: 4) {
                if let onMoveUp = onMoveUp {
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                }
                
                if let onMoveDown = onMoveDown {
                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(AppTheme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 24)
            
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if let label = exercise.label, !label.isEmpty {
                        PillBadge(text: label, icon: "tag")
                    }
                }
                
                HStack(spacing: AppTheme.s12) {
                    if let reps = exercise.plannedReps {
                        Text("\(exercise.plannedSets) × \(reps)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(exercise.plannedSets) סטים")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let muscleGroup = exercise.muscleGroup {
                        Text(muscleGroup)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: AppTheme.s8) {
                Button("ערוך") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("מחק") {
                    onDelete()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundStyle(.red)
            }
        }
        .padding(AppTheme.s16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}


struct EditExerciseSheet: View {
    let exercise: Exercise
    let onSave: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var exerciseName: String
    @State private var plannedSets: Int
    @State private var plannedReps: Int?
    @State private var notes: String
    @State private var label: String
    @State private var muscleGroup: String
    @State private var equipment: String
    @State private var isBodyweight: Bool
    
    init(exercise: Exercise, onSave: @escaping (Exercise) -> Void) {
        self.exercise = exercise
        self.onSave = onSave
        self._exerciseName = State(initialValue: exercise.name)
        self._plannedSets = State(initialValue: exercise.plannedSets)
        self._plannedReps = State(initialValue: exercise.plannedReps)
        self._notes = State(initialValue: exercise.notes ?? "")
        self._label = State(initialValue: exercise.label ?? "")
        self._muscleGroup = State(initialValue: exercise.muscleGroup ?? "")
        self._equipment = State(initialValue: exercise.equipment ?? "")
        self._isBodyweight = State(initialValue: exercise.isBodyweight ?? false)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.s24) {
                    // Exercise details
                    VStack(alignment: .leading, spacing: AppTheme.s16) {
                        Text("פרטי התרגיל")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: AppTheme.s16) {
                            // Exercise name
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("שם התרגיל")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("שם התרגיל...", text: $exerciseName)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            // Sets and reps
                            HStack(spacing: AppTheme.s16) {
                                VStack(alignment: .leading, spacing: AppTheme.s8) {
                                    Text("סטים")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Stepper("\(plannedSets)", value: $plannedSets, in: 1...10)
                                        .labelsHidden()
                                }
                                
                                VStack(alignment: .leading, spacing: AppTheme.s8) {
                                    Text("חזרות")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    TextField("8", value: $plannedReps, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                }
                            }
                            
                            // Additional info
                            VStack(alignment: .leading, spacing: AppTheme.s8) {
                                Text("מידע נוסף")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("קבוצת שריר...", text: $muscleGroup)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("ציוד...", text: $equipment)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("הערות...", text: $notes, axis: .vertical)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                            }
                        }
                    }
                }
                .padding(AppTheme.s24)
            }
            .navigationTitle("עריכת תרגיל")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") {
                        saveExercise()
                    }
                    .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveExercise() {
        exercise.name = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.plannedSets = plannedSets
        exercise.plannedReps = plannedReps
        exercise.notes = notes.isEmpty ? nil : notes
        exercise.label = label.isEmpty ? nil : label
        exercise.muscleGroup = muscleGroup.isEmpty ? nil : muscleGroup
        exercise.equipment = equipment.isEmpty ? nil : equipment
        exercise.isBodyweight = isBodyweight
        
        onSave(exercise)
        dismiss()
    }
}

// MARK: - Previews

#Preview("PillBadge") {
    VStack(spacing: 16) {
        PillBadge(text: "חזה")
        PillBadge(text: "משקל גוף", icon: "figure.strengthtraining.traditional")
        PillBadge(text: "A", icon: "dumbbell")
    }
    .padding()
}

#Preview("PrimaryButton") {
    PrimaryButton(title: "התחל אימון") {
        print("Button tapped")
    }
    .padding()
}

#Preview("EmptyStateView") {
    EmptyStateView(
        iconSystemName: "dumbbell",
        title: "אין תרגילים",
        message: "הוסף תרגילים כדי להתחיל",
        buttonTitle: "הוסף תרגיל"
    ) {
        print("Add exercise tapped")
    }
    .padding()
}

#Preview("StatTile") {
    HStack(spacing: 12) {
        StatTile(
            value: "5",
            label: "אימונים",
            icon: "figure.strengthtraining.traditional",
            color: .blue
        )
        StatTile(
            value: "3",
            label: "תוכניות",
            icon: "list.bullet.rectangle",
            color: .green
        )
    }
    .padding()
}

#Preview("StatCard") {
    HStack(spacing: 12) {
        StatCard(
            title: "אימונים השבוע",
            value: "5",
            icon: "figure.strengthtraining.traditional",
            color: .blue
        )
        StatCard(
            title: "תרגילים שונים",
            value: "12",
            icon: "dumbbell.fill",
            color: .green
        )
    }
    .padding()
}

#Preview("DayChip") {
    HStack(spacing: 8) {
        DayChip(day: PlannedDay(weekday: 1, label: "A"), isSelected: true)
        DayChip(day: PlannedDay(weekday: 3, label: "B"), isSelected: false)
        DayChip(day: PlannedDay(weekday: 5, label: "C"), isSelected: false)
    }
    .padding()
}