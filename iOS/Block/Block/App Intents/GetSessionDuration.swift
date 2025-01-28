//
//  GetSessionDuration.swift
//  Block
//
//  Created by Jeffrey Yao on 21/1/2025.
//

import Foundation
import AppIntents

struct GetSessionDuration: AppIntent {
    static let title: LocalizedStringResource = "Get Session Duration"
    static let description = IntentDescription("Provides the seconds elapsed for the current session, if any.")
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<TimeInterval> {
        let now = Date()
        let start = session.startDate ?? now
        let duration = now.timeIntervalSince(start)
        return .result(value: duration)
    }
    
    @Dependency
    private var session: SessionModel
}
