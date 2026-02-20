import SwiftUI

struct ExpenseListView: View {
    @EnvironmentObject var viewModel: ExpenseListViewModel
    @EnvironmentObject var walletViewModel: WalletViewModel
    @State private var showAddManual = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month navigation + total
                MonthHeaderView(
                    monthDisplay: viewModel.monthDisplay,
                    total: viewModel.monthlyTotal,
                    budget: walletViewModel.currentWallet?.monthlyBudget,
                    onPrevious: { viewModel.previousMonth() },
                    onNext: { viewModel.nextMonth() }
                )

                // Category filter chips
                CategoryFilterView(
                    categoryTotals: viewModel.categoryTotals,
                    selectedCategory: $viewModel.selectedCategory
                )

                // Expense list
                if viewModel.filteredExpenses.isEmpty {
                    ContentUnavailableView(
                        "Nessuna spesa",
                        systemImage: "tray",
                        description: Text("Scansiona uno scontrino o aggiungi una spesa manualmente.")
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredExpenses) { expense in
                            ExpenseRowView(expense: expense)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await viewModel.deleteExpense(expense) }
                                    } label: {
                                        Label("Elimina", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(walletViewModel.currentWallet?.name ?? "Spese")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddManual = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddManual) {
                ManualExpenseView()
                    .environmentObject(walletViewModel)
            }
            .refreshable {
                await viewModel.loadExpenses()
            }
        }
    }
}
