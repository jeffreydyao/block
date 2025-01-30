//
//  SessionAttributes.swift
//  Block
//
//  Created by Jeffrey Yao on 29/1/2025.
//
import Foundation
import ActivityKit

struct SessionAttributes: ActivityAttributes {
    typealias SessionState = ContentState

    // Dynamic data in Live Activities
    public struct ContentState: Codable & Hashable {
        let isActive: Bool
    }
    
    let startDate: Date
}
