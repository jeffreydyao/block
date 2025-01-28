//
//  BlockShortcuts.swift
//  Block
//
//  Created by Jeffrey Yao on 21/1/2025.
//

import Foundation
import AppIntents

class BlockShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = ShortcutTileColor.lightBlue
    
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartManualSession(), phrases: [
            "Start a session", // Starting a Block session directly is the default if invoked via voice or Spotlight. We don't block the user on tapping a Block.
            "Start a block session",
            "Start a manual block session",
        ],
                    shortTitle: "Start Session",
                    systemImageName: "play.fill"
        )
        AppShortcut(intent: StartNFCSession(), phrases: [
            "Start a session using NFC",
            "Start a NFC session",
            "Start a NFC block session"
        ],
                    shortTitle: "Start NFC Session",
                    systemImageName: "play.fill"
        )
        AppShortcut(intent: EndSession(), phrases: [
            "End a session",
            "End a block session"
        ],
                    shortTitle: "End Session",
                    systemImageName: "stop.fill"
        )
        AppShortcut(intent: GetSessionDuration(), phrases: [
            "Get session duration",
            "Get block session duration",
            "How long has my block session been active for?",
        ],
                    shortTitle: "Get Session Duration",
                    systemImageName: "stopwatch.fill"
        )
    }
}
