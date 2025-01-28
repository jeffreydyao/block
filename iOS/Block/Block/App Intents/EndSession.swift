//
//  StartSession.swift
//  Block
//
//  Created by Jeffrey Yao on 21/1/2025.
//

import Foundation
import AppIntents

/**
 Users will open the app often to start a session, so this intent lets them jump to this action quicker.
 TODO:
 - Option / intent for starting without brick? (should probs be default)
 - Can we open NFC dialog over system UI without launching app in foreground?
 - Can we just start session in background + show live activity?
 */
struct StartSession: AppIntent {
    static let title: LocalizedStringResource = "Start Session"
    static let description = IntentDescription("Opens the app and starts a new session.")
    static let openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        try await sessionService.start(trigger: .manual)

        return .result()
    }
    
    @Dependency
    private var sessionService: SessionService
}
