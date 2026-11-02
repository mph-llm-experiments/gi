import GIBowlCore
import SwiftUI

/// What the app does and where its numbers come from. Reached only by a link; never shown on its own.
struct HowItWorksView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                section("The bowl", id: "howItWorks",
                        "Pick Meal or Snack, add what's going in, and the bowl says where you stand against your number: Room to spare, Close to your number, or Over your number.",
                        "When the bowl's eaten, start over. Nothing is tracked past this meal.")

                section("About 15g",
                        "Every amount is rounded to the nearest 5 grams on purpose. Portions are eyeballed, labels are approximate, and a number like 23.4g would suggest a precision nobody has.",
                        "If you want to be careful, treat Close as Over.")

                section("Net carbs",
                        "Carbs here are net carbs: total carbohydrate minus fiber. US labels list the total, so the label reader subtracts fiber when it can find it. EU labels already leave fiber out.")

                VStack(alignment: .leading, spacing: 10) {
                    heading("GI and GL")
                    paragraph("The glycemic index ranks foods by how quickly they raise blood sugar, against pure glucose at 100.")
                    // Side by side where they fit; stacked at accessibility sizes so a range never wraps
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 18) { bands }
                        VStack(alignment: .leading, spacing: 10) { bands }
                    }
                    paragraph("Glycemic load accounts for both the GI and how much carbohydrate a portion holds. A high-GI food can have a low GL in a normal portion.")
                    paragraph("GI is shown as background. The bowl measures carbs, not GI.")
                }

                section("Reading a label",
                        "Photograph the nutrition panel. The app reads serving size, total carbohydrate and fiber on your phone, fills the form, and asks you to check it. The photo is discarded.",
                        "On phones with Apple Intelligence, the on-device model helps read the label. It isn't required.")

                VStack(alignment: .leading, spacing: 10) {
                    heading("Where the numbers come from")
                    paragraph("Everyday foods: USDA FoodData Central, which is in the public domain.")
                    paragraph("GI values: Atkinson FS, Brand-Miller JC, Foster-Powell K, Buyken AE, Goletzke J. International tables of glycemic index and glycemic load values 2021. American Journal of Clinical Nutrition.")
                    Link("doi.org/10.1093/ajcn/nqac031", destination: URL(string: "https://doi.org/10.1093/ajcn/nqac031")!)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                    paragraph("Each food's screen says which source it came from.")
                }

                section("Privacy",
                        "No account, no ads, no analytics. Your numbers, your foods and your bowl stay on this phone. Nothing is sent anywhere.")
            }
            .padding()
        }
        .background(Theme.paper)
        .navigationTitle("How GI Bowl works")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, id: String? = nil, _ paragraphs: String...) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            heading(title, id: id)
            ForEach(paragraphs, id: \.self) { paragraph($0) }
        }
    }

    private func heading(_ title: String, id: String? = nil) -> some View {
        Text(title)
            .font(Theme.title)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier(id ?? "")
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var bands: some View {
        band(.low, "0–55")
        band(.medium, "56–69")
        band(.high, "70+")
    }

    private func band(_ band: GIBand, _ range: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(range)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Theme.textColor(band.state))
                .fixedSize()
            Text(band.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
