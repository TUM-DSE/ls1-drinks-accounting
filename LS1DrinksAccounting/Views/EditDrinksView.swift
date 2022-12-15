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
    @State private var hadError = false
    
    private var drink: Item?
    
    
    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Price", text: $price)
                .keyboardType(.numbersAndPunctuation)
        }
        .alert(isPresented: $malformedPrice) {
            Alert(title: Text("Error"), message: Text("Price is not a number"), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $hadError) {
            Alert(title: Text("Error"), message: Text("Could not add/update drink"), dismissButton: .default(Text("OK")))
        }
        .disableAutocorrection(true)
        .onSubmit {
            submit()
        }
        .navigationBarTitle(Text(drink == nil ? "Add drink" : "Edit drink"), displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            submit()
        }) {
            Text("Done")
        })
    }
    
    private func submit() {
        guard let price = Double(price.trimmingCharacters(in: .whitespaces)) else {
            malformedPrice = true
            return
        }
        
        if var drink {
            drink.name = name
            drink.price = price
            Task {
                do {
                    try await model.updateDrink(drink)
                    dismiss()
                } catch {
                    hadError = true
                }
            }
        } else {
            Task {
                do {
                    try await model.addDrink(name: name, price: price)
                    dismiss()
                } catch {
                    hadError = true
                }
            }
            
        }
    }
    
    init(_ drink: Item?) {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        self.drink = drink
        if let drink {
            self._name = State(initialValue: drink.name)
            self._price = State(initialValue: formatter.string(from: NSNumber(value: drink.price)) ?? "")
        }
    }
}

struct EditDrinksView_Previews: PreviewProvider {
    static var previews: some View {
        EditDrinksView(nil)
    }
}
