//
//  NFCManager.swift
//  Block
//
//  Created by Jeffrey Yao on 11/01/2025.
//

import Foundation
import SwiftUI
import CoreNFC

/// A manager class that handles all NFC operations for reading/writing NTAG215
/// tags and verifying whether they are valid "Block" tags.
///
/// Usage:
/// 1. Create a shared instance or an `ObservableObject` injected into your Views.
/// 2. Call `beginScanning(for:)` with an `NFCOperationType` (e.g. `.addBrick`).
/// 3. React to the result via the optional `completion` closure.
public class NFCManager: NSObject, ObservableObject {
    
    // MARK: - Nested Types
    
    /// The specific NFC operation the user is trying to perform.
    public enum NFCOperationType {
        /// Add a Brick by writing a "Block" signature to a fresh NTAG215 tag.
        case addBrick
        /// Start a block session by verifying the scanned tag is a "Block" tag.
        case startBlock
        /// End a block session by verifying the scanned tag is a "Block" tag.
        case endBlock
    }
    
    // MARK: - Properties
    
    /// The active NFC Tag Reader session, if any.
    private var nfcSession: NFCTagReaderSession?
    
    /// The current operation we are handling (add a brick vs. start/end block).
    private var currentOperation: NFCOperationType?
    
    /// Completion callback that will be invoked with success/failure once the NFC flow ends.
    public var completion: ((Bool, String) -> Void)?
    
    // MARK: - Public Interface
    
    /// Begins scanning for NFC tags with the given operation type.
    /// - Parameters:
    ///   - operation: The operation to perform (addBrick, startBlock, endBlock).
    ///   - completion: A callback returning success/failure and a message.
    public func beginScanning(for operation: NFCOperationType, completion: ((Bool, String) -> Void)? = nil) {
        // Check if NFC reading is available on this device.
        guard NFCTagReaderSession.readingAvailable else {
            completion?(false, "NFC is not available on this device.")
            return
        }
        
        // Store references for use after scanning.
        self.currentOperation = operation
        self.completion = completion
        
        // Configure the user prompt depending on the operation.
        let promptMessage: String
        switch operation {
        case .addBrick:
            promptMessage = "Hold your iPhone near a Block to add it."
        case .startBlock:
            promptMessage = "Hold your iPhone near your Block to start a session."
        case .endBlock:
            promptMessage = "Hold your iPhone near your Block to end the current session."
        }
        
        // Create and begin an NFC Tag Reader Session for ISO 14443 tags (NTAG21x).
        nfcSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        nfcSession?.alertMessage = promptMessage
        nfcSession?.begin()
    }
    
    // MARK: - Write/Read Functions
    
    /// Writes the "Block" signature (8 bytes) to two consecutive pages on an NTAG215.
    ///
    /// Each page on NTAG21x is 4 bytes, so we need 2 pages for 8 bytes.
    /// Adjust `startPage` if pages 4–5 are not free or if your layout differs.
    ///
    /// - Parameters:
    ///   - mifareTag: The connected `NFCMiFareTag` representing the NTAG215.
    ///   - session:   The active `NFCTagReaderSession`.
    func writeBlockSignature(to mifareTag: NFCMiFareTag, session: NFCTagReaderSession) {
        let signature = BlockConstants.blockTagSignature  // 8 bytes total
        let startPage: UInt8 = 4                          // Example: pages 4 and 5
        let firstPageData = signature.prefix(4)           // bytes [0..3]
        let secondPageData = signature.suffix(4)          // bytes [4..7]

        // Write first 4 bytes to page 4
        writePage(mifareTag: mifareTag, pageNumber: startPage, data: firstPageData) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                session.invalidate(errorMessage: "Writing page \(startPage) failed: \(error.localizedDescription)")
                self.completion?(false, "Writing page \(startPage) failed.")
            case .success:
                // Then write the next 4 bytes to page 5
                let secondPageNumber = startPage + 1
                self.writePage(mifareTag: mifareTag, pageNumber: secondPageNumber, data: secondPageData) { result2 in
                    switch result2 {
                    case .failure(let error):
                        session.invalidate(errorMessage: "Writing page \(secondPageNumber) failed: \(error.localizedDescription)")
                        self.completion?(false, "Writing page \(secondPageNumber) failed.")
                    case .success:
                        session.alertMessage = "Block added!"
                        session.invalidate()
                        self.completion?(true, "Block added!")
                        self.cleanupAfterOperation()
                    }
                }
            }
        }
    }
    
    /// Reads 2 pages (8 bytes total) from an NTAG215 and verifies they match
    /// our known "Block" signature. If so, it’s recognized as a valid Block.
    ///
    /// - Parameters:
    ///   - mifareTag: The connected `NFCMiFareTag` representing the NTAG215.
    ///   - session:   The active `NFCTagReaderSession`.
    func readAndVerifyBlockSignature(from mifareTag: NFCMiFareTag, session: NFCTagReaderSession) {
        let startPage: UInt8 = 4   // Must match the pages used in writeBlockSignature
        let pagesToRead = 2       // We need 2 pages (each 4 bytes) for the 8-byte signature
        
        readPages(mifareTag: mifareTag, startPage: startPage, count: pagesToRead) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                session.invalidate(errorMessage: "Reading tag failed: \(error.localizedDescription)")
                self.completion?(false, "Could not read tag data.")
                self.cleanupAfterOperation()
                
            case .success(let data):
                if data == BlockConstants.blockTagSignature {
                    // The read data matches our known signature
                    session.alertMessage = "Valid Block tag detected!"
                    session.invalidate()
                    self.completion?(true, "Block tag confirmed.")
                } else {
                    // Signature mismatch
                    session.invalidate(errorMessage: "This tag isn't recognized as a Block.")
                    self.completion?(false, "Tag verification failed.")
                }
                self.cleanupAfterOperation()
            }
        }
    }
}

// MARK: - NFCTagReaderSessionDelegate

extension NFCManager: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // Called when the session starts scanning. No action needed for most cases.
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        // The session is invalid (timed out, canceled, or encountered an error).
        nfcSession = nil
        currentOperation = nil
        completion?(false, error.localizedDescription)
        completion = nil
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let firstTag = tags.first else { return }
        
        // Attempt to connect to the tag
        session.connect(to: firstTag) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                session.invalidate(errorMessage: "Failed to connect: \(error.localizedDescription)")
                self.completion?(false, "Could not connect to tag.")
                return
            }
            
            // Handle only MiFare-based tags (NTAG21x).
            switch firstTag {
            case .miFare(let mifareTag):
                switch self.currentOperation {
                case .addBrick:
                    self.writeBlockSignature(to: mifareTag, session: session)
                case .startBlock, .endBlock:
                    self.readAndVerifyBlockSignature(from: mifareTag, session: session)
                case .none:
                    // Unknown operation. This shouldn't happen if set properly.
                    session.invalidate(errorMessage: "Unknown operation.")
                }
                
            default:
                session.invalidate(errorMessage: "Unsupported tag type. Please use NTAG215.")
                self.completion?(false, "Unsupported tag type.")
            }
        }
    }
}

// MARK: - Private Helpers

private extension NFCManager {
    
    /// Writes exactly 4 bytes to a specific page on an NTAG21x using the WRITE command (0xA2).
    /// - Parameters:
    ///   - mifareTag:    The connected `NFCMiFareTag`.
    ///   - pageNumber:   The page number to write to (each page is 4 bytes).
    ///   - data:         Must be exactly 4 bytes.
    ///   - completion:   Callback with success/failure.
    func writePage(
        mifareTag: NFCMiFareTag,
        pageNumber: UInt8,
        data: Data,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Each page on NTAG21x is 4 bytes. The 0xA2 command expects 4 bytes of data.
        guard data.count == 4 else {
            let error = NSError(domain: "InvalidDataSize", code: 1, userInfo: [NSLocalizedDescriptionKey: "Data must be 4 bytes."])
            completion(.failure(error))
            return
        }
        // Command for NTAG21x single-page write:  [0xA2, pageNumber, 4 data bytes]
        let command = Data([0xA2, pageNumber]) + data
        mifareTag.sendMiFareCommand(commandPacket: command) { _, error in
             if let error = error {
                 completion(.failure(error))
             } else {
                 completion(.success(()))
             }
         }
    }
    
    /// Reads N pages (4 bytes each) starting from a given page on an NTAG21x using the READ command (0x30).
    /// Note that 0x30 normally returns 16 bytes at once (4 pages).
    ///
    /// In this example, we read page-by-page in a loop to keep it straightforward.
    ///
    /// - Parameters:
    ///   - mifareTag: The connected `NFCMiFareTag`.
    ///   - startPage: The first page to read.
    ///   - count:     How many pages to read (1 page = 4 bytes).
    ///   - completion: Callback with the combined data or an error.
    func readPages(
        mifareTag: NFCMiFareTag,
        startPage: UInt8,
        count: Int,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        var collectedData = Data()
        var lastError: Error?
        
        let group = DispatchGroup()
        
        for page in startPage..<(startPage + UInt8(count)) {
            group.enter()
            // Command for NTAG21x page read: [0x30, pageNumber]
            let command = Data([0x30, page])
            mifareTag.sendMiFareCommand(commandPacket: command) { responseData, error in
                defer { group.leave() }
                
                if let error = error {
                    lastError = error
                    return
                }
                
                // Now 'responseData' is non-optional. Check length to ensure at least 4 bytes.
                if responseData.count < 4 {
                    lastError = NSError(
                        domain: "ReadError",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Insufficient read response."]
                    )
                    return
                }
                
                // We only append the first 4 bytes for this page
                let pageData = responseData.prefix(4)
                collectedData.append(pageData)
            }
        }
        
        group.notify(queue: .main) {
            if let error = lastError {
                completion(.failure(error))
            } else {
                completion(.success(collectedData))
            }
        }
    }
    
    /// Cleans up after a successful or failed NFC operation, resetting internal state.
    func cleanupAfterOperation() {
        nfcSession = nil
        currentOperation = nil
        completion = nil
    }
}
