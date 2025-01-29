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
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<TimeInterval> {
        let now = Date()
        let start = session.startDate ?? now
        let duration = now.timeIntervalSince(start)

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 2
        formatter.includesApproximationPhrase = false
        formatter.includesTimeRemainingPhrase = false
        let formattedDuration = formatter.string(from: duration) ?? "\(Int(round(duration))) seconds"
        
        return .result(value: duration, dialog: "Block session active for \(formattedDuration).")
    }
    
    @Dependency
    private var session: SessionModel
}
