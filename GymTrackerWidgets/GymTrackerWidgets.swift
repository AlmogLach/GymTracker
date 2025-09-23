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
    }
}