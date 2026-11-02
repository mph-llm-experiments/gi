import GIBowlCore
import SwiftData
import SwiftUI

/// The bowl: Meal/Snack, where it stands, and what's in it.
struct BowlSection: View {
    let items: [BowlItem]
    let targets: Targets
    @Binding var mode: BowlMode
    /// While searching, the bowl shrinks to where it stands so results get the room.
    let compact: Bool
    let onSetNumbers: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var colorScheme

    private var total: Double { items.reduce(0) { $0 + $1.carbs } }
    private var target: Int? { targets.target(for: mode) }
    private var state: BowlState? { target.flatMap { stateFor(total: total, target: $0) } }
    private var wash: Color? { Theme.wash(state, dark: colorScheme == .dark) }

    var body: some View {
        if compact {
            if !items.isEmpty {
                Section { status.listRowBackground(wash) }
            }
        } else if items.isEmpty {
            Section {
                modePicker
                    .listRowSeparator(.hidden)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start a bowl")
                        .font(Theme.title)
                    Text("Search for what's going in it.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    NavigationLink("How it works") { HowItWorksView() }
                        .font(.subheadline)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
        } else {
            Section {
                modePicker
                    .listRowSeparator(.hidden)
                    .listRowBackground(wash)

                status
                    .listRowSeparator(.hidden)
                    .listRowBackground(wash)

                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                        Text("\(item.portionLabel) · \(aboutCarbs(item.carbs))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    .accessibilityElement(children: .combine)
                    .listRowBackground(wash)
                }
                .onDelete { offsets in
                    let store = BowlStore(context: context)
                    for index in offsets { store.remove(items[index]) }
                }

                Button("Start over", role: .destructive) {
                    BowlStore(context: context).clear()
                }
                .font(.subheadline)
                .listRowBackground(wash)
            } footer: {
                if let target {
                    Text("Your \(mode.rawValue) number: \(target)g")
                }
            }
            .animation(.default, value: state)
        }
    }

    private var modePicker: some View {
        Picker("Meal or snack", selection: $mode) {
            Text("Meal").tag(BowlMode.meal)
            Text("Snack").tag(BowlMode.snack)
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var status: some View {
        if let target, let state = stateFor(total: total, target: target) {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.title)
                    .font(Theme.display)
                    .foregroundStyle(Theme.textColor(state))
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
