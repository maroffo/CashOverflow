import SwiftUI
import FirebaseCore

@main
struct CashOverflowApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()

        if let key = KeychainService.shared.get(key: "geminiApiKey"), !key.isEmpty {
            ReceiptScannerService.shared.configure(apiKey: key)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}
