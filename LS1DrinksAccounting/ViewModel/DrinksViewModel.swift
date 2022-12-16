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
    private let person: User
    
    init(_ model: Model, person: User) {
        self.model = model
        self.person = person
    }
    
    @Published var isLoading = false
    @Published var hasError = false
    @Published var hasErrorBuyingDrink = false
    @Published var loadingDrink: UUID? = nil
    
    var drinks: [Drink] {
        model.drinks.sorted(by: { $0.name < $1.name })
    }
    
    func loadDrinks() async {
        isLoading = true
        hasError = false
        
        do {
            try await model.loadDrinks()
        } catch {
            hasError = true
        }
        
        isLoading = false
    }
    
    func buy(drink: Drink) async -> Bool {
        await self.setBuyDrinkVars(false, drink.id)
        
        do {
            try await model.buy(drink: drink, for: person)
        } catch {
            await self.setBuyDrinkVars(true, nil)
        }
        
        await self.setBuyDrinkVars(self.hasErrorBuyingDrink, nil)
//        loadingDrink = nil
        return !hasErrorBuyingDrink
    }
    
    @MainActor
    private func setBuyDrinkVars(_ hasErrorBuyingDrink: Bool, _ loadingDrink: UUID?) {
        self.hasErrorBuyingDrink = hasErrorBuyingDrink
        self.loadingDrink = loadingDrink
    }
}
