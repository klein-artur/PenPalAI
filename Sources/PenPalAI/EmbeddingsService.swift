//
//  EmbeddingsService.swift
//  
//
//  Created by Artur Hellmann on 30.10.23.
//

import Foundation
import SwiftDose

class EmbeddingsService {
    @Dose(of: \.urlSession) private var urlSession: URLSession
    
    func getEmbedding(for string: String, apiKey: String) async throws -> [Double] {
        let parameters = "{\"input\": \"\(string)\", \"model\": \"text-embedding-ada-002\", \"encoding_format\": \"float\"}"
        let postData = parameters.data(using: .utf8)
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/embeddings")!,timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw URLError(.badServerResponse)
        }
        
        guard let dataObject = json["data"] as? [[String: Any]] else {
            throw URLError(.badServerResponse)
        }
        
        guard let embedding = dataObject[0]["embedding"] as? [Double] else {
            throw URLError(.badServerResponse)
        }

        return embedding
    }
}
