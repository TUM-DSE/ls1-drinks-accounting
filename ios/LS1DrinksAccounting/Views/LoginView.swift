//
//  LoginView.swift
//  LS1DrinksAccounting
//
//  Created by Martin Fink on 30.12.22.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject
    private var viewModel: LoginViewModel

    @State private var username: String = ""
    @State private var password: String = ""

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    LiquidGlassBackground()

                    if isWideLayout(for: geometry.size) {
                        wideLayout
                    } else {
                        compactLayout
                    }
                }
            }
        }
    }

    private var wideLayout: some View {
        HStack(spacing: 48) {
            VStack(alignment: .leading, spacing: 16) {
                Text("LS1 Drinks")
                    .font(.system(size: 36, weight: .bold))

                Text("Sign in to access the accounting app.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 320, alignment: .leading)
            .liquidGlassCard()

            loginCard
                .frame(width: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var compactLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("LS1 Drinks")
                        .font(.largeTitle.bold())

                    Text("Sign in to access the accounting app.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                loginCard
                    .frame(maxWidth: 420)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .padding(.top, 40)
        }
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Login")
                .font(.title2.bold())

            VStack(spacing: 16) {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .liquidGlassField()

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .liquidGlassField()
            }

            if let error = viewModel.error {
                Text("Error logging in: \(error)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.login(username: username, password: password)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(viewModel.loading ? "Logging in..." : "Login")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(LiquidGlassButtonStyle(tint: .blue))
                .disabled(viewModel.loading || username.isEmpty || password.isEmpty)

                if viewModel.loading {
                    ProgressView()
                        .padding(.leading, 4)
                }
            }
        }
        .liquidGlassCard(cornerRadius: 28, padding: 28)
    }

    private func isWideLayout(for size: CGSize) -> Bool {
        horizontalSizeClass == .regular && size.width > 900
    }

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: LoginViewModel(Model.shared))
            .environmentObject(Model.shared)
            .previewDevice("iPad (10th generation)")
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
