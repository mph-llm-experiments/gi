import PhotosUI
import SwiftUI

/// Read a label: take a photo or choose one. The image goes to `onImage` and isn't kept.
struct LabelCaptureButton: View {
    @Binding var showCamera: Bool
    @Binding var showPhotos: Bool
    let onImage: (CGImage) -> Void

    @State private var photo: PhotosPickerItem?

    var body: some View {
        Group {
            if CameraPicker.isAvailable {
                Button("Photograph a label", systemImage: "camera") { showCamera = true }
                    .accessibilityIdentifier("label.camera")
            }
            Button("Choose a photo of a label", systemImage: "photo") { showPhotos = true }
                .accessibilityIdentifier("label.capture")
            #if DEBUG
            if let fixture = Self.debugFixture {
                Button("Use sample label", systemImage: "doc.text.viewfinder") { onImage(LabelFixtures.named(fixture)) }
                    .accessibilityIdentifier("label.sample")
            }
            #endif
        }
        .photosPicker(isPresented: $showPhotos, selection: $photo, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                if let cg = image.uprightCGImage { onImage(cg) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: photo) {
            guard let photo else { return }
            Task {
                if let data = try? await photo.loadTransferable(type: Data.self),
                   let cg = UIImage(data: data)?.uprightCGImage {
                    onImage(cg)
                }
                self.photo = nil
            }
        }
    }

    #if DEBUG
    /// UI tests: -labelFixture us|eu|blank adds a "Use sample label" option.
    static var debugFixture: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-labelFixture"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
    #endif
}
