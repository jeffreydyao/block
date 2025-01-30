//
//  BlockApp.swift
//  Block
//
//  Created by Jeffrey Yao on 11/1/2025.
//

import AppIntents
import FamilyControls
import ManagedSettings
import SwiftUI

@main
struct BlockApp: App {
    @UIApplicationDelegateAdaptor(QuickActionsAppDelegate.self) private
        var appDelegate
    @State private var settings = SettingsModel()
    @State private var session = SessionModel()
    @State private var sessionService: SessionService = SessionService(
        settings: SettingsModel(), session: SessionModel(),
        nfcService: NFCService(), store: ManagedSettingsStore()
    )

    /// Whether app has been authorized to use FamilyControls.
    @State private var didRequestAuthorization = false
    @Environment(\.colorScheme) var colorScheme
    /// Lifecycle phase of the current scene.
    @Environment(\.scenePhase) var scenePhase

    private let quickActionService = QuickActionsService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    guard !didRequestAuthorization else { return }
                    didRequestAuthorization = true

                    do {
                        try await AuthorizationCenter.shared
                            .requestAuthorization(for: .individual)
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
                    quickActionService.sessionService = sessionService
                    /**
                     Register dependencies of an AppIntent or EntityQuery.
                     Must be registered as soon as possible in code paths which don't assume visible UI.
                     */
                    AppDependencyManager.shared.add(dependency: session)
                    AppDependencyManager.shared.add(dependency: sessionService)
                    /// Register app shortcuts.
                    BlockShortcuts.updateAppShortcutParameters()
                    
                    /// If session active from before, start live activity.
                }
                .onChange(
                    of: scenePhase
                ) {
                    switch scenePhase {
                    case .background:
                        quickActionService.setQuickActions(
                            sessionIsActive: session.isActive)
                    case .inactive, .active:
                        break
                    @unknown default:
                        break
                    }

                }
        }
    }
}
