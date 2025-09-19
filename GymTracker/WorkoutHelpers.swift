//
//  WorkoutHelpers.swift
//  GymTracker
//
//  Helper views and components for workout management
//

import SwiftUI
import SwiftData

// MARK: - Helper Views

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.s8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.s16)
            .background(AppTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
        }
        .buttonStyle(.plain)
    }
}

struct SelectedPlanCard: View {
    let plan: WorkoutPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.s12) {
                VStack(alignment: .leading, spacing: AppTheme.s4) {
                    Text(plan.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primary)
                    
                    Text(plan.planType.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(plan.exercises.count) תרגילים")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.backward")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(AppTheme.s16)
            .background(AppTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
        }
        .buttonStyle(.plain)
    }
}

struct PlanPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let plans: [WorkoutPlan]
    @Binding var selectedPlan: WorkoutPlan?
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.s12) {
                    ForEach(plans, id: \.id) { plan in
                        Button(action: {
                            selectedPlan = plan
                            onDismiss()
                        }) {
                            HStack(spacing: AppTheme.s12) {
                                VStack(alignment: .leading, spacing: AppTheme.s4) {
                                    Text(plan.name)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(AppTheme.primary)
                                    
                                    Text(plan.planType.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(plan.exercises.count) תרגילים")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Image(systemName: "chevron.backward")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(AppTheme.s16)
                            .background(AppTheme.secondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.s20)
                .padding(.bottom, 100)
            }
            .navigationTitle("בחר תוכנית")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("ביטול") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct TemplatePreviewCard: View {
    let template: WorkoutTemplate
    let onUseTemplate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.s16) {
            // Template header
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.s4) {
                    Text(template.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primary)
                    
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(template.difficulty.color)
                    .frame(width: 12, height: 12)
            }
            
            // Template details
            HStack(spacing: AppTheme.s16) {
                Label("\(template.exercises)", systemImage: "dumbbell")
                Spacer()
                Label(template.duration, systemImage: "clock")
                Spacer()
                Label(template.difficulty.rawValue, systemImage: "star")
            }
            .font(.caption)
            .foregroundStyle(AppTheme.secondary)
            
            // Use template button
            Button("השתמש בתבנית") {
                onUseTemplate()
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.s12)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(AppTheme.s20)
        .background(AppTheme.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
