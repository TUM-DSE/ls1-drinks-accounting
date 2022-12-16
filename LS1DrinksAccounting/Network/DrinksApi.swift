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
    let config: NetworkConfig
    
    init(_ config: NetworkConfig) {
        self.config = config
    }
    
    func getDrinks() async throws -> [Drink] {
        guard let url = URL(string: "\(config.baseUrl)/api/drinks") else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await URLSession.shared.data(from: url)
        
        let result = try JSONDecoder().decode([Drink].self, from: data.0)
        
        return result
    }
    
    func create(drink: CreateDrink) async throws -> Drink {
        guard let url = URL(string: "\(config.baseUrl)/api/drinks") else {
            throw NetworkError.invalidUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        let data = try await URLSession.shared.upload(for: request, from: JSONEncoder().encode(drink))
        
        let result = try JSONDecoder().decode(Drink.self, from: data.0)
        
        return result
    }
    
    func update(drink id: UUID, with drink: CreateDrink) async throws -> Drink {
        guard let url = URL(string: "\(config.baseUrl)/api/drinks/\(id)") else {
            throw NetworkError.invalidUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]

        let data = try await URLSession.shared.upload(for: request, from: JSONEncoder().encode(drink))
        
        let result = try JSONDecoder().decode(Drink.self, from: data.0)
        
        return result
    }
}
