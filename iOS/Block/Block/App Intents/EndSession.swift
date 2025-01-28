//
//  EndSession.swift
//  Block
//
//  Created by Jeffrey Yao on 21/1/2025.
//

import Foundation
import AppIntents

struct EndSession: AppIntent {
    static let title: LocalizedStringResource = "End Session"
    static let description = IntentDescription("Opens the app and ends a session.")
    static let openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        try await sessionService.end()

        return .result()
    }
    
    @Dependency
    private var sessionService: SessionService
}
