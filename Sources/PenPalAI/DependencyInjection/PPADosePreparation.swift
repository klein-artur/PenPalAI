//
//  File.swift
//  
//
//  Created by Artur Hellmann on 29.10.23.
//

import Foundation
import SwiftDose
import GPTConnector

private var connectorProvider: InstanceProvider<any GPTConnector> = InstanceProvider {
    // APIKey will be set later.
    GPTConnectorFactory.create()
}

private var memoryDatabaseProvider: InstanceProvider<any MemoryDatabase> = InstanceProvider {
    SQLiteMemoryDatabase()
}

private var sqliteProvider: InstanceProvider<any SQLiteWrapper> = InstanceProvider {
    RealSQLiteWrapper()
}

private var urlSessionProvider: InstanceProvider<URLSession> = InstanceProvider {
    URLSession.shared
}

private var embeddingsServiceProvider: InstanceProvider<EmbeddingsService> = InstanceProvider {
    EmbeddingsService()
}

extension DoseBindings {
    var gptConnector: InstanceProvider<any GPTConnector> {
        get { connectorProvider }
        set { connectorProvider = newValue }
    }
    var memoryDatabase: InstanceProvider<any MemoryDatabase> {
        get { memoryDatabaseProvider }
        set { memoryDatabaseProvider = newValue }
    }
    var sqlite3: InstanceProvider<any SQLiteWrapper> {
        get { sqliteProvider }
        set { sqliteProvider = newValue }
    }
    var urlSession: InstanceProvider<URLSession> {
        get { urlSessionProvider }
        set { urlSessionProvider = newValue }
    }
    var embeddingsService: InstanceProvider<EmbeddingsService> {
        get { embeddingsServiceProvider }
        set { embeddingsServiceProvider = newValue }
    }
}
