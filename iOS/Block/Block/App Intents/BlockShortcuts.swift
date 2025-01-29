//
//  BlockShortcuts.swift
//  Block
//
//  Created by Jeffrey Yao on 21/1/2025.
//

import AppIntents
import Foundation

class BlockShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = ShortcutTileColor
        .lightBlue

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartManualSession(),
            phrases: [
                "Start a session with \(.applicationName)",  // Starting a Block session directly is the default if invoked via voice or Spotlight. We don't block the user on tapping a Block.
                "Start a \(.applicationName) session",
                "Start a session using \(.applicationName)",
                "Start a manual \(.applicationName) session",
            ],
            shortTitle: "Start Session",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: StartNFCSession(),
            phrases: [
                "Start a \(.applicationName) session using NFC",
                "Start a NFC session using  \(.applicationName)",
                "Start a NFC \(.applicationName) session",
            ],
            shortTitle: "Start NFC Session",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: EndSession(),
            phrases: [
                "End a session",
                "End the \(.applicationName) session",
                "End a \(.applicationName) session",
                "End the session using \(.applicationName)",
            ],
            shortTitle: "End Session",
            systemImageName: "stop.fill"
        )
        AppShortcut(
            intent: GetSessionDuration(),
            phrases: [
                "Get session duration",
                "Get \(.applicationName) session duration",
                "How long has my \(.applicationName) session been active for?",
            ],
            shortTitle: "Get Session Duration",
            systemImageName: "stopwatch.fill"
        )
    }
}
