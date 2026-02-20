import SwiftUI

struct CategoryFilterView: View {
    let categoryTotals: [ExpenseCategory: Double]
    @Binding var selectedCategory: ExpenseCategory?

    private var sortedCategories: [(ExpenseCategory, Double)] {
        categoryTotals.sorted { $0.value > $1.value }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" chip
                CategoryChip(
                    label: "Tutte",
                    icon: "square.grid.2x2",
                    color: .blue,
                    isSelected: selectedCategory == nil,
                    amount: nil
                ) {
                    selectedCategory = nil
                }

                ForEach(sortedCategories, id: \.0) { category, amount in
                    CategoryChip(
                        label: category.displayName,
                        icon: category.icon,
                        color: category.color,
                        isSelected: selectedCategory == category,
                        amount: amount
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

struct CategoryChip: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let amount: Double?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption.bold())
                if let amount = amount {
                    Text(amount.formatted(.currency(code: "EUR")))
                        .font(.caption2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.2) : Color(.systemGray6))
            .foregroundStyle(isSelected ? color : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : .clear, lineWidth: 1)
            )
        }
    }
}
