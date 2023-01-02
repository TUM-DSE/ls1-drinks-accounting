//
//  ContentView.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 10.12.22.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: Model
    
    @ObservedObject
    private var viewModel: LoginViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoggedIn == nil {
                ProgressView()
            } else if viewModel.isLoggedIn == true {
                Overview(model)
            } else {
                LoginView(viewModel: viewModel)
            }
        }
        .onAppear {
            Task {
                await viewModel.checkIsLoggedIn()
            }
        }
    }
    
    init(_ model: Model) {
        self.viewModel = LoginViewModel(model)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(Model.shared)
            .environmentObject(Model.shared)
            .previewDevice("iPad (10th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
