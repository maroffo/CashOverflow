import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var showResetPassword = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("CashOverflow")
                            .font(.largeTitle.bold())

                        Text("Gestisci il budget familiare")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 16) {
                        if isSignUp {
                            TextField("Nome", text: $displayName)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.name)
                                .autocorrectionDisabled()
                        }

                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(isSignUp ? .newPassword : .password)
                    }
                    .padding(.horizontal)

                    // Error message
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                if isSignUp {
                                    await authViewModel.signUp(email: email, password: password, displayName: displayName)
                                } else {
                                    await authViewModel.signIn(email: email, password: password)
                                }
                            }
                        } label: {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text(isSignUp ? "Registrati" : "Accedi")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)

                        Button(isSignUp ? "Hai già un account? Accedi" : "Non hai un account? Registrati") {
                            withAnimation {
                                isSignUp.toggle()
                                authViewModel.errorMessage = nil
                            }
                        }
                        .font(.subheadline)

                        if !isSignUp {
                            Button("Password dimenticata?") {
                                showResetPassword = true
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .alert("Reset Password", isPresented: $showResetPassword) {
                TextField("Email", text: $email)
                Button("Invia") {
                    Task { await authViewModel.resetPassword(email: email) }
                }
                Button("Annulla", role: .cancel) {}
            } message: {
                Text("Inserisci la tua email per ricevere il link di reset.")
            }
        }
    }
}
