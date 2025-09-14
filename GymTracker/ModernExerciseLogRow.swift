//
//  ModernExerciseLogRow.swift
//  GymTracker
//
//  Modern exercise row for workout logging
//

import SwiftUI
import SwiftData

struct ModernExerciseLogRow: View {
    let exercise: Exercise
    @Binding var session: WorkoutSession
    let lastDefaults: (reps: Int, weight: Double, rpe: Double?)?
    let weightUnit: AppSettings.WeightUnit
    let weightStep: Double
    
    @State private var isExpanded: Bool = true
    
    private var exerciseSession: ExerciseSession? {
        session.exerciseSessions.first { $0.exerciseName == exercise.name }
    }
    
    private var exerciseIndex: Int? {
        session.exerciseSessions.firstIndex { $0.exerciseName == exercise.name }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            // Exercise Header
            ExerciseHeader(
                exercise: exercise,
                lastSet: lastDefaults != nil ? SetLog(
                    reps: lastDefaults!.reps,
                    weight: lastDefaults!.weight,
                    rpe: lastDefaults?.rpe
                ) : nil,
                lastDate: nil, // Could add last workout date here
                onAddSet: addNewSet
            )
            
            // Sets list (collapsible)
            if isExpanded {
                if let exerciseIdx = exerciseIndex {
                    let sets = session.exerciseSessions[exerciseIdx].setLogs
                    
                    if sets.isEmpty {
                        Text("לא נוספו סטים עדיין")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, AppTheme.s12)
                    } else {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(sets.enumerated()), id: \.offset) { setIndex, setLog in
                                SetRow(
                                    setIndex: setIndex,
                                    setLog: Binding(
                                        get: { sets[setIndex] },
                                        set: { session.exerciseSessions[exerciseIdx].setLogs[setIndex] = $0 }
                                    ),
                                    weightUnit: weightUnit,
                                    weightStep: weightStep,
                                    onDuplicate: {
                                        duplicateSet(at: setIndex, in: exerciseIdx)
                                    },
                                    onDelete: {
                                        deleteSet(at: setIndex, in: exerciseIdx)
                                    }
                                )
                                .id("set_\(setIndex)")
                            }
                        }
                    }
                    
                    // Quick Actions
                    ExerciseQuickActions(
                        onDuplicateLastSet: {
                            duplicateLastSet(in: exerciseIdx)
                        },
                        onAddWarmupSet: {
                            addWarmupSet(in: exerciseIdx)
                        },
                        onClearSets: {
                            clearAllSets(in: exerciseIdx)
                        },
                        onWarmupRamp: {
                            addWarmupRamp(in: exerciseIdx)
                        }
                    )
                }
            }
        }
        .padding(AppTheme.s12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Set Management
    
    private func addNewSet() {
        ensureExerciseExists()
        guard let exerciseIdx = exerciseIndex else { return }
        
        let newSet = SetLog(
            reps: lastDefaults?.reps ?? exercise.plannedReps ?? 8,
            weight: lastDefaults?.weight ?? 0,
            rpe: lastDefaults?.rpe,
            restSeconds: 120,
            isWarmup: false
        )
        
        session.exerciseSessions[exerciseIdx].setLogs.append(newSet)
        hapticFeedback(.medium)
        
        // Auto-expand if collapsed
        if !isExpanded {
            isExpanded = true
        }
    }
    
    private func duplicateSet(at index: Int, in exerciseIdx: Int) {
        let originalSet = session.exerciseSessions[exerciseIdx].setLogs[index]
        let duplicatedSet = SetLog(
            reps: originalSet.reps,
            weight: originalSet.weight,
            rpe: originalSet.rpe,
            notes: originalSet.notes,
            restSeconds: originalSet.restSeconds,
            isWarmup: originalSet.isWarmup
        )
        session.exerciseSessions[exerciseIdx].setLogs.append(duplicatedSet)
        hapticFeedback(.medium)
    }
    
    private func deleteSet(at index: Int, in exerciseIdx: Int) {
        session.exerciseSessions[exerciseIdx].setLogs.remove(at: index)
        hapticFeedback(.heavy)
    }
    
    private func duplicateLastSet(in exerciseIdx: Int) {
        guard let lastSet = session.exerciseSessions[exerciseIdx].setLogs.last else {
            addNewSet()
            return
        }
        
        let duplicatedSet = SetLog(
            reps: lastSet.reps,
            weight: lastSet.weight,
            rpe: lastSet.rpe,
            notes: lastSet.notes,
            restSeconds: lastSet.restSeconds,
            isWarmup: lastSet.isWarmup
        )
        session.exerciseSessions[exerciseIdx].setLogs.append(duplicatedSet)
        hapticFeedback(.medium)
    }
    
    private func addWarmupSet(in exerciseIdx: Int) {
        // Get the heaviest working set to calculate warmup
        let workingSets = session.exerciseSessions[exerciseIdx].setLogs.filter { !($0.isWarmup ?? false) }
        let heaviestWeight = workingSets.max(by: { $0.weight < $1.weight })?.weight ?? 0
        
        let warmupSet = SetLog(
            reps: 8,
            weight: heaviestWeight * 0.6, // 60% of working weight
            rpe: nil,
            restSeconds: 60,
            isWarmup: true
        )
        
        // Insert at beginning
        session.exerciseSessions[exerciseIdx].setLogs.insert(warmupSet, at: 0)
        hapticFeedback(.medium)
    }
    
    private func clearAllSets(in exerciseIdx: Int) {
        session.exerciseSessions[exerciseIdx].setLogs.removeAll()
        hapticFeedback(.heavy)
    }
    
    private func addWarmupRamp(in exerciseIdx: Int) {
        // Get target weight from first working set or user input
        let workingSets = session.exerciseSessions[exerciseIdx].setLogs.filter { !($0.isWarmup ?? false) }
        guard let targetWeight = workingSets.first?.weight, targetWeight > 0 else { return }
        
        let warmupPercentages = [0.4, 0.55, 0.7, 0.8, 0.9]
        let warmupReps = [8, 5, 3, 2, 1]
        
        var warmupSets: [SetLog] = []
        for (percentage, reps) in zip(warmupPercentages, warmupReps) {
            let warmupSet = SetLog(
                reps: reps,
                weight: targetWeight * percentage,
                rpe: nil,
                restSeconds: 60,
                isWarmup: true
            )
            warmupSets.append(warmupSet)
        }
        
        // Insert at beginning
        session.exerciseSessions[exerciseIdx].setLogs.insert(contentsOf: warmupSets, at: 0)
        hapticFeedback(.success)
    }
    
    private func ensureExerciseExists() {
        if !session.exerciseSessions.contains(where: { $0.exerciseName == exercise.name }) {
            let newExerciseSession = ExerciseSession(exerciseName: exercise.name, setLogs: [])
            session.exerciseSessions.append(newExerciseSession)
        }
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
    }
    
    private func hapticFeedback(_ style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }
}