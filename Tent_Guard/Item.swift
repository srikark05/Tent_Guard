//
//  Item.swift
//  Tent_Guard
//
//  Created by Srikar Kunapuli  on 12/20/25.
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
