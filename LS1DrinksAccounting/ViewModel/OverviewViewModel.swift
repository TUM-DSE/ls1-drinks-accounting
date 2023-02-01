//
//  OverviewViewModel.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import Foundation

@MainActor
class OverviewViewModel: ObservableObject {
    
    private let model: Model
    
    
    init(_ model: Model) {
        self.model = model
    }
    
    @Published var isLoading = false
    @Published var hasError = false
    
    var people: [User] {
        model.people.sorted(by: { $0.name < $1.name })
    }
    
    func loadUsers() async {
        isLoading = true
        hasError = false
        
        do {
            try await model.loadUsers()
            try await model.loadDrinks()
        } catch {
            hasError = true
        }
        
        isLoading = false
    }
}
