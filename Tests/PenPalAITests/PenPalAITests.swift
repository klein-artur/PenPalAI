import XCTest
@testable import PenPalAI
import GPTConnector
import SwiftDose

final class PenPalAITests: XCTestCase {
    
    var sut: PenPalAI!
    var memoryMock: MemoryDatabaseMock!
    var chatMock: GPTConnectorMock!
    var embeddingsMock: EmbeddingServiceMock!
    
    override func setUpWithError() throws {
        memoryMock = MemoryDatabaseMock()
        chatMock = GPTConnectorMock()
        embeddingsMock = EmbeddingServiceMock()
        
        DoseBindings[\.memoryDatabase] = InstanceProvider(providerBlock: {
            self.memoryMock
        })
        DoseBindings[\.gptConnector] = InstanceProvider(providerBlock: {
            self.chatMock
        })
        DoseBindings[\.embeddingsService] = InstanceProvider(providerBlock: {
            self.embeddingsMock
        })
        
        sut = PenPalAI(pal: "someFile.ppai", apiKey: "someApiKey")
    }
    
    override func tearDownWithError() throws {
        sut = nil
        memoryMock = nil
        chatMock = nil
    }
    
    func testShouldSetApiKeyAndFileName() {
        // then
        XCTAssertEqual(chatMock.apiKey, "someApiKey")
        XCTAssertEqual(memoryMock.filePath, "someFile.ppai")
    }
    
    func testShouldCallChatWithFirstUserMessage() async throws {
        // given
        let chatCallbackExpectation = expectation(description: "chatCallbackExpectation")
        let keyMemories = [
            Memory(id: UUID(), snipped: "This is a Test", embedding: [], isKeyKnowledge: true, creationDate: .now),
            Memory(id: UUID(), snipped: "This is another Test", embedding: [], isKeyKnowledge: true, creationDate: .now)
        ]
        
        memoryMock.onGetKeyMemories = { number in
            return keyMemories
        }
        chatMock.chatCalledMock = { chat, onChoiceSelect, onFunctionCall in
            
            // then
            XCTAssertEqual(chat.messages[0].content, Constants.System.systemMessage(keyMemories: keyMemories))
            XCTAssertEqual(chat.messages[1].content, "Test message")
            
            chatCallbackExpectation.fulfill()
            
            return [chat]
        }
        
        // when
        _ = try await sut.send(message: "Test message")
        
        // then
        wait(for: [chatCallbackExpectation], timeout: 1)
    }
    
    func testShouldCallChatWithThreeFunctionsGiven() async throws {
        // given
        let chatCallbackExpectation = expectation(description: "chatCallbackExpectation")
        chatMock.chatCalledMock = { chat, onChoiceSelect, onFunctionCall in
            
            // then
            XCTAssertEqual(chat.functions.count, 3)
            XCTAssertEqual(chat.functions[0].name, Constants.System.Functions.GetMemory.name)
            XCTAssertEqual(chat.functions[1].name, Constants.System.Functions.SaveMemory.name)
            XCTAssertEqual(chat.functions[2].name, Constants.System.Functions.ReplaceMemory.name)
            
            chatCallbackExpectation.fulfill()
            
            return [chat]
        }
        
        // when
        _ = try await sut.send(message: "Test message")
        
        // then
        wait(for: [chatCallbackExpectation], timeout: 1)
    }
    
    func testShouldThrowErrorIfNoChatsReturned() async throws {
        // given
        chatMock.chatCalledMock = { _, _, _ in
            return []
        }
        
        // when
        do {
            _ = try await sut.send(message: "Test message")
            XCTFail("Should throw error")
        } catch {
            // then
            XCTAssertEqual(error as? PenPalAI.PenPalError, PenPalAI.PenPalError.chatGenerationFailed)
        }
    }
    
    func testShouldUpdateItsChatAndSendAnswer() async throws {
        // given
        var callNumber = 0
        chatMock.chatCalledMock = { chat, _, _ in
            callNumber += 1
            if callNumber == 1 {
                return [chat.byAddingMessage(.assistant("This is the assistant message", functionCall: nil))]
            } else if callNumber == 2 {
                XCTAssertEqual(chat.messages[2].content, "This is the assistant message")
                XCTAssertEqual(chat.messages[3].content, "Test message")
                return [chat.byAddingMessage(.assistant("The other assistant message", functionCall: nil))]
            } else {
                XCTAssertEqual(chat.messages[4].content, "The other assistant message")
                XCTAssertEqual(chat.messages[5].content, "Test message")
                return [chat.byAddingMessage(.assistant("The last assistant message", functionCall: nil))]
            }
        }
        
        // when
        let answer = try await sut.send(message: "Test user message")
        let secondAnswer = try await sut.send(message: "Test message")
        let thirdAnswer = try await sut.send(message: "Test message")
        
        // then
        XCTAssertEqual(answer, "This is the assistant message")
        XCTAssertEqual(secondAnswer, "The other assistant message")
        XCTAssertEqual(thirdAnswer, "The last assistant message")
    }
    
    
    // MARK: - Chat functions
    
    func testShouldReturnGivenMemory_callEmbeddings() async throws {
        // given
        let memoryCallExpectation = expectation(description: "memoryCallExpectation")
        let chackCallExpectation = expectation(description: "chackCallExpectation")
        let embeddingCallExpectation = expectation(description: "embeddingCallExpectation")
        memoryMock.onFindEmbedding = { embedding, threshold in
            XCTAssertEqual(threshold, Constants.System.embeddingThreshold)
            XCTAssertEqual(embedding, [1.1, 2.2, 3.3])
            memoryCallExpectation.fulfill()
            return [Memory(id: UUID(), snipped: "Test memory", embedding: [], isKeyKnowledge: false, creationDate: .now), Memory(id: UUID(), snipped: "Test memory 2", embedding: [], isKeyKnowledge: false, creationDate: .now)]
        }
        chatMock.chatCalledMock = { chat, _, onFunctionCall in
            let functionResult = try await onFunctionCall(Constants.System.Functions.GetMemory.name, "{\"\(Constants.System.Functions.GetMemory.searchTextParameterName)\": \"Test memory\"}")
            
            XCTAssertEqual(functionResult, "Test memory, Test memory 2")
            
            chackCallExpectation.fulfill()
            return [chat]
        }
        embeddingsMock.onGetEmbedding = { text, apiKey in
            XCTAssertEqual(apiKey, "someApiKey")
            XCTAssertEqual(text, "Test memory")
            embeddingCallExpectation.fulfill()
            return [1.1, 2.2, 3.3]
        }
        
        // when
        _ = try await sut.send(message: "Test message")
        
        // then
        wait(for: [memoryCallExpectation, chackCallExpectation, embeddingCallExpectation], timeout: 1)
    }
    
    func testShouldSaveMemory_callEmbeddings() async throws {
        // given
        let memoryCallExpectation = expectation(description: "memoryCallExpectation")
        let chackCallExpectation = expectation(description: "chackCallExpectation")
        let embeddingCallExpectation = expectation(description: "embeddingCallExpectation")
        memoryMock.onSave = { memory in
            XCTAssertEqual(memory.snipped, "Test memory")
            memoryCallExpectation.fulfill()
        }
        chatMock.chatCalledMock = { chat, _, onFunctionCall in
            let functionResult = try await onFunctionCall(Constants.System.Functions.SaveMemory.name, "{\"\(Constants.System.Functions.SaveMemory.infoParameterName)\": \"Test memory\", \"\(Constants.System.Functions.SaveMemory.isKeyParameterName)\": false                                                          }")
            
            XCTAssertEqual(functionResult, "done")
            
            chackCallExpectation.fulfill()
            return [chat]
        }
        embeddingsMock.onGetEmbedding = { text, apiKey in
            XCTAssertEqual(apiKey, "someApiKey")
            XCTAssertEqual(text, "Test memory")
            embeddingCallExpectation.fulfill()
            return [1.1, 2.2, 3.3]
        }
        
        // when
        _ = try await sut.send(message: "Test message")
        
        // then
        wait(for: [memoryCallExpectation, chackCallExpectation, embeddingCallExpectation], timeout: 1)
    }
    
    func testShouldReplaceMemory_callEmbeddings() async throws {
        // given
        let memoryCallExpectation = expectation(description: "memoryCallExpectation")
        let chackCallExpectation = expectation(description: "chackCallExpectation")
        let embeddingCallExpectation = expectation(description: "embeddingCallExpectation")
        memoryMock.onReplace = { old, new, embeddings in
            XCTAssertEqual(old, "Test memory")
            XCTAssertEqual(new, "Test memory 2")
            XCTAssertEqual(embeddings, [1.1, 2.2, 3.3])
            memoryCallExpectation.fulfill()
        }
        chatMock.chatCalledMock = { chat, _, onFunctionCall in
            let functionResult = try await onFunctionCall(
                Constants.System.Functions.ReplaceMemory.name,
                "{\"\(Constants.System.Functions.ReplaceMemory.oldInfoParameterName)\": \"Test memory\", \"\(Constants.System.Functions.ReplaceMemory.newInfoParameterName)\": \"Test memory 2\"}"
            )
            
            XCTAssertEqual(functionResult, "done")
            
            chackCallExpectation.fulfill()
            return [chat]
        }
        embeddingsMock.onGetEmbedding = { text, apiKey in
            XCTAssertEqual(apiKey, "someApiKey")
            XCTAssertEqual(text, "Test memory 2")
            embeddingCallExpectation.fulfill()
            return [1.1, 2.2, 3.3]
        }
        
        // when
        _ = try await sut.send(message: "Test message")
        
        // then
        wait(for: [memoryCallExpectation, chackCallExpectation, embeddingCallExpectation], timeout: 1)
    }
    
    func testShouldReturnEmpty_noMemory() async throws {
        // given
        let memoryCallExpectation = expectation(description: "memoryCallExpectation")
        let chackCallExpectation = expectation(description: "chackCallExpectation")
        memoryMock.onFindEmbedding = { _, threshold in
            XCTAssertEqual(threshold, Constants.System.embeddingThreshold)
            memoryCallExpectation.fulfill()
            return []
        }
        chatMock.chatCalledMock = { chat, _, onFunctionCall in
            let functionResult = try await onFunctionCall(Constants.System.Functions.GetMemory.name, "{\"\(Constants.System.Functions.GetMemory.searchTextParameterName)\": \"some\"}")
            
            XCTAssertEqual(functionResult, "")
            
            chackCallExpectation.fulfill()
            return [chat]
        }
        
        // when
        _ = try await sut.send(message: "Test message")
        
        // then
        wait(for: [memoryCallExpectation, chackCallExpectation], timeout: 1)
    }
    
}
