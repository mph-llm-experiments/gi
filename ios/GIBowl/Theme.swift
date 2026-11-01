import GIBowlCore
import SwiftUI

enum Theme {
    static func color(_ state: BowlState?) -> Color {
        switch state {
        case .roomToSpare: Color("StateRoom")
        case .close: Color("StateClose")
        case .over: Color("StateOver")
        case nil: .secondary
        }
    }

    static let paper = Color("Paper")
    static let card = Color("Card")
    static let ink = Color("Ink")

    /// The cookbook voice: system serif for names and the bowl's state.
    static let display = Font.system(.title2, design: .serif).weight(.semibold)
    static let title = Font.system(.headline, design: .serif)
}
