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
    
    private init() {
        let config = NetworkConfig()
        self.usersApi = UsersApi(config)
        self.drinksApi = DrinksApi(config)
        self.transactionsApi = TransactionsApi(config)
    }
    
    static let shared = Model()
    
    @Published
    var people: [User] = []
    
    @Published
    var drinks: [Drink] = []
    
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
    
    func loadTransactions(for person: User) async throws -> [TransactionItem] {
        try await Task.sleep(for: Duration(secondsComponent: 1, attosecondsComponent: 0))
        
        return [
            TransactionItem(id: UUID(), date: Date(), item: Drink(name: "Coffee", price: 0.5, icon: "cup.and.saucer"), price: 0.5),
            TransactionItem(id: UUID(), date: Date(), item: Drink(name: "Coffee", price: 0.5, icon: "cup.and.saucer"), price: 0.7),
        ]
    }
    
    func buy(drink: Drink, for user: User) async throws {
        let updatedUser = try await transactionsApi.buyDrink(user: user.id, drink: drink.id)
        
        self.people.removeAll(where: { $0.id == user.id })
        self.people.append(updatedUser)
    }
}
