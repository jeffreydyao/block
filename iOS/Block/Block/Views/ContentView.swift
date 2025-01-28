//
//  ContentView.swift
//  Block
//
//  Created by Jeffrey Yao on 11/1/2025.
//

import SwiftUI
import ManagedSettings

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            VStack {
                SessionView()
                
                // Settings button at bottom
                NavigationLink {
                    SettingsView()
                } label: {
                    Text("Settings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom)
            }
        }
        .tint(colorScheme == .dark ? .white : .black)
    }
}

#Preview {
    PreviewContainer {
        ContentView()
    }
}
