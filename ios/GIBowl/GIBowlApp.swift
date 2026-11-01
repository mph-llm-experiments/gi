import GIBowlCore
import SwiftData
import SwiftUI

extension EnvironmentValues {
    @Entry var catalog = FoodCatalog.empty
}

extension FoodCatalog {
    static let empty = try! FoodCatalog(data: Data(#"{"version":2,"foods":[]}"#.utf8))

    static func bundled() -> FoodCatalog? {
        guard let url = Bundle.main.url(forResource: "foods", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? FoodCatalog(data: data)
    }
}

@main
struct GIBowlApp: App {
    private let catalog = FoodCatalog.bundled()

    var body: some Scene {
        WindowGroup {
            if let catalog {
                MainView()
                    .environment(\.catalog, catalog)
            } else {
                ContentUnavailableView("Food data couldn't load", systemImage: "exclamationmark.triangle", description: Text("Reinstall the app."))
            }
        }
        .modelContainer(for: schema)
    }
}
