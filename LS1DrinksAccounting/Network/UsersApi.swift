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
    let networking: Networking
    
    init(_ networking: Networking) {
        self.networking = networking
    }
    
    func getUsers() async throws -> [User] {
        guard let request = try await networking.get(path: "/api/users", authorized: true) else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await URLSession.shared.data(for: request)
        
        let result = try JSONDecoder().decode([User].self, from: data.0)
        
        return result
    }

    func addUser(user: CreateUser) async throws -> User {
        guard let request = try await networking.post(path: "/api/users", authorized: true) else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await URLSession.shared.upload(for: request, from: try! JSONEncoder().encode(user))
        
        let result = try JSONDecoder().decode(User.self, from: data.0)
        
        return result
    }
}
