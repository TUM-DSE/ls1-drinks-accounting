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
    private var viewModel: OverviewViewModel
    
    @State private var selection: Person?
    @State private var searchText: String = ""
    @State private var showingSheet = false
    
    var people: [Person] {
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
            if let selection {
                NavigationStack {
                    SelectDrinkView(selection, model: model, onDismiss: { self.selection = nil })
                        .navigationTitle(selection.name)
                }
            } else {
                Text("Pick a person")
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
    }
    
    init(_ model: Model) {
        self.viewModel = OverviewViewModel(model)
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
