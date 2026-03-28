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
        ZStack {
            LiquidGlassBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Add person")
                        .font(.title2.bold())

                    TextField("First name", text: $first_name)
                        .liquidGlassField()
                    TextField("Last name", text: $last_name)
                        .liquidGlassField()
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .liquidGlassField()

                    if let error = viewModel.error {
                        Text("Could not submit: \(error)")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button(action: {
                        submit()
                    }) {
                        HStack {
                            Spacer()
                            Text(viewModel.isLoading ? "Submitting..." : "Submit")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(LiquidGlassButtonStyle(tint: .blue))
                    .disabled(viewModel.isLoading || first_name.isEmpty || last_name.isEmpty || email.isEmpty)
                }
                .liquidGlassCard(cornerRadius: 28, padding: 24)
                .frame(maxWidth: 520)
                .padding(24)
            }
        }
        .disableAutocorrection(true)
        .onSubmit {
            submit()
        }
        .navigationTitle("Add person")
        .navigationBarTitleDisplayMode(.inline)
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
