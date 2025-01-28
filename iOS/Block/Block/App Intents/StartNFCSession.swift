//
//  StartSession.swift
//  Block
//
//  Created by Jeffrey Yao on 21/1/2025.
//

import Foundation
import AppIntents

struct StartNFCSession: AppIntent {
    static let title: LocalizedStringResource = "Start Session (NFC)"
    static let description = IntentDescription("Prompts you to tap a Block. If successful, a block session is started. If a session is already running, an error will be returned stating that the action isn't allowed.")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            try await sessionService.start(trigger: .nfc)
            return .result()
        } catch {
            // Session has already started!
            throw AppIntentError.Unrecoverable.notAllowed
        }
    }
    
    @Dependency
    private var sessionService: SessionService
}
