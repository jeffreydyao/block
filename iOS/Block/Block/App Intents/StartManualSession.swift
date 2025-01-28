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
    static let description = IntentDescription("Starts a new Block session in the background.")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        try await sessionService.start(trigger: .manual)

        return .result()
    }
    
    @Dependency
    private var sessionService: SessionService
}
