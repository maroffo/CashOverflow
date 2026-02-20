import Foundation
import FirebaseFirestore

struct Wallet: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var currency: String
    var ownerId: String
    var memberIds: [String]
    var monthlyBudget: Double?
    var createdAt: Date

    init(
        id: String? = nil,
        name: String,
        currency: String = "EUR",
        ownerId: String,
        memberIds: [String] = [],
        monthlyBudget: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.currency = currency
        self.ownerId = ownerId
        self.memberIds = [ownerId] + memberIds
        self.createdAt = createdAt
        self.monthlyBudget = monthlyBudget
    }

    var allMemberIds: [String] { memberIds }
}

struct WalletInvite: Identifiable, Codable {
    @DocumentID var id: String?
    var walletId: String
    var walletName: String
    var invitedBy: String
    var invitedEmail: String
    var status: InviteStatus
    var createdAt: Date

    enum InviteStatus: String, Codable {
        case pending
        case accepted
        case declined
    }
}
