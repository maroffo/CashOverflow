import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private init() {}

    var currentUserId: String? { auth.currentUser?.uid }
    var currentUserEmail: String? { auth.currentUser?.email }
    var isAuthenticated: Bool { auth.currentUser != nil }

    func signUp(email: String, password: String, displayName: String) async throws -> AppUser {
        let result = try await auth.createUser(withEmail: email, password: password)

        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        let user = AppUser(
            id: result.user.uid,
            email: email,
            displayName: displayName,
            createdAt: Date()
        )
        try await db.collection("users").document(result.user.uid).setData(Firestore.Encoder().encode(user))

        // Create a default wallet for the new user
        let wallet = Wallet(name: "Il mio portafoglio", ownerId: result.user.uid)
        let walletRef = try await db.collection("wallets").addDocument(data: Firestore.Encoder().encode(wallet))

        // Set the default wallet as active
        try await db.collection("users").document(result.user.uid).updateData([
            "activeWalletId": walletRef.documentID
        ])

        return user
    }

    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func fetchCurrentUser() async throws -> AppUser? {
        guard let uid = currentUserId else { return nil }
        let doc = try await db.collection("users").document(uid).getDocument()
        return try doc.data(as: AppUser.self)
    }

    func addAuthStateListener(_ handler: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        auth.addStateDidChangeListener { _, user in
            handler(user)
        }
    }

    func removeAuthStateListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }
}
