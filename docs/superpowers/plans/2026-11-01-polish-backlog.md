# Polish Backlog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The rest of the polish list after `2026-11-01-polish-first-pass.md`: calmer search rows, an empty state that teaches, a Lock Screen widget, and the deferred review minors that affect what a person sees. Each task is independent and ships on its own release.

**Architecture:** Same shape as plan 5: pure logic in `GIBowlCore` with Swift Testing, thin SwiftUI on top, UI tests for what the user can see. The widget is a new `GIBowlWidget` extension target in `project.yml` sharing the SwiftData store through an App Group.

**Tech Stack:** Swift 6.4, SwiftUI, WidgetKit, SwiftData (App Group container), Swift Testing, XCUITest, XcodeGen, factory.

**Spec:** `docs/superpowers/specs/2026-10-31-carb-bowl-design.md`. Mike approves tasks from this plan one at a time; nothing here is started until he picks it.

## Global Constraints

- The anti-goals hold: nothing prompts, nags, counts streaks or adds decimals. A widget may show the bowl's state; it may not notify.
- Copy that already exists (state titles, hints, banners) doesn't change.
- Every task ends with the full suites green and `factory release ios`.

## Review Focus

1. **Row splitting on names with unbalanced parentheses** (the parser leaves some): the name shows whole, never an empty first line. Test in Task 1.
2. **Widget with no targets set:** shows "About Ng so far", never a state. Test in Task 3.
3. **Widget after "Start over":** empties within one timeline reload (the app calls `WidgetCenter.reloadTimelines` on every bowl change). Checked by hand in Task 3.
4. **Undo of "Start over" after the app is backgrounded:** the undo offer disappears; the bowl stays cleared (no resurrection on return). Test in Task 4.
5. **Duplicate portion labels on an own food** are rejected at save with a plain message, not silently merged. Test in Task 5.

---

### Task 1/7: Calmer search rows

**Files:** Create `ios/Sources/GIBowlCore/DisplayName.swift`, `ios/Tests/GIBowlCoreTests/DisplayNameTests.swift`; modify `ios/GIBowl/Views/MainView.swift` (`FoodRow`).

**Interfaces:** `public func displayName(_ name: String) -> (title: String, detail: String?)`. Splits a study name into the food and its parenthetical maker/location: the title is the text before the first ` (`; the detail is everything else, parentheses stripped, commas kept. A name with no parenthetical, an unbalanced one, or a title under 3 characters returns `(name, nil)`.

- [ ] Tests: `"Banana, lady finger (Moraitis, Australia)"` → `("Banana, lady finger", "Moraitis, Australia")`; `"Apples, raw"` → no detail; `"+ 50% wheat, separate proving…) Low oat bran…"` (unbalanced) → whole name, nil; `"(Fiordifrutta) jam"` → whole name, nil.
- [ ] `FoodRow` shows the title in body and the detail in `.caption` secondary, two lines max at standard sizes.
- [ ] Commit `"ios: search rows split maker and place from the food"`; release.

---

### Task 2/7: Empty state that teaches

**Files:** Modify `ios/GIBowl/Views/BowlCard.swift`.

Replace "Search for what's going in it." with two serif lines: "Add what's going in, and the bowl says whether it fits your meal or snack number." and "Nothing is tracked past this meal." Keep the "How it works" link from plan 5. UI test: both lines exist on first launch with `-resetData`.

- [ ] Commit `"ios: empty bowl says what it's for"`; release.

---

### Task 3/7: Lock Screen and Home Screen widget

**Files:** Create `ios/GIBowlWidget/` (`GIBowlWidget.swift`, `Info.plist` keys via project.yml), App Group entitlements for both targets; modify `ios/project.yml`, `ios/Sources/GIBowlCore/Schema.swift` (`makeModelContainer(groupIdentifier:)`), `ios/GIBowl/GIBowlApp.swift`, `ios/Sources/GIBowlCore/BowlStore.swift` (reload timelines after each write), `ios/factory.yml` (if the factory needs the extension listed for signing; check `factory doctor`).

**Interfaces:**
- `public struct BowlSnapshot: Codable, Sendable { total: Double; mode: BowlMode; target: Int?; itemCount: Int }` written by `BowlStore` to the App Group's `UserDefaults` on every change (simpler and safer than opening SwiftData from the extension).
- Widget families: `.accessoryRectangular` (Lock Screen: state title + hint), `.systemSmall` (Home: state title, hint, "N items"). Without targets: "About Ng so far". Empty bowl: "No bowl yet".

- [ ] Tests: `BowlSnapshot` round-trips; `BowlStore` writes a snapshot after add/remove/clear (hosted test reading the group defaults).
- [ ] Register the App Group in the portal (`factory profiles --yes` or the portal; **gated, ask Mike**).
- [ ] Commit `"ios: Lock Screen widget shows the bowl's state"`; release.

---

### Task 4/7: Undo for "Start over"

**Files:** Modify `ios/GIBowl/Views/BowlCard.swift`, `ios/Sources/GIBowlCore/BowlStore.swift` (`clear() -> [BowlItemSnapshot]`, `restore(_:)`).

"Start over" clears and shows an inline "Bowl cleared · Undo" row for 6 seconds (a `Task.sleep`, cancelled on scene background). Undo restores the items with their original `addedAt`. No confirmation dialog.

- [ ] Tests: `clear` returns snapshots; `restore` brings them back in order. UI test: Start over → Undo → items are back.
- [ ] Commit `"ios: undo Start over"`; release.

---

### Task 5/7: Own-food form edge cases

**Files:** Modify `ios/GIBowl/Views/OwnFoodForm.swift`, `ios/Sources/GIBowlCore/LabelParser.swift` (`validateOwnFood(portions:) -> String?`), tests.

- Label changes to "Carbs (net)" with the hint "total carbs minus fiber" (spec copy).
- A second portion with a label but no carbs blocks Save with "Fill in the carbs for the second portion, or clear it."
- Duplicate labels block Save with "Give each portion its own name."
- Portion ids in the detail become `label + carbs` (so two identical portions can't collide even on old data).

- [ ] Commit `"ios: own-food form catches half-filled and duplicate portions"`; release.

---

### Task 6/7: Tip jar leftovers

**Files:** Modify `ios/GIBowl/Tips/TipJar.swift`, `ios/GIBowl/Tips/TipJarSection.swift`, `ios/project.yml`.

- Thanks also after a tip completes through `Transaction.updates`.
- VoiceOver label on the price button: "\(displayName), \(displayPrice)".
- Exclude `Tips.storekit` from the app target's resources (keep it in the test bundle); re-run the hosted tests to confirm `SKTestSession` still finds it.
- `AppStore.canMakePayments == false` shows the unavailable copy instead of buttons.

- [ ] Commit `"ios: tip jar: thanks from updates, VoiceOver names, no test config in the app"`; release.

---

### Task 7/7: Data cleanup (website and app share it)

**Files:** `scripts/lib/table1.js`, `data/portions.json`, `tests/`.

- Trim the worst garbled study names: strip a leading fragment that ends in `)` before the first capitalised food word, and drop rows whose name still starts with punctuation or a lowercase fragment after that. Count before/after in the commit.
- Mike's review of `data/portions.json` lands here (labels, sizes, any foods to add).
- Rebuild `public/foods.json`; website tests; deploy the site with `npm run deploy`; app release.

- [ ] Commit `"data: cleaner study names; portions reviewed"`; deploy; release.
