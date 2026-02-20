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
        model = GenerativeModel(name: "gemini-2.0-flash", apiKey: apiKey)
    }

    func scanReceipt(image: UIImage) async throws -> ScannedReceipt {
        guard let model = model else {
            throw ReceiptScannerError.notConfigured
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ReceiptScannerError.invalidImage
        }

        let prompt = """
        Analizza questa foto di uno scontrino/ricevuta e rispondi SOLO con un JSON valido (senza markdown, senza ```).
        Estrai queste informazioni:

        {
            "merchant": "nome del negozio/esercente",
            "date": "data in formato YYYY-MM-DD (o null se non leggibile)",
            "total_amount": 0.00,
            "items": [
                {
                    "name": "nome articolo",
                    "quantity": 1,
                    "unit_price": 0.00,
                    "total_price": 0.00
                }
            ],
            "category": "una tra: groceries, dining, transport, utilities, entertainment, health, shopping, education, housing, insurance, subscriptions, personal, travel, gifts, other",
            "raw_text": "testo completo leggibile dallo scontrino"
        }

        Se un campo non è leggibile, usa un valore di default ragionevole.
        L'importo totale deve corrispondere alla somma degli articoli dove possibile.
        """

        let response = try await model.generateContent(prompt, imageData)

        guard let text = response.text else {
            throw ReceiptScannerError.emptyResponse
        }

        return try parseResponse(text)
    }

    private func parseResponse(_ text: String) throws -> ScannedReceipt {
        // Clean potential markdown wrapping
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw ReceiptScannerError.parseError
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ReceiptScannerError.parseError
        }

        let merchant = json["merchant"] as? String ?? "Sconosciuto"
        let totalAmount = json["total_amount"] as? Double ?? 0.0
        let rawText = json["raw_text"] as? String ?? ""
        let categoryStr = json["category"] as? String ?? "other"
        let category = ExpenseCategory(rawValue: categoryStr) ?? .other

        var date: Date?
        if let dateStr = json["date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            date = formatter.date(from: dateStr)
        }

        var items: [ReceiptItem] = []
        if let jsonItems = json["items"] as? [[String: Any]] {
            items = jsonItems.map { item in
                ReceiptItem(
                    name: item["name"] as? String ?? "",
                    quantity: item["quantity"] as? Int ?? 1,
                    unitPrice: item["unit_price"] as? Double ?? 0,
                    totalPrice: item["total_price"] as? Double
                )
            }
        }

        return ScannedReceipt(
            merchant: merchant,
            date: date,
            totalAmount: totalAmount,
            items: items,
            suggestedCategory: category,
            rawText: rawText
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
