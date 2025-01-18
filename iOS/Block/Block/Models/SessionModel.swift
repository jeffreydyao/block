//
//  SessionModel.swift
//  Block
//
//  Created by Jeffrey Yao on 18/1/2025.
//

import Foundation
import SwiftUI

// Uses this hack here
// https://antonnyman.se/blog/using-appstorage-with-observable
@Observable class SessionModel {
    class Storage {
        @AppStorage("isActive") var isActive: Bool = false
        @AppStorage("startDate") var startDate: Date?
        @AppStorage("trigger") var trigger: SessionTrigger?
    }
    
    private let storage = Storage()
    
    var isActive: Bool {
        didSet { storage.isActive = isActive }
    }
    var startDate: Date? {
        didSet { storage.startDate = startDate }
    }
    var trigger: SessionTrigger? {
        didSet { storage.trigger = trigger }
    }
    
    init() {
        isActive = storage.isActive
        startDate = storage.startDate
        trigger = storage.trigger
    }
}

enum SessionTrigger: String, Codable {
    /// Session was initiated by tapping a NFC Block.
    case nfc
    /// Session was initiated by holding the block button down.
    case manual
}

/// MARK: - Mock values for previews.
extension SessionModel {
    static var previewActive: SessionModel {
        let session = SessionModel()
        session.isActive = true
        session.startDate = Date().addingTimeInterval(-30 * 60) // Session starts 30 minutes ago
        session.trigger = .manual
        return session
    }
}
