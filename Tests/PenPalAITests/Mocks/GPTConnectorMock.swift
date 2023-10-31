//
//  GPTConnectorMock.swift
//  
//
//  Created by Artur Hellmann on 29.10.23.
//

import Foundation
import GPTConnector

class GPTConnectorMock: GPTConnector {
    var chatCalledMock: ((Chat, (([Message], Chat) -> Message), ((String, String) async throws -> String)) async throws -> [Chat])?
    
    var apiKey: String?
    
    func chat(
        context: Chat,
        onChoiceSelect: @escaping (([Message], Chat) -> Message) = { (choices, _) in choices[0] },
        onFunctionCall: @escaping ((String, String) async throws -> String) = { (_, _) in throw GPTConnectorError.noFunctionHandling }
    ) async throws -> [Chat] {
        guard let chatCalledMock else {
            throw NSError()
        }
        return try await chatCalledMock(context, onChoiceSelect, onFunctionCall)
    }
}
