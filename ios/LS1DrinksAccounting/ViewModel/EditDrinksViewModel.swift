//
//  EditDrinksViewModel.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 16.12.22.
//

import Foundation

@MainActor
class EditDrinksViewModel: ObservableObject {
    
    private let model: Model
    private let existingDrinkId: UUID?
    
    @Published var isLoading = false
    @Published var error: String?

    init(_ model: Model, existingDrinkId: UUID?) {
        self.model = model
        self.existingDrinkId = existingDrinkId
    }
    
    func createDrink(name: String, icon: String, price: Double) async -> Bool {
        self.isLoading = true
        self.error = nil

        do {
            if let existingDrinkId {
                try await model.updateDrink(id: existingDrinkId, name: name, icon: icon, price: price)
            } else {
                try await model.addDrink(name: name, icon: icon, price: price)
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        self.isLoading = false
        
        return self.error == nil
    }
}
