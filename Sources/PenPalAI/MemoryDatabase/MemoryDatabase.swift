//
//  MemoryDatabase.swift
//  
//
//  Created by Artur Hellmann on 29.10.23.
//

import Foundation

struct Memory {
    let id: UUID
    let snipped: String
    let embedding: [Double]
    let isKeyKnowledge: Bool
    let creationDate: Date
}

enum MemoryDatabaseError: Error {
    case noFilePath
}

protocol MemoryDatabase {
    
    /// The path to the source file.
    var filePath: String { get set }
    
    /// Saves a memory to the datasource.
    func save(memory: Memory) async throws
    
    /// Returns the given number of key memories sorted by date.
    /// - Parameters:
    /// - number: The number of memories to return.
    /// - Returns: The memories.
    func getKeyMemories(number: Int) async throws -> [Memory]
    
    /// Finds a memory by its snipped.
    /// - Parameters:
    /// - snipped: The snipped to search for.
    /// - Returns: The memory if found, otherwise nil.
    func find(snipped: String) async throws -> Memory?
    
    /// Finds the nearest memory by the embedding with cosine similarity.
    /// - Parameters:
    ///  - embedding: The embedding to search for.
    ///  - threshold: The threshold how similar the vectors should be. As we use cosine, identical will mean 1.0.
    ///  - Returns: The memory if found, otherwise nil.
    func find(embedding: [Double], threshold: Double) async throws -> [Memory]
    
    /// Replaces a snipped with a new snipped.
    /// - Parameters:
    /// - snipped: The snipped to replace.
    /// - newSnipped: The new snipped.
    /// - embedding: The embedding of the new snipped.
    func replace(snipped: String, newSnipped: String, embedding: [Double]) async throws
}
