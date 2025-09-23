//
//  ExerciseLibrary.swift
//  GymTracker
//
//  Common exercise catalog for quick selection
//

import Foundation
import SwiftUI

struct ExerciseLibraryItem: Identifiable, Hashable {
    enum BodyPart: String, CaseIterable { case chest = "חזה", back = "גב", legs = "רגליים", shoulders = "כתפיים", arms = "ידיים", core = "ליבה", fullBody = "כל הגוף" }
    let id = UUID()
    let name: String
    let bodyPart: BodyPart
    let equipment: String?
    let isBodyweight: Bool
}

enum ExerciseLibrary {
    static let exercises: [ExerciseLibraryItem] = [
        // Chest
        ExerciseLibraryItem(name: "לחיצת חזה במוט", bodyPart: .chest, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת חזה בשיפוע חיובי במוט", bodyPart: .chest, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת חזה בשיפוע שלילי במוט", bodyPart: .chest, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת חזה בדאמבלים", bodyPart: .chest, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת חזה בשיפוע חיובי בדאמבלים", bodyPart: .chest, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת חזה בשיפוע שלילי בדאמבלים", bodyPart: .chest, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "פלייס בדאמבלים", bodyPart: .chest, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "פלייס במכונה", bodyPart: .chest, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "קרוס-אובר בכבל", bodyPart: .chest, equipment: "כבל", isBodyweight: false),
        ExerciseLibraryItem(name: "קרוס-אובר בפולי נמוך", bodyPart: .chest, equipment: "כבל", isBodyweight: false),
        ExerciseLibraryItem(name: "קרוס-אובר בפולי עליון", bodyPart: .chest, equipment: "כבל", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת חזה במכונה", bodyPart: .chest, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "שכיבות סמיכה", bodyPart: .chest, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "שכיבות סמיכה בשיפוע", bodyPart: .chest, equipment: nil, isBodyweight: true),

        // Back
        ExerciseLibraryItem(name: "עליות מתח", bodyPart: .back, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "עליות מתח באחיזה הפוכה", bodyPart: .back, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "מתח באחיזה צרה", bodyPart: .back, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "פולי עליון", bodyPart: .back, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "פולי עליון אחיזה הפוכה", bodyPart: .back, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "חתירה במוט", bodyPart: .back, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "חתירה בדאמבלים", bodyPart: .back, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "חתירה בכבל בישיבה", bodyPart: .back, equipment: "כבל", isBodyweight: false),
        ExerciseLibraryItem(name: "חתירת T-בר", bodyPart: .back, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "פייס-פול", bodyPart: .back, equipment: "כבל", isBodyweight: false),
        ExerciseLibraryItem(name: "פשיטת זרוע ישרה בפולי", bodyPart: .back, equipment: "כבל", isBodyweight: false),
        ExerciseLibraryItem(name: "היפר-אקסטנשן גב", bodyPart: .back, equipment: "מכונה", isBodyweight: false),

        // Shoulders
        ExerciseLibraryItem(name: "לחיצת כתפיים בעמידה", bodyPart: .shoulders, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת כתפיים בדאמבלים", bodyPart: .shoulders, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת כתפיים בישיבה בדאמבלים", bodyPart: .shoulders, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "ארנולד פרס", bodyPart: .shoulders, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "צידיים בדאמבלים", bodyPart: .shoulders, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "הרמות קדמיות בדאמבלים", bodyPart: .shoulders, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "הרחקה לצד במכונה", bodyPart: .shoulders, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "ריר דלט פליי בדאמבלים", bodyPart: .shoulders, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "אפרייט ראו", bodyPart: .shoulders, equipment: "מוט", isBodyweight: false),

        // Arms - Biceps
        ExerciseLibraryItem(name: "בייספס בעמידה", bodyPart: .arms, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "בייספס בדאמבלים", bodyPart: .arms, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "בייספס במוט W", bodyPart: .arms, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "האמר קארל (פטיש)", bodyPart: .arms, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "בייספס על ספסל כומר", bodyPart: .arms, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "קונסנטריישן קארל", bodyPart: .arms, equipment: "דאמבלים", isBodyweight: false),

        // Arms - Triceps
        ExerciseLibraryItem(name: "פוש דאון טרייספס", bodyPart: .arms, equipment: "כבל", isBodyweight: false),
        ExerciseLibraryItem(name: "פוש דאון בחבל", bodyPart: .arms, equipment: "כבל", isBodyweight: false),
        ExerciseLibraryItem(name: "פשיטת טרייספס מעל הראש בדאמבל", bodyPart: .arms, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "פשיטת טרייספס מעל הראש בכבל", bodyPart: .arms, equipment: "כבל", isBodyweight: false),
        ExerciseLibraryItem(name: "סקאל-קראשר (פשיטת טרייספס בשכיבה)", bodyPart: .arms, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת חזה באחיזה צרה", bodyPart: .arms, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "מקבילים", bodyPart: .arms, equipment: nil, isBodyweight: true),

        // Legs
        ExerciseLibraryItem(name: "סקוואט", bodyPart: .legs, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "פרונט סקוואט", bodyPart: .legs, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "גובליט סקוואט", bodyPart: .legs, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "לאנג׳ קדמי", bodyPart: .legs, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "לאנג׳ הליכה", bodyPart: .legs, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "לאנג׳ לאחור", bodyPart: .legs, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "לאנג׳ צדדי", bodyPart: .legs, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "ספליט סקוואט בולגרי", bodyPart: .legs, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת רגליים", bodyPart: .legs, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "דד-ליפט", bodyPart: .legs, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "דדליפט רומני", bodyPart: .legs, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "דדליפט רומני בדאמבלים", bodyPart: .legs, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "כפיפת ברכיים בשכיבה", bodyPart: .legs, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "כפיפת ברכיים בישיבה", bodyPart: .legs, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "פשיטת ברכיים", bodyPart: .legs, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "היפ תראסט במוט", bodyPart: .legs, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "גלוט ברידג׳", bodyPart: .legs, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "הרמות שוק בעמידה", bodyPart: .legs, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "הרמות שוק בישיבה", bodyPart: .legs, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "האק סקוואט", bodyPart: .legs, equipment: "מכונה", isBodyweight: false),

        // Core
        ExerciseLibraryItem(name: "פלאנק", bodyPart: .core, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "פלאנק צד", bodyPart: .core, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "כפיפות בטן", bodyPart: .core, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "סיט-אפ", bodyPart: .core, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "הרמות רגליים בתלייה", bodyPart: .core, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "הרמות רגליים בשכיבה", bodyPart: .core, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "קרנצ׳ בכבל", bodyPart: .core, equipment: "כבל", isBodyweight: false),
        ExerciseLibraryItem(name: "רוסיאן טוויסט", bodyPart: .core, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "פאלוף פרס", bodyPart: .core, equipment: "כבל", isBodyweight: false),

        // Full Body / Power
        ExerciseLibraryItem(name: "דדליפט סומו", bodyPart: .fullBody, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "קלין אנד פרס", bodyPart: .fullBody, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "קטלבל סווינג", bodyPart: .fullBody, equipment: "קטלבל", isBodyweight: false),
        ExerciseLibraryItem(name: "בורפיז", bodyPart: .fullBody, equipment: nil, isBodyweight: true)
    ]
}

// MARK: - Preview Views

struct ExerciseLibraryPreview: View {
    @State private var selectedBodyPart: ExerciseLibraryItem.BodyPart? = nil
    
    private var filteredExercises: [ExerciseLibraryItem] {
        if let selectedBodyPart = selectedBodyPart {
            return ExerciseLibrary.exercises.filter { $0.bodyPart == selectedBodyPart }
        }
        return ExerciseLibrary.exercises
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Body part filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ExerciseLibraryItem.BodyPart.allCases, id: \.self) { bodyPart in
                            Button(action: {
                                selectedBodyPart = selectedBodyPart == bodyPart ? nil : bodyPart
                            }) {
                                Text(bodyPart.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        selectedBodyPart == bodyPart ? AppTheme.accent : Color(.systemGray6),
                                        in: Capsule()
                                    )
                                    .foregroundStyle(selectedBodyPart == bodyPart ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Exercise list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredExercises) { exercise in
                            ExerciseLibraryRow(exercise: exercise)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationTitle("ספריית תרגילים")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ExerciseLibraryRow: View {
    let exercise: ExerciseLibraryItem
    var onSelect: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Body part icon
            Image(systemName: bodyPartIcon)
                .font(.title2)
                .foregroundStyle(bodyPartColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(bodyPartColor.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(exercise.bodyPart.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let equipment = exercise.equipment {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(equipment)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if exercise.isBodyweight {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text("משקל גוף")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: {
                onSelect?()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var bodyPartIcon: String {
        switch exercise.bodyPart {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.pull"
        case .legs: return "figure.walk"
        case .shoulders: return "figure.strengthtraining.functional"
        case .arms: return "figure.arms.open"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
    
    private var bodyPartColor: Color {
        switch exercise.bodyPart {
        case .chest: return .red
        case .back: return .blue
        case .legs: return .green
        case .shoulders: return .orange
        case .arms: return .purple
        case .core: return .yellow
        case .fullBody: return .indigo
        }
    }
}

// MARK: - Previews

#Preview("Exercise Library") {
    ExerciseLibraryPreview()
}

#Preview("Exercise Library Row") {
    VStack(spacing: 8) {
        ExerciseLibraryRow(exercise: ExerciseLibrary.exercises[0])
        ExerciseLibraryRow(exercise: ExerciseLibrary.exercises[6]) // Bodyweight exercise
        ExerciseLibraryRow(exercise: ExerciseLibrary.exercises[3]) // Equipment exercise
    }
    .padding()
}

#Preview("Body Part Filter") {
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
            ForEach(ExerciseLibraryItem.BodyPart.allCases, id: \.self) { bodyPart in
                Text(bodyPart.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
    }
}


