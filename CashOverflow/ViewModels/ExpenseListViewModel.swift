import Foundation
import FirebaseFirestore

@MainActor
final class ExpenseListViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var categoryTotals: [ExpenseCategory: Double] = [:]
    @Published var monthlyTotal: Double = 0
    @Published var selectedMonth: Date = Date()
    @Published var selectedCategory: ExpenseCategory?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?
    private let expenseService = ExpenseService.shared

    var walletId: String? {
        didSet {
            if let walletId = walletId {
                startListening(walletId: walletId)
            }
        }
    }

    var filteredExpenses: [Expense] {
        guard let category = selectedCategory else { return expenses }
        return expenses.filter { $0.category == category }
    }

    var monthDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth).capitalized
    }

    func loadExpenses() async {
        guard let walletId = walletId else { return }
        isLoading = true
        do {
            expenses = try await expenseService.fetchExpenses(walletId: walletId, month: selectedMonth)
            updateTotals()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteExpense(_ expense: Expense) async {
        guard let id = expense.id else { return }
        do {
            try await expenseService.deleteExpense(walletId: expense.walletId, expenseId: id)
            expenses.removeAll { $0.id == id }
            updateTotals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func previousMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
        Task { await loadExpenses() }
    }

    func nextMonth() {
        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        Task { await loadExpenses() }
    }

    private func startListening(walletId: String) {
        listener?.remove()
        listener = expenseService.listenToExpenses(walletId: walletId) { [weak self] expenses in
            Task { @MainActor in
                self?.expenses = expenses
                self?.updateTotals()
            }
        }
    }

    private func updateTotals() {
        let calendar = Calendar.current
        let monthExpenses = expenses.filter {
            calendar.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
        monthlyTotal = monthExpenses.reduce(0) { $0 + $1.amount }

        var totals: [ExpenseCategory: Double] = [:]
        for expense in monthExpenses {
            totals[expense.category, default: 0] += expense.amount
        }
        categoryTotals = totals
    }
}
