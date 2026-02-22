import Foundation
import FirebaseFirestore

@MainActor
final class WalletViewModel: ObservableObject {
    @Published var currentWallet: Wallet?
    @Published var wallets: [Wallet] = []
    @Published var pendingInvites: [WalletInvite] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var walletListener: ListenerRegistration?
    private let walletService = WalletService.shared

    func loadWallets(userId: String) async {
        isLoading = true
        do {
            wallets = try await walletService.fetchWallets(forUser: userId)
            if currentWallet == nil, let first = wallets.first {
                currentWallet = first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setActiveWallet(id: String) {
        currentWallet = wallets.first { $0.id == id }
    }

    func createWallet(name: String, currency: String = "EUR", ownerId: String) async {
        isLoading = true
        do {
            let wallet = try await walletService.createWallet(name: name, currency: currency, ownerId: ownerId)
            wallets.append(wallet)
            currentWallet = wallet
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func setMonthlyBudget(_ budget: Double) async {
        guard var wallet = currentWallet else { return }
        wallet.monthlyBudget = budget
        do {
            try await walletService.updateWallet(wallet)
            currentWallet = wallet
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func inviteMember(email: String, userId: String) async {
        guard let wallet = currentWallet, let walletId = wallet.id else { return }
        isLoading = true
        do {
            try await walletService.inviteMember(
                walletId: walletId,
                walletName: wallet.name,
                invitedBy: userId,
                email: email
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadPendingInvites(email: String) async {
        do {
            pendingInvites = try await walletService.fetchPendingInvites(forEmail: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func acceptInvite(_ invite: WalletInvite, userId: String) async {
        do {
            try await walletService.acceptInvite(invite, userId: userId)
            pendingInvites.removeAll { $0.id == invite.id }
            await loadWallets(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func declineInvite(_ invite: WalletInvite) async {
        do {
            try await walletService.declineInvite(invite)
            pendingInvites.removeAll { $0.id == invite.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeMember(userId: String) async {
        guard let walletId = currentWallet?.id else { return }
        do {
            try await walletService.removeMember(walletId: walletId, userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func switchWallet(to wallet: Wallet) {
        currentWallet = wallet
    }
}
