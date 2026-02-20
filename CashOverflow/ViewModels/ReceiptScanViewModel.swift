import Foundation
import UIKit

@MainActor
final class ReceiptScanViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var scannedReceipt: ScannedReceipt?
    @Published var isScanning = false
    @Published var errorMessage: String?

    // Editable fields for user confirmation
    @Published var merchant: String = ""
    @Published var totalAmount: String = ""
    @Published var date: Date = Date()
    @Published var selectedCategory: ExpenseCategory = .other
    @Published var notes: String = ""
    @Published var items: [ReceiptItem] = []

    private let scanner = ReceiptScannerService.shared
    private let expenseService = ExpenseService.shared

    func scanReceipt() async {
        guard let image = capturedImage else { return }
        isScanning = true
        errorMessage = nil

        do {
            let result = try await scanner.scanReceipt(image: image)
            scannedReceipt = result
            populateFields(from: result)
        } catch {
            errorMessage = error.localizedDescription
        }
        isScanning = false
    }

    private func populateFields(from receipt: ScannedReceipt) {
        merchant = receipt.merchant
        totalAmount = String(format: "%.2f", receipt.totalAmount)
        date = receipt.date ?? Date()
        selectedCategory = receipt.suggestedCategory
        items = receipt.items
    }

    func saveExpense(walletId: String, userId: String) async -> Bool {
        guard let amount = Double(totalAmount.replacingOccurrences(of: ",", with: ".")) else {
            errorMessage = "Importo non valido"
            return false
        }

        var receiptURL: String?
        if let image = capturedImage, let data = image.jpegData(compressionQuality: 0.7) {
            do {
                receiptURL = try await expenseService.uploadReceiptImage(data, walletId: walletId)
            } catch {
                // Non-blocking: proceed without image URL
            }
        }

        let expense = Expense(
            walletId: walletId,
            amount: amount,
            title: merchant.isEmpty ? "Spesa" : merchant,
            merchant: merchant,
            category: selectedCategory,
            date: date,
            notes: notes,
            receiptImageURL: receiptURL,
            items: items,
            createdBy: userId
        )

        do {
            _ = try await expenseService.addExpense(expense)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func reset() {
        capturedImage = nil
        scannedReceipt = nil
        merchant = ""
        totalAmount = ""
        date = Date()
        selectedCategory = .other
        notes = ""
        items = []
        errorMessage = nil
    }
}
