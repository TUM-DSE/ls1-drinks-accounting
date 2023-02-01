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
    @State private var first_name = ""
    @State private var last_name = ""
    @State private var email = ""
    
    @ObservedObject
    private var viewModel: AddPersonViewModel
    
    var body: some View {
        Form {
            TextField("First name", text: $first_name)
            TextField("Last name", text: $last_name)
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
            if let error = viewModel.error {
                Text("Could not submit: \(error)")
            }
        }
        .disableAutocorrection(true)
        .onSubmit {
            submit()
        }
        .navigationBarTitle(Text("Add person"), displayMode: .inline)
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
        guard !viewModel.isLoading && !first_name.isEmpty && !last_name.isEmpty && !email.isEmpty else {
            return
        }
        Task {
            if await viewModel.createPerson(first_name: first_name, last_name: last_name, email: email) {
                dismiss()
            }
        }
    }
    
    init(model: Model) {
        self.viewModel = AddPersonViewModel(model)
    }
}

struct AddPersonView_Previews: PreviewProvider {
    static var previews: some View {
        AddPersonView(model: Model.shared)
    }
}
