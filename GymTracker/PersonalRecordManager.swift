//
//  PersonalRecordManager.swift
//  GymTracker
//
//  Manages personal records detection and tracking
//

import Foundation
import SwiftData

class PersonalRecordManager {
    static let shared = PersonalRecordManager()
    
    private init() {}
    
    // MARK: - PR Detection
    
    func checkForPersonalRecord(setLog: SetLog, exerciseName: String, modelContext: ModelContext) -> PersonalRecord? {
        // Don't count warmup sets as PRs
        guard !(setLog.isWarmup ?? false) else { return nil }
        
        // Check if this is a new PR
        if let existingPR = getCurrentPR(for: exerciseName, reps: setLog.reps, modelContext: modelContext) {
            // Check if this beats the existing PR
            if setLog.weight > existingPR.weight {
                return createPersonalRecord(from: setLog, exerciseName: exerciseName, modelContext: modelContext)
            }
        } else {
            // No existing PR for this rep range, this is automatically a PR
            return createPersonalRecord(from: setLog, exerciseName: exerciseName, modelContext: modelContext)
        }
        
        return nil
    }
    
    private func createPersonalRecord(from setLog: SetLog, exerciseName: String, modelContext: ModelContext) -> PersonalRecord {
        let pr = PersonalRecord(
            exerciseName: exerciseName,
            weight: setLog.weight,
            reps: setLog.reps,
            date: Date(),
            isWarmup: setLog.isWarmup ?? false,
            notes: setLog.notes
        )
        
        modelContext.insert(pr)
        
        do {
            try modelContext.save()
            print("🏆 New Personal Record: \(exerciseName) - \(setLog.weight)kg x \(setLog.reps)")
        } catch {
            print("❌ Failed to save personal record: \(error)")
        }
        
        return pr
    }
    
    // MARK: - PR Queries
    
    func getCurrentPR(for exerciseName: String, reps: Int, modelContext: ModelContext) -> PersonalRecord? {
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { pr in
                pr.exerciseName == exerciseName && pr.reps == reps
            },
            sortBy: [SortDescriptor(\.weight, order: .reverse)]
        )
        
        do {
            let records = try modelContext.fetch(descriptor)
            return records.first
        } catch {
            print("❌ Failed to fetch personal records: \(error)")
            return nil
        }
    }
    
    func getAllPRs(for exerciseName: String, modelContext: ModelContext) -> [PersonalRecord] {
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { pr in
                pr.exerciseName == exerciseName
            },
            sortBy: [SortDescriptor(\.reps, order: .forward), SortDescriptor(\.weight, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch all personal records: \(error)")
            return []
        }
    }
    
    func getAllPRs(modelContext: ModelContext) -> [PersonalRecord] {
        let descriptor = FetchDescriptor<PersonalRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch all personal records: \(error)")
            return []
        }
    }
    
    func getRecentPRs(limit: Int = 10, modelContext: ModelContext) -> [PersonalRecord] {
        let descriptor = FetchDescriptor<PersonalRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allPRs = try modelContext.fetch(descriptor)
            return Array(allPRs.prefix(limit))
        } catch {
            print("❌ Failed to fetch recent personal records: \(error)")
            return []
        }
    }
    
    // MARK: - PR Analysis
    
    func getPRStats(for exerciseName: String, modelContext: ModelContext) -> PRStats? {
        let prs = getAllPRs(for: exerciseName, modelContext: modelContext)
        guard !prs.isEmpty else { return nil }
        
        let maxWeight = prs.map { $0.weight }.max() ?? 0
        let totalPRs = prs.count
        let recentPR = prs.first
        let firstPR = prs.last
        
        return PRStats(
            exerciseName: exerciseName,
            maxWeight: maxWeight,
            totalPRs: totalPRs,
            recentPR: recentPR,
            firstPR: firstPR,
            allPRs: prs
        )
    }
    
    func getOverallPRStats(modelContext: ModelContext) -> OverallPRStats {
        let allPRs = getAllPRs(modelContext: modelContext)
        
        let totalPRs = allPRs.count
        let uniqueExercises = Set(allPRs.map { $0.exerciseName }).count
        let recentPRs = Array(allPRs.prefix(5))
        
        // Calculate total weight lifted in PRs
        let totalWeight = allPRs.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        
        return OverallPRStats(
            totalPRs: totalPRs,
            uniqueExercises: uniqueExercises,
            recentPRs: recentPRs,
            totalWeight: totalWeight
        )
    }
}

// MARK: - Supporting Types

struct PRStats {
    let exerciseName: String
    let maxWeight: Double
    let totalPRs: Int
    let recentPR: PersonalRecord?
    let firstPR: PersonalRecord?
    let allPRs: [PersonalRecord]
}

struct OverallPRStats {
    let totalPRs: Int
    let uniqueExercises: Int
    let recentPRs: [PersonalRecord]
    let totalWeight: Double
}
