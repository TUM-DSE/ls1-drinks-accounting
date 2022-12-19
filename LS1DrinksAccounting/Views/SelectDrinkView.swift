//
//  SelectDrinkView.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import SwiftUI

struct SelectDrinkView: View {
    @EnvironmentObject var model: Model
    
    @ObservedObject
    private var viewModel: DrinksViewModel
    
    var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        
        return formatter
    }()
    
    let onDismiss: () -> Void
    
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
                                        BlurView().opacity(0.7)
                                        ProgressView()
                                    }
                                })
                                .background(Color(UIColor.tertiarySystemFill))
                                .cornerRadius(10)
                                .onTapGesture {
                                    if viewModel.isLoading || viewModel.loadingDrink != nil {
                                        return
                                    }

                                    Task {
                                        if await viewModel.buy(drink: item) {
//                                            onDismiss()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                if let user = viewModel.user {
                    Section("Balance") {
                        NavigationLink(destination: {
                            TransactionsView(model: model, person: user)
                        }, label: {
                            HStack {
                                Text("Current balance")
                                Spacer()
                                Text(formatter.string(from: NSNumber(value: user.balance)) ?? "")
                                    
                            }
                        })
                    }
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
    
    init(_ userId: UUID, model: Model, onDismiss: @escaping () -> Void) {
        self.viewModel = DrinksViewModel(model, userId: userId)
        self.onDismiss = onDismiss
    }
}

struct SelectDrinkView_Previews: PreviewProvider {
    static var previews: some View {
        SelectDrinkView(UUID(), model: Model.shared, onDismiss: {})
            .environmentObject(Model.shared)
            .previewDevice("iPad (10th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
