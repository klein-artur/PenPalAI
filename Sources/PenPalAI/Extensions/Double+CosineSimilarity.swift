//
//  File.swift
//  
//
//  Created by Artur Hellmann on 29.10.23.
//

import Foundation
import Darwin

extension Array where Element == Double {
    
    private func dotProduct(with vector: [Double]) -> Double? {
        guard self.count == vector.count else { return nil }
        return zip(self, vector).map(*).reduce(0, +)
    }
    
    private var magnitude: Double {
        return sqrt(self.map { $0 * $0 }.reduce(0, +))
    }
    
    func cosineSimilarity(with vector: [Double]) -> Double? {
        guard let dotProduct = self.dotProduct(with: vector) else { return nil }
        let magnitudeProduct = self.magnitude * vector.magnitude
        return magnitudeProduct == 0.0 ? nil : dotProduct / magnitudeProduct
    }
}
