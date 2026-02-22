import Foundation
import FirebaseFirestore
import FirebaseStorage

final class ExpenseService {
    static let shared = ExpenseService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Expense CRUD

    func addExpense(_ expense: Expense) async throws -> Expense {
        var newExpense = expense
        let ref = try await db.collection("wallets").document(expense.walletId)
            .collection("expenses").addDocument(data: Firestore.Encoder().encode(expense))
        newExpense.id = ref.documentID
        return newExpense
    }

    func updateExpense(_ expense: Expense) async throws {
        guard let id = expense.id else { return }
        try await db.collection("wallets").document(expense.walletId)
            .collection("expenses").document(id)
            .setData(Firestore.Encoder().encode(expense), merge: true)
    }

    func deleteExpense(walletId: String, expenseId: String) async throws {
        try await db.collection("wallets").document(walletId)
            .collection("expenses").document(expenseId).delete()
    }

    func fetchExpenses(walletId: String, month: Date? = nil, category: ExpenseCategory? = nil) async throws -> [Expense] {
        var query: Query = db.collection("wallets").document(walletId).collection("expenses")

        if let month = month {
            let calendar = Calendar.current
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            query = query
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
                .whereField("date", isLessThan: Timestamp(date: end))
        }

        if let category = category {
            query = query.whereField("category", isEqualTo: category.rawValue)
        }

        let snapshot = try await query.order(by: "date", descending: true).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Expense.self) }
    }

    func listenToExpenses(walletId: String, month: Date, onChange: @escaping ([Expense]) -> Void) -> ListenerRegistration {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let end = calendar.date(byAdding: .month, value: 1, to: start)!

        return db.collection("wallets").document(walletId)
            .collection("expenses")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("date", isLessThan: Timestamp(date: end))
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, _ in
                let expenses = snapshot?.documents.compactMap { try? $0.data(as: Expense.self) } ?? []
                onChange(expenses)
            }
    }

    // MARK: - Receipt Image Upload

    func uploadReceiptImage(_ imageData: Data, walletId: String) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let ref = storage.reference().child("receipts/\(walletId)/\(fileName)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    // MARK: - Stats

    func monthlyTotal(walletId: String, month: Date) async throws -> Double {
        let expenses = try await fetchExpenses(walletId: walletId, month: month)
        return expenses.reduce(0) { $0 + $1.amount }
    }

    func categoryTotals(walletId: String, month: Date) async throws -> [ExpenseCategory: Double] {
        let expenses = try await fetchExpenses(walletId: walletId, month: month)
        var totals: [ExpenseCategory: Double] = [:]
        for expense in expenses {
            totals[expense.category, default: 0] += expense.amount
        }
        return totals
    }
}
