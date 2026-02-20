import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var photoURL: String?
    var activeWalletId: String?
    var createdAt: Date

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        photoURL: String? = nil,
        activeWalletId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.activeWalletId = activeWalletId
        self.createdAt = createdAt
    }
}
