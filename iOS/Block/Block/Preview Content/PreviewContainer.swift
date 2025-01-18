//
//  PreviewContainer.swift
//  Block
//
//  Created by Jeffrey Yao on 19/1/2025.
//

import Foundation
import SwiftUI

/// Injects root-level environment objects into previews.
struct PreviewContainer<Content: View>: View {
    let content: Content
    let settings: SettingsModel
    let session: SessionModel
    
    init(
        settings: SettingsModel = SettingsModel(),
        session: SessionModel = SessionModel(),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.settings = settings
        self.session = session
    }
    
    var body: some View {
        content
            .environment(settings)
            .environment(session)
    }
}
