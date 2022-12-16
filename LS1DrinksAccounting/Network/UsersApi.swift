//
//  UsersApi.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 16.12.22.
//

import Foundation

struct CreateUser: Encodable {
    let first_name: String
    let last_name: String
    let email: String
}

class UsersApi {
    let config: NetworkConfig
    
    init(_ config: NetworkConfig) {
        self.config = config
    }
    
    func getUsers() async throws -> [User] {
        guard let url = URL(string: "\(config.baseUrl)/api/users") else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await URLSession.shared.data(from: url)
        
        let result = try JSONDecoder().decode([User].self, from: data.0)
        
        return result
    }

    func addUser(user: CreateUser) async throws -> User {
        guard let url = URL(string: "\(config.baseUrl)/api/users") else {
            throw NetworkError.invalidUrl
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        let data = try await URLSession.shared.upload(for: request, from: try! JSONEncoder().encode(user))
        
        let result = try JSONDecoder().decode(User.self, from: data.0)
        
        return result
    }
}
