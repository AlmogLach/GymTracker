//
//  NewExerciseComponents.swift
//  GymTracker
//
//  Created by Claude on 20/09/2025.
//

import SwiftUI

// MARK: - Exercise Details Sheet

struct NewExerciseDetailsSheet: View {
    let exerciseSession: ExerciseSession
    @Environment(\.dismiss) private var dismiss

    private var totalVolume: Double {
        exerciseSession.setLogs.reduce(0) { total, setLog in
            total + (setLog.weight * Double(setLog.reps))
        }
    }

    private var averageRPE: Double {
        let rpeValues = exerciseSession.setLogs.compactMap { $0.rpe }
        guard !rpeValues.isEmpty else { return 0 }
        return rpeValues.reduce(0, +) / Double(rpeValues.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(spacing: 16) {
                        // Exercise Icon
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(Color.blue)
                        }

                        // Exercise Name
                        Text(exerciseSession.exerciseName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        // Status Badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(exerciseSession.setLogs.isEmpty ? Color.orange : Color.green)
                                .frame(width: 8, height: 8)

                            Text(exerciseSession.setLogs.isEmpty ? "לא התחיל" : "הושלם")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(exerciseSession.setLogs.isEmpty ? Color.orange : Color.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background((exerciseSession.setLogs.isEmpty ? Color.orange : Color.green).opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        // Sets Count
                        VStack(spacing: 8) {
                            Text("\(exerciseSession.setLogs.count)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.blue)

                            Text("סטים")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Total Volume
                        VStack(spacing: 8) {
                            Text("\(Int(totalVolume))")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.green)

                            Text("ק״ג נפח")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Average RPE
                        VStack(spacing: 8) {
                            Text(averageRPE > 0 ? String(format: "%.1f", averageRPE) : "-")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.orange)

                            Text("RPE ממוצע")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Sets List
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("סטים")
                                .font(.headline)
                                .fontWeight(.bold)

                            Spacer()

                            if !exerciseSession.setLogs.isEmpty {
                                Text("\(exerciseSession.setLogs.count) סטים")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }

                        if exerciseSession.setLogs.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "list.number")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)

                                Text("אין סטים")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text("לא נרשמו סטים לתרגיל זה")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(exerciseSession.setLogs.enumerated()), id: \.offset) { index, setLog in
                                    HStack(spacing: 16) {
                                        // Set Number
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 32, height: 32)

                                            Text("\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                        }

                                        // Set Details
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                if setLog.weight > 0 {
                                                    Text("\(String(format: "%.1f", setLog.weight)) ק״ג")
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                }

                                                if setLog.reps > 0 {
                                                    Text("× \(setLog.reps)")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }

                                            if let rpe = setLog.rpe, rpe > 0 {
                                                Text("RPE \(rpe)")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundStyle(Color.blue)
                                            }
                                        }

                                        Spacer()

                                        // Volume for this set
                                        if setLog.weight > 0 && setLog.reps > 0 {
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(String(format: "%.0f", setLog.weight * Double(setLog.reps)))
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)

                                                Text("ק״ג")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("פרטי תרגיל")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("סגור") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - All Exercises Sheet

struct NewAllExercisesSheet: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: ExerciseSession?

    private var totalSets: Int {
        session.exerciseSessions.reduce(0) { $0 + $1.setLogs.count }
    }

    private var totalVolume: Double {
        session.exerciseSessions.reduce(0) { total, exerciseSession in
            total + exerciseSession.setLogs.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Stats
                    VStack(spacing: 16) {
                        Text("סיכום האימון")
                            .font(.title2)
                            .fontWeight(.bold)

                        // Quick Stats
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("\(session.exerciseSessions.count)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.blue)

                                Text("תרגילים")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(spacing: 4) {
                                Text("\(totalSets)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.green)

                                Text("סטים")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(spacing: 4) {
                                Text("\(Int(totalVolume))")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.orange)

                                Text("ק״ג נפח")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Exercises List
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("רשימת תרגילים")
                                .font(.headline)
                                .fontWeight(.bold)

                            Spacer()

                            Text("\(session.exerciseSessions.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }

                        if session.exerciseSessions.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "dumbbell")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)

                                Text("אין תרגילים")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text("אימון זה לא מכיל תרגילים עדיין")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(session.exerciseSessions.enumerated()), id: \.offset) { index, exerciseSession in
                                    SimpleExerciseCard(
                                        exerciseSession: exerciseSession,
                                        index: index + 1
                                    ) {
                                        selectedExercise = exerciseSession
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("כל התרגילים")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("סגור") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedExercise) { exercise in
            NewExerciseDetailsSheet(exerciseSession: exercise)
                .id(exercise.exerciseName)
        }
    }
}

// MARK: - Simple Exercise Card

struct SimpleExerciseCard: View {
    let exerciseSession: ExerciseSession
    let index: Int
    let onTap: () -> Void

    private var totalVolume: Double {
        exerciseSession.setLogs.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Exercise Number
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)

                    Text("\(index)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                // Exercise Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseSession.exerciseName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        Text("\(exerciseSession.setLogs.count) סטים")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if totalVolume > 0 {
                            Text("\(Int(totalVolume)) ק״ג")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Status & Arrow
                HStack(spacing: 8) {
                    Circle()
                        .fill(exerciseSession.setLogs.isEmpty ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)

                    Image(systemName: "chevron.backward")
                        .font(.caption)
                        .foregroundStyle(Color.blue)
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Make ExerciseSession Identifiable

extension ExerciseSession: Identifiable {
    public var id: String {
        exerciseName
    }
}