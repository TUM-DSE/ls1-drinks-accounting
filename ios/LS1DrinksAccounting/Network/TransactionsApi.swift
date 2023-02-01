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
    let user_pin: String?
}

class TransactionsApi {
    let networking: Networking
    
    init(_ networking: Networking) {
        self.networking = networking
    }

    func buyDrink(user: UUID, drink: UUID, userPin: String?) async throws -> User {
        guard let request = try await networking.post(path: "/api/transactions/buy", authorized: true) else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await URLSession.shared.upload(for: request, from: networking.config.encoder.encode(BuyDrinkTransaction(user: user, drink: drink, user_pin: userPin)))
        
        let result = try networking.config.decoder.decode(User.self, from: data.0)
        
        return result
    }
}
