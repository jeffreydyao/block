//
//  MainView.swift
//  Block
//
//  Created by Jeffrey Yao on 12/1/2025.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var blockSessionManager: BlockSessionManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Time elapsed
                if blockSessionManager.isBlocking {
                    VStack(spacing: 4) {
                        Text("Used for")
                            .textCase(.uppercase)
                            .font(.system(.subheadline))
                            .foregroundStyle(.secondary)
                            .fontWeight(.medium)
                        HStack(spacing: 0) {
                            // Apply ContentTransition to each numeric component
                            Text(String(format: "%02d", blockSessionManager.hours))
                                .contentTransition(.numericText())
                                .animation(.default, value: blockSessionManager.hours)
                            Text(":")
                            Text(String(format: "%02d", blockSessionManager.minutes))
                                .contentTransition(.numericText())
                                .animation(.default, value: blockSessionManager.minutes)
                            Text(":")
                            Text(String(format: "%02d", blockSessionManager.seconds))
                                .contentTransition(.numericText())
                                .animation(.default, value: blockSessionManager.seconds)
                        }
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                
                // Lock / Unlock
                if blockSessionManager.isBlocking {
                    Button(action: {
                        blockSessionManager.prepareToEndBlockSession()
                    }) {
                        Text("Unlock")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                // If NOT blocking, show "Block distractions"
                else {
                    Button(action: {
                        blockSessionManager.prepareToStartBlockSession()
                    }) {
                        Text("Block distractions")
                            .font(.title2)
                            .fontWeight(.medium)
                    }
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Spacer()
                
                // Navigation to SettingsView
                NavigationLink("Settings", destination: SettingsView())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            // Show an alert if there's a message
            .alert(item: $blockSessionManager.alertMessage) { msg in
                Alert(title: Text(msg.text))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


#Preview {
    MainView()
        .environmentObject(BlockSessionManager())
        .tint(.white)
}
