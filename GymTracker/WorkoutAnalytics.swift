//
//  WorkoutAnalytics.swift
//  GymTracker
//
//  Analytics and progress tracking views
//

import SwiftUI

// MARK: - Analytics Views

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.s8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s12)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.r16))
    }
}

struct ProgressMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppTheme.s6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.s8)
        .background(AppTheme.tertiaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ProgressInsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.s12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.primary)
                
                Text(value)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondary)
            }
            
            Spacer()
        }
        .padding(AppTheme.s12)
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
