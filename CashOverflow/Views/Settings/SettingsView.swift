import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("geminiApiKey") private var geminiApiKey = ""
    @State private var showApiKeyField = false
    @State private var tempApiKey = ""
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            List {
                // Profile
                Section("Profilo") {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(authViewModel.currentUser?.displayName ?? "Utente")
                                .font(.headline)
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Gemini API
                Section {
                    if geminiApiKey.isEmpty {
                        Button {
                            showApiKeyField = true
                        } label: {
                            Label("Configura Gemini API Key", systemImage: "key.fill")
                        }
                    } else {
                        HStack {
                            Label("Gemini API", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            Button("Modifica") {
                                tempApiKey = geminiApiKey
                                showApiKeyField = true
                            }
                            .font(.caption)
                        }
                    }
                } header: {
                    Text("Scansione scontrini")
                } footer: {
                    Text("Necessaria per la scansione automatica degli scontrini tramite Google Gemini.")
                }

                // Info
                Section("Informazioni") {
                    HStack {
                        Text("Versione")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }

                // Logout
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        Label("Esci", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Impostazioni")
            .alert("Gemini API Key", isPresented: $showApiKeyField) {
                SecureField("API Key", text: $tempApiKey)
                Button("Salva") {
                    geminiApiKey = tempApiKey
                    ReceiptScannerService.shared.configure(apiKey: geminiApiKey)
                    tempApiKey = ""
                }
                Button("Annulla", role: .cancel) { tempApiKey = "" }
            } message: {
                Text("Inserisci la tua API Key di Google Gemini. La puoi ottenere su aistudio.google.com.")
            }
            .confirmationDialog("Vuoi uscire?", isPresented: $showLogoutConfirm) {
                Button("Esci", role: .destructive) {
                    authViewModel.signOut()
                }
                Button("Annulla", role: .cancel) {}
            }
        }
    }
}
