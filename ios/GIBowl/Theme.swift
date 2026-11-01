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

    /// Darker variants for text, so the state title stays readable on light backgrounds.
    static func textColor(_ state: BowlState?) -> Color {
        switch state {
        case .roomToSpare: Color("StateRoomText")
        case .close: Color("StateCloseText")
        case .over: Color("StateOverText")
        case nil: .primary
        }
    }

    static let paper = Color("Paper")
    static let card = Color("Card")

    /// The cookbook voice: system serif for names and the bowl's state.
    static let display = Font.system(.title2, design: .serif).weight(.semibold)
    static let title = Font.system(.headline, design: .serif)
}
