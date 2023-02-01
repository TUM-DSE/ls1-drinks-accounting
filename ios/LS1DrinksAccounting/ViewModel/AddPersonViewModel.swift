//
//  AddPersonViewModel.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 16.12.22.
//

import Foundation

@MainActor
class AddPersonViewModel: ObservableObject {
    
    private let model: Model
    
    @Published var isLoading = false
    @Published var error: String?

    init(_ model: Model) {
        self.model = model
    }
    
    func createPerson(first_name: String, last_name: String, email: String) async -> Bool {
        self.isLoading = true
        self.error = nil

        do {
            try await model.addUser(first_name: first_name, last_name: last_name, email: email)
        } catch {
            self.error = error.localizedDescription
        }
        
        self.isLoading = false
        
        return self.error == nil
    }
}
