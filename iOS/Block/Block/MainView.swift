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
                // If currently blocking, show timer + "Unlock"
                if blockSessionManager.isBlocking {
                    // Show the timer in a monospaced font
                    Text(blockSessionManager.blockTimerString)
                        .font(.system(.largeTitle, design: .monospaced))
                        .padding()
                    
                    // "Unlock" button
                    Button(action: {
                        blockSessionManager.prepareToEndBlockSession()
                    }) {
                        Text("Unlock")
                            .font(.title2)
                            .padding()
                    }
                }
                // If NOT blocking, show "Block distractions"
                else {
                    Button(action: {
                        blockSessionManager.prepareToStartBlockSession()
                    }) {
                        Text("Block distractions")
                            .font(.title2)
                            .padding()
                    }
                }
                
                Spacer()
                
                // Navigation to SettingsView
                NavigationLink("Settings", destination: SettingsView())
                    .font(.callout)
                    .padding(.bottom, 16)
            }
            .padding()
            .navigationTitle("Block")
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
}
