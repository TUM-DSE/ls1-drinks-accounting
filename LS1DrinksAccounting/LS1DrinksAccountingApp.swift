//
//  LS1DrinksAccountingApp.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 10.12.22.
//

import SwiftUI

@main
struct LS1DrinksAccountingApp: App {
    let model = Model.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView(model)
                .environmentObject(model)
        }
    }
}
