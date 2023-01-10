//
//  TransactionItem.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import Foundation

// MARK: - Transaction
struct Transaction: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let amount: Double
    let transactionType: TransactionTypeUnion

    enum CodingKeys: String, CodingKey {
        case id, timestamp, amount
        case transactionType = "transaction_type"
    }
}

enum TransactionTypeUnion: Codable {
    case moneyDeposit
    case purchase(TransactionTypeClass)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(String.self), x == "MoneyDeposit" {
            self = .moneyDeposit
            return
        }
        if let x = try? container.decode(TransactionTypeClass.self) {
            self = .purchase(x)
            return
        }
        throw DecodingError.typeMismatch(TransactionTypeUnion.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for TransactionTypeUnion"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .moneyDeposit:
            break
        case .purchase(let x):
            try container.encode(x)
        }
    }
}

// MARK: - TransactionTypeClass
struct TransactionTypeClass: Codable {
    let purchase: Purchase

    enum CodingKeys: String, CodingKey {
        case purchase = "Purchase"
    }
}

// MARK: - Purchase
struct Purchase: Codable {
    let icon, name: String
}
