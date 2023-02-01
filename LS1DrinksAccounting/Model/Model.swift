//
//  Model.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 10.12.22.
//

import Foundation

@MainActor
class Model: ObservableObject {
    private let usersApi: UsersApi
    private let drinksApi: DrinksApi
    private let transactionsApi: TransactionsApi
    private let authApi: AuthApi
    private let authManager: AuthManager
    private let appConfigApi: AppConfigApi
    let apiBaseUrl: String
    
    private init(baseUrl: String) {
        self.apiBaseUrl = baseUrl
        
        let config = NetworkConfig(baseUrl: baseUrl, decoder: EncodingUtils.decoder, encoder: EncodingUtils.encoder)
        self.authManager = AuthManager(AuthApi(config))

        let networking = Networking(config, authManager)
        self.usersApi = UsersApi(networking)
        self.drinksApi = DrinksApi(networking)
        self.transactionsApi = TransactionsApi(networking)
        self.authApi = AuthApi(config)
        self.appConfigApi = AppConfigApi(networking)
    }
    
    static let shared = {
        let path = Bundle.main.path(forResource: "Info", ofType: "plist")!
        let dict = NSDictionary(contentsOfFile: path)!
        let baseUrl = dict["API_BASE_URL"] as? String ?? "http://localhost:8080"
        return Model(baseUrl: baseUrl)
    }()
    
    private let appVersion = {
        let path = Bundle.main.path(forResource: "Info", ofType: "plist")!
        let dict = NSDictionary(contentsOfFile: path)!
        return dict["APP_VERSION"] as? String
    }()
    
    @Published
    var people: [User] = []
    
    @Published
    var drinks: [Drink] = []
    
    @Published
    var isLoggedIn: Bool? = nil
    
    @Published
    var currentPin: String? = nil
    
    @Published
    var isLatestAppVersion = true
    
    func logoutUser() {
        currentPin = nil
    }
    
    func loadUsers() async throws {
        let users = try await usersApi.getUsers()
        
        people = users
    }
    
    func addUser(first_name: String, last_name: String, email: String) async throws {
        let result = try await usersApi.addUser(user: CreateUser(first_name: first_name, last_name: last_name, email: email))
        
        people.append(result)
    }
    
    func loadDrinks() async throws {
        self.drinks = try await drinksApi.getDrinks()
    }
    
    func addDrink(name: String, icon: String, price: Double) async throws {
        let drink = try await drinksApi.create(drink: CreateDrink(name: name, icon: icon, price: price))
        
        drinks.append(drink)
    }
    
    func updateDrink(id: UUID, name: String, icon: String, price: Double) async throws {
        let drink = try await drinksApi.update(drink: id, with: CreateDrink(name: name, icon: icon, price: price))
        
        drinks.removeAll(where: { $0.id == drink.id })
        drinks.append(drink)
    }
    
    func loadTransactions(for user: User) async throws -> [Transaction] {
        return try await usersApi.getTransactions(for: user.id)
    }
    
    func buy(drink: Drink, for user: User) async throws {
        let updatedUser = try await transactionsApi.buyDrink(user: user.id, drink: drink.id, userPin: currentPin)
        
        self.people.removeAll(where: { $0.id == user.id })
        self.people.append(updatedUser)
    }
    
    func checkPin(for user: User, pin: String) async throws -> Bool {
        let result = try await usersApi.checkPin(user: user.id, pin: pin)
        if result {
            self.currentPin = pin
        }
        return result
    }
    
    func updatePin(for user: User, pin: String) async throws -> Bool {
        let result = try await usersApi.updatePin(user: user.id, oldPin: self.currentPin, newPin: pin)
        if result {
            self.currentPin = pin
            try await loadUsers()
        }
        return result
    }
    
    func login(username: String, password: String) async throws -> Bool {
        KeychainHelper.shared.delete(service: "api-token", account: "ls1-drinks-api")
        KeychainHelper.shared.delete(service: "username", account: "ls1-drinks-api")
        KeychainHelper.shared.delete(service: "password", account: "ls1-drinks-api")
        let token = try await authApi.login(username: username, password: password)
        
        if token == nil {
            isLoggedIn = false
            return false
        }
        
        KeychainHelper.shared.save(token, service: "api-token", account: "ls1-drinks-api")
        KeychainHelper.shared.save(username, service: "username", account: "ls1-drinks-api")
        KeychainHelper.shared.save(password, service: "password", account: "ls1-drinks-api")
        isLoggedIn = true
        return true
    }
    
    func logout() {
        KeychainHelper.shared.delete(service: "api-token", account: "ls1-drinks-api")
        KeychainHelper.shared.delete(service: "username", account: "ls1-drinks-api")
        KeychainHelper.shared.delete(service: "password", account: "ls1-drinks-api")
        
        isLoggedIn = false
    }
    
    func hasValidToken() async throws -> Bool {
        do {
            _ = try await authManager.validToken()
            isLoggedIn = true
            return true
        } catch {
            if error is AuthError {
                isLoggedIn = false
                return false
            }

            isLoggedIn = nil
            throw error
        }
    }
    
    func checkIsLatestAppVersion() async {
        guard let appVersion else {
            return
        }
        
        if let isLatestAppVersion = try? await appConfigApi.isLatestAppVersion(version: appVersion) {
            self.isLatestAppVersion = isLatestAppVersion
        }
    }
}
