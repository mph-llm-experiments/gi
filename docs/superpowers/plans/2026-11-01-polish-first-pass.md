# Polish, First Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the app read at a glance (state wash on the bowl, GI bands, a real icon) and explain itself (a "How GI Bowl works" screen, per-food provenance, a reason when a food has no carbs), without adding prompts or precision.

**Architecture:** Band and provenance logic go into `GIBowlCore` (pure, tested). Views consume them. The icon is a PNG rendered by a committed Swift script so it can be regenerated. The How-it-works screen is static SwiftUI copy, reachable from Settings and from the empty bowl.

**Tech Stack:** Swift 6.4, SwiftUI, Swift Testing, XCUITest, CoreGraphics (icon script), XcodeGen, factory release.

**Spec:** `docs/superpowers/specs/2026-10-31-carb-bowl-design.md` (anti-goals: no nagging, no false precision, no onboarding carousel). Follows plans 1–4. Plan 6 (`2026-11-01-polish-backlog.md`) holds the rest of the polish list.

## Global Constraints

- No new prompts, badges, counters or onboarding flow. The How-it-works screen is reached only by tapping a link.
- GI bands, exactly as the website: `≤55` Low, `56–69` Medium, `≥70` High. Colors are the existing state colors (sage / amber / terracotta) and their text variants.
- State wash on the bowl: the state color at 10% opacity in light mode and 16% in dark, as the section's row background. Animated with `.animation(.default, value: state)`.
- Provenance copy, exactly: `"USDA FoodData Central · #<fdcId>"`, `"GI study 2021 · row <n>"`, `"Added by you"`.
- No-carbs copy, exactly: `"This food comes from a GI study that didn't weigh it as eaten, so it has no carb amounts. Add your own carbs to use it in a bowl."`
- Icon: 1024×1024 PNG, paper background `#faf6f1`, sage bowl `#7a9a5a`, one amber `#c4a23a` and one terracotta `#c26a4a` berry. No text.
- Every release goes through `factory release ios` from `ios/`.

## Review Focus

1. **GI boundaries:** 55 → Low, 56 → Medium, 69 → Medium, 70 → High, nil → no band. Test in Task 1.
2. **Provenance for a study row whose id isn't `s<digits>`** (defensive; the build never emits one): returns nil, no crash. Test in Task 1.
3. **State wash in dark mode** must not swallow the title text: the title uses `Theme.textColor`, which is the light variant in dark mode. Checked by screenshot in Task 2.
4. **The How-it-works screen at accessibility XXXL:** long paragraphs wrap, nothing truncates (`fixedSize(horizontal: false, vertical: true)` on every Text). Screenshot in Task 3.
5. **Icon on a dark home screen:** the paper background is opaque, so iOS's dark-mode tinting doesn't apply; the bowl must still read at 60pt. Visual check in Task 4.

---

### Task 1/4: GI bands and provenance (core)

**Files:**
- Create: `ios/Sources/GIBowlCore/GIBand.swift`, `ios/Tests/GIBowlCoreTests/GIBandTests.swift`
- Modify: `ios/Sources/GIBowlCore/SearchableFood.swift` (add `provenance`), `ios/Tests/GIBowlCoreTests/FoodSearchTests.swift` (provenance assertions)

**Interfaces:**
- Produces:
  - `public enum GIBand: Sendable { case low, medium, high }` with `public var title: String` ("Low GI" / "Medium GI" / "High GI") and `public var state: BowlState` (low → `.roomToSpare`, medium → `.close`, high → `.over`, so the views reuse `Theme.color` / `Theme.textColor`).
  - `public func giBand(_ gi: Int?) -> GIBand?`
  - `SearchableFood.provenance: String?` — set from `Food`: `fdcId` → USDA copy; `id` matching `^s(\d+)$` → study copy; custom init → "Added by you"; otherwise nil.
  - `SearchableFood.hasNoCarbData: Bool` — `source == .dataset && portions.isEmpty`.

- [ ] **Step 1: Failing tests**

```swift
@Test(arguments: [(55, GIBand.low), (56, .medium), (69, .medium), (70, .high), (1, .low), (100, .high)])
func bands(_ gi: Int, _ band: GIBand) { #expect(giBand(gi) == band) }
@Test func noGINoBand() { #expect(giBand(nil) == nil) }
@Test func bandTitlesAndStates() {
  #expect(GIBand.medium.title == "Medium GI"); #expect(GIBand.high.state == .over)
}
// in FoodSearchTests, using the real catalog:
@Test func provenanceReadsFromTheFood() {
  let usda = SearchableFood(food: catalog["c:cottage-cheese"]!)
  #expect(usda.provenance == "USDA FoodData Central · #172182")
  let study = SearchableFood(food: catalog["s1078"]!)
  #expect(study.provenance == "GI study 2021 · row 1078")
  #expect(fage.provenance == "Added by you")
  #expect(study.hasNoCarbData == false)
  #expect(SearchableFood(food: catalog.foods.first { $0.kind == .study && $0.portions.isEmpty }!).hasNoCarbData)
}
```

- [ ] **Step 2: Run, expect FAIL** — `swift test --package-path ios`.
- [ ] **Step 3: Implement.** `provenance` is computed in the initializers and stored.
- [ ] **Step 4: Run, expect PASS.**
- [ ] **Step 5: Commit** — `git commit -m "ios: GI bands and per-food provenance"`

---

### Task 2/4: State wash, GI bands in the UI, provenance and the no-carbs reason

**Files:** Modify `ios/GIBowl/Theme.swift` (`wash(_:)`), `ios/GIBowl/Views/BowlCard.swift`, `ios/GIBowl/Views/MainView.swift` (`FoodRow`), `ios/GIBowl/Views/FoodDetailView.swift`, `ios/GIBowlUITests/KitchenFlowTests.swift`.

**Interfaces:**
- Consumes: `giBand`, `GIBand`, `SearchableFood.provenance`, `.hasNoCarbData`
- Produces: `Theme.wash(_ state: BowlState?) -> Color` (state color at `Theme.washOpacity`, which is 0.10 light / 0.16 dark via `Color(uiColor:)` dynamic provider; `.clear` for nil).

Behavior:
- **BowlCard:** every row in the non-empty bowl section gets `.listRowBackground(Theme.wash(state))`; the status row animates on state change. The compact (searching) status row gets the same wash.
- **FoodRow:** the trailing "GI 44" becomes a 10pt circle in `Theme.color(band.state)` followed by the number in secondary text; nil GI shows "—" with no circle. Accessibility label: "GI 44, Low GI".
- **FoodDetailView:** the GI stat shows the number with the band word beneath it in `Theme.textColor(band.state)` ("Low GI"); GL stays as is. Under the portions (or under the no-portions text) a footnote in `.caption`/secondary: the provenance. For `hasNoCarbData`, replace "This food doesn't have carb amounts." with the Global Constraints no-carbs copy; the "Add carbs for this" button stays.
- Accessibility identifiers: `detail.band`, `detail.provenance`.

- [ ] **Step 1: Failing UI test additions** (in `testCanIAddFruitToCottageCheese` after opening cottage cheese, and a new test):

```swift
XCTAssertEqual(app.staticTexts["detail.provenance"].label, "USDA FoodData Central · #172182")
func testStudyFoodShowsBandAndReason() {
  let app = XCUIApplication(); app.launchArguments = ["-resetData"]; app.launch()
  open(app, "apples raw", "Apples, raw")
  XCTAssertEqual(app.staticTexts["detail.band"].label, "Low GI")
  XCTAssertEqual(app.staticTexts["detail.provenance"].label, "GI study 2021 · row 1078")
  open(app, "jasmine rice", "Jasmine rice, cooked in rice cooker (SunRice; Ricegrowers Ltd., NSW, Australia)")
  XCTAssertTrue(app.staticTexts["This food comes from a GI study that didn't weigh it as eaten, so it has no carb amounts. Add your own carbs to use it in a bowl."].exists)
}
```

- [ ] **Step 2: Run, expect FAIL.**  **Step 3: Implement.**  **Step 4: Run, expect PASS**, then screenshot the bowl in each state (light and dark via `xcrun simctl ui <udid> appearance dark`) and look at them once.
- [ ] **Step 5: Commit** — `git commit -m "ios: state wash on the bowl, GI bands, provenance, a reason for missing carbs"`

---

### Task 3/4: "How GI Bowl works"

**Files:** Create `ios/GIBowl/Views/HowItWorksView.swift`; modify `ios/GIBowl/Views/SettingsView.swift` (NavigationLink in About), `ios/GIBowl/Views/BowlCard.swift` (a "How it works" link under the empty-state copy), `ios/GIBowlUITests/KitchenFlowTests.swift`.

Content, as sections with a serif heading and one or two short paragraphs each (`fixedSize(horizontal: false, vertical: true)` on every Text):
1. **The bowl.** "Pick Meal or Snack, add what's going in, and the bowl says where you stand against your number: Room to spare, Close to your number, or Over your number. When the bowl's eaten, start over. Nothing is tracked past this meal."
2. **About Ng.** "Every amount is rounded to the nearest 5 grams on purpose. Portions are eyeballed, labels are approximate, and a number like 23.4g would suggest a precision nobody has. If you want to be careful, treat Close as Over."
3. **Net carbs.** "Carbs here are net carbs: total carbohydrate minus fiber. US labels list the total, so the label reader subtracts fiber when it can find it. EU labels already leave fiber out."
4. **GI and GL.** The website's copy: bands 0–55 Low, 56–69 Medium, 70+ High, with the colored band words; GL in one sentence. "GI is shown as background. The bowl measures carbs, not GI."
5. **Reading a label.** "Photograph the nutrition panel. The app reads serving size, total carbohydrate and fiber on your phone, fills the form, and asks you to check it. The photo is discarded. On phones with Apple Intelligence, the on-device model helps read the label; it isn't required."
6. **Where the numbers come from.** Everyday foods: USDA FoodData Central (public domain). GI values: the 2021 international tables (citation, DOI link). Each food's screen says which.
7. **Privacy.** "No account, no ads, no analytics. Your numbers, your foods and your bowl stay on this phone. Nothing is sent anywhere."

Navigation title "How GI Bowl works"; accessibility identifier `howItWorks` on the screen's first heading.

- [ ] **Step 1: Failing UI test:**

```swift
func testHowItWorksIsReachableAndQuiet() {
  let app = XCUIApplication(); app.launchArguments = ["-resetData"]; app.launch()
  app.buttons["How it works"].tap()                       // from the empty bowl
  XCTAssertTrue(app.staticTexts["howItWorks"].waitForExistence(timeout: 5))
  app.navigationBars.buttons.firstMatch.tap()
  app.buttons["Settings"].tap()
  app.buttons["How GI Bowl works"].tap()
  XCTAssertTrue(app.staticTexts["howItWorks"].waitForExistence(timeout: 5))
}
```

- [ ] **Step 2: Run, expect FAIL.**  **Step 3: Implement.**  **Step 4: Run, expect PASS**; screenshot at XXXL.
- [ ] **Step 5: Commit** — `git commit -m "ios: How GI Bowl works"`

---

### Task 4/4: App icon, then release

**Files:** Create `ios/scripts/render-icon.swift`; regenerate `ios/GIBowl/Assets.xcassets/AppIcon.appiconset/icon-1024.png`.

- [ ] **Step 1: Write the script.** CoreGraphics, no dependencies: 1024² canvas, paper fill; a bowl as the lower half of an ellipse (centre 512×560, radii 300×260) in sage with a 22pt darker rim (`#55723a`) and a small foot; two berries (r 54) at (430, 420) amber and (560, 400) terracotta, slightly overlapping the rim so they sit in the bowl. Writes PNG via `CGImageDestination`. Run with `swift ios/scripts/render-icon.swift ios/GIBowl/Assets.xcassets/AppIcon.appiconset/icon-1024.png`.
- [ ] **Step 2: Run it, look at the PNG once**, adjust once if the bowl reads badly at small size (view it scaled to 120px).
- [ ] **Step 3: Build for the simulator and screenshot the home screen** (`xcrun simctl io <udid> screenshot` after `simctl launch` of the home screen) to see it at 60pt.
- [ ] **Step 4: Commit** — `git commit -m "ios: app icon"`.
- [ ] **Step 5: Full suites** (`swift test`, hosted, UI), then `factory release ios` from `ios/`, push.
