//
//  File.swift
//  
//
//  Created by Artur Hellmann on 30.10.23.
//

import Foundation
@testable import PenPalAI

class EmbeddingServiceMock: EmbeddingsService {
    var onGetEmbedding: ((String, String) -> [Double])?
    
    override func getEmbedding(for string: String, apiKey: String) async throws -> [Double] {
        return onGetEmbedding?(string, apiKey) ?? []
    }
}
