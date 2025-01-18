//
//  SettingsModel.swift
//  Block
//
//  Created by Jeffrey Yao on 18/1/2025.
//

import Foundation
import SwiftUI
import FamilyControls

@Observable class SettingsModel {
    /// FamilyActivitySelection representing the content to block. Includes apps and websites.
    var blockedContent: FamilyActivitySelection = .init() {
        didSet {
            let encoder = PropertyListEncoder()
            // Save whenever blockedContent changes
            if let data = try? encoder.encode(blockedContent) {
                UserDefaults.standard.set(data, forKey: "blockedContent")
                
            }
        }
    }
    
    init() {
        // Load FamilyActivitySelection from UserDefaults, enabling persisted settings
        if let data = UserDefaults.standard.data(forKey: "blockedContent") {
            // Default encoder for UserDefaults is PropertyListDecoder
            let decoder = PropertyListDecoder()
            if let decoded = try? decoder.decode(FamilyActivitySelection.self, from: data) {
                blockedContent = decoded
            }
        }
    }
}


