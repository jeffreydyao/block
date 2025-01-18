//
//  BlockService.swift
//  Block
//
//  Created by Jeffrey Yao on 18/1/2025.
//

import Foundation

class BlockService {
    private let nfcService: NFCService
    
    init(nfcService: NFCService) {
        self.nfcService = nfcService
    }
    
    func addBlock() async throws {
        try await nfcService.scan(for: .addBlock)
    }
}
