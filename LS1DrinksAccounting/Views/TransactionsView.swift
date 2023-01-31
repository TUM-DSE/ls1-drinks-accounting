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
    
    var transactionGroupedByDate: [Date: [Transaction]] {
        Dictionary(grouping: viewModel.transactions, by: { Calendar.current.startOfDay(for: $0.timestamp) })
    }
    
    var headers: [Date] {
        transactionGroupedByDate.map { $0.key }.sorted().reversed()
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(headers, id: \.self) { date in
                        Section(header: sectionHeader(for: date)) {
                            section(for: date)
                        }
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
    
    func sectionHeader(for date: Date) -> some View {
        Group {
            if Calendar.current.startOfDay(for: date) == Calendar.current.startOfDay(for: Date()) {
                Text("today")
            } else {
                Text(date, style: .date)
            }
        }
    }
    
    func section(for date: Date) -> some View {
        ForEach(transactionGroupedByDate[date]!) { transaction in
            item(for: transaction)
        }
    }
    
    func item(for transaction: Transaction) -> some View {
        HStack {
            if case .moneyDeposit = transaction.transactionType {
                Label("Deposit", systemImage: "eurosign.circle")
            }
            if case let .purchase(transactionData) = transaction.transactionType {
                Label(title: { Text(transactionData.purchase.name) }, icon: { Text(transactionData.purchase.icon) })
            }
            Text(formatter.string(from: NSNumber(value: transaction.amount)) ?? "")
            Spacer()
            Text(transaction.timestamp, style: .time)
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
