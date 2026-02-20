import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateStyle = .medium
        return formatter.string(from: expense.date)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: expense.category.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(expense.category.color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(expense.category.displayName)
                        .font(.caption)
                        .foregroundStyle(expense.category.color)

                    if !expense.merchant.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(expense.merchant)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Text(dateFormatted)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Amount
            Text(expense.amount.formatted(.currency(code: expense.currency)))
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(.primary)

            // Receipt indicator
            if expense.receiptImageURL != nil {
                Image(systemName: "doc.text.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}
