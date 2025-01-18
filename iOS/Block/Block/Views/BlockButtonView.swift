//
//  BlockButton.swift
//  Block
//
//  Created by Jeffrey Yao on 18/1/2025.
//

import Foundation
import SwiftUI

/// Indicates that a user wants to start a block session.
enum BlockButtonEvent {
    /// This event fires when the user taps the button.
    case tap
    /// This event fires after the user has held the button for the `holdThreshold` defined in `BlockButton`.
    case hold
}

struct BlockButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Properties
    /// Callback that fires after a user indicates intent to start a block session.
    let onAction: (BlockButtonEvent) -> Void
    
    /// Total duration user must hold button for to start a block session.
    private let totalHoldDuration: TimeInterval = 4.0
    /// Duration user must hold button for before hold countdown begins + animatino appears.
    private let holdThreshold: TimeInterval = 1.0
    
    @State private var timer = Timer.publish(every: 0.01, on: .current, in: .common).autoconnect()
    @State private var timerCount: CGFloat = 0
    @State private var progress: CGFloat = 0
    @State private var isHolding: Bool = false
    @State private var isHoldCompleted: Bool = false
    @State private var shouldTriggerTap: Bool = true
    @State private var lastHapticSecond: Int = 0
    @State private var showCancelText: Bool = false
    
    var body: some View {
        VStack {
            Button(action: {}) {
                Text("Block distractions")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            .tint(colorScheme == .dark ? .white : .black)
            .background(
                ZStack(alignment: .leading) {
                    GeometryReader {
                        let size = $0.size
                        
                        if !isHoldCompleted {
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .frame(width: size.width * progress)
                                .transition(.opacity)
                        }
                    }
                }
            )
            .clipShape(.capsule)
            .buttonBorderShape(.capsule)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .onReceive(timer) { _ in
                handleTimer()
            }
            .onLongPressGesture(minimumDuration: totalHoldDuration, perform: {
                isHolding = false
                cancelTimer()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHoldCompleted = true
                    showCancelText = false
                }
            }, onPressingChanged: { status in
                if status {
                    // Started pressing
                    isHoldCompleted = false
                    reset()
                    isHolding = true
                    addTimer()
                } else {
                    // Ended pressing
                    withAnimation(.easeOut(duration: 0.2)) {
                        showCancelText = false
                    }
                    if shouldTriggerTap && timerCount < holdThreshold {
                        onAction(.tap)
                    }
                    cancelTimer()
                    reset()
                }
            })
            
            if showCancelText {
                Text("Release to cancel")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: showCancelText)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleTimer() {
        guard isHolding && progress != 1 else { return }
        
        timerCount += 0.01
        if timerCount >= holdThreshold {
            // Update progress
            shouldTriggerTap = false
            progress = max(min((timerCount - holdThreshold) / (totalHoldDuration - holdThreshold), 1), 0)
            
            // Trigger haptic on each second
            let currentSecond = Int(timerCount)
            if currentSecond != lastHapticSecond {
                triggerHapticFeedback()
                lastHapticSecond = currentSecond
            }
            
            // Show cancel text
            if !showCancelText {
                withAnimation {
                    showCancelText = true
                }
            }
            
            // Check for completion
            if progress >= 1 {
                onAction(.hold)
                isHoldCompleted = true
                withAnimation(.easeOut(duration: 0.2)) {
                    showCancelText = false
                }
                cancelTimer()
            }
        }
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.prepare()
        generator.impactOccurred()
    }
    
    private func addTimer() {
        timer = Timer.publish(every: 0.01, on: .current, in: .common).autoconnect()
    }
    
    private func cancelTimer() {
        timer.upstream.connect().cancel()
    }
    
    private func reset() {
        isHolding = false
        progress = 0
        timerCount = 0
        shouldTriggerTap = true
        lastHapticSecond = 0
    }
}



#Preview {
    BlockButtonView(onAction: { event in print(event) })
}
