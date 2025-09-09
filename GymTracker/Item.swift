//
//  Item.swift
//  GymTracker
//
//  Created by almog lachiany on 09/09/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
