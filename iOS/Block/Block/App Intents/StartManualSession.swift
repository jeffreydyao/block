//
//  StartSession.swift
//  Block
//
//  Created by Jeffrey Yao on 21/1/2025.
//

import Foundation
import AppIntents

struct StartManualSession: AppIntent {
    static let title: LocalizedStringResource = "Start Session (Manual)"
    static let description = IntentDescription("Starts a new Block session in the background. If a session is already running, an error will be returned stating that the action isn't allowed.")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            try await sessionService.start(trigger: .manual)
            return .result()
        } catch {
            // Session has already started!
            throw AppIntentError.Unrecoverable.notAllowed
        }
    }
    
    @Dependency
    private var sessionService: SessionService
}
