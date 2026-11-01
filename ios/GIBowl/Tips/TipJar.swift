import Observation
import StoreKit

/// Three one-time tips. A tip unlocks nothing; the app never asks for one.
@MainActor
@Observable
final class TipJar {
    enum State: Equatable {
        case loading
        case ready([Product])
        case unavailable

        static func == (a: State, b: State) -> Bool {
            switch (a, b) {
            case (.loading, .loading), (.unavailable, .unavailable): true
            case (.ready(let x), .ready(let y)): x.map(\.id) == y.map(\.id)
            default: false
            }
        }
    }

    static let productIDs = [
        "net.puddingtime.GIBowl.tip.small",
        "net.puddingtime.GIBowl.tip.medium",
        "net.puddingtime.GIBowl.tip.large",
    ]

    private(set) var state: State = .loading
    private(set) var purchasing: Product.ID?
    private(set) var thanked = false

    func load() async {
        do {
            let products = try await Product.products(for: Self.productIDs)
            state = products.isEmpty ? .unavailable : .ready(products.sorted { $0.price < $1.price })
        } catch {
            // Leaving Settings mid-load cancels it; that isn't a reason to say tips are unavailable.
            if Task.isCancelled || error is CancellationError { return }
            state = .unavailable
        }
    }

    /// Loads unless products are already here, so an earlier failure (say, offline) is retried
    /// the next time Settings opens instead of sticking until the app is closed.
    func loadIfNeeded() async {
        if case .ready = state { return }
        await load()
    }

    func tip(_ product: Product) async {
        guard purchasing == nil else { return }
        purchasing = product.id
        defer { purchasing = nil }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                thanked = true
            case .success(.unverified(let transaction, _)):
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // A failed purchase stays quiet; the buttons are usable again.
        }
    }

    /// Finishes tips that complete outside a purchase call (interrupted earlier, Ask to Buy approved later).
    func listenForTransactions() -> Task<Void, Never> {
        Task {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                } else if case .unverified(let transaction, _) = update {
                    await transaction.finish()
                }
            }
        }
    }
}
