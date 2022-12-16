//
//  TransactionsViewModel.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import Foundation

@MainActor
class TransactionsViewModel: ObservableObject {
    private let model: Model
    private let person: User
    
    init(_ model: Model, person: User) {
        self.model = model
        self.person = person
    }
    
    @Published var isLoading = false
    @Published var hasError = false
    @Published var transactions: [TransactionItem] = []
    
    func loadTransactions() async {
        isLoading = true
        hasError = false
        
        do {
            self.transactions = try await model.loadTransactions(for: person).sorted(by: { $0.date < $1.date })
        } catch {
            hasError = true
        }
        
        isLoading = false
    }
}
