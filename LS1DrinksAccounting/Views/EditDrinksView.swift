//
//  EditDrinksView.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import SwiftUI

struct EditDrinksView: View {
    @EnvironmentObject var model: Model
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var price: String = ""
    
    @State private var malformedPrice = false
    
    private var drink: Drink?
    
    @ObservedObject
    private var viewModel: EditDrinksViewModel
    
    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Price", text: $price)
                .keyboardType(.numbersAndPunctuation)
            if let error = viewModel.error {
                Text("Could not submit: \(error)")
            }
        }
        .alert(isPresented: $malformedPrice) {
            Alert(title: Text("Error"), message: Text("Price is not a number"), dismissButton: .default(Text("OK")))
        }
        .disableAutocorrection(true)
        .onSubmit {
            submit()
        }
        .navigationBarTitle(Text(drink == nil ? "Add drink" : "Edit drink"), displayMode: .inline)
        .navigationBarItems(trailing: HStack {
            if viewModel.isLoading {
                ProgressView()
            }
            Button(action: {
                submit()
            }) {
                Text("Submit")
            }.disabled(viewModel.isLoading)
        })
        .onAppear {
            viewModel.error = nil
        }
    }
    
    private func submit() {
        guard !viewModel.isLoading && !name.isEmpty else {
            return
        }
        guard let price = Double(price.trimmingCharacters(in: .whitespaces)) else {
            malformedPrice = true
            return
        }
        
        
        Task {
            if await viewModel.createDrink(name: name, icon: "cup.and.saucer", price: price) {
                dismiss()
            }
        }
    }
    
    init(_ drink: Drink?, model: Model) {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        self.drink = drink
        if let drink {
            self._name = State(initialValue: drink.name)
            self._price = State(initialValue: formatter.string(from: NSNumber(value: drink.price)) ?? "")
        }
        
        self.viewModel = EditDrinksViewModel(model, existingDrinkId: drink?.id)
    }
}

struct EditDrinksView_Previews: PreviewProvider {
    static var previews: some View {
        EditDrinksView(nil, model: Model.shared)
    }
}
