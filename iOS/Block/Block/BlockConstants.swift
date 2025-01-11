//
//  BlockConstants.swift
//  Block
//
//  Created by Jeffrey Yao on 11/1/2025.
//

import Foundation

/// Shared constants used across the Block project.
public struct BlockConstants {
    /// The raw data identifying a "Block" tag.
    /// For an open-source project, you might keep this constant the same for all builds.
    /// In a production app, you could replace this with a secure, random signature
    /// to prevent forging.
    public static let blockTagSignature: Data = Data([0x42, 0x6C, 0x6F, 0x63, 0x6B, 0x21, 0xAA, 0xFF])
}
