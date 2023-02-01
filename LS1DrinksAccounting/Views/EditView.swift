//
//  EditView.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 11.12.22.
//

import SwiftUI

struct EditView: View {
    @EnvironmentObject var model: Model
    @Environment(\.dismiss) var dismiss
    
    enum SelectedTab: String, CaseIterable, Identifiable {
        case people
        case items
        
        var id: Self { self }
    }
    
    var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        
        return formatter
    }()
    
    @State var selectedTab: SelectedTab = .people
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Edit", selection: $selectedTab) {
                    Text("People").tag(SelectedTab.people)
                    Text("Drinks").tag(SelectedTab.items)
                }
                .pickerStyle(.segmented)
                
                if selectedTab == .people {
                    List {
                        ForEach(model.people) { person in
                            Label(person.name, systemImage: "person")
                        }
                        NavigationLink(destination: {
                            AddPersonView(model: model)
                        }, label: {
                            Label("Add person", systemImage: "plus")
                        })
                    }
                } else {
                    List {
                        ForEach(Array(model.drinks)) { drink in
                            NavigationLink(destination: {
                                EditDrinksView(drink, model: model)
                            }, label: {
                                HStack {
                                    Label(title: { Text(drink.name) }, icon: { Text(drink.icon) })
                                    Spacer()
                                    Text(formatter.string(from: NSNumber(value: drink.price)) ?? "n/a")
                                }
                            })
                        }
                        NavigationLink(destination: {
                            EditDrinksView(nil, model: model)
                        }, label: {
                            Label("Add drink", systemImage: "plus")
                        })
                    }
                }
            }
            .navigationBarTitle(Text("Edit"), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                dismiss()
            }) {
                Text("Done")
            })
        }
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView()
            .environmentObject(Model.shared)
            .previewDevice("iPad (10th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
