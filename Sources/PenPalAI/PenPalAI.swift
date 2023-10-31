import GPTConnector
import Foundation
import SwiftDose

public class PenPalAI {
    
    @Dose(of: \.gptConnector) private var gptConnector: any GPTConnector
    @Dose(of: \.memoryDatabase) private var memoryDatabase: any MemoryDatabase
    @Dose(of: \.embeddingsService) private var embeddingsService: EmbeddingsService
    
    public enum PenPalError: Error {
        case chatGenerationFailed
    }
    
    private var currentChat: Chat? = nil
    private let apiKey: String
    
    /// Creates a new PenPalAI instance.
    /// - Parameters:
    ///  - pal: The path to the PenPalAI file which should be an SQLite file. If the file does not exist yet, it will be created on the first call to `send(message:)`.
    ///  - apiKey: The API key for the OpenAI API.
    public init(pal: String, apiKey: String) {
        self.apiKey = apiKey
        gptConnector.apiKey = apiKey
        memoryDatabase.filePath = pal
    }
    
    public func send(message: String?) async throws -> String {
        var chat = currentChat ?? createNewChat()
        
        if let message = message {
            chat = chat.byAddingMessage(.user(message))
        }
        
        guard let newChat = try await gptConnector.chat(context: chat, onFunctionCall: self.handleFunction(name:arguments:)).first else {
            throw PenPalError.chatGenerationFailed
        }
        
        currentChat = newChat
        
        return newChat.messages.last?.content ?? ""
    }
    
    private func handleFunction(name: String, arguments: String) async throws -> String {
        switch name {
        case Constants.System.Functions.GetMemory.name:
            return try await handleGetMemory(arguments: arguments)
        case Constants.System.Functions.SaveMemory.name:
            return try await handleSaveMemory(arguments: arguments)
        case Constants.System.Functions.ReplaceMemory.name:
            return try await handleReplaceMemory(arguments: arguments)
        default:
            throw PenPalError.chatGenerationFailed
        }
    }
    
    private func handleGetMemory(arguments: String) async throws -> String {
        guard let jsonData = arguments.data(using: .utf8),
              let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
              let searchText = dictionary[Constants.System.Functions.GetMemory.searchTextParameterName] as? String else {
            return "error"
        }
        
        let embeddings = try await embeddingsService.getEmbedding(for: searchText, apiKey: self.apiKey)
        
        return try await memoryDatabase.find(embedding: embeddings, threshold: Constants.System.embeddingThreshold).map { $0.snipped }.joined(separator: ", ")
    }
    
    private func handleSaveMemory(arguments: String) async throws -> String {
        guard let jsonData = arguments.data(using: .utf8),
              let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
              let snipped = dictionary[Constants.System.Functions.SaveMemory.infoParameterName] as? String else {
            return "error"
        }
        
        let embeddings = try await embeddingsService.getEmbedding(for: snipped, apiKey: self.apiKey)
        
        try await memoryDatabase.save(memory: Memory(id: UUID(), snipped: snipped, embedding: embeddings))
        
        return "done"
    }
    
    private func handleReplaceMemory(arguments: String) async throws -> String {
        guard let jsonData = arguments.data(using: .utf8),
              let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
              let snipped = dictionary[Constants.System.Functions.ReplaceMemory.oldInfoParameterName] as? String,
              let newSnipped = dictionary[Constants.System.Functions.ReplaceMemory.newInfoParameterName] as? String else {
            return "error"
        }
        
        let embeddings = try await embeddingsService.getEmbedding(for: newSnipped, apiKey: self.apiKey)
        
        try await memoryDatabase.replace(snipped: snipped, newSnipped: newSnipped, embedding: embeddings)
        
        return "done"
    }
    
    // MARK: - Private
    
    private func createNewChat() -> Chat {
        Chat(
            messages: [.system(Constants.System.systemMessage)],
            functions: [
                .init(
                    name: Constants.System.Functions.GetMemory.name,
                    description: Constants.System.Functions.GetMemory.description,
                    parameters: [
                        .init(
                            name: Constants.System.Functions.GetMemory.searchTextParameterName,
                            type: .string,
                            description: Constants.System.Functions.GetMemory.searchTextParameterDescription,
                            required: true
                        )
                    ]
                ),
                .init(
                    name: Constants.System.Functions.SaveMemory.name,
                    description: Constants.System.Functions.SaveMemory.description,
                    parameters: [
                        .init(
                            name: Constants.System.Functions.SaveMemory.infoParameterName,
                            type: .string,
                            description: Constants.System.Functions.SaveMemory.infoParameterDescription,
                            required: true
                        )
                    ]
                ),
                .init(
                    name: Constants.System.Functions.ReplaceMemory.name,
                    description: Constants.System.Functions.ReplaceMemory.description,
                    parameters: [
                        .init(
                            name: Constants.System.Functions.ReplaceMemory.oldInfoParameterName,
                            type: .string,
                            description: Constants.System.Functions.ReplaceMemory.oldInfoParameterDescription,
                            required: true
                        ),
                        .init(
                            name: Constants.System.Functions.ReplaceMemory.newInfoParameterName,
                            type: .string,
                            description: Constants.System.Functions.ReplaceMemory.newInfoParameterDescription,
                            required: true
                        )
                    ]
                )
            ]
        )
    }
}
