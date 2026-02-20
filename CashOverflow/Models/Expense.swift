import Foundation
import FirebaseFirestore

struct Expense: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var walletId: String
    var amount: Double
    var currency: String
    var title: String
    var merchant: String
    var category: ExpenseCategory
    var date: Date
    var notes: String
    var receiptImageURL: String?
    var items: [ReceiptItem]
    var createdBy: String
    var createdAt: Date

    init(
        id: String? = nil,
        walletId: String,
        amount: Double,
        currency: String = "EUR",
        title: String,
        merchant: String = "",
        category: ExpenseCategory = .other,
        date: Date = Date(),
        notes: String = "",
        receiptImageURL: String? = nil,
        items: [ReceiptItem] = [],
        createdBy: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.walletId = walletId
        self.amount = amount
        self.currency = currency
        self.title = title
        self.merchant = merchant
        self.category = category
        self.date = date
        self.notes = notes
        self.receiptImageURL = receiptImageURL
        self.items = items
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

struct ReceiptItem: Codable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var quantity: Int
    var unitPrice: Double
    var totalPrice: Double

    init(name: String, quantity: Int = 1, unitPrice: Double, totalPrice: Double? = nil) {
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice ?? (Double(quantity) * unitPrice)
    }
}
