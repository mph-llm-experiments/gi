import GIBowlCore
import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.catalog) private var catalog
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomFood.name) private var customFoods: [CustomFood]

    @State private var query = ""
    @State private var path: [SearchableFood] = []

    private var search: FoodSearch {
        FoodSearch(catalog.foods.map(SearchableFood.init) + customFoods.map(\.searchable))
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                let results = search.search(query)
                ForEach(results) { food in
                    NavigationLink(value: food) {
                        FoodRow(food: food)
                    }
                }
            }
            .navigationTitle("GI Bowl")
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
