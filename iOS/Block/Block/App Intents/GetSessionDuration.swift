//
//  GetTimeRemaining.swift
//  Block
//
//  Created by Jeffrey Yao on 21/1/2025.
//

import Foundation
import AppIntents

struct GetTimeRemaining: AppIntent {
    static let title: LocalizedStringResource = "Get Time Remaining"
    static let description = IntentDescription("Provides the time remaining for the current session, if any.")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        try await sessionService.end()
        
        session.startDate
        return .result()
    }
    
    @Dependency
    private var session: SessionModel
}
