//
//  GymTrackerWidgetsLiveActivity.swift
//  GymTrackerWidgets
//
//  Created by almog lachiany on 23/09/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GymTrackerWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GymTrackerWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GymTrackerWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension GymTrackerWidgetsAttributes {
    fileprivate static var preview: GymTrackerWidgetsAttributes {
        GymTrackerWidgetsAttributes(name: "World")
    }
}

extension GymTrackerWidgetsAttributes.ContentState {
    fileprivate static var smiley: GymTrackerWidgetsAttributes.ContentState {
        GymTrackerWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GymTrackerWidgetsAttributes.ContentState {
         GymTrackerWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GymTrackerWidgetsAttributes.preview) {
   GymTrackerWidgetsLiveActivity()
} contentStates: {
    GymTrackerWidgetsAttributes.ContentState.smiley
    GymTrackerWidgetsAttributes.ContentState.starEyes
}
