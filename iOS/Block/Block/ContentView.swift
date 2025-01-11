//
//  ContentView.swift
//  Block
//
//  Created by Jeffrey Yao on 11/1/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainView()
    }
}

#Preview {
    ContentView()
        .environmentObject(BlockSessionManager())
}
