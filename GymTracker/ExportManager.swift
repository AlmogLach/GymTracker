//
//  ExportManager.swift
//  GymTracker
//
//  Created by almog lachiany on 23/09/2025.
//

import Foundation
import SwiftData
import SwiftUI

class ExportManager: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Monthly Export
    func generateMonthlyExport(for month: Date) -> String {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month
        
        // Fetch all workout sessions for the month
        let sessions = fetchSessionsForMonth(start: startOfMonth, end: endOfMonth)
        
        // Generate the table
        return generateTableHTML(sessions: sessions, month: month)
    }
    
    private func fetchSessionsForMonth(start: Date, end: Date) -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.date >= start && session.date < end
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching sessions: \(error)")
            return []
        }
    }
    
    private func generateTableHTML(sessions: [WorkoutSession], month: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let monthName = formatter.string(from: month)
        
        var html = """
        <!DOCTYPE html>
        <html dir="rtl" lang="he">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>דוח חודשי - \(monthName)</title>
            <style>
                body {
                    font-family: 'Arial', sans-serif;
                    margin: 20px;
                    background-color: #f5f5f5;
                }
                .container {
                    background-color: white;
                    padding: 20px;
                    border-radius: 10px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }
                h1 {
                    text-align: center;
                    color: #333;
                    margin-bottom: 30px;
                }
                .instructions {
                    background-color: #e8f4f8;
                    padding: 15px;
                    border-radius: 8px;
                    margin-bottom: 20px;
                    border-right: 4px solid #007AFF;
                }
                .instructions h3 {
                    margin-top: 0;
                    color: #007AFF;
                }
                .instructions p {
                    margin: 5px 0;
                    line-height: 1.5;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 20px;
                    font-size: 12px;
                }
                th, td {
                    border: 1px solid #ddd;
                    padding: 8px;
                    text-align: center;
                    vertical-align: middle;
                }
                th {
                    background-color: #007AFF;
                    color: white;
            font-weight: bold;
                }
                .exercise-header {
                    background-color: #f0f0f0;
                    font-weight: bold;
                }
                .date-cell {
                    background-color: #e8f4f8;
                    font-weight: bold;
                    min-width: 120px;
                }
                .weight-cell {
                    background-color: #fff3cd;
                    min-width: 60px;
                }
                .morning-weight {
                    background-color: #d4edda;
                }
                .summary {
                    margin-top: 30px;
                    padding: 20px;
                    background-color: #f8f9fa;
                    border-radius: 8px;
                }
                .summary h3 {
                    color: #007AFF;
                    margin-top: 0;
                }
                .stat-item {
                    display: inline-block;
                    margin: 10px 20px 10px 0;
                    padding: 10px;
                    background-color: white;
                    border-radius: 5px;
                    border: 1px solid #ddd;
                }
                .stat-value {
                    font-size: 18px;
                    font-weight: bold;
                    color: #007AFF;
                }
                .stat-label {
                    font-size: 12px;
                    color: #666;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>דוח חודשי - \(monthName)</h1>
                
                <div class="instructions">
                    <h3>הוראות מילוי:</h3>
                    <p>• למלא את השורה הראשונה מיד אחרי אימון\סבב ראשון, ומשם - לעדכן את השורה הבאה כל שבועיים.</p>
                    <p>• להישקל בבוקר, לפני שאכלת או שתית, אחרי שירותים.</p>
                    <p>• משקלי עבודה בחדר כושר - לכתוב את הסה"כ משקל (שני הצדדים יחדיו), כולל המוט (בתרגילים הרלוונטיים). מוט של סמיט מאשין - לא להחשיב.</p>
                </div>
        """
        
        // Generate exercise summary
        let exerciseSummary = generateExerciseSummary(sessions: sessions)
        html += generateSummarySection(exerciseSummary: exerciseSummary)
        
        // Generate main table
        html += generateMainTable(sessions: sessions)
        
        html += """
            </div>
        </body>
        </html>
        """
        
        return html
    }
    
    private func generateExerciseSummary(sessions: [WorkoutSession]) -> [String: (totalSets: Int, maxWeight: Double, totalVolume: Double)] {
        var summary: [String: (totalSets: Int, maxWeight: Double, totalVolume: Double)] = [:]
        
        for session in sessions {
            for exerciseSession in session.exerciseSessions {
                let exerciseName = exerciseSession.exerciseName
                let workingSets = exerciseSession.setLogs.filter { !($0.isWarmup ?? false) }
                
                if !workingSets.isEmpty {
                    let totalSets = workingSets.count
                    let maxWeight = workingSets.map { $0.weight }.max() ?? 0
                    let totalVolume = workingSets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
                    
                    if let existing = summary[exerciseName] {
                        summary[exerciseName] = (
                            totalSets: existing.totalSets + totalSets,
                            maxWeight: max(existing.maxWeight, maxWeight),
                            totalVolume: existing.totalVolume + totalVolume
                        )
                    } else {
                        summary[exerciseName] = (totalSets: totalSets, maxWeight: maxWeight, totalVolume: totalVolume)
                    }
                }
            }
        }
        
        return summary
    }
    
    private func generateSummarySection(exerciseSummary: [String: (totalSets: Int, maxWeight: Double, totalVolume: Double)]) -> String {
        let totalWorkouts = exerciseSummary.values.reduce(0) { $0 + $1.totalSets }
        let totalVolume = exerciseSummary.values.reduce(0) { $0 + $1.totalVolume }
        let uniqueExercises = exerciseSummary.count
        
        return """
        <div class="summary">
            <h3>סיכום החודש</h3>
            <div class="stat-item">
                <div class="stat-value">\(totalWorkouts)</div>
                <div class="stat-label">סטים סה"כ</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">\(String(format: "%.1f", totalVolume))</div>
                <div class="stat-label">ק"ג נפח סה"כ</div>
            </div>
            <div class="stat-item">
                <div class="stat-value">\(uniqueExercises)</div>
                <div class="stat-label">תרגילים שונים</div>
            </div>
        </div>
        """
    }
    
    private func generateMainTable(sessions: [WorkoutSession]) -> String {
        // Get all unique exercises from the month
        let allExercises = Set(sessions.flatMap { $0.exerciseSessions.map { $0.exerciseName } })
        let sortedExercises = Array(allExercises).sorted()
        
        var html = """
        <table>
            <thead>
                <tr>
                    <th class="date-cell">תאריך</th>
                    <th class="morning-weight">משקל בוקר</th>
        """
        
        // Add exercise columns
        for exercise in sortedExercises {
            html += "<th class=\"exercise-header\">\(exercise)</th>"
        }
        
        html += """
                </tr>
            </thead>
            <tbody>
        """
        
        // Group sessions by date
        let groupedSessions = Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.date)
        }
        
        let sortedDates = groupedSessions.keys.sorted()
        
        for date in sortedDates {
            let daySessions = groupedSessions[date] ?? []
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM"
            let dateString = dateFormatter.string(from: date)
            
            html += "<tr>"
            html += "<td class=\"date-cell\">\(dateString)</td>"
            html += "<td class=\"morning-weight weight-cell\"></td>" // Empty for user to fill
            
            // Add exercise data
            for exercise in sortedExercises {
                let exerciseData = getExerciseDataForDate(daySessions: daySessions, exerciseName: exercise)
                html += "<td class=\"weight-cell\">\(exerciseData)</td>"
            }
            
            html += "</tr>"
        }
        
        html += """
            </tbody>
        </table>
        """
        
        return html
    }
    
    private func getExerciseDataForDate(daySessions: [WorkoutSession], exerciseName: String) -> String {
        for session in daySessions {
            if let exerciseSession = session.exerciseSessions.first(where: { $0.exerciseName == exerciseName }) {
                let workingSets = exerciseSession.setLogs.filter { !($0.isWarmup ?? false) }
                if let bestSet = workingSets.max(by: { $0.weight < $1.weight }) {
                    return "\(String(format: "%.1f", bestSet.weight)) × \(bestSet.reps)"
                }
            }
        }
        return ""
    }
    
    // MARK: - Export to Files
    func exportToFile(for month: Date) -> URL? {
        let html = generateMonthlyExport(for: month)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let fileName = "gymtracker-\(formatter.string(from: month)).html"
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        do {
            try html.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing file: \(error)")
            return nil
        }
    }
    
    func shareExport(for month: Date) -> [Any] {
        guard let fileURL = exportToFile(for: month) else { return [] }
        return [fileURL]
    }
}
