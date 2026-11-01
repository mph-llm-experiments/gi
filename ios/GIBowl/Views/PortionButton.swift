import GIBowlCore
import SwiftUI

/// A portion to add, outlined in the color of the state the bowl would land in.
struct PortionButton: View {
    let preview: PortionPreview
    let action: () -> Void

    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(preview.portion.label)
                    .font(.body.weight(.semibold))
                Text(preview.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if differentiateWithoutColor, let state = preview.landsIn {
                    Text(state.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textColor(state))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Theme.color(preview.landsIn), lineWidth: preview.landsIn == nil ? 1 : 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("portion.\(preview.portion.label)")
        .accessibilityLabel("\(preview.portion.label), \(preview.label)")
        .accessibilityValue(preview.landsIn?.title ?? "")
    }
}
