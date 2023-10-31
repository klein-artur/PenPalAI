//
//  MemoryDatabaseMock.swift
//  
//
//  Created by Artur Hellmann on 30.10.23.
//

import Foundation
@testable import PenPalAI

class MemoryDatabaseMock: MemoryDatabase {
    var filePath: String = "mockFilePath"
    
    // Callbacks for capturing calls and setting return values dynamically
    var onSave: ((Memory) async throws -> Void)?
    var onFindSnipped: ((String) async throws -> Memory?)?
    var onFindEmbedding: (([Double], Double) async throws -> [Memory])?
    var onReplace: ((String, String, [Double]) async throws -> Void)?
    
    func save(memory: Memory) async throws {
        try await onSave?(memory) ?? ()
    }
    
    func find(snipped: String) async throws -> Memory? {
        return try await onFindSnipped?(snipped) ?? nil
    }
    
    func find(embedding: [Double], threshold: Double) async throws -> [Memory] {
        return try await onFindEmbedding?(embedding, threshold) ?? []
    }
    
    func replace(snipped: String, newSnipped: String, embedding: [Double]) async throws {
        try await onReplace?(snipped, newSnipped, embedding)
    }
}
