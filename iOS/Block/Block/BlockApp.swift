//
//  BlockApp.swift
//  Block
//
//  Created by Jeffrey Yao on 11/1/2025.
//

import SwiftUI
import FamilyControls

@main
struct BlockApp: App {
    @StateObject private var blockSessionManager = BlockSessionManager()
    
    // Track if we've requested authorization already, so we don't spam the user
    @State private var didRequestAuthorization = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(blockSessionManager)
                .task {
                           guard !didRequestAuthorization else { return }
                           didRequestAuthorization = true
                           
                           do {
                               // This call is now async in iOS 17
                               try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                               print("FamilyControls authorization succeeded.")
                               // The user is a parent/guardian and has granted permission
                           } catch {
                               print("FamilyControls authorization failed: \(error)")
                           }
                       }
                .tint(.white)
        }
    }
}
