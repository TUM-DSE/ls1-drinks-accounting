//
//  AnimatableNumber.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 31.01.23.
//

import Foundation
import SwiftUI

struct AnimatableCurrencyModifier: AnimatableModifier {
    var number: Double

    var animatableData: CGFloat {
        get { CGFloat(number) }
        set { number = Double(newValue) }
    }
    
    var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        
        return formatter
    }()

    func body(content: Content) -> some View {
        Text("\(formatter.string(from: NSNumber(value: number)) ?? "n/a")")
    }
}
