import GIBowlCore
import SwiftData
import CoreGraphics
import SwiftUI

/// Add or edit a food of your own: a name, one or two portions with net carbs, optional GI.
struct OwnFoodForm: View {
    let prefillName: String?
    let editing: CustomFood?
    let onSaved: (SearchableFood) -> Void
    /// Opens straight into taking or choosing a photo.
    var startWithCapture = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var portion = ""
    @State private var carbs = ""
    @State private var portion2 = ""
    @State private var carbs2 = ""
    @State private var gi = ""
    @State private var reading = false
    @State private var banner: String?
    @State private var bannerIsWarning = false
    @State private var showCamera = false
    @State private var showPhotos = false

    private var canSave: Bool {
        !name.trimmed.isEmpty && !portion.trimmed.isEmpty && Int(carbs.trimmed) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if reading {
                        ProgressView("Reading the label…")
                    } else {
                        LabelCaptureButton(showCamera: $showCamera, showPhotos: $showPhotos) { image in
                            read(image)
                        }
                    }
                    if let banner {
                        Text(banner)
                            .font(.subheadline)
                            .foregroundStyle(bannerIsWarning ? Theme.textColor(.close) : .secondary)
                            .accessibilityIdentifier("label.banner")
                    }
                }
                Section {
                    TextField("What is it?", text: $name)
                        .accessibilityIdentifier("own.name")
                }
                Section {
                    TextField("Portion, like ½ cup", text: $portion)
                        .accessibilityIdentifier("own.portion")
                    carbsField($carbs, id: "own.carbs")
                } header: {
                    Text("Portion")
                } footer: {
                    Text("Net carbs: total carbs minus fiber.")
                }
                Section("Another portion (optional)") {
                    TextField("Portion, like 1 cup", text: $portion2)
                    carbsField($carbs2, id: "own.carbs2")
                }
                Section("GI (optional)") {
                    TextField("GI", text: $gi)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(editing == nil ? "Your own food" : "Edit food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .accessibilityIdentifier("own.save")
                }
            }
            .onAppear {
                load()
                if startWithCapture {
                    if CameraPicker.isAvailable { showCamera = true } else { showPhotos = true }
                }
            }
        }
    }

    private func carbsField(_ text: Binding<String>, id: String) -> some View {
        LabeledContent("Carbs") {
            HStack(spacing: 4) {
                TextField("0", text: text)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier(id)
                Text("g").foregroundStyle(.secondary)
            }
        }
    }

    private func load() {
        if let editing {
            name = editing.name
            gi = editing.gi.map(String.init) ?? ""
            if let first = editing.portions.first {
                portion = first.label
                carbs = String(Int(first.carbs.rounded()))
            }
            if editing.portions.count > 1 {
                portion2 = editing.portions[1].label
                carbs2 = String(Int(editing.portions[1].carbs.rounded()))
            }
        } else if let prefillName {
            name = prefillName
        }
    }

    private func read(_ image: CGImage) {
        reading = true
        Task {
            let result = await LabelReader().read(image)
            apply(result)
            reading = false
        }
    }

    /// Prefills the form from a label with whatever was read. Nothing is saved until Save.
    func apply(_ reading: LabelReading) {
        let fill = LabelFormFill(reading: reading, currentName: name)
        name = fill.name
        portion = fill.portion
        carbs = fill.carbs
        banner = fill.banner
        bannerIsWarning = fill.isWarning
    }

    private func save() {
        guard let first = Int(carbs.trimmed) else { return }
        var portions = [Portion(label: portion.trimmed, carbs: Double(first))]
        if !portion2.trimmed.isEmpty, let second = Int(carbs2.trimmed) {
            portions.append(Portion(label: portion2.trimmed, carbs: Double(second)))
        }
        let food = BowlStore(context: context).saveCustomFood(
            name: name.trimmed,
            gi: gi.positiveInt,
            portions: portions,
            replacing: editing
        )
        dismiss()
        onSaved(food.searchable)
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
