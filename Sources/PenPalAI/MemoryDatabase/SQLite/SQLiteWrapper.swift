//
//  SQLiteWrapper.swift
//  
//
//  Created by Artur Hellmann on 29.10.23.
//

import Foundation
import CSQLite

protocol SQLiteWrapper {
    func open(_ filename: UnsafePointer<Int8>!, _ ppDb: UnsafeMutablePointer<OpaquePointer?>!) -> Int32
    func close(_ db: OpaquePointer!) -> Int32
    func exec(_ db: OpaquePointer!, _ sql: UnsafePointer<Int8>!, _ callback: (@convention(c) (UnsafeMutableRawPointer?, Int32, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32)!, _ pArg: UnsafeMutableRawPointer!, _ errMsg: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>!) -> Int32
    func prepare_v2(_ db: OpaquePointer!, _ zSql: UnsafePointer<Int8>!, _ nByte: Int32, _ ppStmt: UnsafeMutablePointer<OpaquePointer?>!, _ pzTail: UnsafeMutablePointer<UnsafePointer<Int8>?>!) -> Int32
    func step(_ pStmt: OpaquePointer!) -> Int32
    func column_double(_ pStmt: OpaquePointer!, _ iCol: Int32) -> Double
    func column_text(_ pStmt: OpaquePointer!, _ iCol: Int32) -> UnsafePointer<UInt8>!
    func column_int64(_ pStmt: OpaquePointer!, _ iCol: Int32) -> sqlite3_int64
    func bind_double(_ pStmt: OpaquePointer!, _ index: Int32, _ value: Double) -> Int32
    func bind_text(_ pStmt: OpaquePointer!, _ index: Int32, _ text: UnsafePointer<Int8>!, _ len: Int32, _ f: (@convention(c) (UnsafeMutableRawPointer?) -> Swift.Void)!) -> Int32
    func bind_blob(_ pStmt: OpaquePointer!, _ index: Int32, _ blob: UnsafeRawPointer!, _ len: Int32, _ f: (@convention(c) (UnsafeMutableRawPointer?) -> Swift.Void)!) -> Int32
    func finalize(_ pStmt: OpaquePointer!) -> Int32
}

struct RealSQLiteWrapper: SQLiteWrapper {
    func open(_ filename: UnsafePointer<Int8>!, _ ppDb: UnsafeMutablePointer<OpaquePointer?>!) -> Int32 {
        return sqlite3_open(filename, ppDb)
    }
    
    func close(_ db: OpaquePointer!) -> Int32 {
        return sqlite3_close(db)
    }
    
    func exec(_ db: OpaquePointer!, _ sql: UnsafePointer<Int8>!, _ callback: (@convention(c) (UnsafeMutableRawPointer?, Int32, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?, UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>?) -> Int32)!, _ pArg: UnsafeMutableRawPointer!, _ errMsg: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>!) -> Int32 {
        return sqlite3_exec(db, sql, callback, pArg, errMsg)
    }
    
    func prepare_v2(_ db: OpaquePointer!, _ zSql: UnsafePointer<Int8>!, _ nByte: Int32, _ ppStmt: UnsafeMutablePointer<OpaquePointer?>!, _ pzTail: UnsafeMutablePointer<UnsafePointer<Int8>?>!) -> Int32 {
        return sqlite3_prepare_v2(db, zSql, nByte, ppStmt, pzTail)
    }
    
    func step(_ pStmt: OpaquePointer!) -> Int32 {
        return sqlite3_step(pStmt)
    }
    
    func column_double(_ pStmt: OpaquePointer!, _ iCol: Int32) -> Double {
        return sqlite3_column_double(pStmt, iCol)
    }
    
    func column_text(_ pStmt: OpaquePointer!, _ iCol: Int32) -> UnsafePointer<UInt8>! {
        return sqlite3_column_text(pStmt, iCol)
    }
    
    func column_int64(_ pStmt: OpaquePointer!, _ iCol: Int32) -> sqlite3_int64 {
        return sqlite3_column_int64(pStmt, iCol)
    }
    
    func bind_double(_ pStmt: OpaquePointer!, _ index: Int32, _ value: Double) -> Int32 {
        return sqlite3_bind_double(pStmt, index, value)
    }
    
    func bind_text(_ pStmt: OpaquePointer!, _ index: Int32, _ text: UnsafePointer<Int8>!, _ len: Int32, _ f: (@convention(c) (UnsafeMutableRawPointer?) -> Swift.Void)!) -> Int32 {
        return sqlite3_bind_text(pStmt, index, text, len, f)
    }
    
    func bind_blob(_ pStmt: OpaquePointer!, _ index: Int32, _ blob: UnsafeRawPointer!, _ len: Int32, _ f: (@convention(c) (UnsafeMutableRawPointer?) -> Swift.Void)!) -> Int32 {
        return sqlite3_bind_blob(pStmt, index, blob, len, f)
    }
    
    func finalize(_ pStmt: OpaquePointer!) -> Int32 {
        return sqlite3_finalize(pStmt)
    }
}

