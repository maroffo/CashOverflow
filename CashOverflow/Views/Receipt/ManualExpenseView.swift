import SwiftUI

struct ManualExpenseView: View {
    @EnvironmentObject var walletViewModel: WalletViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amount = ""
    @State private var merchant = ""
    @State private var category: ExpenseCategory = .other
    @State private var date = Date()
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Dettagli") {
                    TextField("Titolo spesa", text: $title)

                    HStack {
                        Text("Importo")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("EUR")
                            .foregroundStyle(.secondary)
                    }

                    TextField("Esercente (opzionale)", text: $merchant)

                    DatePicker("Data", selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "it_IT"))
                }

                Section("Categoria") {
                    Picker("Categoria", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Note") {
                    TextField("Note aggiuntive...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Nuova spesa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        Task { await save() }
                    }
                    .disabled(isSaving || title.isEmpty || amount.isEmpty)
                }
            }
        }
    }

    private func save() async {
        guard let walletId = walletViewModel.currentWallet?.id,
              let userId = authViewModel.currentUser?.id else { return }

        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Importo non valido"
            return
        }

        isSaving = true
        let expense = Expense(
            walletId: walletId,
            amount: amountValue,
            title: title,
            merchant: merchant,
            category: category,
            date: date,
            notes: notes,
            createdBy: userId
        )

        do {
            _ = try await ExpenseService.shared.addExpense(expense)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
