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
    static let description = IntentDescription("Prompts you to tap a Block. If successful, a block session is started.")
    
    @MainActor
    func perform() async throws -> some IntentResult {
        try await sessionService.start(trigger: .nfc)

        return .result()
    }
    
    @Dependency
    private var sessionService: SessionService
}
