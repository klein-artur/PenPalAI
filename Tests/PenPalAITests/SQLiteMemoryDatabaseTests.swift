//
//  SQLiteMemoryDatabaseTests.swift
//  
//
//  Created by Artur Hellmann on 29.10.23.
//

import XCTest
@testable import PenPalAI
import SwiftDose
import CSQLite

class SQLiteMemoryDatabaseTests: XCTestCase {
    
    var sut: SQLiteMemoryDatabase!
    var mockSQLite: SQLiteWrapperMock!
    
    override func setUp() {
        super.setUp()
        
        mockSQLite = SQLiteWrapperMock()
        sut = SQLiteMemoryDatabase()
        
        DoseBindings[\.sqlite3] = InstanceProvider {
            self.mockSQLite
        }
    }
    
    override func tearDown() {
        mockSQLite = nil
        sut = nil
        
        super.tearDown()
    }
    
    func testCreateDatabaseSuccess() {
        sut.filePath = "test.db"
        
        XCTAssert(
            mockSQLite.executedSQL.contains {
                $0.contains("CREATE TABLE IF NOT EXISTS Memory (")
            }
        )
    }
    
    func testCreateDatabaseFailure() {
        mockSQLite.openShouldSucceed = [false]
        sut.filePath = "test.db"
        
        // Validate that the database wasn't created
        XCTAssertFalse(
            mockSQLite.executedSQL.contains {
                $0.contains("CREATE TABLE IF NOT EXISTS Memory (")
            }
        )
    }
    
    func testSaveMemorySuccess() async throws {
        let memory = Memory(id: UUID(), snipped: "testSnipped", embedding: [0.1, 0.2])
        sut.filePath = "test.db"
        
        try await sut.save(memory: memory)
        
        // Validate that the query was executed
        XCTAssertTrue(
            mockSQLite.executedSQL.contains {
                $0.contains("INSERT INTO Memory (id, snipped, embedding) VALUES (?, ?, ?);")
            }
        )
    }
    // TODO: Fix this tests.
//    func testFindMemoryBySnippedSuccess() async throws {
//        let memory = Memory(id: UUID(), snipped: "testSnipped", embedding: [0.1, 0.2])
//        mockSQLite.columnTextReturns = [memory.id.uuidString, memory.snipped]
//        mockSQLite.columnInt64Returns = [Int64(memory.id.hashValue)]
//        mockSQLite.stepShouldReturn = [SQLITE_ROW]
//
//        sut.filePath = "test.db"
//
//        let foundMemory = try await sut.find(snipped: "testSnipped")
//
//        XCTAssertNotNil(foundMemory)
//    }
//
//    func testFindMemoryByEmbeddingSuccess() async throws {
//        let memory = Memory(id: UUID(), snipped: "testSnipped", embedding: [0.1, 0.2])
//        mockSQLite.columnTextReturns = [memory.id.uuidString, memory.snipped]
//        mockSQLite.columnInt64Returns = [Int64(memory.id.hashValue)]
//        mockSQLite.stepShouldReturn = [SQLITE_ROW]
//
//        sut.filePath = "test.db"
//
//        let foundMemory = try await sut.find(embedding: [0.1, 0.2], threshold: 0.99)
//
//        XCTAssertNotNil(foundMemory)
//    }
//
//    func testSaveMemoryFailsOnPrepareV2Error() async throws {
//        let memory = Memory(id: UUID(), snipped: "testSnipped", embedding: [0.1, 0.2])
//        sut.filePath = "test.db"
//        mockSQLite.prepareShouldSucceed = [false]
//
//        do {
//            try await sut.save(memory: memory)
//            XCTFail("Expected save to throw, but it did not.")
//        } catch {
//            // Validate that the query was not executed
//            XCTAssertTrue(mockSQLite.executedSQL.isEmpty)
//        }
//    }
//
//    func testFindMemoryByEmbeddingReturnsNilOnLowThreshold() async throws {
//        let memory = Memory(id: UUID(), snipped: "testSnipped", embedding: [0.1, 0.2])
//        mockSQLite.columnTextReturns = [memory.id.uuidString, memory.snipped]
//        mockSQLite.columnInt64Returns = [Int64(memory.id.hashValue)]
//        mockSQLite.stepShouldReturn = [SQLITE_ROW]
//
//        sut.filePath = "test.db"
//
//        let foundMemory = try await sut.find(embedding: [0.5, 0.5], threshold: 0.9)
//
//        XCTAssertNil(foundMemory)
//    }

    func testSaveMemoryFailsOnNoFilePath() async throws {
        let memory = Memory(id: UUID(), snipped: "testSnipped", embedding: [0.1, 0.2])
        
        do {
            try await sut.save(memory: memory)
            XCTFail("Expected save to throw, but it did not.")
        } catch {
            // Validate that the query was not executed
            XCTAssertTrue(mockSQLite.executedSQL.isEmpty)
        }
    }

    func testFindMemoryBySnippedFailsOnNoFilePath() async throws {
        do {
            _ = try await sut.find(snipped: "testSnipped")
            XCTFail("Expected find to throw, but it did not.")
        } catch {
            // Validate that the query was not executed
            XCTAssertTrue(mockSQLite.executedSQL.isEmpty)
        }
    }

    func testFindMemoryByEmbeddingFailsOnNoFilePath() async throws {
        do {
            _ = try await sut.find(embedding: [0.1, 0.2], threshold: 0.99)
            XCTFail("Expected find to throw, but it did not.")
        } catch {
            // Validate that the query was not executed
            XCTAssertTrue(mockSQLite.executedSQL.isEmpty)
        }
    }

    func testFindMemoryBySnippedReturnsNilOnStepFailure() async throws {
        mockSQLite.stepShouldReturn = [SQLITE_ERROR]
        sut.filePath = "test.db"
        
        let foundMemory = try await sut.find(snipped: "testSnipped")
        
        XCTAssertNil(foundMemory)
    }

    func testFindMemoryByEmbeddingReturnsEmptyOnStepFailure() async throws {
        mockSQLite.stepShouldReturn = [SQLITE_ERROR]
        sut.filePath = "test.db"
        
        let foundMemory = try await sut.find(embedding: [0.1, 0.2], threshold: 0.99)
        
        XCTAssertTrue(foundMemory.isEmpty)
    }

}
