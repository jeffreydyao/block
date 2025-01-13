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
            Form {
                Section() {
                    Button("Add Block") {
                        blockSessionManager.addBrick()
                    }
                    // Disable when a block session is active (so users can’t circumvent blocking)
                    .disabled(blockSessionManager.isBlocking)
                } footer: {
                    VStack(alignment: .leading) {
                        Text("Blocks are physical objects with a NFC tag, which can be used to start and stop block sessions.")
                        Spacer()
                        Text("NTAG21x series NFC tags are supported for use with Block.")
                    }
                }
                
                Section() {
                    Button("Choose apps to block") {
                        blockSessionManager.manageDistractingApps()
                    }
                } footer: {
                    Text("Selected apps can't be accessed during block sessions. Uninstalling the app won't bypass this!")
                }
                
                Section() {
                    Button("Emergency unblock", role: .destructive) {
                        blockSessionManager.emergencyUnblock()
                    }
                }
            }
            .navigationTitle("Settings")
        }
        // Present the FamilyActivityPicker when needed
        .sheet(isPresented: $blockSessionManager.isShowingFamilyActivityPicker) {
            NavigationView {
                FamilyActivityPicker(selection: $blockSessionManager.familyActivitySelection)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle("Choose apps to block")
                    .toolbar() {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                blockSessionManager.isShowingFamilyActivityPicker = false
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                // Persist and dismiss
                                blockSessionManager.storeSelectedApps()
                                blockSessionManager.isShowingFamilyActivityPicker = false
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(BlockSessionManager())
}
