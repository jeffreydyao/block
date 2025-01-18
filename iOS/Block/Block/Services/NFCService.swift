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
    private var completion: ((Result<Void, Error>) -> Void)?
    
    // MARK: - Public Interface
    
    /// Scans for an NFC tag and performs the specified operation
    func scan(for operation: Operation) async throws {
        guard NFCTagReaderSession.readingAvailable else {
            throw NFCError.unavailable
        }
        
        try await withCheckedThrowingContinuation { continuation in
            beginScanning(for: operation) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func beginScanning(
        for operation: Operation,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        currentOperation = operation
        self.completion = completion
        
        session = NFCTagReaderSession(
            pollingOption: .iso14443,
            delegate: self
        )
        session?.alertMessage = operation.prompt
        session?.begin()
    }
    
    private func handleTag(_ tag: NFCTag, in session: NFCTagReaderSession) {
        guard case let .miFare(tag) = tag else {
            session.invalidate(errorMessage: "Unsupported tag type")
            completion?(.failure(NFCError.invalidTag))
            return
        }
        
        switch currentOperation {
        case .addBlock:
            writeBrickSignature(to: tag, in: session)
        case .startBlock, .endBlock:
            verifyBrickSignature(from: tag, in: session)
        case .none:
            session.invalidate(errorMessage: "No operation specified")
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
                session.invalidate()
                completion?(.success(()))
            } catch {
                session.invalidate(errorMessage: "Failed to write signature")
                completion?(.failure(error))
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
                if data == BlockConstants.blockTagSignature {
                    session.alertMessage = "Block verified"
                    session.invalidate()
                    completion?(.success(()))
                } else {
                    throw NFCError.verificationFailed
                }
            } catch {
                session.invalidate(errorMessage: "Verification failed")
                completion?(.failure(error))
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
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}
    
    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didInvalidateWithError error: Error
    ) {
        self.session = nil
        completion?(.failure(error))
        completion = nil
    }
    
    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didDetect tags: [NFCTag]
    ) {
        guard let tag = tags.first else { return }
        
        session.connect(to: tag) { [weak self] error in
            if let error {
                session.invalidate(errorMessage: error.localizedDescription)
                self?.completion?(.failure(error))
                return
            }
            
            self?.handleTag(tag, in: session)
        }
    }
}
