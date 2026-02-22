// ABOUTME: Scans receipt images using Gemini 2.0 Flash with structured JSON output.
// ABOUTME: Returns parsed ScannedReceipt for user confirmation before saving as Expense.

import Foundation
import UIKit
import GoogleGenerativeAI

struct ScannedReceipt {
    var merchant: String
    var date: Date?
    var totalAmount: Double
    var items: [ReceiptItem]
    var suggestedCategory: ExpenseCategory
    var rawText: String
}

final class ReceiptScannerService {
    static let shared = ReceiptScannerService()

    private var model: GenerativeModel?

    private init() {}

    func configure(apiKey: String) {
        let config = GenerationConfig(
            responseMIMEType: "application/json",
            responseSchema: Self.receiptSchema
        )
        model = GenerativeModel(
            name: "gemini-2.0-flash",
            apiKey: apiKey,
            generationConfig: config
        )
    }

    func scanReceipt(image: UIImage) async throws -> ScannedReceipt {
        guard let model = model else {
            throw ReceiptScannerError.notConfigured
        }

        let prompt = """
        Analizza questa foto di uno scontrino/ricevuta.
        Estrai le informazioni richieste dallo schema JSON.
        Se un campo non è leggibile, usa un valore di default ragionevole.
        L'importo totale deve corrispondere alla somma degli articoli dove possibile.
        La categoria deve essere una tra: groceries, dining, transport, utilities, entertainment, health, shopping, education, housing, insurance, subscriptions, personal, travel, gifts, other.
        """

        let response = try await model.generateContent(prompt, image)

        guard let text = response.text, let data = text.data(using: .utf8) else {
            throw ReceiptScannerError.emptyResponse
        }

        let decoded = try JSONDecoder().decode(GeminiReceiptResponse.self, from: data)
        return decoded.toScannedReceipt()
    }

    // MARK: - Schema

    private static let receiptSchema = Schema(
        type: .object,
        properties: [
            "merchant": Schema(type: .string, description: "Nome del negozio/esercente"),
            "date": Schema(type: .string, description: "Data in formato YYYY-MM-DD, null se non leggibile", nullable: true),
            "total_amount": Schema(type: .number, format: "double", description: "Importo totale"),
            "items": Schema(
                type: .array,
                items: Schema(
                    type: .object,
                    properties: [
                        "name": Schema(type: .string, description: "Nome articolo"),
                        "quantity": Schema(type: .integer, description: "Quantità"),
                        "unit_price": Schema(type: .number, format: "double", description: "Prezzo unitario"),
                        "total_price": Schema(type: .number, format: "double", description: "Prezzo totale riga")
                    ],
                    requiredProperties: ["name", "quantity", "unit_price", "total_price"]
                )
            ),
            "category": Schema(type: .string, description: "Categoria della spesa"),
            "raw_text": Schema(type: .string, description: "Testo completo leggibile dallo scontrino")
        ],
        requiredProperties: ["merchant", "total_amount", "items", "category", "raw_text"]
    )
}

// MARK: - Codable Response

private struct GeminiReceiptResponse: Decodable {
    let merchant: String
    let date: String?
    let totalAmount: Double
    let items: [GeminiReceiptItem]
    let category: String
    let rawText: String

    enum CodingKeys: String, CodingKey {
        case merchant
        case date
        case totalAmount = "total_amount"
        case items
        case category
        case rawText = "raw_text"
    }

    func toScannedReceipt() -> ScannedReceipt {
        var parsedDate: Date?
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            parsedDate = formatter.date(from: date)
        }

        return ScannedReceipt(
            merchant: merchant,
            date: parsedDate,
            totalAmount: totalAmount,
            items: items.map { $0.toReceiptItem() },
            suggestedCategory: ExpenseCategory(rawValue: category) ?? .other,
            rawText: rawText
        )
    }
}

private struct GeminiReceiptItem: Decodable {
    let name: String
    let quantity: Int
    let unitPrice: Double
    let totalPrice: Double

    enum CodingKeys: String, CodingKey {
        case name
        case quantity
        case unitPrice = "unit_price"
        case totalPrice = "total_price"
    }

    func toReceiptItem() -> ReceiptItem {
        ReceiptItem(
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: totalPrice
        )
    }
}

enum ReceiptScannerError: LocalizedError {
    case notConfigured
    case invalidImage
    case emptyResponse
    case parseError

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Il servizio di scansione non è configurato. Inserisci la API key di Gemini nelle impostazioni."
        case .invalidImage: "Impossibile elaborare l'immagine."
        case .emptyResponse: "Nessuna risposta dal servizio di riconoscimento."
        case .parseError: "Impossibile interpretare i dati dello scontrino. Riprova o inserisci i dati manualmente."
        }
    }
}
