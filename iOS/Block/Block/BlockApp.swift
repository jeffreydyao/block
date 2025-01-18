//
//  BlockApp.swift
//  Block
//
//  Created by Jeffrey Yao on 11/1/2025.
//

import SwiftUI
import FamilyControls
import ManagedSettings

@main
struct BlockApp: App {
    init() {
        
    }
    
    @State private var settings = SettingsModel()
    @State private var session = SessionModel()
    
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
        }
    }
}
