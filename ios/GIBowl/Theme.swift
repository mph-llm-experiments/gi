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

    /// A faint tint of the state colour behind the bowl, stronger in the dark where it reads fainter.
    /// Nil (no number set yet) keeps the List's own row background, so the card doesn't vanish.
    static func wash(_ state: BowlState?, dark: Bool) -> Color? {
        guard let state else { return nil }
        return color(state).opacity(dark ? 0.16 : 0.10)
    }

    static let paper = Color("Paper")
    static let card = Color("Card")

    /// The cookbook voice: system serif for names and the bowl's state.
    static let display = Font.system(.title2, design: .serif).weight(.semibold)
    static let title = Font.system(.headline, design: .serif)
}
