//
//  User.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 10.12.22.
//

import Foundation

struct User: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let first_name: String
    let last_name: String
    let email: String
    let balance: Double
    let has_pin: Bool
    
    var name: String {
        "\(last_name), \(first_name)"
    }
    
    init(first_name: String, last_name: String, email: String, balance: Double) {
        self.id = UUID()
        self.first_name = first_name
        self.last_name = last_name
        self.email = email
        self.balance = balance
        self.has_pin = false
    }

    init(first_name: String, last_name: String, email: String) {
        self.init(first_name: first_name, last_name: last_name, email: email, balance: 0)
    }
}
