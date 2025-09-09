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
    var unit: AppSettings.WeightUnit { settingsList.first?.weightUnit ?? .kg }

    var body: some View {
        NavigationStack {
            Text("גרפים וסטטיסטיקות - בשלב הבא (\(unit.symbol))")
                .navigationTitle("סטטיסטיקות")
        }
    }
}
