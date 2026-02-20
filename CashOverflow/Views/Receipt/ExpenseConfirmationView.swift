import SwiftUI

struct ExpenseConfirmationView: View {
    @ObservedObject var viewModel: ReceiptScanViewModel
    @EnvironmentObject var walletViewModel: WalletViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Dettagli spesa") {
                    HStack {
                        Text("Esercente")
                        Spacer()
                        TextField("Nome esercente", text: $viewModel.merchant)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Importo")
                        Spacer()
                        TextField("0.00", text: $viewModel.totalAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("EUR")
                            .foregroundStyle(.secondary)
                    }

                    DatePicker("Data", selection: $viewModel.date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "it_IT"))
                }

                Section("Categoria") {
                    Picker("Categoria", selection: $viewModel.selectedCategory) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                if !viewModel.items.isEmpty {
                    Section("Articoli riconosciuti") {
                        ForEach(viewModel.items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.subheadline)
                                    if item.quantity > 1 {
                                        Text("x\(item.quantity)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(item.totalPrice.formatted(.currency(code: "EUR")))
                                    .font(.subheadline.monospacedDigit())
                            }
                        }
                    }
                }

                Section("Note") {
                    TextField("Note aggiuntive...", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Conferma spesa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        guard let walletId = walletViewModel.currentWallet?.id,
              let userId = authViewModel.currentUser?.id else { return }

        isSaving = true
        let success = await viewModel.saveExpense(walletId: walletId, userId: userId)
        isSaving = false

        if success {
            viewModel.reset()
            dismiss()
        }
    }
}
