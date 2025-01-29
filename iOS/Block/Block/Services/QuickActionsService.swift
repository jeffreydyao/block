//
//  QuickActionsService.swift
//  Block
//
//  Created by Jeffrey Yao on 29/1/2025.
//

import Foundation
import SwiftUI
import UIKit

enum QuickAction: String {
    case startSession = "com.block.startSession"
    case endSession = "com.block.endSession"

    var shortcutItem: UIApplicationShortcutItem {
        switch self {
        case .startSession:
            return UIApplicationShortcutItem(
                type: self.rawValue,
                localizedTitle: "Start session",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "play.fill")
            )
        case .endSession:
            return UIApplicationShortcutItem(
                type: self.rawValue,
                localizedTitle: "End session",
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "stop.fill")
            )
        }
    }

}

final class QuickActionsService {
    static let shared = QuickActionsService()
    var sessionService: SessionService? = nil
    
    
    func setQuickActions(sessionIsActive: Bool) {
        let shortcutItem = sessionIsActive ? QuickAction.endSession.shortcutItem : QuickAction.startSession.shortcutItem
        UIApplication.shared.shortcutItems = [shortcutItem]
    }

    func handleShortcutItem(shortcutItem: UIApplicationShortcutItem) {
        guard let action = QuickAction(rawValue: shortcutItem.type) else {
            return
        }
        
        guard let sessionService = sessionService else {
            print("Session service not initialized")
            return
        }

        Task { @MainActor in
            do {
                switch action {
                case .startSession:
                    print("Starting session")
                    
                try await sessionService.start(trigger: .manual)
                case .endSession:
                    print("Ending session")
                try await sessionService.end(skipNfcScan: false)
                }
            } catch {
                print(
                    "Error handling quick action: \(error.localizedDescription)"
                )
            }
        }
    }
}

// MARK: - AppDelegate
class QuickActionsAppDelegate: NSObject, UIApplicationDelegate {
    private let quickActionsService = QuickActionsService.shared

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            quickActionsService.handleShortcutItem(shortcutItem: shortcutItem)
        }
                
        let sceneConfiguration = UISceneConfiguration(
            name: connectingSceneSession.configuration.name,
            sessionRole: connectingSceneSession.role
            )
        sceneConfiguration.delegateClass = QuickActionsSceneDelegate.self
        return sceneConfiguration
    }
}

class QuickActionsSceneDelegate: UIResponder, UIWindowSceneDelegate {
    private let quickActionsService = QuickActionsService.shared
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        quickActionsService.handleShortcutItem(shortcutItem: shortcutItem)
        completionHandler(true)
    }
}
