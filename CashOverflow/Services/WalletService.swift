import Foundation
import FirebaseFirestore

final class WalletService {
    static let shared = WalletService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Wallet CRUD

    func createWallet(name: String, currency: String = "EUR", ownerId: String) async throws -> Wallet {
        var wallet = Wallet(name: name, currency: currency, ownerId: ownerId)
        let ref = try await db.collection("wallets").addDocument(data: Firestore.Encoder().encode(wallet))
        wallet.id = ref.documentID
        return wallet
    }

    func fetchWallet(id: String) async throws -> Wallet? {
        let doc = try await db.collection("wallets").document(id).getDocument()
        return try doc.data(as: Wallet.self)
    }

    func fetchWallets(forUser userId: String) async throws -> [Wallet] {
        let snapshot = try await db.collection("wallets")
            .whereField("memberIds", arrayContains: userId)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Wallet.self) }
    }

    func updateWallet(_ wallet: Wallet) async throws {
        guard let id = wallet.id else { return }
        try await db.collection("wallets").document(id).setData(Firestore.Encoder().encode(wallet), merge: true)
    }

    func deleteWallet(id: String) async throws {
        try await db.collection("wallets").document(id).delete()
    }

    // MARK: - Sharing

    func inviteMember(walletId: String, walletName: String, invitedBy: String, email: String) async throws {
        let invite = WalletInvite(
            walletId: walletId,
            walletName: walletName,
            invitedBy: invitedBy,
            invitedEmail: email,
            status: .pending,
            createdAt: Date()
        )
        try await db.collection("invites").addDocument(data: Firestore.Encoder().encode(invite))
    }

    func fetchPendingInvites(forEmail email: String) async throws -> [WalletInvite] {
        let snapshot = try await db.collection("invites")
            .whereField("invitedEmail", isEqualTo: email)
            .whereField("status", isEqualTo: WalletInvite.InviteStatus.pending.rawValue)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: WalletInvite.self) }
    }

    func acceptInvite(_ invite: WalletInvite, userId: String) async throws {
        guard let inviteId = invite.id else { return }

        let batch = db.batch()
        batch.updateData(
            ["status": WalletInvite.InviteStatus.accepted.rawValue],
            forDocument: db.collection("invites").document(inviteId)
        )
        batch.updateData(
            ["memberIds": FieldValue.arrayUnion([userId])],
            forDocument: db.collection("wallets").document(invite.walletId)
        )
        try await batch.commit()
    }

    func declineInvite(_ invite: WalletInvite) async throws {
        guard let inviteId = invite.id else { return }
        try await db.collection("invites").document(inviteId).updateData([
            "status": WalletInvite.InviteStatus.declined.rawValue
        ])
    }

    func removeMember(walletId: String, userId: String) async throws {
        try await db.collection("wallets").document(walletId).updateData([
            "memberIds": FieldValue.arrayRemove([userId])
        ])
    }

    func listenToWallet(id: String, onChange: @escaping (Wallet?) -> Void) -> ListenerRegistration {
        db.collection("wallets").document(id).addSnapshotListener { snapshot, _ in
            let wallet = try? snapshot?.data(as: Wallet.self)
            onChange(wallet)
        }
    }
}
