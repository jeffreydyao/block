//
//  BlockApp.swift
//  Block
//
//  Created by Jeffrey Yao on 11/1/2025.
//

import SwiftUI
import FamilyControls
import ManagedSettings
import AppIntents

@main
struct BlockApp: App {
    init() {

    }
    
    @State private var settings = SettingsModel()
    @State private var session = SessionModel()
    @State private var sessionService: SessionService = SessionService(
        settings: SettingsModel(), session: SessionModel(), nfcService: NFCService(), store: ManagedSettingsStore()
    )
    
    /// Whether app has been authorized to use FamilyControls.
    @State private var didRequestAuthorization = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    guard !didRequestAuthorization else { return }
                    didRequestAuthorization = true
                    
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                        print("FamilyControls authorization succeeded.")
                    } catch {
                        print("FamilyControls authorization failed: \(error)")
                    }
                }
                .tint(colorScheme == .dark ? .white : .black)
            // Make app settings + current session globally accessible via Environment.
                .environment(settings)
                .environment(session)
                .task {
                    sessionService = SessionService(
                        settings: settings,
                        session: session,
                        nfcService: NFCService(),
                        store: ManagedSettingsStore()
                    )
                    
                    /**
                     Register dependencies of an AppIntent or EntityQuery.
                     Must be registered as soon as possible in code paths which don't assume visible UI.
                     */
                    AppDependencyManager.shared.add(dependency: session)
                    AppDependencyManager.shared.add(dependency: sessionService)
                    /// Register app shortcuts.
                    BlockShortcuts.updateAppShortcutParameters()
                }
        }
    }
}
