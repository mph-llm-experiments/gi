# Photo Capture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add your own food by photographing its nutrition label. The app reads serving size and net carbs, then you confirm or edit before saving.

**Architecture:**
- A pure `LabelParser` in `GIBowlCore` turns recognized text lines into a `LabelReading`.
- In the app, `LabelReader` runs Vision text recognition on every device and feeds the parser. Where `SystemLanguageModel` is available, it also asks the on-device model with the image attached (`Attachment(cgImage)`, confirmed in the iOS 27 SDK) for structured output, and prefers that result.
- The result prefills `OwnFoodForm`. Nothing is saved without the user tapping Save. Images aren't kept.

**Tech Stack:** Swift 6.4, SwiftUI, Vision (`RecognizeTextRequest`), FoundationModels (iOS 27 image attachments, `@Generable`), PhotosUI, Swift Testing, XCUITest.

**Spec:** `docs/superpowers/specs/2026-10-31-carb-bowl-design.md` ("Photo capture (v1)", "Net carbs everywhere"). Builds on plan 2 (`docs/superpowers/plans/2026-10-31-ios-app-core.md`).

## Global Constraints

- **Net carbs.**
  - US labels: total carbohydrate minus dietary fiber. When fiber isn't found, use the total and say so.
  - EU labels: "Carbohydrate" already excludes fibre and is used as is.
- **Always confirm.** A reading only prefills the form. The confirm copy, exactly:
  - "Read from the label. Check the numbers before saving."
  - "Couldn't find fiber, so this uses total carbs." (US, no fiber)
  - "Couldn't read the label. Fill in what you can." (nothing usable)
- Carbs in the form are whole grams, rounded.
- **Images.** Never written to disk or SwiftData. They're released after reading.
- **No network.** The model path is on-device only (`SystemLanguageModel.default`), never Private Cloud Compute.
- **Devices without Apple Intelligence** get everything through Vision and the parser.
- Camera permission string: "Photograph a nutrition label to add a food."

## Review Focus

1. **Noisy recognized text:** "Total Carb. 12g", "Total Carbohydrates 12 g", "Carbohydrate 12g 4%", "Dietary Fiber 0g", and "Fibre 2.5 g" with a decimal comma ("2,5 g"). Each parses correctly. Test in Task 2.
2. **EU per-100g plus per-portion columns:** the per-portion value is chosen and labelled with its portion ("per portion (30g)"). With only per-100g, the label is "100g". Test in Task 2.
3. **Fiber larger than total** (bad recognition) or a negative net: net is floored at 0 and the reading is marked unreliable, with no fiber subtracted. Test in Task 2.
4. **Model unavailable, or it throws** (simulator, old device, Apple Intelligence off): the Vision reading is used and there's no error on screen. Test in Task 3 (`LabelReader` with a failing model extractor).
5. **A photo that isn't a label** (blank image): the form opens with the "Couldn't read the label" message and an empty portion. Test in Task 4 UI test via the blank fixture.

---

### Task 1/4: Prep — versioned schema, safe container, cached search

**Files:**
- Create: `ios/Sources/GIBowlCore/Schema.swift`, `ios/Tests/GIBowlCoreTests/SchemaTests.swift`
- Modify: `ios/Sources/GIBowlCore/UserData.swift` (remove `public let schema`), `ios/Tests/GIBowlCoreTests/BowlStoreTests.swift`, `ios/GIBowl/GIBowlApp.swift`, `ios/GIBowl/Views/MainView.swift`

**Interfaces:**
- Produces:
  - `public enum GIBowlSchemaV1: VersionedSchema` (version 1.0.0, models `[CustomFood.self, BowlItem.self]`)
  - `public enum GIBowlMigrationPlan: SchemaMigrationPlan` (schemas `[GIBowlSchemaV1.self]`, stages `[]`)
  - `public func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer`

Behavior:
- **App launch:** call `makeModelContainer()` in a do/catch. On failure, show: "Your saved foods couldn't be opened. Reinstall the app to start fresh." No `try!`.
- **MainView:** hold `FoodSearch` in `@State`. Rebuild it on appear and in `.onChange(of: customFoods)`. Skip searching when the query is empty.

- [ ] **Step 1: Failing test** — `@Test @MainActor func containerBuildsWithMigrationPlan() throws { let c = try makeModelContainer(inMemory: true); #expect(c.schema.entities.count == 2) }`. Switch `BowlStoreTests.MemoryStore` to `makeModelContainer(inMemory: true)`.
- [ ] **Step 2: Run, expect FAIL** — `swift test --package-path ios`.
- [ ] **Step 3: Implement** the schema, the container factory, the app error view, and the cached search.
- [ ] **Step 4: Run, expect PASS.** Run `swift test`, then the UI suite (`timeout 900 xcodebuild … test`), which must stay green.
- [ ] **Step 5: Commit** — `git commit -m "ios: versioned schema, safe container, cached search"`

---

### Task 2/4: Label parser

**Files:** Create `ios/Sources/GIBowlCore/LabelParser.swift`, `ios/Tests/GIBowlCoreTests/LabelParserTests.swift`

**Interfaces:**
- Produces:
  - `public struct LabelReading: Equatable, Sendable`:
    - `servingLabel: String?`
    - `netCarbs: Double?`
    - `totalCarbs: Double?`
    - `fiber: Double?`
    - `format: Format` (`.us | .eu | .unknown`)
    - `fiberMissing: Bool`
    - `unreliable: Bool`
    - `productName: String?`
  - `public enum LabelParser { public static func parse(lines: [String]) -> LabelReading }`

Rules:
- **Normalization.** Lowercase. A decimal comma between digits becomes a dot. Collapse whitespace.
- **US format** if any line matches `total carb`. The total is the first number with an optional `g` after `total carb[a-z.]*`. Fiber comes from `dietary fib(er|re)` or a bare `fib(er|re)`. Serving is the text after `serving size`, trimmed, e.g. "2/3 cup (55g)".
- **EU format** if a line matches `^carbohydrate` and there's no "total carb".
  - Take the numbers on that line. With two or more, use the last as per portion. Find the portion header (`per portion`, `per serving`, `per \d+ ?g` other than 100g) and use it as the serving label, e.g. "per portion (30g)".
  - With one number, the serving label is "100g".
  - Fibre isn't subtracted.
- **Net and flags.**
  - US: `net = total - fiber` when fiber is found and ≤ total.
  - If fiber > total, set `unreliable = true` and `net = total`.
  - If there's no fiber, set `fiberMissing = true` and `net = total`.
  - Net is floored at 0.
- **Product name:** none from Vision. The model path supplies it.

- [ ] **Step 1: Failing tests:**

```swift
@Test func usLabel() {
  let r = LabelParser.parse(lines: ["Nutrition Facts", "8 servings per container", "Serving size 2/3 cup (55g)", "Calories 230", "Total Carbohydrate 37g 13%", "Dietary Fiber 4g 14%", "Total Sugars 12g"])
  #expect(r.format == .us && r.servingLabel == "2/3 cup (55g)" && r.totalCarbs == 37 && r.fiber == 4 && r.netCarbs == 33 && !r.fiberMissing)
}
@Test func usNoisy() {
  #expect(LabelParser.parse(lines: ["Serving Size 1 bar (40 g)", "Total Carb. 24 g", "Fiber 3g"]).netCarbs == 21)
  #expect(LabelParser.parse(lines: ["Total Carbohydrates 12 g"]).fiberMissing)
  #expect(LabelParser.parse(lines: ["Total Carbohydrate 5g", "Dietary Fiber 0g"]).netCarbs == 5)
}
@Test func euLabelPicksPortion() {
  let r = LabelParser.parse(lines: ["Nutrition", "per 100g per portion (30g)", "Energy 1580kJ 474kJ", "Fat 6.0g 1.8g", "Carbohydrate 60,5 g 18,2 g", "of which sugars 20g 6g", "Fibre 8,0g 2,4g"])
  #expect(r.format == .eu && r.servingLabel == "per portion (30g)" && r.netCarbs == 18.2)
}
@Test func euPer100Only() {
  let r = LabelParser.parse(lines: ["Typical values per 100g", "Carbohydrate 12.5g"])
  #expect(r.servingLabel == "100g" && r.netCarbs == 12.5)
}
@Test func fiberAboveTotalIsUnreliable() {
  let r = LabelParser.parse(lines: ["Total Carbohydrate 3g", "Dietary Fiber 8g"])
  #expect(r.unreliable && r.netCarbs == 3)
}
@Test func nothingUsable() {
  let r = LabelParser.parse(lines: ["Hello", "world"])
  #expect(r.netCarbs == nil && r.format == .unknown)
}
```

- [ ] **Step 2: Run, expect FAIL.**  **Step 3: Implement** with `Regex` literals.  **Step 4: Run, expect PASS.**
- [ ] **Step 5: Commit** — `git commit -m "ios: nutrition label parser (US and EU, net carbs)"`

---

### Task 3/4: Reading a label image (Vision + on-device model)

**Files:**
- Create: `ios/GIBowl/Label/LabelReader.swift`, `ios/GIBowl/Label/ModelLabelExtractor.swift`, `ios/GIBowl/Label/LabelFixtures.swift` (DEBUG: renders label text into a `CGImage`)
- Create: `ios/GIBowlTests/LabelReaderTests.swift` (new hosted unit-test target `GIBowlTests` in `project.yml`, added to the scheme's test targets)

**Interfaces:**
- Consumes: `LabelParser`, `LabelReading`
- Produces:
  - `protocol LabelTextRecognizer: Sendable { func lines(in image: CGImage) async throws -> [String] }`, implemented by `VisionTextRecognizer` (`RecognizeTextRequest`, `.accurate`, language correction off).
  - `protocol LabelModelExtractor: Sendable { var isAvailable: Bool { get }; func extract(from image: CGImage) async throws -> LabelReading }`
    - Implemented by `ModelLabelExtractor`: `SystemLanguageModel.default.isAvailable`, a `@Generable struct Extraction { productName: String?; servingLabel: String?; totalCarbohydrateGrams: Double?; dietaryFiberGrams: Double?; isUSLabel: Bool }`, prompt built with `Attachment(image)`.
    - It maps the extraction to a `LabelReading` by applying the same net-carb rules. Put the shared rule into `LabelParser.reading(total:fiber:format:serving:)` in core.
  - `struct LabelReader { init(recognizer:, model:); func read(_ image: CGImage) async -> LabelReading }`
    - Runs Vision and the parser.
    - If `model.isAvailable`, it tries the model. If the model returns `netCarbs != nil`, it returns the model reading, filling `servingLabel` from the Vision reading when the model's is nil. Otherwise it returns the Vision reading.
    - Model errors are swallowed.
  - `enum LabelFixtures { static func image(_ lines: [String]) -> CGImage }` (DEBUG)

Model instructions (exact):
> Read this nutrition label. Report the serving size as printed, total carbohydrate in grams for one serving, and dietary fiber in grams for one serving. If a value isn't printed, leave it empty. Don't guess.

- [ ] **Step 1: Failing tests** (hosted, run on the simulator):

```swift
@Test func readsRenderedUSLabel() async throws {
  let image = LabelFixtures.image(["Nutrition Facts", "Serving size 1 cup (240g)", "Total Carbohydrate 26g", "Dietary Fiber 3g"])
  let r = await LabelReader(recognizer: VisionTextRecognizer(), model: UnavailableModel()).read(image)
  #expect(r.netCarbs == 23 && r.servingLabel == "1 cup (240g)")
}
@Test func modelFailureFallsBackToVision() async throws {
  let image = LabelFixtures.image(["Total Carbohydrate 10g", "Dietary Fiber 2g"])
  let r = await LabelReader(recognizer: VisionTextRecognizer(), model: ThrowingModel()).read(image)
  #expect(r.netCarbs == 8)
}
@Test func modelResultPreferred() async throws {
  let r = await LabelReader(recognizer: StubRecognizer(lines: ["Total Carbohydrate 10g"]), model: StubModel(reading: LabelParser.reading(total: 12, fiber: 2, format: .us, serving: nil))).read(LabelFixtures.image(["x"]))
  #expect(r.netCarbs == 10 && r.fiberMissing == false)
}
@Test func blankImageReadsNothing() async {
  #expect(await LabelReader(recognizer: VisionTextRecognizer(), model: UnavailableModel()).read(LabelFixtures.image([])).netCarbs == nil)
}
```

- [ ] **Step 2: Run, expect FAIL** — `timeout 900 xcodebuild … test -only-testing:GIBowlTests`.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run, expect PASS.** Also log whether `SystemLanguageModel.default.isAvailable` is true on the simulator. If it's false, the real model path can't be exercised here. Record that as a Ruling and list it in the final report as unverified.
- [ ] **Step 5: Commit** — `git commit -m "ios: read label images with Vision and the on-device model"`

---

### Task 4/4: Capture and confirm

**Files:**
- Create: `ios/GIBowl/Label/LabelCaptureButton.swift` (menu: Take Photo / Choose Photo), `ios/GIBowl/Label/CameraPicker.swift` (`UIImagePickerController` wrapper)
- Modify: `ios/GIBowl/Views/OwnFoodForm.swift`, `ios/GIBowl/Views/MainView.swift`, `ios/project.yml` (`INFOPLIST_KEY_NSCameraUsageDescription`), `ios/GIBowlUITests/KitchenFlowTests.swift`

**Interfaces:**
- Consumes: `LabelReader`, `LabelReading`, `LabelFixtures`
- Produces: `OwnFoodForm.apply(_ reading: LabelReading)`. It fills the portion with `servingLabel ?? ""` and the carbs with `netCarbs` rounded, fills the name from `productName` only when the name is empty, and sets the banner text by the rules in Global Constraints.

Behavior:
- **OwnFoodForm** gets a "Read a label" section at the top with `LabelCaptureButton`.
  - The camera option is hidden when `UIImagePickerController.isSourceTypeAvailable(.camera)` is false.
  - A `PhotosPicker` covers choosing a photo.
  - While reading, it shows a `ProgressView("Reading the label…")`.
  - The banner appears above the fields in secondary text. "Couldn't…" messages use the amber text color.
- **Search** gets an "Add from a label" row under "Add your own food". It opens `OwnFoodForm` with capture started.
- **DEBUG only:** the `-labelFixture us|eu|blank` launch argument makes `LabelCaptureButton` show a "Use sample label" item. That item reads a `LabelFixtures` image through the real Vision path, so the UI test exercises recognition end to end.
- Accessibility identifiers: `label.capture`, `label.sample`, `label.banner`.

- [ ] **Step 1: Failing UI tests:**

```swift
func testAddFromUSLabel() {
  let app = XCUIApplication(); app.launchArguments = ["-resetData", "-seedTargets", "45,15", "-labelFixture", "us"]; app.launch()
  search(app, "granola"); app.buttons["own.add"].tap()
  app.buttons["label.capture"].tap(); app.buttons["label.sample"].tap()
  XCTAssertEqual(app.staticTexts["label.banner"].waitForExistence(timeout: 10) ? app.staticTexts["label.banner"].label : "", "Read from the label. Check the numbers before saving.")
  XCTAssertEqual(app.textFields["own.carbs"].value as? String, "33")
  app.buttons["own.save"].tap()
  XCTAssertTrue(app.buttons["portion.2/3 cup (55g)"].waitForExistence(timeout: 5))
}
func testBlankPhotoSaysSo() { /* -labelFixture blank → banner "Couldn't read the label. Fill in what you can." and own.carbs empty */ }
```

The US fixture is the `usLabel` lines from Task 2: 37 − 4 = 33.
- [ ] **Step 2: Run, expect FAIL.**  **Step 3: Implement.**  **Step 4: Run, expect PASS.** Run the full core and UI suites.
- [ ] **Step 5: Commit** — `git commit -m "ios: add a food by photographing its label"`
