/// Rough grams: nearest 5g, never below 5g.
public func roughGrams(_ grams: Double) -> Int {
    max(5, Int((grams / 5).rounded()) * 5)
}

/// Carbs as people eyeball them: "about 15g", or "a few grams" under 3g.
public func aboutCarbs(_ grams: Double) -> String {
    grams < 3 ? "a few grams" : "about \(roughGrams(grams))g"
}

/// Where the bowl stands against the target.
public enum BowlState: Sendable {
    case roomToSpare
    case close
    case over

    public var title: String {
        switch self {
        case .roomToSpare: "Room to spare"
        case .close: "Close to your number"
        case .over: "Over your number"
        }
    }
}

/// The state for an unrounded total. No target (nil or ≤ 0) means no state.
public func stateFor(total: Double, target: Int?) -> BowlState? {
    guard let target, target > 0 else { return nil }
    let t = Double(target)
    if total > t { return .over }
    return total < 0.75 * t ? .roomToSpare : .close
}

/// One line under the state.
public func hint(total: Double, target: Int) -> String {
    let remaining = Double(target) - total
    if remaining < 0 { return "Roughly \(roughGrams(-remaining))g past it" }
    if remaining < 3 { return "Right about at it" }
    return "Room for \(aboutCarbs(remaining)) more"
}
