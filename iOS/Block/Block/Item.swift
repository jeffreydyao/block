//
//  Item.swift
//  Block
//
//  Created by Jeffrey Yao on 11/1/2025.
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