//
//  Model.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 10.12.22.
//

import Foundation

class Model: ObservableObject {
    private init() {}
    
    static let shared = Model()
    
    @Published
    var people: [Person] = []
    
    @Published
    var drinks: Set<Item> = []
    
    func loadUsers() async throws {
        try await Task.sleep(for: Duration(secondsComponent: 1, attosecondsComponent: 0))
        
        people = [
            Person(name: "Martin Fink", email: "Martin.Fink@in.tum.de", balance: -1.4),
            Person(name: "Max Mustermann", email: "max.muster@in.tum.de", balance: 12.5),
            Person(name: "John Doe", email: "john.doe@in.tum.de", balance: 10.0),
        ]
    }
    
    func addUser(name: String, email: String) async throws {
        try await Task.sleep(for: Duration(secondsComponent: 1, attosecondsComponent: 0))
        
        people.append(Person(name: name, email: email))
    }
    
    func loadDrinks() async throws {
        //        try await Task.sleep(for: Duration(secondsComponent: 1, attosecondsComponent: 0))
        
        drinks = [
            Item(name: "Coffee", price: 0.5, icon: "cup.and.saucer"),
            Item(name: "Coffee with milk", price: 0.7, icon: "mug"),
            Item(name: "Spezi", price: 1.5, icon: "mug"),
            Item(name: "Coffee2", price: 0.5, icon: "cup.and.saucer"),
            Item(name: "Coffee with milk2", price: 0.7, icon: "mug"),
            Item(name: "Spezi2", price: 1.5, icon: "mug"),
            Item(name: "Coffee3", price: 0.5, icon: "cup.and.saucer"),
            Item(name: "Coffee with milk3", price: 0.7, icon: "mug"),
            Item(name: "Spezi3", price: 1.5, icon: "mug"),
        ]
    }
    
    func addDrink(name: String, price: Double) async throws {
        try await Task.sleep(for: Duration(secondsComponent: 1, attosecondsComponent: 0))
        
        drinks.insert(Item(name: name, price: price, icon: "cup.and.saucer"))
    }
    
    func updateDrink(_ drink: Item) async throws {
        try await Task.sleep(for: Duration(secondsComponent: 1, attosecondsComponent: 0))
        
        drinks.insert(drink)
    }
    
    func loadTransactions(for person: Person) async throws -> [TransactionItem] {
        try await Task.sleep(for: Duration(secondsComponent: 1, attosecondsComponent: 0))
        
        return [
            TransactionItem(id: UUID(), date: Date(), item: Item(name: "Coffee", price: 0.5, icon: "cup.and.saucer"), price: 0.5),
            TransactionItem(id: UUID(), date: Date(), item: Item(name: "Coffee", price: 0.5, icon: "cup.and.saucer"), price: 0.7),
        ]
    }
    
    func buy(drink: Item, for: Person) async throws {
        try await Task.sleep(for: Duration(secondsComponent: 1, attosecondsComponent: 0))
        
        // TODO
    }
}
