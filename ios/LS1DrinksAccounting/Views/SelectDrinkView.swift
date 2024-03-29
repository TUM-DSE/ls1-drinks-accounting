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
    
    @State
    private var showingChangePasswordDialog = false
    
    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    
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
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                Text("Error loading items: \(error)")
            } else if let user = viewModel.user {
                if viewModel.shouldShowEnterPin {
                    VStack(spacing: 40) {
                        Text("Enter passcode")
                            .font(.title)
                        ZStack {
                            PasscodeField(handler: { pin, handler in
                                Task {
                                    let result = await viewModel.checkPin(pin: pin)
                                    handler(result)
                                }
                            })
                            if viewModel.showPinLoading {
                                ProgressView()
                                    .frame(width: 120, height: 120)
                                    .background(BlurView().cornerRadius(16))
                            }
                        }
                        .frame(maxWidth: 400)
                    }
                } else {
                    List {
                        Section("Drinks") {
                            if let error = viewModel.errorBuyingDrink {
                                Text("Error selecting drink: \(error)")
                            }
                            ZStack {
                                grid
                            }
                        }
                        
                        Section("Balance") {
                            NavigationLink(destination: {
                                TransactionsView(model: model, person: user)
                            }, label: {
                                HStack {
                                    Text("Current balance")
                                    Spacer()
                                    Text(formatter.string(from: NSNumber(value: user.balance)) ?? "")
                                        .animation(nil)
                                        .modifier(AnimatableCurrencyModifier(number: user.balance))
                                        .foregroundColor(user.balance < 0 ? Color.red : nil)
                                        .animation(.linear, value: user.balance)
                                }
                            })
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable {
                        await viewModel.loadDrinks()
                    }
                    .toolbar {
                        if viewModel.shouldShowEnterPin {
                            Group {}
                        } else {
                            HStack {
                                if viewModel.user?.has_pin == true {
                                    Button(action: { model.logoutUser() }) {
                                        Label("Lock", systemImage: "lock.fill")
                                            .labelStyle(.titleAndIcon)
                                    }
                                }
                                Button(action: { showingChangePasswordDialog = true }) {
                                    Label("Set pin", systemImage: "rectangle.and.pencil.and.ellipsis")
                                        .labelStyle(.titleAndIcon)
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $showingChangePasswordDialog, content: {
                        NavigationStack {
                            PasscodeField(showPin: true, handler: { pin, _ in
                                Task {
                                    let _ = await viewModel.setPin(pin: pin)
                                    showingChangePasswordDialog = false
                                }
                            })
                            .navigationTitle("Set passcode for user")
                            .frame(maxWidth: 400)
                        }
                    })
                }
            } else {
                Text("Error")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .onAppear {
            Task {
                await viewModel.loadDrinks()
            }
        }
        .onReceive(timer) { _ in
            Task {
                await viewModel.loadDrinks()
            }
        }
    }
    
    var grid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(viewModel.drinks) { item in
                DrinkItemView(item: item, viewModel: viewModel, formatter: formatter)
            }
        }
    }
    
    init(_ userId: UUID, model: Model, onDismiss: @escaping () -> Void) {
        self.viewModel = DrinksViewModel(model, userId: userId)
        self.onDismiss = onDismiss
    }
}

struct DrinkItemView: View {
    let item: Drink
    let viewModel: DrinksViewModel
    let formatter: NumberFormatter
    
    @State
    private var showingBuyConfirmation = false
    @State
    private var animateSuccess = false
    
    var body: some View {
        ZStack {
            VStack {
                Text(item.icon).font(.title2)
                Text(item.name)
                    .font(.title2)
                    .padding(.bottom)
                Text(formatter.string(from: NSNumber(value: item.price)) ?? "n/a")
            }
        }
        .confirmationDialog("Buy item", isPresented: $showingBuyConfirmation, actions: {
            Button("Buy \(item.name)", action: {
                Task {
                    animateSuccess = false
                    if await viewModel.buy(drink: item) {
                        withAnimation {
                            animateSuccess = true
                        }
                        try? await Task.sleep(for: Duration(secondsComponent: 3, attosecondsComponent: 0))
                        withAnimation {
                            animateSuccess = false
                        }
                    }
                }
            })
        })
        .padding(.vertical, 25)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(ZStack {
            if viewModel.loadingDrink == item.id {
                BlurView().opacity(0.7)
                ProgressView()
            }
            if animateSuccess {
                ZStack {
                    BlurView()
                        .background(.green.opacity(0.6))

                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.white)
                        .font(.system(size: 80))
                }
                .transition(.slide)
            }
        })
        .background(Color(UIColor.tertiarySystemFill))
        .cornerRadius(10)
        .onTapGesture {
            if viewModel.isLoading || viewModel.loadingDrink != nil {
                return
            }
            
            showingBuyConfirmation = true
        }
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
