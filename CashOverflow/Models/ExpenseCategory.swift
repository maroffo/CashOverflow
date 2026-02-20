import Foundation
import SwiftUI

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case groceries = "groceries"
    case dining = "dining"
    case transport = "transport"
    case utilities = "utilities"
    case entertainment = "entertainment"
    case health = "health"
    case shopping = "shopping"
    case education = "education"
    case housing = "housing"
    case insurance = "insurance"
    case subscriptions = "subscriptions"
    case personal = "personal"
    case travel = "travel"
    case gifts = "gifts"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .groceries: "Alimentari"
        case .dining: "Ristoranti"
        case .transport: "Trasporti"
        case .utilities: "Utenze"
        case .entertainment: "Intrattenimento"
        case .health: "Salute"
        case .shopping: "Shopping"
        case .education: "Istruzione"
        case .housing: "Casa"
        case .insurance: "Assicurazioni"
        case .subscriptions: "Abbonamenti"
        case .personal: "Personale"
        case .travel: "Viaggi"
        case .gifts: "Regali"
        case .other: "Altro"
        }
    }

    var icon: String {
        switch self {
        case .groceries: "cart.fill"
        case .dining: "fork.knife"
        case .transport: "car.fill"
        case .utilities: "bolt.fill"
        case .entertainment: "film.fill"
        case .health: "heart.fill"
        case .shopping: "bag.fill"
        case .education: "book.fill"
        case .housing: "house.fill"
        case .insurance: "shield.fill"
        case .subscriptions: "repeat"
        case .personal: "person.fill"
        case .travel: "airplane"
        case .gifts: "gift.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .groceries: .green
        case .dining: .orange
        case .transport: .blue
        case .utilities: .yellow
        case .entertainment: .purple
        case .health: .red
        case .shopping: .pink
        case .education: .cyan
        case .housing: .brown
        case .insurance: .gray
        case .subscriptions: .indigo
        case .personal: .mint
        case .travel: .teal
        case .gifts: .red
        case .other: .secondary
        }
    }
}
