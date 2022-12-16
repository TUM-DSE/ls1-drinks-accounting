//
//  SelectDrinkView.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import SwiftUI

struct SelectDrinkView: View {
    @EnvironmentObject var model: Model
    private let viewModel: DrinksViewModel
    
    var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        
        return formatter
    }()
    
    let onDismiss: () -> Void
    let person: User
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        ZStack {
            List {
                Section("Drinks") {
                    ZStack {
                        if viewModel.isLoading {
                            ProgressView()
                        }
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(viewModel.drinks) { item in
                                VStack {
                                    Image(systemName: item.icon).font(.title2)
                                    Text(item.name)
                                        .font(.title2)
                                        .padding(.bottom)
                                    Text(formatter.string(from: NSNumber(value: item.price)) ?? "n/a")
                                }
                                .padding(.vertical, 25)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .overlay(ZStack {
                                    if viewModel.loadingDrink == item.id {
                                        BlurView()
                                        ProgressView()
                                    }
                                })
                                .background(Color(UIColor.tertiarySystemFill))
                                .cornerRadius(10)
                                .onTapGesture {
                                    Task {
                                        if await viewModel.buy(drink: item) {
                                            onDismiss()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section("Balance") {
                    Text(viewModel.loadingDrink?.uuidString ?? "n/a")
                    NavigationLink(destination: {
                        TransactionsView(model: model, person: person)
                    }, label: {
                        HStack {
                            Text("Current balance")
                            Spacer()
                            Text(formatter.string(from: NSNumber(value: person.balance)) ?? "")
                        }
                    })
                }
            }
            .refreshable {
                await viewModel.loadDrinks()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadDrinks()
            }
        }
        
    }
    
    init(_ person: User, model: Model, onDismiss: @escaping () -> Void) {
        self.viewModel = DrinksViewModel(model, person: person)
        self.person = person
        self.onDismiss = onDismiss
    }
}

struct SelectDrinkView_Previews: PreviewProvider {
    static var previews: some View {
        SelectDrinkView(User(first_name: "Max", last_name: "Mustermann", email: "email@example.com", balance: 12.3), model: Model.shared, onDismiss: {})
            .environmentObject(Model.shared)
            .previewDevice("iPad (10th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
