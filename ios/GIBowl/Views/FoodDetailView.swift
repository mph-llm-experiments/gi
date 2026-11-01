import GIBowlCore
import SwiftData
import SwiftUI

struct FoodDetailView: View {
    let food: SearchableFood
    let onAdded: () -> Void

    @Environment(\.modelContext) private var context
    @Query private var bowl: [BowlItem]
    @AppStorage("targetMeal") private var targetMeal = 0
    @AppStorage("targetSnack") private var targetSnack = 0
    @AppStorage("bowlMode") private var bowlMode = BowlMode.snack.rawValue

    private var targets: Targets { Targets(meal: targetMeal, snack: targetSnack) }
    private var mode: BowlMode { BowlMode(rawValue: bowlMode) ?? .snack }
    private var bowlTotal: Double { bowl.reduce(0) { $0 + $1.carbs } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(food.name)
                        .font(Theme.display)
                        .fixedSize(horizontal: false, vertical: true)
                    if let category = food.category {
                        Text(category.capitalized)
                            .font(.caption.smallCaps())
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 24) {
                    stat("GI", food.gi.map(String.init) ?? "—")
                    stat("GL", food.gl.map(String.init) ?? "—")
                }

                if food.portions.isEmpty {
                    Text("This food doesn't have carb amounts.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Add to the bowl")
                            .font(Theme.title)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                            ForEach(previews(for: food, bowlTotal: bowlTotal, target: targets.target(for: mode)), id: \.portion) { preview in
                                PortionButton(preview: preview) { add(preview.portion) }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.paper)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.impact(weight: .light), trigger: bowl.count)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.monospacedDigit())
        }
    }

    private func add(_ portion: Portion) {
        BowlStore(context: context).add(food, portion: portion)
        onAdded()
    }
}
