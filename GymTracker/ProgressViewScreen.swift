//
//  ProgressViewScreen.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

struct ProgressViewScreen: View {
    @Query private var settingsList: [AppSettings]
    @Query(sort: [SortDescriptor(\WorkoutSession.date, order: .reverse)]) private var sessions: [WorkoutSession]
    
    var unit: AppSettings.WeightUnit { settingsList.first?.weightUnit ?? .kg }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Quick stats overview
                    quickStatsGrid
                    
                    // Coming soon section
                    comingSoonSection
                    
                    // Feature roadmap
                    featureRoadmapSection
                }
                .padding(16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("סטטיסטיקות")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ProgressStatCard(
                title: "סה״כ אימונים",
                value: "\(sessions.count)",
                icon: "figure.strengthtraining.traditional",
                color: .blue
            )
            
            ProgressStatCard(
                title: "השבוע",
                value: "\(thisWeekSessions)",
                icon: "calendar.badge.checkmark",
                color: .green
            )
            
            ProgressStatCard(
                title: "יחידת משקל",
                value: unit.symbol,
                icon: "scalemass.fill",
                color: .orange
            )
            
            ProgressStatCard(
                title: "נפח השבוע",
                value: String(format: "%.0f", totalVolumeThisWeek),
                icon: "chart.bar.fill",
                color: .purple
            )
        }
    }
    
    private var comingSoonSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                // Icon and title
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.blue)
                }
                
                VStack(spacing: 8) {
                    Text("גרפים מתקדמים")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    
                    Text("בקרוב נוסיף מעקב מתקדם אחר ההתקדמות שלך")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var featureRoadmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("תכונות עתידיות")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            VStack(spacing: 12) {
                FeatureRoadmapItem(
                    title: "מעקב התקדמות לתרגיל",
                    description: "גרפים של משקל וחזרות לכל תרגיל",
                    icon: "chart.xyaxis.line",
                    color: .green
                )
                
                FeatureRoadmapItem(
                    title: "ניתוח נפח אימונים",
                    description: "מעקב אחר נפח שבועי וחודשי",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                FeatureRoadmapItem(
                    title: "יעדים והישגים",
                    description: "הגדר יעדים וקבל מדליות",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                FeatureRoadmapItem(
                    title: "השוואת תקופות",
                    description: "השווה ביצועים בין תקופות שונות",
                    icon: "arrow.left.arrow.right",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Computed Properties
    
    private var thisWeekSessions: Int {
        let calendar = Calendar.current
        return sessions.filter { session in
            calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: Date())
        }.count
    }
    
    private var totalVolumeThisWeek: Double {
        let calendar = Calendar.current
        let thisWeekSessions = sessions.filter { session in
            calendar.dateInterval(of: .weekOfYear, for: session.date) == calendar.dateInterval(of: .weekOfYear, for: Date())
        }
        let totalKg = thisWeekSessions.reduce(0.0) { total, session in
            total + session.exerciseSessions.flatMap { $0.setLogs }.reduce(0.0) { $0 + (Double($1.reps) * $1.weight) }
        }
        return unit.toDisplay(fromKg: totalKg)
    }
}

struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct FeatureRoadmapItem: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "clock.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
