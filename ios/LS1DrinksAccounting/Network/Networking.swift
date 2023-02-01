//
//  Networking.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 02.01.23.
//

import Foundation

class Networking {
    let config: NetworkConfig
    let authManager: AuthManager
    
    init(_ config: NetworkConfig, _ authManager: AuthManager) {
        self.config = config
        self.authManager = authManager
    }
    
    func get(path: String, authorized: Bool) async throws -> URLRequest? {
        return try await self.request(path: path, authorized: authorized)
    }
    
    func post(path: String, authorized: Bool) async throws -> URLRequest? {
        guard var request = try await self.request(path: path, authorized: authorized) else {
            return nil
        }
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]

        return request
    }
    
    func put(path: String, authorized: Bool) async throws -> URLRequest? {
        guard var request = try await self.request(path: path, authorized: authorized) else {
            return nil
        }
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]

        return request
    }
    
    private func request(path: String, authorized: Bool) async throws -> URLRequest? {
        guard let url = URL(string: "\(config.baseUrl)\(path)") else {
            return nil
        }
        var urlRequest = URLRequest(url: url)
        if authorized {
            let token = try await authManager.validToken()
            urlRequest.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        }
        return urlRequest
    }
}
