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

struct CheckPin: Encodable {
    let user_pin: String
}

struct UpdatePin: Encodable {
    let old_pin: String?
    let new_pin: String?
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
        
        let result = try networking.config.decoder.decode([User].self, from: data.0)
        
        return result
    }

    func addUser(user: CreateUser) async throws -> User {
        guard let request = try await networking.post(path: "/api/users", authorized: true) else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await URLSession.shared.upload(for: request, from: try! networking.config.encoder.encode(user))
        
        let result = try networking.config.decoder.decode(User.self, from: data.0)
        
        return result
    }
    
    func getTransactions(for userId: UUID) async throws -> [Transaction] {
        guard let request = try await networking.get(path: "/api/users/\(userId)/transactions", authorized: true) else {
            throw NetworkError.invalidUrl
        }

        let data = try await URLSession.shared.data(for: request)
        
        let result = try networking.config.decoder.decode([Transaction].self, from: data.0)
        
        return result
    }
    
    func checkPin(user: UUID, pin: String) async throws -> Bool {
        guard let request = try await networking.post(path: "/api/users/\(user)/check_pin", authorized: true) else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await URLSession.shared.upload(for: request, from: networking.config.encoder.encode(CheckPin(user_pin: pin)))
        
        let result = try networking.config.decoder.decode(Bool.self, from: data.0)
        
        return result
    }
    
    func updatePin(user: UUID, oldPin: String?, newPin: String?) async throws -> Bool {
        guard let request = try await networking.put(path: "/api/users/\(user)/pin", authorized: true) else {
            throw NetworkError.invalidUrl
        }
        
        let data = try await URLSession.shared.upload(for: request, from: networking.config.encoder.encode(UpdatePin(old_pin: oldPin, new_pin: newPin)))
        
        let result = try networking.config.decoder.decode(Bool.self, from: data.0)
        
        return result
    }
}
