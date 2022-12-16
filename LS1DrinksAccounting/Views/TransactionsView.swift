//
//  TransactionsView.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import SwiftUI

struct TransactionsView: View {
    @ObservedObject
    private var viewModel: TransactionsViewModel
    
    var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"

        return formatter
    }()
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                List(viewModel.transactions) { transaction in
                    HStack {
                        Label(transaction.item.name, systemImage: transaction.item.icon)
                        Spacer()
                        Text(transaction.date, style: .date)
                        Text(formatter.string(from: NSNumber(value: transaction.price)) ?? "")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadTransactions()
            }
        }
    }
    
    init(model: Model, person: User) {
        viewModel = TransactionsViewModel(model, person: person)
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView(model: Model.shared, person: User(first_name: "Max", last_name: "Mustermann", email: "a@example.com", balance: -1.0))
    }
}
