# GI Bowl — Native iOS App Design

*Working name. The final App Store name is still open.*

## Intent

Mike's physician gave him a carb target per meal and a different one per snack. The moment this serves: standing in the kitchen with cottage cheese in a bowl, wondering if he can add a fruit. The question is "roughly, am I still under my number?", not "exactly how many grams is this?"

The app should be free, useful, and clean. The existing GI and carb apps are "shitty and opportunistic": ad-driven, nagging. This one should be "a clean, simple experience that isn't nagging me to do anything and respects my time." It's for Mike first, and for the App Store someday, with an optional tip jar.

Mockup of the bowl interaction (a throwaway web prototype, for feel only): https://claude.ai/artifact/K24XaM2U3UBRb9TTzthAou

## What it is

An iPhone app built around **the bowl**: one meal or snack being put together right now.

1. Pick Meal or Snack.
2. Search for foods, or photograph a label, and add them in rough household sizes.
3. See a plain-language state: **Room to spare / Close to your number / Over your number**.
4. Before adding, each portion option shows where the bowl would land. That's the "can I add this?" answer and the core of the app.

GI lookup (search, GI/GL values, low/medium/high) comes along, so the app also covers what gi.puddingtime.net does. GI is background context. The carb target is the main thing.

## Goals

- Answer "can I add this?" in a few taps, while standing in the kitchen.
- Eyeball portions only (small / medium / large, ½ cup, a handful). Never a gram input.
- Foods that aren't in the data can be added once and reused, by typing them in or by photographing the nutrition label.
- Works fully offline, on device, with no account.

## Non-goals (v1)

- No daily log, meal history, or totals across meals. When the bowl is eaten, it's done.
- No bowl-level GL total.
- No iPad, Mac, or Watch layouts. iPhone only. (iPad may run the iPhone layout.)
- No sync, no account, no server.
- No changes to gi.puddingtime.net beyond the shared data fix (see "Data").
- No cleanup of the garbled food names from the PDF parse. That's separate work.

## Anti-goals

These make it a failure even if it technically works:

- **False precision.** No decimals, no "23.4g of 30g", no gram fields. Carbs display as "about Ng", rounded to the nearest 5g (minimum shown "about 5g"; under 3g shows "a few grams"). Over-precision "will discourage me from using it or cause me to spiral when it is not precise."
- **Nagging.** No notifications, no rating or review prompts, no onboarding carousel, no streaks, no "you went over" language, and no tip prompts. Being over is information, not failure.
- **Opportunism.** No ads, no analytics, no tracking, no third-party SDKs, no data leaving the device. App Store privacy label: Data Not Collected.
- **Health advice.** The app never recommends targets or foods. The targets are the user's own, and the app only reports where the bowl stands against them. (This also keeps App Store health-app review simple.)

## Constraints and how it's built

- **Platform (Mike's choice):** a fully native app, not a web view. SwiftUI.
- **My defaults:** iOS 27 minimum (label reading uses iOS 27's Foundation Models image input). Swift 6 concurrency. SwiftData for user data. No third-party dependencies.
- **Location:** `ios/` in this repo, beside the data pipeline it depends on. *(My call.)*
- **Visual language:** carry over the website's warm, cookbook feel from `.impeccable.md`: sage / amber / terracotta for low / medium / high, and a serif display face. Adapt it to native conventions, including Dynamic Type, dark mode and VoiceOver. It should feel like a calm iOS app, not a web page.
- **Devices without Apple Intelligence** must get every feature. The model is an upgrade, never a requirement (see "Photo capture").

## Data

### Fix the carb data (shared with the website)

`scripts/parse-table1.js` reads the test-portion available carbs (25 or 50g, column `giIdx + 3`) and the test-portion weight (`giIdx + 4`), then line 244 overwrites `carbs` with the category's standard portion. The website currently shows, for example, raw apples as "431g serving · 15g carbs", which is about 3× off.

- The parser emits `carbsPer100g` = test carbs ÷ test grams × 100, to one decimal.
- **Dry vs cooked (Mike's decision).** Table 1 footnote 3 says test weights "may refer to dry or wet weight." Cereal grains work out to a median of about 68g per 100g, while cooked rice is about 28. So:
  - `carbsPer100g` is trusted only in categories where weights are as eaten: fruit, dairy, beverages, breads. The builder may extend this after a sanity check.
  - Any value above 100, or otherwise implausible for its category, is dropped.
  - Grains, pasta, cereals and snacks get carbs only from curated portions (below).
- Dataset food ids come from the table's row number, because 76 names repeat.
- The website's detail view switches to the corrected data. That's the only website change. *(My call. Both read the same data.)*

### Household portions

The study has no everyday sizes, so add a hand-curated `data/portions.json`.

- **Per-food entries** store **carbs per portion directly** (label + carbs, from USDA household measures). They don't depend on the study's ratio. Start with raw fruit, then breads, rice, pasta, potato, oats, milk, yogurt, and other common whole foods.
- **Category defaults** (label + grams, multiplied by `carbsPer100g`) apply only to trusted categories. Dried fruit, juices and spreads are routed by name pattern to their own defaults (a small handful, a glass, a spoonful), not whole-fruit sizes.
- 2–3 sizes per food. Values are rough and must be plausible household amounts.
- AI may draft this table and the dry/cooked labels at build time. A person reviews it before it ships.

### Bundling

A build step (in `scripts/`) produces one JSON file that the app bundles: foods, ids, GI, GL, category, `carbsPer100g` where trusted, and portions. The app reads it at launch; it never fetches data.

### Net carbs everywhere (Mike's decision)

Mike's physician said "carbs". Mike is fine counting **net carbs** (total carbohydrate minus fiber). Every number in the app uses that basis:

- The study's available carbohydrate is already close to net and is used as is.
- US labels list total carbohydrate. The label reader also finds Dietary Fiber and subtracts it. If fiber can't be found, it uses the total and says so on the confirm screen.
- EU labels already list carbohydrate without fiber, so it's used as is.
- Typed-in own foods ask for "carbs (net)", with a one-line hint: "total carbs minus fiber".
- The About screen explains net carbs in one sentence.

### Built-in everyday foods (Claude's recommendation, confirmed by Mike)

The study mostly leaves out low-carb staples: plain cottage cheese, eggs, meat, hard cheese, most vegetables, and nearly all nuts. Mike's own kitchen moment hits this gap first. The canonical foods in `portions.json` therefore include a hand-picked set of everyday foods, with net carbs from USDA FoodData Central (public domain). GI is shown only where a study row is linked. Each canonical food records its carb source (`usda` or `study`) so the data's provenance stays traceable for the licensing check.

## The app

### Targets

- Two numbers: meal and snack, in grams. No defaults; these are the user's own numbers.
- Set inline the first time the user adds to a bowl, as two fields and Save. Change them later in Settings.
- Without targets, the bowl shows only the rough total, with no state.

### The bowl

- One current bowl. It persists across launches until "Start over".
- A Meal / Snack switch picks the target and remembers the last choice.
- Shows the state in words, a one-line hint, then the items (name · portion · "about Ng", swipe to remove).
- States, with target `t` and unrounded total `c`:
  - `c < 0.75t` → **Room to spare** (sage). Hint: "Room for about Ng more".
  - `0.75t ≤ c ≤ t` → **Close to your number** (amber). Hint: "Room for about Ng more", or "Right about at it" when under 3g remains.
  - `c > t` → **Over your number** (terracotta). Hint: "Roughly Ng past it".
- Words only, no progress bar. *(My call. A bar invites staring at the number.)*
- Rounding applies only to what's shown. States use the unrounded total.

### Adding food

- Search covers dataset foods and the user's own foods together, with the user's foods marked. Fuzzy, tolerant of typos.
- A food's detail shows its GI, its GL, and portion buttons. Each button is labelled "about Ng" and colored for the state the bowl would land in after adding it. Before targets are set, the buttons are neutral.
- Tap adds the portion. There's no confirmation. Removing an item undoes it.
- Foods without carb data show GI plus "Add carbs for this", which opens the own-food form prefilled with the name.

### Your own foods

- Name, portion label (free text, e.g. "½ cup"), carbs for that portion in whole grams. Optional second portion. Optional GI.
- Editable and deletable. Stable ids.

### Photo capture (v1)

Add your own food by photographing its nutrition label.

- Capture with the camera or pick from Photos.
- **Everywhere:** Vision text recognition plus a deterministic label parser that finds serving size and total carbohydrate. US and EU label formats.
- **With Apple Intelligence:** the Foundation Models on-device model with image input, plus its OCR tool, extracts structured `{ servingLabel, carbsPerServing, productName? }`. Where both paths run, the model's result is preferred.
- Always shows what was read and asks the user to confirm or edit before saving. Never silently saves.
- If nothing usable is found, the form opens with whatever was read, plus a plain message.
- Images aren't kept after extraction.

### Tip jar

- An About screen with a few one-time tip in-app purchases (StoreKit 2, consumables). Mentioned there and nowhere else. No prompts, no badges, no "you've used this 10 times".
- A tip unlocks nothing. Every feature is free.

### Extensibility

Bowl items store `{ foodId, source: dataset | custom, portionLabel, carbs }`, with carbs resolved when the item is added. This keeps the bowl independent of where food data comes from, so a second source (for example USDA) can be added later without migrating anything.

## Launch blockers (before App Store, not before building)

- **Rights to the study data.** `DATA-LICENSE.md` says the compilation is "subject to its copyright terms." Personal use is fine. Distribution in a tip-supported app needs the publisher's permission, or a switch to a public-domain base (USDA FoodData Central) with GI added only where licensing allows. This hasn't been checked yet.
- App name, icon, privacy policy page (it can be one paragraph: nothing is collected), and App Store screenshots.

## Settled during review (my calls)

- **Curated portions attach to canonical foods, not to table rows.** `portions.json` defines canonical foods (e.g. "White rice, cooked", "Apple, raw"), each with its own stable id, portions with carbs per portion, and an optional link to the study rows that supply GI. Search ranks canonical foods above raw table rows, so a search for "rice" leads with a clean entry instead of 15 garbled ones.
- **Website after the fix:** the detail view shows carbs per curated portion where they exist and "—" where they don't. It drops the test-portion "serving" field. The same build script produces the site's `foods.json` and the app's bundle.
- **iOS 27 minimum stands.** WWDC26's image-understanding session and several write-ups confirm image input and an OCR tool. If the shipping API differs, the model path narrows to tidying Vision's recognized text; nothing else changes.
- About 422 of the 2,089 table rows don't parse cleanly at the test-carbs and test-weight columns, so fewer study foods get `carbsPer100g` than the totals suggest. Canonical foods cover the common cases anyway.
- Table row numbers are unique, so they're safe ids for study rows.

## Left to the builder

- Screen structure and navigation, microcopy beyond the state names and hints, and the exact visual treatment.
- Portion values and the category-default table.
- Label-parser heuristics and the Foundation Models prompt and schema.
- Project structure, testing approach (Swift Testing for the pure logic: rounding, states, portion carbs, label parsing), and the build script's format.
