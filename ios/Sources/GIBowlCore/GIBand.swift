/// The glycemic index bands used in the 2021 tables: ≤55 low, 56–69 medium, ≥70 high.
public enum GIBand: Sendable, Equatable {
    case low
    case medium
    case high

    public var title: String {
        switch self {
        case .low: "Low GI"
        case .medium: "Medium GI"
        case .high: "High GI"
        }
    }

    /// The bowl state that shares this band's colour, so views reuse one palette.
    public var state: BowlState {
        switch self {
        case .low: .roomToSpare
        case .medium: .close
        case .high: .over
        }
    }
}

public func giBand(_ gi: Int?) -> GIBand? {
    guard let gi else { return nil }
    if gi <= 55 { return .low }
    if gi <= 69 { return .medium }
    return .high
}
