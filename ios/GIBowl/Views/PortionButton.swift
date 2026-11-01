import GIBowlCore
import SwiftUI

/// A portion to add, outlined in the color of the state the bowl would land in.
struct PortionButton: View {
    let preview: PortionPreview
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(preview.portion.label)
                    .font(.body.weight(.semibold))
                Text(preview.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
        .accessibilityHint(preview.landsIn.map { "Adding this puts the bowl at: \($0.title)" } ?? "")
    }
}
