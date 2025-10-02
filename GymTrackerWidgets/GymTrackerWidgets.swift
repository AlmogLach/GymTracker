//
//  GymTrackerWidgets.swift
//  GymTrackerWidgets
//
//  Created by almog lachiany on 23/09/2025.
//

import WidgetKit
import SwiftUI
import ActivityKit

struct GymTrackerWidgets: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            RestLiveActivity()
        }
        
        // Home Screen Widgets
        GymTrackerSmallWidget()
        GymTrackerMediumWidget()
        GymTrackerLargeWidget()
    }
}

// MARK: - Small Widget
struct GymTrackerSmallWidget: Widget {
    let kind: String = "GymTrackerSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GymTrackerProvider()) { entry in
            GymTrackerSmallWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("אימון מהיר")
        .description("התחל אימון או צפה בסטטיסטיקות")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Medium Widget
struct GymTrackerMediumWidget: Widget {
    let kind: String = "GymTrackerMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GymTrackerProvider()) { entry in
            GymTrackerMediumWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("סקירת אימונים")
        .description("תוכנית האימונים והתקדמות השבוע")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Large Widget
struct GymTrackerLargeWidget: Widget {
    let kind: String = "GymTrackerLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GymTrackerProvider()) { entry in
            GymTrackerLargeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("דשבורד אימונים")
        .description("סטטיסטיקות מפורטות ותוכנית השבוע")
        .supportedFamilies([.systemLarge])
    }
}