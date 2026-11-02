import GIBowlCore
import SwiftUI
import UIKit

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
    static func wash(_ state: BowlState?) -> Color {
        guard let state else { return .clear }
        let name = switch state {
        case .roomToSpare: "StateRoom"
        case .close: "StateClose"
        case .over: "StateOver"
        }
        return Color(uiColor: UIColor { traits in
            UIColor(named: name)!.withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.16 : 0.10)
        })
    }

    static let paper = Color("Paper")
    static let card = Color("Card")

    /// The cookbook voice: system serif for names and the bowl's state.
    static let display = Font.system(.title2, design: .serif).weight(.semibold)
    static let title = Font.system(.headline, design: .serif)
}
