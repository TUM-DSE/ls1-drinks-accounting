//
//  DrinksViewModel.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import Foundation

@MainActor
class DrinksViewModel: ObservableObject {
    
    private let model: Model
    private let userId: UUID
    
    init(_ model: Model, userId: UUID) {
        self.model = model
        self.userId = userId
    }
    
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var errorBuyingDrink: String? = nil
    @Published var loadingDrink: UUID? = nil

    var user: User? {
        model.people.first(where: { $0.id == userId })
    }
    
    var drinks: [Drink] {
        model.drinks.sorted(by: { $0.name < $1.name })
    }
    
    var shouldShowEnterPin: Bool {
        user?.has_pin == true && model.currentPin == nil
    }
    
    func loadDrinks() async {
        isLoading = true
        error = nil
        
        do {
            try await model.loadDrinks()
            try await model.loadUsers()
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func buy(drink: Drink) async -> Bool {
        guard let user else {
            self.errorBuyingDrink = "user not found"
            return false
        }
        
        self.errorBuyingDrink = nil
        self.loadingDrink = drink.id
        
        do {
            try await model.buy(drink: drink, for: user)
        } catch {
            self.errorBuyingDrink = error.localizedDescription
        }

        self.loadingDrink = nil

        return errorBuyingDrink == nil
    }
    
    func checkPin(pin: String) async -> Bool {
        guard let user else {
            return false
        }
        defer { self.isLoading = false }
        
        self.isLoading = true
        
        do {
            return try await model.checkPin(for: user, pin: pin)
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func setPin(pin: String) async -> Bool {
        guard let user else {
            return false
        }
//        defer { self.isLoadingPin }
        
//        self.isLoading = true
        
        do {
            return try await model.updatePin(for: user, pin: pin)
        } catch {
//            self.hasError = true
            return false
        }
    }
}
