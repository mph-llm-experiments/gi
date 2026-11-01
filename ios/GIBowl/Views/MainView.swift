import GIBowlCore
import SwiftData
import SwiftUI

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
                    onSetNumbers: { showingTargets = true }
                )
                let results = search.search(query)
                ForEach(results) { food in
                    NavigationLink(value: food) {
                        FoodRow(food: food)
                    }
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
                TargetsSheet { meal, snack in
                    targetMeal = meal
                    targetSnack = snack
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search foods")
            .navigationDestination(for: SearchableFood.self) { food in
                FoodDetailView(food: food) {
                    query = ""
                    path = []
                }
            }
        }
    }
}

struct FoodRow: View {
    let food: SearchableFood

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .lineLimit(3)
                if food.source == .custom {
                    Text("Yours")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            Text(food.gi.map { "GI \($0)" } ?? "GI —")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
