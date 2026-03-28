//
//  SelectDrinkView.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 12.12.22.
//

import SwiftUI

struct SelectDrinkView: View {
    @Environment(\.colorScheme) private var colorScheme

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
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18),
    ]

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.large)
            } else if let error = viewModel.error {
                Text("Error loading items: \(error)")
                    .liquidGlassCard()
                    .padding(24)
            } else if let user = viewModel.user {
                content(for: user)
            } else {
                Text("Error")
                    .liquidGlassCard()
                    .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    @ViewBuilder
    private func content(for user: User) -> some View {
        if viewModel.shouldShowEnterPin {
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
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
            .frame(maxWidth: 420)
            .toolbar {
                lockToolbarButton
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    NavigationLink {
                        TransactionsView(model: model, person: user)
                    } label: {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current balance")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)

                                Text(formatter.string(from: NSNumber(value: user.balance)) ?? "")
                                    .animation(nil)
                                    .modifier(AnimatableCurrencyModifier(number: user.balance))
                                    .animation(.linear, value: user.balance)
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                            }

                            Spacer()

                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title2)
                        }
                        .contentShape(Rectangle())
                        .foregroundColor(user.balance < 0 ? Color.red : .primary)
                    }
                    .buttonStyle(.plain)
                    .lightweightPanelStyle(colorScheme: colorScheme)

                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Select a drink")
                                    .font(.title2.weight(.bold))
                            }

                            Spacer()
                        }

                        if let error = viewModel.errorBuyingDrink {
                            Text("Error selecting drink: \(error)")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        grid
                    }
                }
                .padding(24)
            }
            .refreshable {
                await viewModel.loadDrinks()
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button(action: { showingChangePasswordDialog = true }) {
                        Label("Set pin", systemImage: "rectangle.and.pencil.and.ellipsis")
                            .labelStyle(.titleAndIcon)
                    }

                    lockToolbarButton
                }
            }
            .sheet(isPresented: $showingChangePasswordDialog) {
                NavigationStack {
                    ZStack {
                        LiquidGlassBackground()

                        PasscodeField(showPin: true, handler: { pin, _ in
                            Task {
                                let _ = await viewModel.setPin(pin: pin)
                                showingChangePasswordDialog = false
                            }
                        })
                        .frame(maxWidth: 420)
                        .padding(24)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(viewModel.drinks) { item in
                DrinkItemView(item: item, viewModel: viewModel, formatter: formatter)
            }
        }
    }

    private var lockToolbarButton: some View {
        Button(action: {
            model.logoutUser()
            onDismiss()
        }) {
            Label("Lock", systemImage: "xmark")
                .labelStyle(.iconOnly)
        }
    }

    init(_ userId: UUID, model: Model, onDismiss: @escaping () -> Void) {
        self.viewModel = DrinksViewModel(model, userId: userId)
        self.onDismiss = onDismiss
    }
}

struct DrinkItemView: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: Drink
    let viewModel: DrinksViewModel
    let formatter: NumberFormatter

    @State
    private var showingBuyConfirmation = false
    @State
    private var animateSuccess = false

    var body: some View {
        Button {
            if viewModel.isLoading || viewModel.loadingDrink != nil {
                return
            }

            showingBuyConfirmation = true
        } label: {
            VStack(spacing: 10) {
                Text(item.icon)
                    .font(.system(size: 34))

                Text(item.name)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(formatter.string(from: NSNumber(value: item.price)) ?? "n/a")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .padding(18)
            .background(tileFillColor, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(tileStrokeColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
        .overlay {
            ZStack {
                if viewModel.loadingDrink == item.id {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(tileOverlayColor)
                    ProgressView()
                }

                if animateSuccess {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.green.opacity(0.62))

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 72))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .transition(.opacity.combined(with: .scale))
        }
        .scaleEffect(viewModel.loadingDrink == item.id ? 0.99 : 1)
        .animation(.easeOut(duration: 0.12), value: viewModel.loadingDrink == item.id)
    }

    private var tileFillColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.52)
    }

    private var tileStrokeColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color.white.opacity(0.55)
    }

    private var tileOverlayColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.22)
            : Color.white.opacity(0.55)
    }
}

private struct LightweightPanelModifier: ViewModifier {
    let colorScheme: ColorScheme
    var cornerRadius: CGFloat = 28
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(panelFillColor, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(panelStrokeColor, lineWidth: 1)
            }
    }

    private var panelFillColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.07) : Color.white.opacity(0.46)
    }

    private var panelStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.white.opacity(0.50)
    }
}

private extension View {
    func lightweightPanelStyle(colorScheme: ColorScheme, cornerRadius: CGFloat = 28, padding: CGFloat = 20) -> some View {
        modifier(LightweightPanelModifier(colorScheme: colorScheme, cornerRadius: cornerRadius, padding: padding))
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
