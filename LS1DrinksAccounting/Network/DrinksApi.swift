//
//  DrinksApi.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 16.12.22.
//

import Foundation

struct CreateDrink: Encodable {
    let name: String
    let icon: String
    let price: Double
}

class DrinksApi {
    let networking: Networking
    
    init(_ networking: Networking) {
        self.networking = networking
    }

    func getDrinks() async throws -> [Drink] {
        guard let request = try await networking.get(path: "/api/drinks", authorized: true) else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await URLSession.shared.data(for: request)
        
        let result = try JSONDecoder().decode([Drink].self, from: data.0)
        
        return result
    }
    
    func create(drink: CreateDrink) async throws -> Drink {
        guard let request = try await networking.post(path: "/api/drinks", authorized: true) else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await URLSession.shared.upload(for: request, from: JSONEncoder().encode(drink))
        
        let result = try JSONDecoder().decode(Drink.self, from: data.0)
        
        return result
    }
    
    func update(drink id: UUID, with drink: CreateDrink) async throws -> Drink {
        guard let request = try await networking.post(path: "/api/drinks/\(id)", authorized: true) else {
            throw NetworkError.invalidUrl
        }

        let data = try await URLSession.shared.upload(for: request, from: JSONEncoder().encode(drink))
        
        let result = try JSONDecoder().decode(Drink.self, from: data.0)
        
        return result
    }
}
