import GIBowlCore
import SwiftUI

struct MainView: View {
    @Environment(\.catalog) private var catalog

    var body: some View {
        NavigationStack {
            List(catalog.foods.prefix(20)) { food in
                Text(food.name)
            }
            .navigationTitle("GI Bowl")
        }
    }
}
