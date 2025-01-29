//
//  SessionService.swift
//  Block
//
//  Created by Jeffrey Yao on 18/1/2025.
//

import Foundation
import SwiftUI
import ManagedSettings
import FamilyControls


enum SessionError: LocalizedError {
    case alreadyActive
    
    var errorDescription: String? {
        switch self {
        case .alreadyActive:
            return "A session is already active."
        }
    }
}

class SessionService {
    // MARK: - Dependencies
    private let store: ManagedSettingsStore
    private let nfcService: NFCService
    private let settings: SettingsModel
    private let session: SessionModel
    
    init(
        settings: SettingsModel,
        session: SessionModel,
        nfcService: NFCService = .init(),
        store: ManagedSettingsStore = .init()
    ) {
        self.settings = settings
        self.session = session
        self.nfcService = nfcService
        self.store = store
    }
    
    // MARK: - Session Operations
    /// Starts a block session by verifying NFC and enabling shields
    func start(
        trigger: SessionTrigger
    ) async throws {
        if session.isActive {
            throw SessionError.alreadyActive
        }
        if trigger == .nfc {
            try await nfcService.scan(for: .startBlock)
        }
        print("start")
        session.isActive = true
        session.startDate = Date()
        session.trigger = trigger
        shieldApps()
    }
    
    /// Ends the current block session by verifying NFC and removing shields
    func end(
        skipNfcScan: Bool = false
    ) async throws {
        if !skipNfcScan {
            try await nfcService.scan(for: .endBlock)
        }
        session.isActive = false
        session.startDate = nil
        session.trigger = nil
        unshieldApps()
    }
    
    // MARK: - Shield Management
    private func shieldApps() {
        store.shield.applications = settings.blockedContent.applicationTokens
        store.shield.applicationCategories = .specific(settings.blockedContent.categoryTokens)
    }
    
    private func unshieldApps() {
        store.clearAllSettings()
    }
}
