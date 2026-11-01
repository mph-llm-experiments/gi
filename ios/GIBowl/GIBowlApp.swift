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
    private let container: ModelContainer

    init() {
        container = try! ModelContainer(for: Schema(schema))
        #if DEBUG
        applyTestLaunchArguments()
        #endif
    }

    #if DEBUG
    /// UI tests: -resetData clears the bowl, your foods and your numbers; -seedTargets 45,15 sets numbers.
    private func applyTestLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        let defaults = UserDefaults.standard
        if args.contains("-resetData") {
            try? container.mainContext.delete(model: BowlItem.self)
            try? container.mainContext.delete(model: CustomFood.self)
            try? container.mainContext.save()
            for key in ["targetMeal", "targetSnack", "bowlMode"] { defaults.removeObject(forKey: key) }
        }
        if let i = args.firstIndex(of: "-seedTargets"), i + 1 < args.count {
            let parts = args[i + 1].split(separator: ",").compactMap { Int($0) }
            if parts.count == 2 {
                defaults.set(parts[0], forKey: "targetMeal")
                defaults.set(parts[1], forKey: "targetSnack")
            }
        }
    }
    #endif

    var body: some Scene {
        WindowGroup {
            if let catalog {
                MainView()
                    .environment(\.catalog, catalog)
            } else {
                ContentUnavailableView("Food data couldn't load", systemImage: "exclamationmark.triangle", description: Text("Reinstall the app."))
            }
        }
        .modelContainer(container)
    }
}
