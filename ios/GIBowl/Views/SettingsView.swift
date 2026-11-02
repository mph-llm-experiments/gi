import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("targetMeal") private var targetMeal = 0
    @AppStorage("targetSnack") private var targetSnack = 0
    @State private var meal = ""
    @State private var snack = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Your numbers") {
                    TargetFields(meal: $meal, snack: $snack)
                }

                Section("About") {
                    Text("GI Bowl helps you see, roughly, whether a meal or snack fits the carb numbers you're aiming for.")
                    Text("Carbs are net carbs (total carbohydrate minus fiber), shown as rough amounts.")
                    Text("No ads, no tracking. Nothing leaves your phone.")
                    NavigationLink("How GI Bowl works") { HowItWorksView() }
                }

                Section("Where the numbers come from") {
                    Text("Everyday foods: USDA FoodData Central.")
                    VStack(alignment: .leading, spacing: 6) {
                        Text("GI values: Atkinson FS, Brand-Miller JC, Foster-Powell K, Buyken AE, Goletzke J. International tables of glycemic index and glycemic load values 2021. American Journal of Clinical Nutrition.")
                        Link("doi.org/10.1093/ajcn/nqab233", destination: URL(string: "https://doi.org/10.1093/ajcn/nqab233")!)
                    }
                    .font(.footnote)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                meal = targetMeal > 0 ? String(targetMeal) : ""
                snack = targetSnack > 0 ? String(targetSnack) : ""
            }
            .onChange(of: meal) { targetMeal = meal.positiveInt ?? 0 }
            .onChange(of: snack) { targetSnack = snack.positiveInt ?? 0 }
        }
    }
}
