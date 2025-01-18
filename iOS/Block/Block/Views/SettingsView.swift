//
//  SettingsView.swift
//  Block
//
//  Created by Jeffrey Yao on 12/1/2025.
//

import SwiftUI
import FamilyControls
import ManagedSettings

struct SettingsView: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(SessionModel.self) private var session
    
    @State private var sessionService: SessionService = SessionService(
        settings: SettingsModel(), session: SessionModel(), nfcService: NFCService(), store: ManagedSettingsStore()
    )
    private let blockService = BlockService(nfcService: NFCService())
    
    @State private var showingActivityPicker = false
    
    var body: some View {
        Form {
            Section {
                Button("Add Block") {
                    Task {
                        try? await blockService.addBlock()
                    }
                }
                .disabled(session.isActive)
            } footer: {
                VStack(alignment: .leading) {
                    Text("Blocks are physical objects with a NFC tag, which can be used to start and stop block sessions.")
                    Spacer()
                    Text("NTAG21x series NFC tags are supported for use with Block.")
                }
            }
            
            Section {
                Button("Choose apps to block") {
                    showingActivityPicker = true
                }
                .disabled(session.isActive)
            } footer: {
                Text("Selected apps can't be accessed during block sessions. Uninstalling the app won't bypass this!")
            }
            
#if DEBUG
            Section {
                Button("Emergency unblock", role: .destructive) {
                    Task {
                        try? await sessionService.end(skipNfcScan: true)
                    }
                }
            }
#endif
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingActivityPicker) {
            ActivityPickerView(
                selection: Binding(
                    get: { settings.blockedContent },
                    set: { settings.blockedContent = $0 }
                )
            )
        }
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

#Preview {
    PreviewContainer {
        SettingsView()
    }
}
