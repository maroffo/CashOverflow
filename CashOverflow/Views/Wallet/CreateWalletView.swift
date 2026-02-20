import SwiftUI

struct CreateWalletView: View {
    @EnvironmentObject var walletViewModel: WalletViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var currency = "EUR"
    @State private var budgetStr = ""

    private let currencies = ["EUR", "USD", "GBP", "CHF"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Dettagli") {
                    TextField("Nome portafoglio", text: $name)

                    Picker("Valuta", selection: $currency) {
                        ForEach(currencies, id: \.self) { c in
                            Text(c).tag(c)
                        }
                    }
                }

                Section("Budget mensile (opzionale)") {
                    HStack {
                        TextField("0.00", text: $budgetStr)
                            .keyboardType(.decimalPad)
                        Text(currency)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Nuovo portafoglio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crea") {
                        Task { await create() }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func create() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        await walletViewModel.createWallet(name: name, currency: currency, ownerId: userId)

        if let budget = Double(budgetStr.replacingOccurrences(of: ",", with: ".")), budget > 0 {
            await walletViewModel.setMonthlyBudget(budget)
        }

        dismiss()
    }
}
