//
//  LoginView.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 30.12.22.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject
    private var viewModel: LoginViewModel
    
    @State private var username: String = ""
    @State private var password: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Username", text: $username)
                    .autocorrectionDisabled()
                SecureField("Password", text: $password)
                if let error = viewModel.error {
                    Text("Error logging in: \(error)")
                        .foregroundColor(Color(UIColor.secondaryLabel))
                }
                HStack {
                    Button("Login") {
                        Task {
                            await viewModel.login(username: username, password: password)
                        }
                    }
                    if viewModel.loading {
                        ProgressView().padding(.leading, 16)
                    }
                }
                .disabled(viewModel.loading)
            }
            .navigationTitle("Login")
            
        }
    }
    
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: LoginViewModel(Model.shared))
            .environmentObject(Model.shared)
            .previewDevice("iPad (10th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
