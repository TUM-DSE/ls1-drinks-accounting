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
    private let pageSize = 100
    
    init(_ model: Model, person: User) {
        self.model = model
        self.person = person
    }
    
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasError = false
    @Published var hasMore = true
    @Published var transactions: [Transaction] = []
    
    func loadTransactions() async {
        isLoading = true
        hasError = false
        hasMore = true
        transactions = []
        
        do {
            let items = try await model.loadTransactions(for: person, limit: pageSize)
            self.transactions = items
            self.hasMore = items.count == pageSize
        } catch {
            hasError = true
        }
        
        isLoading = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore, !isLoading else {
            return
        }
        guard let last = transactions.last else {
            return
        }

        isLoadingMore = true

        do {
            let items = try await model.loadTransactions(for: person, limit: pageSize, before: last)
            self.transactions.append(contentsOf: items)
            self.hasMore = items.count == pageSize
        } catch {
            hasError = true
        }

        isLoadingMore = false
    }
}
