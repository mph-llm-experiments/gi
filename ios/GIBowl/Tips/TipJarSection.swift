import StoreKit
import SwiftUI

/// The tip jar, in Settings only. No prompts anywhere else.
struct TipJarSection: View {
    @Environment(TipJar.self) private var jar

    var body: some View {
        Section {
            switch jar.state {
            case .loading:
                ProgressView()
            case .unavailable:
                Text("Tips aren't available right now.")
                    .foregroundStyle(.secondary)
            case .ready(let products):
                ForEach(products) { product in
                    HStack {
                        Text(product.displayName)
                        Spacer()
                        Button(product.displayPrice) {
                            Task { await jar.tip(product) }
                        }
                        .buttonStyle(.bordered)
                        .disabled(jar.purchasing != nil)
                        .accessibilityIdentifier("tip.\(product.id.split(separator: ".").last ?? "")")
                    }
                }
            }
            if jar.thanked {
                Text("Thank you. That really helps.")
                    .accessibilityIdentifier("tip.thanks")
            }
        } header: {
            Text("Tip jar")
        } footer: {
            Text("GI Bowl is free and has no ads. If it helps you, a tip helps keep it that way.")
        }
        .task {
            if jar.state == .loading { await jar.load() }
        }
    }
}
