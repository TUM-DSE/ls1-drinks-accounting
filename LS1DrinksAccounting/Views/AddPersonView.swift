//
//  AddPersonView.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import SwiftUI

struct AddPersonView: View {
    @EnvironmentObject var model: Model
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    
    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
        }
        .disableAutocorrection(true)
        .onSubmit {
            submit()
        }
        .navigationBarTitle(Text("Add person"), displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            submit()
        }) {
            Text("Done")
        })
    }
    
    private func submit() {
        model.people.append(Person(name: name, email: email))
        dismiss()
    }
}

struct AddPersonView_Previews: PreviewProvider {
    static var previews: some View {
        AddPersonView()
    }
}
