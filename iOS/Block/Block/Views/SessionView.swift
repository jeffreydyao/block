//
//  SessionView.swift
//  Block
//
//  Created by Jeffrey Yao on 18/1/2025.
//

import Foundation
import SwiftUI
import ManagedSettings

struct SessionView: View {
    @Environment(SessionModel.self) private var session
    @Environment(SettingsModel.self) private var settings
    @Environment(\.colorScheme) var colorScheme
    @State private var sessionService: SessionService = SessionService(
        settings: SettingsModel(), session: SessionModel(), nfcService: NFCService(), store: ManagedSettingsStore()
    )
    
    var body: some View {
        VStack(spacing: 40) {
            // Time elapsed
            if session.isActive {
                VStack(spacing: 4) {
                    Text("Used for")
                        .textCase(.uppercase)
                        .font(.system(.subheadline))
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                    TimerView()
                }
            }
            
            Spacer()
            
            // Lock / Unlock
            if session.isActive {
                Button(action: {
                    Task {
                        try? await sessionService.end()
                    }
                }) {
                    Text("Unlock")
                        .font(.title2)
                        .fontWeight(.medium)
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(colorScheme == .dark ? .white : .black)
            } else {
                BlockButtonView { eventType in
                    Task {
                        let trigger: SessionTrigger
                        if eventType == .tap {
                            trigger = .nfc
                        } else {  // or specifically: else if eventType == .hold
                            trigger = .manual
                        }
                        
                        try? await sessionService.start(trigger: trigger)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .task {
            sessionService = SessionService(
                settings: settings,
                session: session,
                nfcService: NFCService(),
                store: ManagedSettingsStore()
            )
        }
    }
}

#if DEBUG
#Preview {
    PreviewContainer(session: .previewActive) {
        SessionView()
    }
}
#endif
