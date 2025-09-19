//
//  WorkoutTemplates.swift
//  GymTracker
//
//  Template-related views and models for workout templates
//

import SwiftUI

// MARK: - Template Models

struct WorkoutTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let exercises: Int
    let duration: String
    let category: WorkoutEditView.TemplateCategory
    let difficulty: Difficulty
    let isFeatured: Bool
    
    enum Difficulty: String, CaseIterable {
        case beginner = "מתחיל"
        case intermediate = "בינוני"
        case advanced = "מתקדם"
        
        var color: Color {
            switch self {
            case .beginner: return AppTheme.success
            case .intermediate: return AppTheme.warning
            case .advanced: return AppTheme.error
            }
        }
    }
}

// MARK: - Template Views

struct TemplateCategoryCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.s8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s16)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}

struct FeaturedTemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s12) {
            // Header with badge
            HStack {
                Text("מומלץ")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.s8)
                    .padding(.vertical, AppTheme.s4)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.warning)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.s8) {
                Text(template.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primary)
                
                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(template.exercises)", systemImage: "dumbbell")
                    Spacer()
                    Label(template.duration, systemImage: "clock")
                }
                .font(.caption2)
                .foregroundStyle(AppTheme.secondary)
            }
            
            Spacer()
            
            Button("השתמש בתבנית") {
                onTap()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.s8)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(AppTheme.s16)
        .frame(width: 200, height: 180)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct TemplateGridCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s8) {
            HStack {
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primary)
                
                Spacer()
                
                Circle()
                    .fill(template.difficulty.color)
                    .frame(width: 8, height: 8)
            }
            
            Text(template.description)
                .font(.caption)
                .foregroundStyle(AppTheme.secondary)
                .lineLimit(2)
            
            HStack {
                Label("\(template.exercises)", systemImage: "dumbbell")
                Spacer()
                Label(template.duration, systemImage: "clock")
            }
            .font(.caption2)
            .foregroundStyle(AppTheme.secondary)
            
            Button("השתמש") {
                onTap()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.s6)
            .background(AppTheme.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(AppTheme.s12)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}

struct CustomTemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.s12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(template.exercises)")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("תרגילים")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondary)
            }
            
            Button(action: onTap) {
                Image(systemName: "chevron.backward")
                    .font(.caption)
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(AppTheme.s16)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}
