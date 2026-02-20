import Foundation
import FirebaseAuth

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        authHandle = AuthService.shared.addAuthStateListener { [weak self] user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                if user != nil {
                    self?.currentUser = try? await AuthService.shared.fetchCurrentUser()
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }

    deinit {
        if let handle = authHandle {
            AuthService.shared.removeAuthStateListener(handle)
        }
    }

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await AuthService.shared.signUp(email: email, password: password, displayName: displayName)
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        do {
            try AuthService.shared.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.resetPassword(email: email)
            errorMessage = "Email di reset inviata. Controlla la tua casella di posta."
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
