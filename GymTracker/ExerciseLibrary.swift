//
//  ExerciseLibrary.swift
//  GymTracker
//
//  Common exercise catalog for quick selection
//

import Foundation

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
        ExerciseLibraryItem(name: "לחיצת חזה במוט", bodyPart: .chest, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת חזה בדאמבלים", bodyPart: .chest, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "פלייס במכונה", bodyPart: .chest, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "סקוואט", bodyPart: .legs, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת רגליים", bodyPart: .legs, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "דד-ליפט", bodyPart: .legs, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "עליות מתח", bodyPart: .back, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "חתירה במוט", bodyPart: .back, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "חתירה בדאמבלים", bodyPart: .back, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "פולי עליון", bodyPart: .back, equipment: "מכונה", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת כתפיים בעמידה", bodyPart: .shoulders, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "לחיצת כתפיים בדאמבלים", bodyPart: .shoulders, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "צידיים בדאמבלים", bodyPart: .shoulders, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "בייספס בעמידה", bodyPart: .arms, equipment: "מוט", isBodyweight: false),
        ExerciseLibraryItem(name: "בייספס בדאמבלים", bodyPart: .arms, equipment: "דאמבלים", isBodyweight: false),
        ExerciseLibraryItem(name: "פוש דאון טרייספס", bodyPart: .arms, equipment: "כבל", isBodyweight: false),
        ExerciseLibraryItem(name: "מקבילים", bodyPart: .arms, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "פלאנק", bodyPart: .core, equipment: nil, isBodyweight: true),
        ExerciseLibraryItem(name: "כפיפות בטן", bodyPart: .core, equipment: nil, isBodyweight: true),
    ]
}


