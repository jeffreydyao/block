//
//  SettingsView.swift
//  Block
//
//  Created by Jeffrey Yao on 12/1/2025.
//

import SwiftUI

import SwiftUI
import FamilyControls

struct SettingsView: View {
    /// We use the manager to access functions like `addBrick()`, `manageDistractingApps()`, etc.
    @EnvironmentObject var blockSessionManager: BlockSessionManager
    
    var body: some View {
        NavigationView {
            List {
                // Add Brick
                Section {
                    Button("Add Brick") {
                        blockSessionManager.addBrick()
                    }
                    // Disable when a block session is active (so users can’t circumvent blocking)
                    .disabled(blockSessionManager.isBlocking)
                }
                
                // Manage distracting apps (opens FamilyActivityPicker)
                Section {
                    Button("Manage distracting apps") {
                        blockSessionManager.manageDistractingApps()
                    }
                }
                
                // Emergency unblock (developer tool; remove in production)
                Section {
                    Button(role: .destructive) {
                        blockSessionManager.emergencyUnblock()
                    } label: {
                        Text("Emergency unblock")
                    }
                }
            }
            .navigationTitle("Settings")
        }
        // Present the FamilyActivityPicker when needed
        .sheet(isPresented: $blockSessionManager.isShowingFamilyActivityPicker) {
            VStack(spacing: 16) {
                Text("Select apps you want to block")
                    .font(.headline)
                    .padding(.top, 16)
                
                FamilyActivityPicker(selection: $blockSessionManager.familyActivitySelection)
                    .padding(.horizontal, 16)
                
                Button("OK") {
                    // Persist and dismiss
                    blockSessionManager.storeSelectedApps()
                    blockSessionManager.isShowingFamilyActivityPicker = false
                }
                .font(.title2)
                .padding()
                
                // Optionally allow swipe to dismiss. If you want to disable it:
                // .interactiveDismissDisabled(true)
            }
            .presentationDetents([.medium, .large])  // iOS 16+; optional
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(BlockSessionManager())
}
