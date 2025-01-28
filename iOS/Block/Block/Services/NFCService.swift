import CoreNFC

/// Handles NFC operations for Block tags (NTAG215)
class NFCService: NSObject {
    // MARK: - Types
    
    enum Operation {
        case addBlock
        case startBlock
        case endBlock
        
        var prompt: String {
            switch self {
            case .addBlock: "Hold your iPhone near a Block to add it"
            case .startBlock: "Hold your iPhone near your Block to start a session"
            case .endBlock: "Hold your iPhone near your Block to end the session"
            }
        }
    }
    
    enum NFCError: Error {
        case unavailable
        case invalidTag
        case connectionFailed
        case readFailed
        case writeFailed
        case verificationFailed
    }
    
    // MARK: - Properties
    
    private var session: NFCTagReaderSession?
    private var currentOperation: Operation?
    private var continuation: CheckedContinuation<Void, Error>?

    // MARK: - Public Interface
    
    /// Scans for an NFC tag and performs the specified operation
    func scan(for operation: Operation) async throws {
        guard NFCTagReaderSession.readingAvailable else {
            throw NFCError.unavailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Keep a reference to our continuation so we can resume it later
            self.continuation = continuation
            self.beginScanning(for: operation)
        }
    }
    
    // MARK: - Private Methods
    
    private func beginScanning(for operation: Operation) {
        currentOperation = operation
        
        session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        session?.alertMessage = operation.prompt
        session?.begin()
    }
    
    private func handleTag(_ tag: NFCTag, in session: NFCTagReaderSession) {
        guard case let .miFare(miFareTag) = tag else {
            // If we call .invalidate(errorMessage:), Core NFC will later call
            // `didInvalidateWithError` with an error. We should resume the continuation
            // ourselves here—before that delegate call occurs—to avoid double resume.
            failAndInvalidateSession(session, with: NFCError.invalidTag, message: "Unsupported tag type")
            return
        }
        
        // Handle the actual operation
        switch currentOperation {
        case .addBlock:
            writeBrickSignature(to: miFareTag, in: session)
        case .startBlock, .endBlock:
            verifyBrickSignature(from: miFareTag, in: session)
        case .none:
            failAndInvalidateSession(session, with: NFCError.invalidTag, message: "No operation specified")
        }
    }
    
    private func writeBrickSignature(
        to tag: NFCMiFareTag,
        in session: NFCTagReaderSession
    ) {
        let signature = BlockConstants.blockTagSignature
        let startPage: UInt8 = 4
        
        Task {
            do {
                try await writePages(signature, to: tag, startingAt: startPage)
                session.alertMessage = "Block added successfully"
                
                // Succeed and end the session
                succeedAndInvalidateSession(session)
            } catch {
                failAndInvalidateSession(session, with: error, message: "Failed to write signature")
            }
        }
    }
    
    private func verifyBrickSignature(
        from tag: NFCMiFareTag,
        in session: NFCTagReaderSession
    ) {
        Task {
            do {
                let data = try await readPages(from: tag, startPage: 4, count: 2)
                guard data == BlockConstants.blockTagSignature else {
                    throw NFCError.verificationFailed
                }
                
                session.alertMessage = "Block verified"
                succeedAndInvalidateSession(session)
                
            } catch {
                failAndInvalidateSession(session, with: error, message: "Verification failed")
            }
        }
    }
    
    
    private func writePages(
        _ data: Data,
        to tag: NFCMiFareTag,
        startingAt page: UInt8
    ) async throws {
        // Write 4 bytes at a time
        for i in 0..<(data.count + 3) / 4 {
            let pageData = data.subdata(
                in: i * 4..<min((i + 1) * 4, data.count)
            )
            try await writePage(pageData, to: tag, at: page + UInt8(i))
        }
    }
    
    private func writePage(
        _ data: Data,
        to tag: NFCMiFareTag,
        at page: UInt8
    ) async throws {
        let command = Data([0xA2, page]) + data
        try await tag.sendMiFareCommand(commandPacket: command)
    }
    
    private func readPages(
        from tag: NFCMiFareTag,
        startPage: UInt8,
        count: Int
    ) async throws -> Data {
        var data = Data()
        
        for page in 0..<count {
            let command = Data([0x30, startPage + UInt8(page)])
            let response = try await tag.sendMiFareCommand(commandPacket: command)
            data.append(response.prefix(4))
        }
        
        return data
    }
}

// MARK: - NFCTagReaderSessionDelegate

extension NFCService: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // do nothing
    }
    
    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didInvalidateWithError error: Error
    ) {
        // If we haven't resumed yet, do so now with an error.
        // (This will happen if the user taps "Cancel" or
        // if iOS forcibly invalidates the session.)
        self.session = nil
        guard let continuation = continuation else { return }
        self.continuation = nil
        
        continuation.resume(throwing: error)
    }
    
    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didDetect tags: [NFCTag]
    ) {
        guard let tag = tags.first else { return }
        
        session.connect(to: tag) { [weak self] error in
            if let error {
                // e.g. a connection failure
                self?.failAndInvalidateSession(session, with: error, message: error.localizedDescription)
                return
            }
            
            self?.handleTag(tag, in: session)
        }
    }
}

// MARK: - Helpers

private extension NFCService {
    
    func succeedAndInvalidateSession(_ session: NFCTagReaderSession) {
        // Resume the continuation first (with success).
        // Then call invalidate() so that any subsequent
        // didInvalidateWithError sees that continuation == nil
        // and won't attempt to resume it again.
        if let continuation = continuation {
            self.continuation = nil
            continuation.resume(returning: ())
        }
        session.invalidate()
    }
    
    func failAndInvalidateSession(
        _ session: NFCTagReaderSession,
        with error: Error,
        message: String
    ) {
        if let continuation = continuation {
            self.continuation = nil
            continuation.resume(throwing: error)
        }
        session.invalidate(errorMessage: message)
    }
}
