//
//  AuthManager.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 02.01.23.
//

import Foundation

enum AuthError: Error {
    case missingToken
    case missingCredentials
}

actor AuthManager {
    private var currentToken: AuthToken? {
        KeychainHelper.shared.read(service: "api-token", account: "ls1-drinks-api", type: AuthToken.self)
    }
    private var refreshTask: Task<AuthToken, Error>?
    private let authApi: AuthApi
    
    init(_ authApi: AuthApi) {
        self.authApi = authApi
    }

    func validToken() async throws -> AuthToken {
        if let handle = refreshTask {
            return try await handle.value
        }

        guard let token = currentToken else {
            throw AuthError.missingToken
        }

        if token.isValid {
            return token
        }

        return try await refreshToken()
    }

    func refreshToken() async throws -> AuthToken {
        if let refreshTask = refreshTask {
            return try await refreshTask.value
        }

        let task = Task { () throws -> AuthToken in
            defer { refreshTask = nil }

            let username = KeychainHelper.shared.read(service: "username", account: "ls1-drinks-api", type: String.self)
            let password = KeychainHelper.shared.read(service: "password", account: "ls1-drinks-api", type: String.self)
            
            guard let username, let password else {
                throw AuthError.missingCredentials
            }
            
            let newToken = try await authApi.login(username: username, password: password)
            
            KeychainHelper.shared.save(newToken, service: "api-token", account: "ls1-drinks-api")
            
            guard let newToken else {
                throw AuthError.missingCredentials
            }

            return newToken
        }

        self.refreshTask = task

        return try await task.value
    }
}
