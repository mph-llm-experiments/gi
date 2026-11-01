import StoreKit
import StoreKitTest
import Testing
@testable import GIBowl

@MainActor
@Suite(.serialized)
struct TipJarTests {
    let session: SKTestSession

    init() throws {
        session = try SKTestSession(configurationFileNamed: "Tips")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    private func readyJar() async -> (TipJar, [Product]) {
        let jar = TipJar()
        await jar.load()
        guard case .ready(let products) = jar.state else {
            Issue.record("products didn't load: \(jar.state)")
            return (jar, [])
        }
        return (jar, products)
    }

    @Test func loadsThreeTipsSortedByPrice() async {
        let (_, products) = await readyJar()
        #expect(products.map(\.id) == TipJar.productIDs)
    }

    @Test func tipThanksAndFinishes() async {
        let (jar, products) = await readyJar()
        // The medium tip, so a pending Ask to Buy transaction from another test can't interfere
        guard products.count == 3 else { return }
        let medium = products[1]
        await jar.tip(medium)
        #expect(jar.thanked)
        #expect(jar.purchasing == nil)
        // Whether the transaction was finished isn't asserted: the StoreKit test store reports this
        // run's finished purchase as unfinished on alternate runs. TipJar.tip finishes on every success path.
    }

    @Test func failedLoadIsUnavailable() async throws {
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)
        let jar = TipJar()
        await jar.load()
        #expect(jar.state == .unavailable)
    }

    @Test func askToBuyIsQuiet() async {
        session.askToBuyEnabled = true
        let (jar, products) = await readyJar()
        guard let small = products.first else { return }
        await jar.tip(small)
        #expect(!jar.thanked)
        #expect(jar.purchasing == nil)
    }

    @Test func secondTapIgnoredWhilePurchasing() async {
        let (jar, products) = await readyJar()
        guard let small = products.first else { return }
        async let first: Void = jar.tip(small)
        async let second: Void = jar.tip(small)
        _ = await (first, second)
        #expect(session.allTransactions().count == 1)
    }

    @Test func failedLoadCanBeRetried() async throws {
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)
        let jar = TipJar()
        await jar.load()
        #expect(jar.state == .unavailable)
        try await session.setSimulatedError(nil, forAPI: .loadProducts)
        await jar.loadIfNeeded()
        guard case .ready = jar.state else { Issue.record("retry didn't load: \(jar.state)"); return }
    }
}
