//
//  SettingsView.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]

    var settings: AppSettings {
        if let s = settingsList.first { return s }
        let s = AppSettings()
        modelContext.insert(s)
        return s
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("יחידות משקל", selection: Binding(get: { settings.weightUnit }, set: { settings.weightUnit = $0 })) {
                    ForEach(AppSettings.WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                }
            }
            .navigationTitle("הגדרות")
        }
    }
}
