//
//  MockSQLiteWrapper.swift
//  
//
//  Created by Artur Hellmann on 29.10.23.
//

@testable import PenPalAI

import Foundation
import CSQLite

class SQLiteWrapperMock: SQLiteWrapper {
    
    var openShouldSucceed: [Bool] = [true]
    var closeShouldSucceed: [Bool] = [true]
    var execShouldSucceed: [Bool] = [true]
    var prepareShouldSucceed: [Bool] = [true]
    var stepShouldReturn: [Int32] = [SQLITE_DONE]

    var columnDoubleReturns: [Double] = [0.0]
    var columnTextReturns: [String] = [""]
    var columnInt64Returns: [Int64] = [0]
    
    private var openIndex = 0
    private var closeIndex = 0
    private var execIndex = 0
    private var prepareIndex = 0
    private var stepIndex = 0
    
    private var columnDoubleIndex = 0
    private var columnTextIndex = 0
    private var columnInt64Index = 0
    
    var executedSQL: [String] = []
    var boundText: [String] = []
    var boundBlob: [Data] = []

    func open(_ filename: UnsafePointer<Int8>!, _ ppDb: UnsafeMutablePointer<OpaquePointer?>!) -> Int32 {
        let result = openShouldSucceed[openIndex % openShouldSucceed.count]
        openIndex += 1
        return result ? SQLITE_OK : SQLITE_ERROR
    }
    
    func close(_ db: OpaquePointer!) -> Int32 {
        let result = closeShouldSucceed[closeIndex % closeShouldSucceed.count]
        closeIndex += 1
        return result ? SQLITE_OK : SQLITE_ERROR
    }

    func exec(_ db: OpaquePointer!, _ sql: UnsafePointer<Int8>!, _ callback: (@convention(c) (UnsafeMutableRawPointer?, Int32, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32)!, _ pArg: UnsafeMutableRawPointer!, _ errMsg: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>!) -> Int32 {
        let sqlString = String(cString: sql)
        executedSQL.append(sqlString)
        
        let result = execShouldSucceed[execIndex % execShouldSucceed.count]
        execIndex += 1
        return result ? SQLITE_OK : SQLITE_ERROR
    }
    
    func prepare_v2(_ db: OpaquePointer!, _ zSql: UnsafePointer<Int8>!, _ nByte: Int32, _ ppStmt: UnsafeMutablePointer<OpaquePointer?>!, _ pzTail: UnsafeMutablePointer<UnsafePointer<Int8>?>!) -> Int32 {
        let sqlString = String(cString: zSql)
        executedSQL.append(sqlString)
        
        let result = prepareShouldSucceed[prepareIndex % prepareShouldSucceed.count]
        prepareIndex += 1
        return result ? SQLITE_OK : SQLITE_ERROR
    }
    
    func step(_ pStmt: OpaquePointer!) -> Int32 {
        let result = stepShouldReturn[stepIndex % stepShouldReturn.count]
        stepIndex += 1
        return result
    }
    
    func column_double(_ pStmt: OpaquePointer!, _ iCol: Int32) -> Double {
        let value = columnDoubleReturns[columnDoubleIndex % columnDoubleReturns.count]
        columnDoubleIndex += 1
        return value
    }
    
    func column_text(_ pStmt: OpaquePointer!, _ iCol: Int32) -> UnsafePointer<UInt8>! {
        let value = columnTextReturns[columnTextIndex % columnTextReturns.count]
        columnTextIndex += 1
        
        // Copy the data into a new buffer
        let count = value.utf8CString.count
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        let bufferPointer = UnsafeMutableBufferPointer(start: buffer, count: count)
        
        _ = bufferPointer.initialize(from: value.utf8CString.map { UInt8(bitPattern: $0) })
        
        // Don't forget to deallocate this buffer when you're done with it!
        allocatedBuffers.append(buffer)
        return UnsafePointer(buffer)
    }
    
    func column_int64(_ pStmt: OpaquePointer!, _ iCol: Int32) -> sqlite3_int64 {
        let value = columnInt64Returns[columnInt64Index % columnInt64Returns.count]
        columnInt64Index += 1
        return value
    }
    
    func bind_double(_ pStmt: OpaquePointer!, _ index: Int32, _ value: Double) -> Int32 {
        return SQLITE_OK
    }
    
    func bind_text(_ pStmt: OpaquePointer!, _ index: Int32, _ text: UnsafePointer<Int8>!, _ len: Int32, _ f: (@convention(c) (UnsafeMutableRawPointer?) -> Swift.Void)!) -> Int32 {
        let boundTextString = String(cString: text)
        boundText.append(boundTextString)
        return SQLITE_OK
    }
    
    func bind_blob(_ pStmt: OpaquePointer!, _ index: Int32, _ blob: UnsafeRawPointer!, _ len: Int32, _ f: (@convention(c) (UnsafeMutableRawPointer?) -> Swift.Void)!) -> Int32 {
        let data = Data(bytes: blob, count: Int(len))
        boundBlob.append(data)
        return SQLITE_OK
    }
    
    func finalize(_ pStmt: OpaquePointer!) -> Int32 {
        return SQLITE_OK
    }
    
    var allocatedBuffers: [UnsafeMutablePointer<UInt8>] = []

    func deallocBuffers() {
        for buffer in allocatedBuffers {
            buffer.deallocate()
        }
        allocatedBuffers.removeAll()
    }
}
