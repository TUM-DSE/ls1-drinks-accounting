//
//  Overview.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 02.01.23.
//

import SwiftUI

struct Overview: View {
    @EnvironmentObject var model: Model
    
    @ObservedObject
    private var viewModel: OverviewViewModel
    
    @State private var selection: User?
    @State private var searchText: String = ""
    @State private var showingSheet = false
    @State private var path: [User] = []
    
    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    
    var people: [User] {
        if !searchText.isEmpty {
            return viewModel.people.filter { $0.name.contains(searchText) }
        } else {
            return viewModel.people
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(people, selection: $selection) { person in
                NavigationLink(value: person) {
                    Text(person.name)
                }
            }
            .refreshable(action: {
                await viewModel.loadUsers()
            })
            .searchable(text: $searchText)
            .toolbar {
                Button(action: { showingSheet = true }) {
                    Image(systemName: "pencil")
                }
            }
        } detail: {
            NavigationStack(path: $path) {
                if let selection {
                    SelectDrinkView(selection.id, model: model, onDismiss: { self.selection = nil })
                        .navigationTitle(selection.name)
                } else {
                    Text("Pick a person")
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadUsers()
            }
        }
        .sheet(isPresented: $showingSheet) {
            EditView()
        }
        .onChange(of: selection, perform: { _ in
            model.logoutUser()
            path = []
        })
        .onReceive(timer) { _ in
            Task {
                await viewModel.loadUsers()
            }
        }
    }
    
    init(_ model: Model) {
        self.viewModel = OverviewViewModel(model)
    }
}

struct Overview_Previews: PreviewProvider {
    static var previews: some View {
        Overview(Model.shared)
            .environmentObject(Model.shared)
            .previewDevice("iPad (10th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
