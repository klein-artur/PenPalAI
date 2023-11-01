//
//  SQLiteMemoryDatabase.swift
//  
//
//  Created by Artur Hellmann on 29.10.23.
//

import Foundation
import CSQLite
import SwiftDose

class SQLiteMemoryDatabase: MemoryDatabase {
    
    @Dose(of: \.sqlite3) var sqlite3: any SQLiteWrapper
    
    var filePath: String = "" {
        didSet {
            do {
                try createDatabaseIfNotExists()
            } catch {
                print("Failed to create database: \(error)")
            }
        }
    }
    
    private var filePathResolved: String {
        (filePath as NSString).expandingTildeInPath
    }
    
    private var db: OpaquePointer?
    
    private func createDatabaseIfNotExists() throws {
        if sqlite3.open(filePathResolved, &db) != SQLITE_OK {
            throw NSError(domain: "SQLite", code: 1, userInfo: nil)
        }
        
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS Memory (
            id TEXT PRIMARY KEY,
            snipped TEXT,
            embedding BLOB,
            isKeyKnowledge INTEGER,
            creationDate TIMESTAMP
        );
        """
        
        if sqlite3.exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK {
            throw NSError(domain: "SQLite", code: 2, userInfo: nil)
        }
    }
    
    func save(memory: Memory) async throws {
        guard !filePathResolved.isEmpty else { throw MemoryDatabaseError.noFilePath }
        
        let insertQuery = "INSERT INTO Memory (id, snipped, embedding, isKeyKnowledge, creationDate) VALUES (?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?
        
        defer {
            _ = sqlite3.finalize(stmt)
        }
        
        if sqlite3.prepare_v2(db, insertQuery, -1, &stmt, nil) != SQLITE_OK {
            throw NSError(domain: "SQLite", code: 3, userInfo: nil)
        }
        
        _ = sqlite3.bind_text(stmt, 1, (memory.id.uuidString as NSString).utf8String, -1, nil)
        _ = sqlite3.bind_text(stmt, 2, (memory.snipped as NSString).utf8String, -1, nil)
        
        let data = try NSKeyedArchiver.archivedData(withRootObject: memory.embedding, requiringSecureCoding: false)
                _ = sqlite3.bind_blob(stmt, 3, (data as NSData).bytes, Int32(data.count), nil)
        
        _ = sqlite3.bind_int64(stmt, 4, Int64(memory.isKeyKnowledge ? 1 : 0))
        _ = sqlite3.bind_int64(stmt, 5, Int64(memory.creationDate.timeIntervalSince1970))
        
        if sqlite3.step(stmt) != SQLITE_DONE {
            throw NSError(domain: "SQLite", code: 4, userInfo: nil)
        }
    }
    
    func find(snipped: String) async throws -> Memory? {
        guard !filePathResolved.isEmpty else { throw MemoryDatabaseError.noFilePath }
        
        let selectQuery = "SELECT * FROM Memory WHERE snipped = ?;"
        var stmt: OpaquePointer?
        
        if sqlite3.prepare_v2(db, selectQuery, -1, &stmt, nil) != SQLITE_OK {
            throw NSError(domain: "SQLite", code: 5, userInfo: nil)
        }
        
        defer {
            _ = sqlite3.finalize(stmt)
        }
        
        _ = sqlite3.bind_text(stmt, 1, (snipped as NSString).utf8String, -1, nil)
        
        if sqlite3.step(stmt) == SQLITE_ROW {
            let idString = String(cString: sqlite3.column_text(stmt, 0))
            let id = UUID(uuidString: idString)!
            
            let snipped = String(cString: sqlite3.column_text(stmt, 1))
            let isKeyKnowledge = sqlite3.column_int64(stmt, 3) == 1
            let creationDate = Date(timeIntervalSince1970: TimeInterval(sqlite3.column_int64(stmt, 4)))
            
            let blob = sqlite3.column_blob(stmt, 2)
            let blobLength = sqlite3.column_bytes(stmt, 2)
            let data = Data(bytes: blob!, count: Int(blobLength))
            
            let embedding: [Double] = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [Double]
            
            return Memory(id: id, snipped: snipped, embedding: embedding, isKeyKnowledge: isKeyKnowledge, creationDate: creationDate)
        } else {
            return nil
        }
    }
    
    func find(embedding: [Double], threshold: Double) async throws -> [Memory] {
        guard !filePathResolved.isEmpty else { throw MemoryDatabaseError.noFilePath }
        
        let selectQuery = "SELECT * FROM Memory;"
        var stmt: OpaquePointer?
        
        var memories: [Memory] = []
        
        defer {
            _ = sqlite3.finalize(stmt)
        }
        
        if sqlite3.prepare_v2(db, selectQuery, -1, &stmt, nil) != SQLITE_OK {
            throw NSError(domain: "SQLite", code: 6, userInfo: nil)
        }
        
        while sqlite3.step(stmt) == SQLITE_ROW {
            let idString = String(cString: sqlite3.column_text(stmt, 0))
            let id = UUID(uuidString: idString)!
            
            let snipped = String(cString: sqlite3.column_text(stmt, 1))
            let isKeyKnowledge = sqlite3.column_int64(stmt, 3) == 1
            let creationDate = Date(timeIntervalSince1970: TimeInterval(sqlite3.column_int64(stmt, 4)))
            
            let blob = sqlite3.column_blob(stmt, 2)
            let blobLength = sqlite3.column_bytes(stmt, 2)
            let data = Data(bytes: blob!, count: Int(blobLength))
            
            let existingEmbedding: [Double] = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [Double]
            
            let similarity = calculateCosineSimilarity(embedding, existingEmbedding)
            
            if similarity >= threshold {
                memories.append(Memory(id: id, snipped: snipped, embedding: existingEmbedding, isKeyKnowledge: isKeyKnowledge, creationDate: creationDate))
            }
        }
        
        return memories
    }

    
    func replace(snipped: String, newSnipped: String, embedding: [Double]) async throws {
        guard !filePathResolved.isEmpty else { throw MemoryDatabaseError.noFilePath }

        // First, find the Memory object by old snipped.
        guard let existingMemory = try await find(snipped: snipped) else {
            return
        }

        // Then, delete it.
        let deleteQuery = "DELETE FROM Memory WHERE snipped = ?;"
        var deleteStmt: OpaquePointer?

        defer {
            _ = sqlite3.finalize(deleteStmt)
        }

        if sqlite3.prepare_v2(db, deleteQuery, -1, &deleteStmt, nil) != SQLITE_OK {
            throw NSError(domain: "SQLite", code: 7, userInfo: nil)
        }

        _ = sqlite3.bind_text(deleteStmt, 1, (snipped as NSString).utf8String, -1, nil)

        if sqlite3.step(deleteStmt) != SQLITE_DONE {
            throw NSError(domain: "SQLite", code: 8, userInfo: nil)
        }

        // Finally, insert a new Memory object with the new snipped but same ID and embedding.
        let newMemory = Memory(id: existingMemory.id, snipped: newSnipped, embedding: embedding, isKeyKnowledge: existingMemory.isKeyKnowledge, creationDate: .now)
        try await save(memory: newMemory)
    }
    
    func getKeyMemories(number: Int) async throws -> [Memory] {
        guard !filePathResolved.isEmpty else { throw MemoryDatabaseError.noFilePath }
        
        let selectQuery = "SELECT * FROM Memory WHERE isKeyKnowledge = 1 ORDER BY creationDate DESC LIMIT \(number);"
        var stmt: OpaquePointer?
        
        var memories: [Memory] = []
        
        defer {
            _ = sqlite3.finalize(stmt)
        }
        
        if sqlite3.prepare_v2(db, selectQuery, -1, &stmt, nil) != SQLITE_OK {
            throw NSError(domain: "SQLite", code: 6, userInfo: nil)
        }
        
        while sqlite3.step(stmt) == SQLITE_ROW {
            let idString = String(cString: sqlite3.column_text(stmt, 0))
            let id = UUID(uuidString: idString)!
            
            let snipped = String(cString: sqlite3.column_text(stmt, 1))
            let isKeyKnowledge = sqlite3.column_int64(stmt, 3) == 1
            let creationDate = Date(timeIntervalSince1970: TimeInterval(sqlite3.column_int64(stmt, 4)))
            
            let blob = sqlite3.column_blob(stmt, 2)
            let blobLength = sqlite3.column_bytes(stmt, 2)
            let data = Data(bytes: blob!, count: Int(blobLength))
            
            let existingEmbedding: [Double] = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! [Double]
            
            memories.append(Memory(id: id, snipped: snipped, embedding: existingEmbedding, isKeyKnowledge: isKeyKnowledge, creationDate: creationDate))
        }
        
        return memories
    }


    
    private func calculateCosineSimilarity(_ vec1: [Double], _ vec2: [Double]) -> Double {
        guard let similarity = vec1.cosineSimilarity(with: vec2) else {
            // Handle edge cases as needed, here it returns 0.0
            return 0.0
        }
        return similarity
    }
}
