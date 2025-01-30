//
//  SessionService.swift
//  Block
//
//  Created by Jeffrey Yao on 18/1/2025.
//

import ActivityKit
import FamilyControls
import Foundation
import ManagedSettings
import SwiftUI

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
        session.isActive = true
        let startDate = Date()
        session.startDate = startDate
        session.trigger = trigger
        shieldApps()
        
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                let sessionAttrs = SessionAttributes(startDate: startDate)
                let sessionState = SessionAttributes.ContentState(
                    isActive: true
                )

                let activity = try Activity<SessionAttributes>.request(
                    attributes: sessionAttrs,
                    content: ActivityContent(state: sessionState, staleDate: nil)
                )
                
                print("Started activity: \(activity.id)")
            } catch {
                let errorMessage = """
                    Couldn't start activity
                    ------------------------
                    \(String(describing: error))
                    """

                print(errorMessage)
            }
        }
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

        for activity in Activity<SessionAttributes>.activities {
            let sessionState = SessionAttributes.ContentState(
                isActive: false)
            await activity.end(
                .init(state: sessionState, staleDate: nil),
                dismissalPolicy: .immediate)
        }
    }

    // MARK: - Shield Management
    private func shieldApps() {
        store.shield.applications = settings.blockedContent.applicationTokens
        store.shield.applicationCategories = .specific(
            settings.blockedContent.categoryTokens)
    }

    private func unshieldApps() {
        store.clearAllSettings()
    }
}
