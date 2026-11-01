import GIBowlCore
import SwiftData
import SwiftUI

extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct MainView: View {
    @Environment(\.catalog) private var catalog
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomFood.name) private var customFoods: [CustomFood]
    @Query(sort: \BowlItem.addedAt) private var bowl: [BowlItem]
    @AppStorage("targetMeal") private var targetMeal = 0
    @AppStorage("targetSnack") private var targetSnack = 0
    @AppStorage("bowlMode") private var bowlMode = BowlMode.snack.rawValue
    @State private var showingTargets = false
    @State private var showingSettings = false
    @State private var ownFoodName: String?

    @State private var query = ""
    @State private var path: [SearchableFood] = []

    private var search: FoodSearch {
        FoodSearch(catalog.foods.map(SearchableFood.init) + customFoods.map(\.searchable))
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                BowlSection(
                    items: bowl,
                    targets: Targets(meal: targetMeal, snack: targetSnack),
                    mode: Binding(get: { BowlMode(rawValue: bowlMode) ?? .snack }, set: { bowlMode = $0.rawValue }),
                    compact: !query.trimmed.isEmpty,
                    onSetNumbers: { showingTargets = true }
                )
                let results = search.search(query)
                ForEach(results) { food in
                    NavigationLink(value: food) {
                        FoodRow(food: food)
                    }
                }
                if !query.trimmed.isEmpty {
                    Button("Add your own food") { ownFoodName = query.trimmed }
                        .accessibilityIdentifier("own.add")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.paper)
            .navigationTitle("GI Bowl")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { showingSettings = true }
                }
            }
            .sheet(isPresented: $showingTargets) {
                TargetsSheet(current: Targets(meal: targetMeal, snack: targetSnack)) { meal, snack in
                    targetMeal = meal
                    targetSnack = snack
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(item: $ownFoodName) { name in
                OwnFoodForm(prefillName: name, editing: nil) { path = [$0] }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search foods")
            .navigationDestination(for: SearchableFood.self) { food in
                FoodDetailView(
                    food: food,
                    onAdded: {
                        query = ""
                        path = []
                    },
                    onShow: { path = [$0] },
                    onDeleted: {
                        query = ""
                        path = []
                    }
                )
            }
        }
    }
}

struct FoodRow: View {
    let food: SearchableFood

    @Environment(\.dynamicTypeSize) private var typeSize

    private var giText: some View {
        Text(food.gi.map { "GI \($0)" } ?? "GI —")
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
    }

    private var nameBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(food.name)
                .lineLimit(typeSize.isAccessibilitySize ? nil : 3)
            if food.source == .custom {
                Text("Yours")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    var body: some View {
        // At accessibility sizes the name gets the full width and GI drops below it.
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                nameBlock
                giText
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                nameBlock
                Spacer(minLength: 12)
                giText
            }
        }
    }
}
