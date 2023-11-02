//
//  GPTConnectorMock.swift
//  
//
//  Created by Artur Hellmann on 29.10.23.
//

import Foundation
import GPTConnector

class GPTConnectorMock: GPTConnector {
    func chat(
        context: Chat,
        onMessagesReceived: @escaping (([Message], Chat) -> Message), 
        onToolCall: @escaping ((ToolCall) async throws -> String)) async throws -> Chat {
            
        guard let chatCalledMock else {
            throw NSError()
        }
        return try await chatCalledMock(context, onMessagesReceived, onToolCall)
    }
    
    func chat(
        context: Chat,
        onMessagesReceived: @escaping (([Message], Chat) -> Message),
        onFunctionCall: @escaping ((String, String) async throws -> String)) async throws -> Chat {
            // do nothing.
            return Chat(messages: [], tools: [])
    }
    
    var chatCalledMock: ((Chat, (([Message], Chat) -> Message), ((ToolCall) async throws -> String)) async throws -> Chat)?
    
    var apiKey: String?
}
