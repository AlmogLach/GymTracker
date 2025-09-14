//
//  WorkoutComponents.swift
//  GymTracker
//
//  Polished compact components for workout logging
//

import SwiftUI
import SwiftData

// MARK: - Numeric Field with Stepper
struct NumericField: View {
    let title: String
    let unit: String?
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    let onCommit: () -> Void
    
    @FocusState private var isFocused: Bool
    @State private var textValue: String = ""
    
    init(
        title: String,
        unit: String? = nil,
        value: Binding<Double>,
        step: Double = 1.0,
        range: ClosedRange<Double> = 0...999,
        onCommit: @escaping () -> Void = {}
    ) {
        self.title = title
        self.unit = unit
        self._value = value
        self.step = step
        self.range = range
        self.onCommit = onCommit
    }
    
    var body: some View {
        HStack(spacing: 4) {
            TextField(title, text: $textValue)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .frame(width: 60)
                .onChange(of: textValue) { _, newValue in
                    if let doubleValue = Double(newValue), doubleValue.isFinite {
                        value = max(range.lowerBound, min(range.upperBound, doubleValue))
                    }
                }
                .onChange(of: value) { _, newValue in
                    if !isFocused && newValue.isFinite {
                        textValue = String(format: newValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", newValue)
                    }
                }
                .onSubmit {
                    onCommit()
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button("-\(step.formatted())") {
                            let newValue = max(range.lowerBound, value - step)
                            value = newValue
                            hapticFeedback(.light)
                        }
                        .disabled(value <= range.lowerBound)
                        
                        Button("+\(step.formatted())") {
                            let newValue = min(range.upperBound, value + step)
                            value = newValue
                            hapticFeedback(.light)
                        }
                        .disabled(value >= range.upperBound)
                        
                        Spacer()
                        
                        Button("סיום") {
                            isFocused = false
                            onCommit()
                        }
                        .fontWeight(.semibold)
                    }
                }
            
            VStack(spacing: 2) {
                Button(action: {
                    let newValue = min(range.upperBound, value + step)
                    value = newValue
                    hapticFeedback(.light)
                }) {
                    Image(systemName: "plus")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderless)
                .disabled(value >= range.upperBound)
                
                Button(action: {
                    let newValue = max(range.lowerBound, value - step)
                    value = newValue
                    hapticFeedback(.light)
                }) {
                    Image(systemName: "minus")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderless)
                .disabled(value <= range.lowerBound)
            }
            .frame(width: 20)
            
            if let unit = unit {
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 20, alignment: .leading)
            }
        }
        .onAppear {
            if value.isFinite {
                textValue = String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value)
            } else {
                textValue = "0"
            }
        }
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
    }
}

// MARK: - RPE Picker
struct RPEPicker: View {
    @Binding var rpe: Double?
    
    var body: some View {
        HStack(spacing: 4) {
            Text("RPE")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .leading)
            
            Picker("RPE", selection: Binding(
                get: { rpe ?? 0 },
                set: { rpe = $0 == 0 ? nil : $0 }
            )) {
                Text("—").tag(0.0)
                ForEach([6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0], id: \.self) { value in
                    Text("\(value, specifier: "%.1f")").tag(value)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 50)
        }
    }
}

// MARK: - Last Time Chip
struct LastTimeChip: View {
    let lastSet: SetLog?
    let date: Date?
    
    var body: some View {
        if let lastSet = lastSet, let date = date {
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("\(Int(lastSet.weight))×\(lastSet.reps)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let rpe = lastSet.rpe {
                    Text("@RPE\(rpe, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text("·")
                    .foregroundStyle(.secondary)
                
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: Capsule())
        }
    }
}

// MARK: - Exercise Header
struct ExerciseHeader: View {
    let exercise: Exercise
    let lastSet: SetLog?
    let lastDate: Date?
    let onAddSet: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if let muscleGroup = exercise.muscleGroup {
                        HStack(spacing: 4) {
                            Text(muscleGroup)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if let equipment = exercise.equipment {
                                Text("·")
                                    .foregroundStyle(.secondary)
                                Text(equipment)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if exercise.isBodyweight == true {
                                Text("·")
                                    .foregroundStyle(.secondary)
                                Text("משקל גוף")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: onAddSet) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("הוסף סט")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if lastSet != nil || lastDate != nil {
                LastTimeChip(lastSet: lastSet, date: lastDate)
                    .padding(.top, 2)
            }
        }
    }
}

// MARK: - Set Row Component
struct SetRow: View {
    let setIndex: Int
    @Binding var setLog: SetLog
    let weightUnit: AppSettings.WeightUnit
    let weightStep: Double
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case reps, weight
    }
    
    var body: some View {
        HStack(spacing: AppTheme.s8) {
            // Set number
            Text("\(setIndex + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .center)
            
            // Reps field
            NumericField(
                title: "חזרות",
                value: Binding(
                    get: { Double(setLog.reps) },
                    set: { setLog.reps = Int($0) }
                ),
                step: 1,
                range: 1...100
            )
            
            // Weight field
            NumericField(
                title: "משקל",
                unit: weightUnit.symbol,
                value: $setLog.weight,
                step: weightStep,
                range: 0...999
            )
            
            // RPE picker
            RPEPicker(rpe: $setLog.rpe)
            
            // Warmup toggle
            Button(action: {
                setLog.isWarmup?.toggle()
                hapticFeedback(.light)
            }) {
                Image(systemName: setLog.isWarmup == true ? "flame.fill" : "flame")
                    .font(.caption)
                    .foregroundStyle(setLog.isWarmup == true ? .orange : .secondary)
            }
            .buttonStyle(.borderless)
            
            // Actions
            HStack(spacing: 4) {
                Button(action: {
                    onDuplicate()
                    hapticFeedback(.medium)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.blue)
                
                Button(action: {
                    onDelete()
                    hapticFeedback(.heavy)
                }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
    }
}

// MARK: - Exercise Quick Actions
struct ExerciseQuickActions: View {
    let onDuplicateLastSet: () -> Void
    let onAddWarmupSet: () -> Void
    let onClearSets: () -> Void
    let onWarmupRamp: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.s8) {
            Button("שכפל סט אחרון", action: onDuplicateLastSet)
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.mini)
            
            Button("חימום", action: onAddWarmupSet)
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.mini)
            
            Menu("עוד") {
                Button("רמפת חימום", action: onWarmupRamp)
                Button("נקה סטים", role: .destructive, action: onClearSets)
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .controlSize(.mini)
            
            Spacer()
        }
        .padding(.top, AppTheme.s8)
    }
}

// MARK: - Compact Components for Polished UI

struct CompactNumericField: View {
    let title: String
    let unit: String?
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    
    @FocusState private var isFocused: Bool
    @State private var textValue: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 4) {
                TextField("0", text: $textValue)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .frame(width: 50)
                    .onChange(of: textValue) { _, newValue in
                        if let doubleValue = Double(newValue), doubleValue.isFinite {
                            value = max(range.lowerBound, min(range.upperBound, doubleValue))
                        }
                    }
                    .onChange(of: value) { _, newValue in
                        if !isFocused && newValue.isFinite {
                            textValue = String(format: newValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", newValue)
                        }
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Button("-\(step.formatted())") {
                                value = max(range.lowerBound, value - step)
                                hapticFeedback(.light)
                            }
                            .disabled(value <= range.lowerBound)
                            
                            Button("+\(step.formatted())") {
                                value = min(range.upperBound, value + step)
                                hapticFeedback(.light)
                            }
                            .disabled(value >= range.upperBound)
                            
                            Spacer()
                            
                            Button("סיום") {
                                isFocused = false
                            }
                            .fontWeight(.semibold)
                        }
                    }
                
                if let unit = unit {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                VStack(spacing: 1) {
                    Button(action: {
                        value = min(range.upperBound, value + step)
                        hapticFeedback(.light)
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.mini)
                    .disabled(value >= range.upperBound)
                    
                    Button(action: {
                        value = max(range.lowerBound, value - step)
                        hapticFeedback(.light)
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.mini)
                    .disabled(value <= range.lowerBound)
                }
                .frame(width: 16)
            }
        }
        .onAppear {
            if value.isFinite {
                textValue = String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value)
            } else {
                textValue = "0"
            }
        }
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
    }
}

struct RPEChipsPicker: View {
    @Binding var rpe: Double?
    
    private let rpeValues: [Double] = [6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("RPE")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(rpeValues, id: \.self) { value in
                        Button(action: {
                            rpe = rpe == value ? nil : value
                            hapticFeedback(.light)
                        }) {
                            Text(value.formatted(.number.precision(.fractionLength(1))))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    rpe == value ? Color.accentColor : Color(.systemGray5),
                                    in: Capsule()
                                )
                                .foregroundStyle(rpe == value ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    @Binding var session: WorkoutSession
    let lastDefaults: (reps: Int, weight: Double, rpe: Double?)?
    let weightUnit: AppSettings.WeightUnit
    let weightStep: Double
    let onAddSet: () -> Void
    
    @State private var isExpanded: Bool = true
    
    private var exerciseSession: ExerciseSession? {
        session.exerciseSessions.first { $0.exerciseName == exercise.name }
    }
    
    private var exerciseIndex: Int? {
        session.exerciseSessions.firstIndex { $0.exerciseName == exercise.name }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Exercise header with compact add button
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let muscleGroup = exercise.muscleGroup {
                        HStack(spacing: 4) {
                            Text(muscleGroup)
                                .foregroundStyle(.secondary)
                            
                            if let equipment = exercise.equipment {
                                Text("·")
                                    .foregroundStyle(.tertiary)
                                Text(equipment)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if exercise.isBodyweight == true {
                                Text("·")
                                    .foregroundStyle(.tertiary)
                                Text("משקל גוף")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption)
                    }
                }
                
                Spacer()
                
                Button("הוסף סט", systemImage: "plus.circle.fill") {
                    print("DEBUG: ExerciseCard add set button tapped for \(exercise.name)")
                    onAddSet()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .font(.caption)
            }
            
            if isExpanded, let exerciseIdx = exerciseIndex {
                let sets = session.exerciseSessions[exerciseIdx].setLogs
                
                if !sets.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Sets grid
                    VStack(spacing: 4) {
                        ForEach(Array(sets.enumerated()), id: \.offset) { setIndex, setLog in
                            CompactSetRow(
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
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                }
                
                // Compact action chips
                HStack(spacing: 8) {
                    ActionChip(title: "שכפל סט אחרון") {
                        duplicateLastSet(in: exerciseIdx)
                    }
                    
                    ActionChip(title: "חימום") {
                        addWarmupSet(in: exerciseIdx)
                    }
                    
                    Menu {
                        Button("רמפת חימום") {
                            addWarmupRamp(in: exerciseIdx)
                        }
                        Button("נקה סטים", role: .destructive) {
                            clearAllSets(in: exerciseIdx)
                        }
                    } label: {
                        ActionChip(title: "עוד")
                    }
                    
                    Spacer()
                }
                
                // Exercise summary
                if !sets.isEmpty {
                    HStack {
                        Text("סה״כ סטים: \(sets.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("·")
                            .foregroundStyle(.tertiary)
                        
                        let volume = sets.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
                        Text("ווליום: \(volume, specifier: "%.0f") \(weightUnit.symbol)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            ensureExerciseExists()
        }
    }
    
    // MARK: - Set Management (same logic as before)
    
    private func ensureExerciseExists() {
        if !session.exerciseSessions.contains(where: { $0.exerciseName == exercise.name }) {
            let newExerciseSession = ExerciseSession(exerciseName: exercise.name, setLogs: [])
            session.exerciseSessions.append(newExerciseSession)
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
            // Add new set if no sets exist
            let newSet = SetLog(
                reps: lastDefaults?.reps ?? exercise.plannedReps ?? 8,
                weight: lastDefaults?.weight ?? 0,
                rpe: lastDefaults?.rpe,
                restSeconds: 120,
                isWarmup: false
            )
            session.exerciseSessions[exerciseIdx].setLogs.append(newSet)
            hapticFeedback(.medium)
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
        let workingSets = session.exerciseSessions[exerciseIdx].setLogs.filter { !($0.isWarmup ?? false) }
        let heaviestWeight = workingSets.max(by: { $0.weight < $1.weight })?.weight ?? 0
        
        let warmupSet = SetLog(
            reps: 8,
            weight: heaviestWeight * 0.6,
            rpe: nil,
            restSeconds: 60,
            isWarmup: true
        )
        
        session.exerciseSessions[exerciseIdx].setLogs.insert(warmupSet, at: 0)
        hapticFeedback(.medium)
    }
    
    private func addWarmupRamp(in exerciseIdx: Int) {
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
        
        session.exerciseSessions[exerciseIdx].setLogs.insert(contentsOf: warmupSets, at: 0)
        hapticFeedback(.success)
    }
    
    private func clearAllSets(in exerciseIdx: Int) {
        session.exerciseSessions[exerciseIdx].setLogs.removeAll()
        hapticFeedback(.heavy)
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

struct CompactSetRow: View {
    let setIndex: Int
    @Binding var setLog: SetLog
    let weightUnit: AppSettings.WeightUnit
    let weightStep: Double
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    @FocusState private var focusedField: Field?
    @State private var showActions: Bool = false
    
    private enum Field {
        case reps, weight
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Set number with warmup indicator
            HStack(spacing: 2) {
                Text("\(setIndex + 1)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(minWidth: 20)
                
                if setLog.isWarmup == true {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
            }
            .frame(width: 30, alignment: .leading)
            
            // Reps field
            CompactNumericField(
                title: "חזרות",
                unit: nil,
                value: Binding(
                    get: { Double(setLog.reps) },
                    set: { setLog.reps = Int($0) }
                ),
                step: 1,
                range: 1...100
            )
            .frame(width: 60)
            
            // Weight field
            CompactNumericField(
                title: "משקל",
                unit: weightUnit.symbol,
                value: $setLog.weight,
                step: weightStep,
                range: 0...999
            )
            .frame(width: 70)
            
            // RPE picker
            RPEChipsPicker(rpe: $setLog.rpe)
                .frame(width: 120)
            
            Spacer()
            
            // Action buttons (show on hover/focus)
            HStack(spacing: 4) {
                Button(action: {
                    setLog.isWarmup?.toggle()
                    hapticFeedback(.light)
                }) {
                    Image(systemName: setLog.isWarmup == true ? "flame.fill" : "flame")
                        .font(.caption2)
                        .foregroundStyle(setLog.isWarmup == true ? .orange : .secondary)
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                
                Button(action: {
                    onDuplicate()
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                
                Button(action: {
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }
            .opacity(showActions ? 1 : 0.6)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                showActions = hovering
            }
        }
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impact = UIImpactFeedbackGenerator(style: style)
        impact.impactOccurred()
    }
}

struct ActionChip: View {
    let title: String
    let action: (() -> Void)?
    
    init(title: String, action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6), in: Capsule())
                .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
    }
}