# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
open Package.swift          # Opens in Xcode, resolves SPM deps automatically
swift build                 # CLI build (library target, no executable)
```

Run in Xcode: select iOS 17+ simulator, Cmd+R. No automated tests exist yet.

## Architecture

SwiftUI MVVM app (iOS 17+) with Firebase backend and Gemini AI receipt scanning.

**Layers:** Views -> ViewModels (@MainActor, ObservableObject) -> Services (singletons via `static let shared`) -> Firebase/Gemini APIs

**EnvironmentObject hierarchy:**
- `CashOverflowApp` creates `AuthViewModel` at root
- `RootView` switches between `AuthView` and `MainTabView` based on `authViewModel.isAuthenticated`
- `MainTabView` creates and passes `WalletViewModel` + `ExpenseListViewModel` to child tabs

**Real-time sync:** ViewModels hold `ListenerRegistration` references from Firestore snapshot listeners. Always `listener?.remove()` before setting a new one; cleanup in `deinit`.

## Firestore Data Model

```
/users/{uid}                         # AppUser (email, displayName, activeWalletId)
/wallets/{walletId}                  # Wallet (name, currency, ownerId, memberIds[], monthlyBudget)
/wallets/{walletId}/expenses/{id}    # Expense (amount, title, merchant, category, date, items[])
/invites/{id}                        # WalletInvite (walletId, invitedEmail, status: pending|accepted|declined)
```

Security: all wallet/expense access gated on `request.auth.uid in resource.data.memberIds`. See README for full rules.

Storage path: `receipts/{walletId}/{uuid}.jpg`

## Key Patterns

- **Models** use `Codable` + `@DocumentID` for Firestore serialization. Encode with `Firestore.Encoder().encode()`, decode with `snapshot.data(as: Model.self)`.
- **Async/await** throughout, no completion handlers. ViewModels catch errors into `@Published var errorMessage: String?`.
- **Receipt scanning:** `ReceiptScannerService` sends image + Italian-language structured JSON prompt to Gemini 2.0 Flash, parses response into `ScannedReceipt`. User edits fields in `ExpenseConfirmationView` before saving.
- **15 expense categories** in `ExpenseCategory` enum, each with Italian displayName, SF Symbol icon, and SwiftUI color.

## Configuration

- `GoogleService-Info.plist` required but gitignored. Must be added manually from Firebase Console.
- Gemini API key: entered by user in Settings tab, stored in `@AppStorage` (UserDefaults).
- Locale hardcoded to `it_IT` in formatters. UI strings are Italian throughout.
- Default currency: EUR (configurable per wallet).

## Dependencies

| Package | Version | Used For |
|---------|---------|----------|
| firebase-ios-sdk | >= 11.0.0 | FirebaseAuth, FirebaseFirestore, FirebaseStorage |
| generative-ai-swift | >= 0.5.0 | Google Gemini API (receipt OCR) |
