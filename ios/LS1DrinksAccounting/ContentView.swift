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
    
    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            if !model.isLatestAppVersion {
                VStack {
                    Text("New update available. Please click to update")
                        .padding(.bottom)
                }
                .onTapGesture {
                    UIApplication.shared.open(URL(string: "itms-services://?action=download-manifest&url=\(model.apiBaseUrl)/app/manifest.plist")!, options: [:], completionHandler: nil)
                }
                .frame(maxWidth: .infinity)
                .background(.blue.opacity(0.7))
            }
            if viewModel.isLoggedIn == nil {
                if let error = viewModel.error {
                    Text(error)
                        .padding(.bottom)
                    Button("Reload", action: { load() })
                } else {
                    ProgressView()
                }
            } else if viewModel.isLoggedIn == true {
                Overview(model)
            } else {
                LoginView(viewModel: viewModel)
            }
        }
        .onAppear { load() }
        .onReceive(timer) { _ in
            Task {
                await model.checkIsLatestAppVersion()
            }
        }
    }
    
    private func load() {
        Task {
            await viewModel.checkIsLoggedIn()
            await model.checkIsLatestAppVersion()
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
