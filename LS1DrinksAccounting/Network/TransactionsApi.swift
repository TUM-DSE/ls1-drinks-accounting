//
//  TransactionsApi.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 16.12.22.
//

import Foundation

struct BuyDrinkTransaction: Encodable {
    let user: UUID
    let drink: UUID
}

class TransactionsApi {
    let config: NetworkConfig
    
    init(_ config: NetworkConfig) {
        self.config = config
    }
    
    func buyDrink(user: UUID, drink: UUID) async throws -> User {
        guard let url = URL(string: "\(config.baseUrl)/api/transactions/buy") else {
            throw NetworkError.invalidUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        let data = try await URLSession.shared.upload(for: request, from: JSONEncoder().encode(BuyDrinkTransaction(user: user, drink: drink)))
        
        let result = try JSONDecoder().decode(User.self, from: data.0)
        
        return result
    }
}
