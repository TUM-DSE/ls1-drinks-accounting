//
//  Item.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 11.12.22.
//

import Foundation

struct Drink: Identifiable, Hashable, Equatable, Codable {
    let id: UUID
    var name: String
    var price: Double
    var icon: String
    
    init(name: String, price: Double, icon: String) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.icon = icon
    }
}
