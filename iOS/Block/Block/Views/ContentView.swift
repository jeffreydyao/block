//
//  ContentView.swift
//  Block
//
//  Created by Jeffrey Yao on 11/1/2025.
//

import SwiftUI
import ManagedSettings

struct ContentView: View {
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
        .tint(Color.adaptive)
    }
}

// Helper for dynamic color based on color scheme
extension Color {
    static var adaptive: Color {
        @Environment(\.colorScheme) var colorScheme
        return colorScheme == .dark ? .white : .black
    }
}

#if DEBUG
#Preview {
    PreviewContainer {
        ContentView()
    }
}
#endif
