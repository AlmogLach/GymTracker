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
}

enum ExerciseLibrary {
    static let exercises: [ExerciseLibraryItem] = [
        ExerciseLibraryItem(name: "לחיצת חזה במוט", bodyPart: .chest, equipment: "מוט"),
        ExerciseLibraryItem(name: "לחיצת חזה בדאמבלים", bodyPart: .chest, equipment: "דאמבלים"),
        ExerciseLibraryItem(name: "פלייס במכונה", bodyPart: .chest, equipment: "מכונה"),
        ExerciseLibraryItem(name: "סקוואט", bodyPart: .legs, equipment: "מוט"),
        ExerciseLibraryItem(name: "לחיצת רגליים", bodyPart: .legs, equipment: "מכונה"),
        ExerciseLibraryItem(name: "דד-ליפט", bodyPart: .legs, equipment: "מוט"),
        ExerciseLibraryItem(name: "עליות מתח", bodyPart: .back, equipment: nil),
        ExerciseLibraryItem(name: "חתירה במוט", bodyPart: .back, equipment: "מוט"),
        ExerciseLibraryItem(name: "חתירה בדאמבלים", bodyPart: .back, equipment: "דאמבלים"),
        ExerciseLibraryItem(name: "פולי עליון", bodyPart: .back, equipment: "מכונה"),
        ExerciseLibraryItem(name: "לחיצת כתפיים בעמידה", bodyPart: .shoulders, equipment: "מוט"),
        ExerciseLibraryItem(name: "לחיצת כתפיים בדאמבלים", bodyPart: .shoulders, equipment: "דאמבלים"),
        ExerciseLibraryItem(name: "צידיים בדאמבלים", bodyPart: .shoulders, equipment: "דאמבלים"),
        ExerciseLibraryItem(name: "בייספס בעמידה", bodyPart: .arms, equipment: "מוט"),
        ExerciseLibraryItem(name: "בייספס בדאמבלים", bodyPart: .arms, equipment: "דאמבלים"),
        ExerciseLibraryItem(name: "פוש דאון טרייספס", bodyPart: .arms, equipment: "כבל"),
        ExerciseLibraryItem(name: "מקבילים", bodyPart: .arms, equipment: nil),
        ExerciseLibraryItem(name: "פלאנק", bodyPart: .core, equipment: nil),
        ExerciseLibraryItem(name: "כפיפות בטן", bodyPart: .core, equipment: nil),
    ]
}


