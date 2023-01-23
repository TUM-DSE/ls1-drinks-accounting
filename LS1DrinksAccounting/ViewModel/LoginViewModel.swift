//
//  LoginViewModel.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 30.12.22.
//

import Foundation

@MainActor
class LoginViewModel: ObservableObject {
    
    @Published var loading = false
    @Published var error: String? = nil
    private let model: Model
    
    var isLoggedIn: Bool? {
        model.isLoggedIn
    }
    
    init(_ model: Model) {
        self.model = model
    }
    
    func login(username: String, password: String) async -> Bool {
        defer {
            loading = false
        }
        loading = true
        error = nil
        
        do {
            let result = try await model.login(username: username, password: password)
            if !result {
                error = "Incorrect username/password"
            }
//            self.isLoggedIn = result
            return result
        } catch {
            self.error = error.localizedDescription
        }
        
        return false
    }
    
    func checkIsLoggedIn() async {
        error = nil
        do {
            let _ = try await model.hasValidToken()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
