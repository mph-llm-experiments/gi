import GIBowlCore
import SwiftData
import SwiftUI

/// The bowl: Meal/Snack, where it stands, and what's in it.
struct BowlSection: View {
    let items: [BowlItem]
    let targets: Targets
    @Binding var mode: BowlMode
    let onSetNumbers: () -> Void

    @Environment(\.modelContext) private var context

    private var total: Double { items.reduce(0) { $0 + $1.carbs } }
    private var target: Int? { targets.target(for: mode) }

    var body: some View {
        if items.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start a bowl")
                        .font(Theme.title)
                    Text("Search for what's going in it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        } else {
            Section {
                Picker("Meal or snack", selection: $mode) {
                    Text("Meal").tag(BowlMode.meal)
                    Text("Snack").tag(BowlMode.snack)
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)

                status
                    .listRowSeparator(.hidden)

                ForEach(items) { item in
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(item.name) · \(item.portionLabel)")
                            .lineLimit(2)
                        Spacer(minLength: 12)
                        Text(aboutCarbs(item.carbs))
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                .onDelete { offsets in
                    let store = BowlStore(context: context)
                    for index in offsets { store.remove(items[index]) }
                }

                Button("Start over", role: .destructive) {
                    BowlStore(context: context).clear()
                }
                .font(.subheadline)
            } footer: {
                if let target {
                    Text("Your \(mode.rawValue) number: \(target)g")
                }
            }
        }
    }

    @ViewBuilder
    private var status: some View {
        if let target, let state = stateFor(total: total, target: target) {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.title)
                    .font(Theme.display)
                    .foregroundStyle(Theme.color(state))
                    .accessibilityIdentifier("bowl.state")
                Text(hint(total: total, target: target))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("bowl.hint")
            }
            .padding(.vertical, 4)
            .animation(.default, value: state)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(aboutCarbs(total).prefix(1).uppercased())\(aboutCarbs(total).dropFirst()) so far")
                    .font(Theme.title)
                    .accessibilityIdentifier("bowl.state")
                Button("Set your numbers", action: onSetNumbers)
                    .font(.subheadline)
            }
            .padding(.vertical, 4)
        }
    }
}
