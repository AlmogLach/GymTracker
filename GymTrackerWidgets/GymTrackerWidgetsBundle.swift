//
//  GymTrackerWidgetsBundle.swift
//  GymTrackerWidgets
//
//  Created by almog lachiany on 23/09/2025.
//

import WidgetKit
import SwiftUI

@main
struct GymTrackerWidgetsBundle: WidgetBundle {
    var body: some Widget {
        GymTrackerWidgets()
        GymTrackerWidgetsControl()
        GymTrackerWidgetsLiveActivity()
    }
}
