import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var walletViewModel = WalletViewModel()
    @StateObject private var expenseListViewModel = ExpenseListViewModel()

    var body: some View {
        TabView {
            ExpenseListView()
                .environmentObject(expenseListViewModel)
                .environmentObject(walletViewModel)
                .tabItem {
                    Label("Spese", systemImage: "list.bullet")
                }

            ReceiptCaptureView()
                .environmentObject(walletViewModel)
                .tabItem {
                    Label("Scansiona", systemImage: "camera.fill")
                }

            WalletView()
                .environmentObject(walletViewModel)
                .tabItem {
                    Label("Portafoglio", systemImage: "wallet.pass.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Impostazioni", systemImage: "gear")
                }
        }
        .tint(.blue)
        .task {
            if let userId = authViewModel.currentUser?.id {
                await walletViewModel.loadWallets(userId: userId)
                if let activeWalletId = authViewModel.currentUser?.activeWalletId {
                    await walletViewModel.loadWallet(id: activeWalletId)
                }
                expenseListViewModel.walletId = walletViewModel.currentWallet?.id
            }
        }
        .onChange(of: walletViewModel.currentWallet?.id) { _, newId in
            expenseListViewModel.walletId = newId
        }
    }
}
