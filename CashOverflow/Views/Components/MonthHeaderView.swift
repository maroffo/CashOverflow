import SwiftUI

struct MonthHeaderView: View {
    let monthDisplay: String
    let total: Double
    let budget: Double?
    let onPrevious: () -> Void
    let onNext: () -> Void

    private var budgetProgress: Double? {
        guard let budget = budget, budget > 0 else { return nil }
        return min(total / budget, 1.0)
    }

    private var budgetColor: Color {
        guard let progress = budgetProgress else { return .blue }
        if progress < 0.7 { return .green }
        if progress < 0.9 { return .orange }
        return .red
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                }

                Spacer()

                Text(monthDisplay)
                    .font(.title3.bold())

                Spacer()

                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.title3.bold())
                }
            }

            // Total
            Text(total.formatted(.currency(code: "EUR")))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(budgetColor)

            // Budget bar
            if let budget = budget, let progress = budgetProgress {
                VStack(spacing: 4) {
                    ProgressView(value: progress)
                        .tint(budgetColor)

                    HStack {
                        Text("Budget: \(budget.formatted(.currency(code: "EUR")))")
                        Spacer()
                        let remaining = budget - total
                        Text(remaining >= 0 ? "Rimangono: \(remaining.formatted(.currency(code: "EUR")))" : "Sforato!")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
