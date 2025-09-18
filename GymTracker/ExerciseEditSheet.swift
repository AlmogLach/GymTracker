//
//  ExerciseEditSheet.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

struct ExerciseEditSheet: View {
    @State private var exercise: Exercise
    let onSave: (Exercise) -> Void
    let onCancel: () -> Void
    
    init(exercise: Exercise, onSave: @escaping (Exercise) -> Void, onCancel: @escaping () -> Void) {
        self._exercise = State(initialValue: exercise)
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Exercise header card
                    exerciseHeaderCard
                    
                    // Exercise settings card
                    exerciseSettingsCard
                    
                    // Exercise info card (if available)
                    if exercise.muscleGroup != nil || exercise.equipment != nil || exercise.isBodyweight == true {
                        exerciseInfoCard
                    }
                    
                    // Notes card
                    notesCard
                }
                .padding(16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("עריכת תרגיל")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") {
                        onCancel()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("שמור") {
                        onSave(exercise)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .disabled(exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private var exerciseHeaderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("פרטי התרגיל")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    TextField("שם התרגיל", text: $exercise.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .textFieldStyle(.plain)
                }
                
                Spacer()
                
                // Exercise icon
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }
            
            // Exercise label (if exists)
            if let label = exercise.label, !label.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.orange)
                    
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var exerciseSettingsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("הגדרות אימון")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            VStack(spacing: 16) {
                // Sets counter
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("מספר סטים")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("כמות הסטים המתוכננת לתרגיל")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            if exercise.plannedSets > 1 {
                                exercise.plannedSets -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(exercise.plannedSets > 1 ? .blue : .gray)
                        }
                        .disabled(exercise.plannedSets <= 1)
                        
                        Text("\(exercise.plannedSets)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .frame(width: 40)
                        
                        Button(action: {
                            if exercise.plannedSets < 10 {
                                exercise.plannedSets += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(exercise.plannedSets < 10 ? .blue : .gray)
                        }
                        .disabled(exercise.plannedSets >= 10)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                
                // Reps counter
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("מספר חזרות")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("חזרות מתוכננות בכל סט")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            let current = exercise.plannedReps ?? 8
                            if current > 1 {
                                exercise.plannedReps = current - 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundStyle((exercise.plannedReps ?? 8) > 1 ? .green : .gray)
                        }
                        .disabled((exercise.plannedReps ?? 8) <= 1)
                        
                        Text("\(exercise.plannedReps ?? 8)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .frame(width: 40)
                        
                        Button(action: {
                            let current = exercise.plannedReps ?? 8
                            if current < 50 {
                                exercise.plannedReps = current + 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle((exercise.plannedReps ?? 8) < 50 ? .green : .gray)
                        }
                        .disabled((exercise.plannedReps ?? 8) >= 50)
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var exerciseInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("מידע נוסף")
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            VStack(spacing: 12) {
                if let muscleGroup = exercise.muscleGroup {
                    ExerciseInfoRow(
                        icon: "figure.strengthtraining.traditional",
                        title: "קבוצת שריר",
                        value: muscleGroup,
                        color: .purple
                    )
                }
                
                if let equipment = exercise.equipment {
                    ExerciseInfoRow(
                        icon: "dumbbell",
                        title: "ציוד נדרש",
                        value: equipment,
                        color: .orange
                    )
                }
                
                if exercise.isBodyweight == true {
                    ExerciseInfoRow(
                        icon: "figure.walk",
                        title: "סוג תרגיל",
                        value: "משקל גוף",
                        color: .green
                    )
                }
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("הערות")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                Spacer()
                
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            TextField("הוסף הערות לתרגיל (אופציונלי)", text: Binding(
                get: { exercise.notes ?? "" },
                set: { exercise.notes = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .font(.system(size: 16))
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .lineLimit(3...6)
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct ExerciseInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

#Preview {
    ExerciseEditSheet(
        exercise: Exercise(
            name: "סקוואט",
            plannedSets: 3,
            plannedReps: 8,
            notes: "תרגיל בסיסי לפלג גוף תחתון",
            label: "A",
            muscleGroup: "רגליים",
            equipment: "משקולת",
            isBodyweight: false,
            workoutDay: "A"
        ),
        onSave: { _ in },
        onCancel: { }
    )
    .modelContainer(for: [WorkoutPlan.self, Exercise.self, WorkoutSession.self, ExerciseSession.self, SetLog.self, AppSettings.self], inMemory: true)
}