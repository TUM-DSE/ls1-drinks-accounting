//
//  PasscodeField.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.01.23.
//

import SwiftUI
import Combine

struct PinEntryButton: View {
    let title: any View
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            AnyView(title)
                .font(.title)
                .foregroundColor(Color(UIColor.label))
                .frame(width: 60, height: 60)
                .background(Color(UIColor.secondarySystemFill))
                .cornerRadius(30)
//                .shadow(color: .gray, radius: 3, x: 0, y: 2)
        }
    }
}

struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}


public struct PasscodeField: View {
    
    var maxDigits: Int = 4
    
    @State var pin: String = ""
    var showPin = false
    @State var isDisabled = false
    
    @FocusState private var isFocused: Bool
    
    var handler: (String, @escaping (Bool) -> Void) -> Void
    
    public var body: some View {
        VStack(spacing: 40) {
            pinDots
            buttons
        }
    }
    
    private var buttons: some View {
        VStack(spacing: 20) {
            ForEach(0...2, id: \.self) { row in
                HStack(spacing: 20) {
                    ForEach(1...3, id: \.self) { col in
                        let number = row * 3 + col
                        PinEntryButton(title: Text("\(number)")) {
                            appendToPin(number)
                        }
                    }
                }
            }
            HStack(spacing: 20) {
                PinEntryButton(title: Text("")) {
                }
                .opacity(0)
                PinEntryButton(title: Text("0")) {
                    appendToPin(0)
                }
                PinEntryButton(title: Image(systemName: "delete.backward")) {
                    deleteFromPin()
                }
            }
        }
    }
    
    private func appendToPin(_ digit: Int) {
        if pin.count < maxDigits {
            withAnimation(.linear(duration: 0.2)) {
                pin.append("\(digit)")
            }
        }
        submitPin()
    }
    
    private func deleteFromPin() {
        if !pin.isEmpty {
            withAnimation(.linear(duration: 0.2)) {
                pin.removeLast()
            }
        }
    }
    
    @State var attempts: Int = 0
    
    private var pinDots: some View {
        HStack(spacing: 20) {
            ForEach(0..<maxDigits) { index in
                Image(systemName: self.getImageName(at: index))
                    .font(.largeTitle)
            }
        }
        .modifier(Shake(animatableData: CGFloat(attempts)))
    }
    
    private func submitPin() {
        guard !pin.isEmpty else {
            return
        }
        
        if pin.count == maxDigits {
            isDisabled = true
            
            handler(pin) { isSuccess in
                if !isSuccess {
                    withAnimation {
                        pin = ""
                        attempts += 1
                    }
                    isDisabled = false
                }
            }
        }
        
        // this code is never reached under  normal circumstances. If the user pastes a text with count higher than the
        // max digits, we remove the additional characters and make a recursive call.
        if pin.count > maxDigits {
            pin = String(pin.prefix(maxDigits))
            submitPin()
        }
    }
    
    private func getImageName(at index: Int) -> String {
        if index >= self.pin.count {
            return "circle"
        }
        
        if self.showPin {
            return self.pin.digits[index].numberString + ".circle"
        }
        
        return "circle.fill"
    }
}

struct PasscodeField_Previews: PreviewProvider {
    static var previews: some View {
        PasscodeField(handler: { s, b in
            
        })
    }
}


extension String {
    
    var digits: [Int] {
        var result = [Int]()
        
        for char in self {
            if let number = Int(String(char)) {
                result.append(number)
            } else {
                result.append(0)
            }
        }
        
        return result
    }
    
}

extension Int {
    
    var numberString: String {
        
        guard self < 10 else { return "0" }
        
        return String(self)
    }
}
