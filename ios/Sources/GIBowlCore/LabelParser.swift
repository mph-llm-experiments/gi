import Foundation

/// What was read off a nutrition label, in net carbs per serving.
public struct LabelReading: Equatable, Sendable {
    public enum Format: Sendable {
        case us
        case eu
        case unknown
    }

    public var servingLabel: String?
    public var netCarbs: Double?
    public var totalCarbs: Double?
    public var fiber: Double?
    public var format: Format
    /// US label without a fiber line: net carbs fall back to the total.
    public var fiberMissing: Bool
    /// The numbers don't add up (fiber above total), so fiber was ignored.
    public var unreliable: Bool
    public var productName: String?

    public static let empty = LabelReading(format: .unknown, fiberMissing: false, unreliable: false)

    public init(servingLabel: String? = nil, netCarbs: Double? = nil, totalCarbs: Double? = nil, fiber: Double? = nil, format: Format, fiberMissing: Bool, unreliable: Bool, productName: String? = nil) {
        self.servingLabel = servingLabel
        self.netCarbs = netCarbs
        self.totalCarbs = totalCarbs
        self.fiber = fiber
        self.format = format
        self.fiberMissing = fiberMissing
        self.unreliable = unreliable
        self.productName = productName
    }
}

public enum LabelParser {
    /// Net carbs from a total and fiber. US totals include fiber; EU carbohydrate already excludes it.
    public static func reading(total: Double?, fiber: Double?, format: LabelReading.Format, serving: String?, productName: String? = nil) -> LabelReading {
        var r = LabelReading(servingLabel: serving, totalCarbs: total, fiber: fiber, format: format, fiberMissing: false, unreliable: false, productName: productName)
        guard let total else { return r }
        if format == .us {
            if let fiber {
                if fiber > total {
                    r.unreliable = true
                    r.netCarbs = total
                } else {
                    r.netCarbs = total - fiber
                }
            } else {
                r.fiberMissing = true
                r.netCarbs = total
            }
        } else {
            r.netCarbs = total
        }
        r.netCarbs = r.netCarbs.map { max(0, $0) }
        return r
    }

    public static func parse(lines raw: [String]) -> LabelReading {
        let lines = raw.map(normalize)

        if let totalLine = lines.first(where: { $0.contains("total carb") }) {
            let total = firstNumber(after: /total carb[a-z.]*/, in: totalLine)
            let fiberLine = lines.first { $0.contains("fiber") || $0.contains("fibre") }
            let fiber = fiberLine.flatMap { firstNumber(after: /(dietary )?fib(er|re)/, in: $0) }
            let serving = servingSize(in: raw)
            return reading(total: total, fiber: fiber, format: .us, serving: serving)
        }

        if let carbLine = lines.first(where: { $0.hasPrefix("carbohydrate") }) {
            let values = numbers(in: carbLine)
            guard let last = values.last else { return .empty }
            let serving = values.count >= 2 ? portionHeader(in: lines) ?? "1 portion" : "100g"
            return reading(total: last, fiber: nil, format: .eu, serving: serving)
        }

        return .empty
    }

    /// Lowercase, decimal commas to dots, single spaces.
    static func normalize(_ line: String) -> String {
        var s = line.lowercased()
        s = s.replacing(/(\d),(\d)/) { "\($0.1).\($0.2)" }
        s = s.replacing(/\s+/, with: " ")
        return s.trimmingCharacters(in: .whitespaces)
    }

    static func numbers(in line: String) -> [Double] {
        line.matches(of: /(\d+(?:\.\d+)?)\s*(?:mg|g)?/).compactMap { match in
            // Skip percentages
            let end = match.range.upperBound
            if end < line.endIndex, line[end...].hasPrefix("%") { return nil }
            return Double(match.1)
        }
    }

    static func firstNumber(after label: some RegexComponent, in line: String) -> Double? {
        guard let match = line.firstMatch(of: label) else { return nil }
        let rest = String(line[match.range.upperBound...])
        guard let num = rest.firstMatch(of: /(\d+(?:\.\d+)?)\s*(mg|g)?/) else { return nil }
        let value = Double(num.1) ?? 0
        return num.2 == "mg" ? value / 1000 : value
    }

    static func servingSize(in raw: [String]) -> String? {
        for line in raw {
            let collapsed = line.replacing(/\s+/, with: " ")
            if let m = collapsed.firstMatch(of: /(?i)serving size:?\s*(.+)/) {
                return String(m.1).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    static func portionHeader(in lines: [String]) -> String? {
        for line in lines {
            if let m = line.firstMatch(of: /per (portion|serving)(\s*\([^)]*\))?/) {
                return String(m.0)
            }
            for m in line.matches(of: /per (\d+(?:\.\d+)?) ?(g|ml)/) where m.1 != "100" {
                return String(m.0)
            }
        }
        return nil
    }
}
