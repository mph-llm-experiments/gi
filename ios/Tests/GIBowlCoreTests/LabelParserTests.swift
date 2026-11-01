import Testing
@testable import GIBowlCore

@Test func usLabel() {
    let r = LabelParser.parse(lines: ["Nutrition Facts", "8 servings per container", "Serving size 2/3 cup (55g)", "Calories 230", "Total Carbohydrate 37g 13%", "Dietary Fiber 4g 14%", "Total Sugars 12g"])
    #expect(r.format == .us)
    #expect(r.servingLabel == "2/3 cup (55g)")
    #expect(r.totalCarbs == 37 && r.fiber == 4 && r.netCarbs == 33)
    #expect(!r.fiberMissing && !r.unreliable)
}

@Test func usNoisy() {
    let bar = LabelParser.parse(lines: ["Serving Size 1 bar (40 g)", "Total Carb. 24 g", "Fiber 3g"])
    #expect(bar.netCarbs == 21)
    #expect(bar.servingLabel == "1 bar (40 g)")
    #expect(LabelParser.parse(lines: ["Total Carbohydrates 12 g"]).fiberMissing)
    #expect(LabelParser.parse(lines: ["Total Carbohydrates 12 g"]).netCarbs == 12)
    #expect(LabelParser.parse(lines: ["Total Carbohydrate 5g", "Dietary Fiber 0g"]).netCarbs == 5)
}

@Test func euLabelPicksPortion() {
    let r = LabelParser.parse(lines: ["Nutrition", "per 100g per portion (30g)", "Energy 1580kJ 474kJ", "Fat 6.0g 1.8g", "Carbohydrate 60,5 g 18,2 g", "of which sugars 20g 6g", "Fibre 8,0g 2,4g"])
    #expect(r.format == .eu)
    #expect(r.servingLabel == "per portion (30g)")
    #expect(r.netCarbs == 18.2)
}

@Test func euPer100Only() {
    let r = LabelParser.parse(lines: ["Typical values per 100g", "Carbohydrate 12.5g"])
    #expect(r.servingLabel == "100g")
    #expect(r.netCarbs == 12.5)
}

@Test func fiberAboveTotalIsUnreliable() {
    let r = LabelParser.parse(lines: ["Total Carbohydrate 3g", "Dietary Fiber 8g"])
    #expect(r.unreliable)
    #expect(r.netCarbs == 3)
}

@Test func nothingUsable() {
    let r = LabelParser.parse(lines: ["Hello", "world"])
    #expect(r.netCarbs == nil && r.format == .unknown)
}

@Test func sharedNetCarbRule() {
    #expect(LabelParser.reading(total: 12, fiber: 2, format: .us, serving: nil).netCarbs == 10)
    #expect(LabelParser.reading(total: 12, fiber: nil, format: .us, serving: nil).fiberMissing)
    #expect(LabelParser.reading(total: 12, fiber: 3, format: .eu, serving: "100g").netCarbs == 12)
}

@Test func fiberComesFromTheFiberLineNotAClaimOrIngredients() {
    let brand = LabelParser.parse(lines: ["Fiber One", "Serving size 1 bar (40g)", "Total Carbohydrate 29g", "Dietary Fiber 9g"])
    #expect(brand.fiber == 9 && brand.netCarbs == 20)
    let interleaved = LabelParser.parse(lines: ["Total Carbohydrate 29g 11%", "INGREDIENTS: OATS, CHICORY ROOT FIBER, SUGAR, 2% OR LESS SALT", "Dietary Fiber 5g"])
    #expect(interleaved.fiber == 5 && interleaved.netCarbs == 24)
    #expect(LabelParser.parse(lines: ["Good source of fiber", "Total Carbohydrate 20g"]).fiberMissing)
}

@Test func numbersOnTheNextLineCount() {
    #expect(LabelParser.parse(lines: ["Total Carbohydrate", "37g", "Dietary Fiber", "4g"]).netCarbs == 33)
    let eu = LabelParser.parse(lines: ["Carbohydrate", "60g"])
    #expect(eu.format == .eu && eu.netCarbs == 60 && eu.servingLabel == "100g")
}

@Test func formFillUsesWhateverWasRead() {
    let ok = LabelFormFill(reading: LabelParser.parse(lines: ["Serving size 1 bar (40g)", "Total Carbohydrate 24g", "Fiber 3g"]), currentName: "bar")
    #expect(ok.portion == "1 bar (40g)" && ok.carbs == "21" && ok.banner == "Read from the label. Check the numbers before saving." && !ok.isWarning)
    let none = LabelFormFill(reading: .empty, currentName: "bar")
    #expect(none.carbs == "" && none.portion == "" && none.banner == "Couldn't read the label. Fill in what you can." && none.isWarning)
    let servingOnly = LabelFormFill(reading: LabelParser.parse(lines: ["Serving size 2 cookies (30g)"]), currentName: "")
    #expect(servingOnly.portion == "2 cookies (30g)" && servingOnly.carbs == "")
    let noFiber = LabelFormFill(reading: LabelParser.parse(lines: ["Total Carbohydrate 12g"]), currentName: "x")
    #expect(noFiber.banner == "Couldn't find fiber, so this uses total carbs." && noFiber.isWarning)
    let named = LabelFormFill(reading: LabelParser.reading(total: 10, fiber: 1, format: .us, serving: nil, productName: "Granola"), currentName: "")
    #expect(named.name == "Granola")
}
