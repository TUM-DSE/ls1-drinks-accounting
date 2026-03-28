//
//  LiquidGlass.swift
//  LS1DrinksAccounting
//
//  Created by Codex on 28.03.26.
//

import SwiftUI

struct LiquidGlassBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(primaryOrbColor)
                .frame(width: colorScheme == .dark ? 380 : 340, height: colorScheme == .dark ? 380 : 340)
                .blur(radius: colorScheme == .dark ? 48 : 24)
                .offset(x: -180, y: -220)

            Circle()
                .fill(secondaryOrbColor)
                .frame(width: colorScheme == .dark ? 360 : 320, height: colorScheme == .dark ? 360 : 320)
                .blur(radius: colorScheme == .dark ? 52 : 28)
                .offset(x: 180, y: 240)

            Circle()
                .fill(highlightOrbColor)
                .frame(width: colorScheme == .dark ? 300 : 260, height: colorScheme == .dark ? 300 : 260)
                .blur(radius: colorScheme == .dark ? 32 : 16)
                .offset(x: 180, y: -180)

            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.12),
                        Color.clear,
                        Color.black.opacity(0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.07, green: 0.09, blue: 0.13),
                Color(red: 0.10, green: 0.14, blue: 0.20),
                Color(red: 0.14, green: 0.10, blue: 0.09)
            ]
        }

        return [
            Color(red: 0.95, green: 0.97, blue: 1.0),
            Color(red: 0.89, green: 0.95, blue: 0.98),
            Color(red: 0.98, green: 0.94, blue: 0.89)
        ]
    }

    private var primaryOrbColor: Color {
        colorScheme == .dark ? Color.cyan.opacity(0.18) : Color.cyan.opacity(0.22)
    }

    private var secondaryOrbColor: Color {
        colorScheme == .dark ? Color.orange.opacity(0.14) : Color.orange.opacity(0.18)
    }

    private var highlightOrbColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.45)
    }
}

struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 28
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.10), radius: 24, y: 16)
    }
}

struct LiquidGlassButtonStyle: ButtonStyle {
    var tint: Color = .accentColor
    var prominence: CGFloat = 1

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.16 : 0.22 * prominence))
            )
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(configuration.isPressed ? 0.22 : 0.38), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 28, padding: CGFloat = 20) -> some View {
        modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func liquidGlassField() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.34), lineWidth: 1)
            }
    }
}
