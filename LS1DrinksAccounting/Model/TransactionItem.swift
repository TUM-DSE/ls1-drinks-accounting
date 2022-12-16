//
//  TransactionItem.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import Foundation

struct TransactionItem: Identifiable {
    let id: UUID
    let date: Date
    let item: Drink
    let price: Double
}
