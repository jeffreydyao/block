//
//  TimerView.swift
//  Block
//
//  Created by Jeffrey Yao on 18/1/2025.
//

import Foundation
import SwiftUI

struct TimerView: View {
    @Environment(SessionModel.self) private var session
    @State private var elapsed: TimeInterval = 0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 0) {
            Text(String(format: "%02d", hours))
                .contentTransition(.numericText())
                .animation(.default, value: hours)
            Text(":")
            Text(String(format: "%02d", minutes))
                .contentTransition(.numericText())
                .animation(.default, value: minutes)
            Text(":")
            Text(String(format: "%02d", seconds))
                .contentTransition(.numericText())
                .animation(.default, value: seconds)
        }
        .font(.system(.title3, design: .monospaced))
        .fontWeight(.semibold)
        .onReceive(timer) { _ in
            updateElapsed()
        }
        .onAppear {
            // Initialise with correct value immediately to prevent initial flicker of 00:00:00.
            let startDate = session.startDate ?? Date()
            elapsed = Date().timeIntervalSince(startDate)
        }
    }
    
    private var hours: Int { Int(elapsed) / 3600 }
    private var minutes: Int { (Int(elapsed) % 3600) / 60 }
    private var seconds: Int { Int(elapsed) % 60 }
    
    private func updateElapsed() {
        guard let start = session.startDate else { return }
        elapsed = Date().timeIntervalSince(start)
    }
}

#Preview {
    PreviewContainer {
        TimerView()
    }
}
