//
//  Person.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 10.12.22.
//

import Foundation

struct Person: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let email: String
    let balance: Double
    
    init(name: String, email: String, balance: Double) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.balance = balance
    }

    init(name: String, email: String) {
        self.init(name: name, email: email, balance: 0)
    }
}
