import GIBowlCore
import SwiftUI

/// Two number fields for the user's meal and snack carb numbers.
struct TargetFields: View {
    @Binding var meal: String
    @Binding var snack: String

    var body: some View {
        field("Meal", text: $meal, id: "targets.meal")
        field("Snack", text: $snack, id: "targets.snack")
    }

    private func field(_ label: String, text: Binding<String>, id: String) -> some View {
        LabeledContent(label) {
            HStack(spacing: 4) {
                TextField("0", text: text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier(id)
                Text("g").foregroundStyle(.secondary)
            }
        }
    }
}

extension String {
    /// A whole number above zero, or nil.
    var positiveInt: Int? { Int(trimmingCharacters(in: .whitespaces)).flatMap { $0 > 0 ? $0 : nil } }
}

struct TargetsSheet: View {
    var current = Targets(meal: nil, snack: nil)
    let onSave: (Int, Int) -> Void
    var onCancel: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var meal = ""
    @State private var snack = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TargetFields(meal: $meal, snack: $snack)
                } header: {
                    Text("The carb numbers you're aiming for, per meal and per snack.")
                        .textCase(nil)
                }
            }
            .navigationTitle("Your numbers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let m = meal.positiveInt, let s = snack.positiveInt {
                            onSave(m, s)
                            dismiss()
                        }
                    }
                    .disabled(meal.positiveInt == nil || snack.positiveInt == nil)
                    .accessibilityIdentifier("targets.save")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            meal = current.meal.map(String.init) ?? ""
            snack = current.snack.map(String.init) ?? ""
        }
    }
}
