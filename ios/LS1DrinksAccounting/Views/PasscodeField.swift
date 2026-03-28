//
//  PasscodeField.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.01.23.
//

import SwiftUI
import Combine

struct PinEntryButton: View {
    let title: AnyView
    let isPlaceholder: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            title
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 78, height: 78)
        }
        .glassEffect(.regular.interactive())
        .opacity(isPlaceholder ? 0 : 1)
        .disabled(isPlaceholder)
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

    var handler: (String, @escaping (Bool) -> Void) -> Void
    
    public var body: some View {
        VStack(spacing: 28) {
            pinHeader
            pinDots
            buttons
        }
    }

    private var pinHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.primary.opacity(0.82))

            Text(showPin ? "Set your passcode" : "Enter your passcode")
                .font(.title3.weight(.semibold))
        }
    }
    
    private var buttons: some View {
        VStack(spacing: 20) {
            ForEach(0...2, id: \.self) { row in
                HStack(spacing: 20) {
                    ForEach(1...3, id: \.self) { col in
                        let number = row * 3 + col
                        PinEntryButton(title: AnyView(Text("\(number)")), isPlaceholder: false) {
                            appendToPin(number)
                        }
                    }
                }
            }
            HStack(spacing: 20) {
                PinEntryButton(title: AnyView(Text("")), isPlaceholder: true) {
                }
                PinEntryButton(title: AnyView(Text("0")), isPlaceholder: false) {
                    appendToPin(0)
                }
                PinEntryButton(title: AnyView(Image(systemName: "delete.backward")), isPlaceholder: false) {
                    deleteFromPin()
                }
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
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
                ZStack {
                    Circle()
                        .fill(pin.count > index ? Color.primary.opacity(0.78) : Color.black.opacity(0.12))
                        .frame(width: 18, height: 18)
                        .overlay {
                            Circle()
                                .strokeBorder(pin.count > index ? Color.white.opacity(0.35) : Color.black.opacity(0.18), lineWidth: 1)
                        }

                    if showPin, index < pin.count {
                        Text("\(pin.digits[index])")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.24), in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.14), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
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
                }
                isDisabled = false
            }
        }
        
        // this code is never reached under  normal circumstances. If the user pastes a text with count higher than the
        // max digits, we remove the additional characters and make a recursive call.
        if pin.count > maxDigits {
            pin = String(pin.prefix(maxDigits))
            submitPin()
        }
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
