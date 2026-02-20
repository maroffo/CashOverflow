import SwiftUI

struct WalletView: View {
    @EnvironmentObject var walletViewModel: WalletViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showInvite = false
    @State private var showCreateWallet = false
    @State private var inviteEmail = ""

    var body: some View {
        NavigationStack {
            List {
                // Current wallet info
                if let wallet = walletViewModel.currentWallet {
                    Section("Portafoglio attivo") {
                        HStack {
                            Image(systemName: "wallet.pass.fill")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(wallet.name)
                                    .font(.headline)
                                Text("\(wallet.memberIds.count) \(wallet.memberIds.count == 1 ? "membro" : "membri")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let budget = wallet.monthlyBudget {
                            HStack {
                                Text("Budget mensile")
                                Spacer()
                                Text(budget.formatted(.currency(code: wallet.currency)))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Members
                    Section("Membri") {
                        ForEach(wallet.memberIds, id: \.self) { memberId in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(memberId == wallet.ownerId ? .blue : .gray)
                                Text(memberId == authViewModel.currentUser?.id ? "Tu" : memberId)
                                Spacer()
                                if memberId == wallet.ownerId {
                                    Text("Admin")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }

                        Button {
                            showInvite = true
                        } label: {
                            Label("Invita membro", systemImage: "person.badge.plus")
                        }
                    }
                }

                // Other wallets
                if walletViewModel.wallets.count > 1 {
                    Section("I tuoi portafogli") {
                        ForEach(walletViewModel.wallets) { wallet in
                            Button {
                                walletViewModel.switchWallet(to: wallet)
                            } label: {
                                HStack {
                                    Text(wallet.name)
                                    Spacer()
                                    if wallet.id == walletViewModel.currentWallet?.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                // Pending invites
                if !walletViewModel.pendingInvites.isEmpty {
                    Section("Inviti ricevuti") {
                        ForEach(walletViewModel.pendingInvites) { invite in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(invite.walletName)
                                    .font(.subheadline.bold())
                                Text("Invitato da: \(invite.invitedBy)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Button("Accetta") {
                                        Task {
                                            if let userId = authViewModel.currentUser?.id {
                                                await walletViewModel.acceptInvite(invite, userId: userId)
                                            }
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)

                                    Button("Rifiuta") {
                                        Task { await walletViewModel.declineInvite(invite) }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Create new wallet
                Section {
                    Button {
                        showCreateWallet = true
                    } label: {
                        Label("Crea nuovo portafoglio", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Portafoglio")
            .task {
                if let email = authViewModel.currentUser?.email {
                    await walletViewModel.loadPendingInvites(email: email)
                }
            }
            .alert("Invita membro", isPresented: $showInvite) {
                TextField("Email", text: $inviteEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                Button("Invia invito") {
                    Task {
                        if let userId = authViewModel.currentUser?.id {
                            await walletViewModel.inviteMember(email: inviteEmail, userId: userId)
                            inviteEmail = ""
                        }
                    }
                }
                Button("Annulla", role: .cancel) { inviteEmail = "" }
            } message: {
                Text("Inserisci l'email della persona da invitare.")
            }
            .sheet(isPresented: $showCreateWallet) {
                CreateWalletView()
                    .environmentObject(walletViewModel)
                    .environmentObject(authViewModel)
            }
        }
    }
}
