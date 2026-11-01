import Foundation

/// Lowercased ASCII word tokens with diacritics folded away.
public func normalize(_ s: String) -> [String] {
    let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
    var tokens: [String] = []
    var current = ""
    for scalar in folded.unicodeScalars {
        if scalar.isASCII, CharacterSet.alphanumerics.contains(scalar) {
            current.unicodeScalars.append(scalar)
        } else if !current.isEmpty {
            tokens.append(current)
            current = ""
        }
    }
    if !current.isEmpty { tokens.append(current) }
    return tokens
}

/// True when a and b differ by at most one insertion, deletion or substitution.
func withinOneEdit(_ a: [UInt8], _ b: [UInt8]) -> Bool {
    if abs(a.count - b.count) > 1 { return false }
    var i = 0, j = 0, edits = 0
    while i < a.count, j < b.count {
        if a[i] == b[j] {
            i += 1; j += 1
            continue
        }
        edits += 1
        if edits > 1 { return false }
        if a.count > b.count { i += 1 } else if a.count < b.count { j += 1 } else { i += 1; j += 1 }
    }
    return edits + (a.count - i) + (b.count - j) <= 1
}

func hasPrefix(_ t: [UInt8], _ q: [UInt8]) -> Bool {
    t.count >= q.count && t.starts(with: q)
}

func contains(_ t: [UInt8], _ q: [UInt8]) -> Bool {
    if q.count > t.count { return false }
    var i = 0
    while i + q.count <= t.count {
        if t[i] == q[0], t[i..<(i + q.count)].elementsEqual(q) { return true }
        i += 1
    }
    return false
}

/// Word-based search, forgiving of one typo per word.
public struct FoodSearch: Sendable {
    private struct Entry: Sendable {
        let food: SearchableFood
        let tokens: [[UInt8]]
    }

    private let entries: [Entry]

    public init(_ foods: [SearchableFood]) {
        entries = foods.map { Entry(food: $0, tokens: normalize($0.name).map { Array($0.utf8) }) }
    }

    public func search(_ query: String, limit: Int = 50) -> [SearchableFood] {
        let queryTokens = normalize(query).map { Array($0.utf8) }
        if queryTokens.isEmpty || (queryTokens.count == 1 && queryTokens[0].count < 2) { return [] }

        var scored: [(entry: Entry, score: Int)] = []
        for entry in entries {
            var total = 0
            var matchedAll = true
            for q in queryTokens {
                var best = 0
                for t in entry.tokens {
                    if hasPrefix(t, q) { best = 3; break }
                    if contains(t, q) { best = max(best, 2) }
                    else if best == 0, q.count >= 4, withinOneEdit(q, t) { best = 1 }
                }
                if best == 0 { matchedAll = false; break }
                total += best
            }
            if matchedAll { scored.append((entry, total)) }
        }

        scored.sort { a, b in
            if a.entry.food.tier != b.entry.food.tier { return a.entry.food.tier < b.entry.food.tier }
            if a.score != b.score { return a.score > b.score }
            return a.entry.food.name.count < b.entry.food.name.count
        }
        return scored.prefix(limit).map(\.entry.food)
    }
}
