# Food Data Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the broken carb data with a tested pipeline that emits net carbs per household portion for study rows and for a curated set of everyday foods, and switch the website to it.

**Architecture:** Pure ES-module functions in `scripts/lib/` parse Table 1, compute and vet carbs per 100g, assign category-default portions, and validate hand-curated canonical foods. `scripts/build-foods.js` assembles them into one `public/foods.json`, which the website reads now and the iOS app (plan 2) will bundle. The website gets only the display changes needed to show the corrected data.

**Tech Stack:** Node 20+ ES modules, `node:test`, Fuse.js (existing), vanilla JS PWA (existing).

**Spec:** `docs/superpowers/specs/2026-10-31-carb-bowl-design.md` (sections "Data", "Net carbs everywhere", "Built-in everyday foods", "Settled during review").

This is plan 1 of 4. Plans 2 (iOS app core), 3 (photo capture), and 4 (tip jar) follow and consume this plan's `public/foods.json`.

## Global Constraints

- No new runtime dependencies on the website; no build step for `public/`.
- All carb values are **net carbs**. The study's available carbohydrate is used as is. USDA values are total carbohydrate minus dietary fiber, floored at 0.
- `carbsPer100g` = test carbs ÷ test grams × 100, rounded to one decimal.
- `carbsPer100g` is trusted only for categories `FRUIT AND FRUIT PRODUCTS`, `DAIRY PRODUCTS AND ALTERNATIVES`, `BEVERAGES`, `BREADS`. It is dropped if it's > 100 or outside that category's plausible range.
- Study row ids are the Table 1 row number, as the string `s<row>` (e.g. `s1078`). Canonical ids are kebab-case slugs prefixed `c:` (e.g. `c:apple-raw`).
- Household portions: 2–3 per food, plausible household amounts, never study test weights.
- Website display: carbs show as "about Ng", rounded to the nearest 5g, minimum "about 5g". Under 3g shows "a few grams".
- The only website changes allowed: the detail view's carb data, search ordering (canonical first), history id migration, and the service worker cache bump.

## Review Focus

1. **Duplicate study names (76 repeat):** the two rows named "Banana, lady finger (Moraitis, Australia)" must keep distinct ids, and history migration must pick a deterministic one. Test in Task 5 and Task 6.
2. **Implausible ratios:** a row with test weight 0, missing columns, or a ratio > 100 (breakfast cereals reach 131) must end up with no `carbsPer100g` and no portions, never a crash or a huge number. Test in Task 2.
3. **Fruit-category non-fruit:** "Apple juice…", "Apples, dried", and "Orange marmalade…" must get glass, handful, and spoon sizes, not Small/Medium/Large fruit. Test in Task 3.
4. **Canonical food with no study link:** cottage cheese has no GI. The website card must render GI "—" with no classification color, and the output must omit `gi` instead of writing `null` or `NaN`. Test in Task 5 (output) and Task 6 (`formatPortion` with no GI context).
5. **Stale localStorage history:** entries saved by the current site have `name/gi/gl/carbs/serving` and no `id`. They must be matched by name once and rewritten. Entries that match nothing are dropped, not rendered with the old wrong carbs. Test in Task 6.

---

## Output schema (`public/foods.json`)

`buildFoods` (Task 5) returns this, and both the website and the iOS app read it.

```jsonc
{
  "version": 2,
  "foods": [
    {
      "id": "c:apple-raw",          // or "s1078"
      "kind": "canonical",          // or "study"
      "name": "Apple, raw",
      "category": "FRUIT AND FRUIT PRODUCTS",
      "gi": 44,                     // omitted when unknown
      "gl": 7,                      // study rows only; omitted when unknown
      "carbsPer100g": 11.6,         // study rows in trusted categories only
      "carbSource": "usda",         // "usda" | "study"; omitted when there are no portions
      "fdcId": 171688,              // canonical usda foods only
      "portions": [ { "label": "Medium", "carbs": 21.3 } ]   // [] when none; carbs one decimal
    }
  ]
}
```

---

### Task 1: Table 1 parser as a pure module

**Files:**
- Create: `scripts/lib/table1.js`
- Create: `tests/table1.test.js`
- Modify: `scripts/parse-table1.js` (deleted in Task 5; leave it untouched here)

**Interfaces:**
- Produces: `parseTable1(text: string) => StudyRow[]` where `StudyRow = { row: number, name: string, category: string, gi: number, gl: number|null, testCarbs: number|null, testGrams: number|null }`. `testCarbs` and `testGrams` are the raw floats from columns `giIdx + 3` and `giIdx + 4`, unrounded. `category` is normalized (`PASTA and NOODLES` → `PASTA AND NOODLES`). Rows with malformed names are filtered by the same rules as today.

- [ ] **Step 1: Write the failing tests**

```js
// tests/table1.test.js
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { parseTable1 } from '../scripts/lib/table1.js';

const text = readFileSync(new URL('../data/supplementary/table1.txt', import.meta.url), 'utf-8');
const rows = parseTable1(text);

describe('parseTable1', () => {
  it('reads raw apples with test portion columns intact', () => {
    const apple = rows.find(r => r.row === 1078);
    assert.equal(apple.name, 'Apples, raw');
    assert.equal(apple.category, 'FRUIT AND FRUIT PRODUCTS');
    assert.equal(apple.gi, 44);
    assert.equal(apple.gl, 7);
    assert.equal(apple.testCarbs, 50);
    assert.equal(apple.testGrams, 431);
  });
  it('reads a 25g test portion', () => {
    const s = rows.find(r => r.row === 1174);
    assert.equal(s.testCarbs, 25);
    assert.equal(s.testGrams, 925);
  });
  it('row numbers are unique', () => {
    assert.equal(new Set(rows.map(r => r.row)).size, rows.length);
  });
  it('keeps roughly the current food count', () => {
    assert.ok(rows.length >= 2000 && rows.length <= 2100, `got ${rows.length}`);
  });
  it('normalizes the pasta category', () => {
    assert.ok(!rows.some(r => r.category === 'PASTA and NOODLES'));
  });
});
```

- [ ] **Step 2: Run, expect FAIL** — `node --test tests/table1.test.js` → "Cannot find module".

- [ ] **Step 3: Implement `parseTable1`** by moving the line-classification and name-collection logic from `scripts/parse-table1.js` into `scripts/lib/table1.js`. Changes: no file I/O and no `console.log`. `parseDataLine` returns floats via `parseFloat` without `Math.round`, plus `row`. Drop the category-carbs tracking.

- [ ] **Step 4: Run, expect PASS** — `node --test tests/table1.test.js`.

- [ ] **Step 5: Commit** — `git add scripts/lib/table1.js tests/table1.test.js && git commit -m "data: extract Table 1 parser into a tested module"`

---

### Task 2: Carb ratio and plausibility

**Files:**
- Create: `scripts/lib/carbs.js`
- Create: `tests/carbs.test.js`

**Interfaces:**
- Produces:
  - `TRUSTED_CATEGORIES: Set<string>`, exactly the four from Global Constraints.
  - `PLAUSIBLE_RANGE: Record<string, [min: number, max: number]>` in g per 100g: fruit `[1, 85]` (dried fruit reaches ~80), dairy `[2, 70]`, beverages `[2, 70]`, breads `[25, 70]`.
  - `carbsPer100g(testCarbs: number|null, testGrams: number|null) => number|null`. Null when either input is missing, non-finite, or ≤ 0. Otherwise rounded to one decimal.
  - `trustedCarbsPer100g(row: StudyRow) => number|null`. Null unless the category is trusted and the value is ≤ 100 and within `PLAUSIBLE_RANGE`.

- [ ] **Step 1: Write the failing tests**

```js
import { carbsPer100g, trustedCarbsPer100g } from '../scripts/lib/carbs.js';
// carbsPer100g
assert.equal(carbsPer100g(50, 431), 11.6);
assert.equal(carbsPer100g(25, 925), 2.7);
assert.equal(carbsPer100g(50, 0), null);
assert.equal(carbsPer100g(null, 431), null);
assert.equal(carbsPer100g(50, NaN), null);
// trustedCarbsPer100g
const row = (category, testCarbs, testGrams) => ({ row: 1, name: 'x', category, gi: 50, gl: null, testCarbs, testGrams });
assert.equal(trustedCarbsPer100g(row('FRUIT AND FRUIT PRODUCTS', 50, 431)), 11.6);
assert.equal(trustedCarbsPer100g(row('CEREAL GRAINS', 50, 70)), null);          // untrusted category
assert.equal(trustedCarbsPer100g(row('BREADS', 50, 38)), null);                  // 131.6 > 100
assert.equal(trustedCarbsPer100g(row('BREADS', 50, 400)), null);                 // 12.5 below bread range
assert.equal(trustedCarbsPer100g(row('DAIRY PRODUCTS AND ALTERNATIVES', 25, 520)), 4.8);
```

- [ ] **Step 2: Run, expect FAIL** — `node --test tests/carbs.test.js`.
- [ ] **Step 3: Implement** in `scripts/lib/carbs.js`.
- [ ] **Step 4: Run, expect PASS.** Also run `node -e` over `parseTable1` output and print, per trusted category, the count trusted vs dropped. Paste the counts into the commit message body.
- [ ] **Step 5: Commit** — `git commit -m "data: compute and vet carbs per 100g"`

---

### Task 3: Category-default portions for study rows

**Files:**
- Create: `data/category-portions.json`
- Create: `scripts/lib/category-portions.js`
- Create: `tests/category-portions.test.js`

**Interfaces:**
- Consumes: `trustedCarbsPer100g` (Task 2).
- Produces: `portionsForStudyRow(row: StudyRow, rules: CategoryRules) => Portion[]` where `Portion = { label: string, carbs: number }` (one decimal), and `loadCategoryRules() => CategoryRules`, which reads the JSON. Returns `[]` when `trustedCarbsPer100g(row)` is null.

`data/category-portions.json` shape: `{ "<CATEGORY>": [ { "match": "<case-insensitive regex source>" | null, "sizes": [ { "label": string, "grams": number } ] } ] }`. Rules are tried in order (canned before juice, so "Apples, canned in juice" gets cup sizes). The first rule whose `match` tests true against `row.name` wins, and a `null` match is the category's fallback (it must come last). Starting values (the builder may adjust the grams, not the routing):

| Category | match | sizes |
|---|---|---|
| FRUIT | `canned\|tinned\|in juice\|in syrup` | ½ cup 120, 1 cup 240 |
| FRUIT | `juice\|nectar\|drink\|smoothie` | Small glass 150, Large glass 250 |
| FRUIT | `dried\|raisin\|sultana\|prune\|date\b` | Small handful 15, Handful 30 |
| FRUIT | `jam\|spread\|marmalade\|conserve\|compote` | 1 tsp 7, 1 tbsp 20 |
| FRUIT | null | Small 100, Medium 150, Large 200 |
| DAIRY | `milk\|drink\|shake\|smoothie` | Small glass 150, Large glass 250 |
| DAIRY | `ice cream\|frozen` | Small scoop 50, 2 scoops 100 |
| DAIRY | null | ½ cup 120, 1 cup 245 |
| BEVERAGES | null | Small glass 150, Can 355, Large glass 250 |
| BREADS | null | 1 slice 35, 2 slices 70 |

- [ ] **Step 1: Write the failing tests** using real names:

```js
const rules = loadCategoryRules();
const fruit = (name, testCarbs = 50, testGrams = 431) => ({ row: 1, name, category: 'FRUIT AND FRUIT PRODUCTS', gi: 44, gl: 7, testCarbs, testGrams });
assert.deepEqual(portionsForStudyRow(fruit('Apples, raw'), rules).map(p => p.label), ['Small', 'Medium', 'Large']);
assert.equal(portionsForStudyRow(fruit('Apples, raw'), rules)[1].carbs, 17.4);   // 11.6 × 150 / 100
assert.deepEqual(portionsForStudyRow(fruit('Apple juice, Granny Smith, unsweetened', 50, 443), rules).map(p => p.label), ['Small glass', 'Large glass']);
assert.deepEqual(portionsForStudyRow(fruit('Apples, canned in juice', 50, 338), rules).map(p => p.label), ['½ cup', '1 cup']);
assert.deepEqual(portionsForStudyRow(fruit('Apples, dried', 50, 82), rules).map(p => p.label), ['Small handful', 'Handful']);
assert.deepEqual(portionsForStudyRow(fruit('Orange marmalade, bitter orange', 50, 75), rules).map(p => p.label), ['1 tsp', '1 tbsp']);
assert.deepEqual(portionsForStudyRow({ ...fruit('Rice'), category: 'CEREAL GRAINS' }, rules), []);
// every category's last rule has match null
for (const list of Object.values(rules)) assert.equal(list.at(-1).match, null);
```

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement** the JSON and the module. `carbs = Math.round(per100 * grams / 10) / 10`.
- [ ] **Step 4: Run, expect PASS.**
- [ ] **Step 5: Commit** — `git commit -m "data: category-default household portions"`

---

### Task 4: Canonical everyday foods

**Files:**
- Create: `data/portions.json`
- Create: `scripts/lib/canonical.js`
- Create: `tests/canonical.test.js`

**Interfaces:**
- Consumes: `StudyRow[]` (Task 1), used only to check `studyRows` links.
- Produces:
  - `loadCanonical() => CanonicalFood[]`, where `CanonicalFood = { slug: string, name: string, category: string, carbSource: 'usda'|'study', fdcId?: number, studyRows: number[], portions: Portion[] }`.
  - `validateCanonical(foods: CanonicalFood[], rows: StudyRow[]) => string[]`, returning a list of human-readable problems (empty = valid).

`validateCanonical` rules:
- slugs are unique kebab-case.
- `carbSource: 'usda'` requires an integer `fdcId`.
- 2–3 portions, with unique labels.
- every `carbs` is ≥ 0, ≤ 150, and has at most one decimal.
- every `studyRows` entry exists in `rows`.
- `category` is one of the study's categories or one of `MEAT, FISH AND EGGS`, `CHEESE`, `FATS AND OILS`, `VEGETABLES`.

**Seed list.** Net carbs per portion come from USDA FoodData Central (SR Legacy or Foundation), recorded with `fdcId`: total carbohydrate − fiber, one decimal, floored at 0. Link `studyRows` where an obvious study row exists, e.g. `c:apple-raw` → `[1078]`, `c:banana-raw` → `[1088]`.
- Fruit: apple, banana, blueberries, strawberries, raspberries, grapes, orange, pear, peach, mango, pineapple, cherries, kiwi, watermelon, cantaloupe.
- Dairy: cottage cheese (small curd, 2%), plain Greek yogurt, plain yogurt, milk (2%), cheddar, mozzarella.
- Protein: egg, chicken breast, ground beef, salmon, tofu.
- Grains (cooked where applicable): white rice, brown rice, pasta, rolled oats, quinoa, white bread, whole wheat bread, flour tortilla, bagel.
- Starchy vegetables: baked potato, sweet potato, corn.
- Vegetables: broccoli, carrots, spinach, lettuce, tomato, cucumber, bell pepper, green beans.
- Legumes: black beans, chickpeas, lentils.
- Nuts and spreads: almonds, peanuts, walnuts, peanut butter, hummus.

Portion labels are household terms ("1 medium", "½ cup", "1 cup cooked", "1 slice", "1 large egg", "1 oz", "2 tbsp").

- [ ] **Step 1: Write the failing tests**

```js
const foods = loadCanonical();
const rows = parseTable1(text);
assert.deepEqual(validateCanonical(foods, rows), []);
assert.ok(foods.length >= 55);
const cc = foods.find(f => f.slug === 'cottage-cheese');
assert.equal(cc.carbSource, 'usda'); assert.ok(Number.isInteger(cc.fdcId));
assert.ok(cc.portions.every(p => p.carbs < 10));            // ½ cup cottage cheese is a few grams
const rice = foods.find(f => f.slug === 'white-rice-cooked');
const cup = rice.portions.find(p => /1 cup/.test(p.label));
assert.ok(cup.carbs > 35 && cup.carbs < 55);                  // cooked, not dry
assert.deepEqual(foods.find(f => f.slug === 'apple-raw').studyRows, [1078]);
// validator catches problems
assert.match(validateCanonical([{ ...cc, fdcId: undefined }], rows)[0], /fdcId/);
assert.match(validateCanonical([{ ...cc, portions: [cc.portions[0]] }], rows)[0], /portions/);
assert.match(validateCanonical([{ ...cc, studyRows: [999999] }], rows)[0], /999999/);
```

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement `canonical.js`, then research and write `data/portions.json`.** Look up each food's FDC entry and record its `fdcId`. Don't estimate from memory.
- [ ] **Step 4: Run, expect PASS.**
- [ ] **Step 5: Commit** — `git commit -m "data: canonical everyday foods with USDA net carbs"`. In the commit body, note that Mike should review `data/portions.json`.

---

### Task 5: Build script and output

**Files:**
- Create: `scripts/lib/build.js`
- Create: `scripts/build-foods.js`
- Create: `tests/build.test.js`
- Delete: `scripts/parse-table1.js`
- Modify: `DATA-LICENSE.md` (regeneration command), `README.md` (add a "Regenerating the data" line: `node scripts/build-foods.js`), `package.json` (add `"build:data": "node scripts/build-foods.js"`)
- Regenerate: `public/foods.json`

**Interfaces:**
- Consumes: `parseTable1`, `trustedCarbsPer100g`, `portionsForStudyRow`, `loadCategoryRules`, `loadCanonical`, `validateCanonical`.
- Produces: `buildFoods(rows: StudyRow[], canonical: CanonicalFood[], rules: CategoryRules) => { version: 2, foods: OutputFood[] }`, matching the Output schema above.
  - Canonical foods come first, sorted by name; then study rows, sorted by name, then row.
  - A canonical `gi` is the rounded median GI of its linked `studyRows`, omitted if there are none. Canonical foods never carry `gl` or `carbsPer100g`.
  - Study rows carry `carbSource: 'study'` only when they have portions.
- `scripts/build-foods.js` validates (and exits 1 printing the problems if `validateCanonical` returns any), writes `public/foods.json` (pretty-printed), and prints these counts: total, canonical, study with portions, and study without portions.

- [ ] **Step 1: Write the failing tests**

```js
const out = buildFoods(parseTable1(text), loadCanonical(), loadCategoryRules());
assert.equal(out.version, 2);
const ids = out.foods.map(f => f.id);
assert.equal(new Set(ids).size, ids.length);
assert.equal(out.foods[0].kind, 'canonical');
const dupes = out.foods.filter(f => f.kind === 'study' && f.name === 'Banana, lady finger (Moraitis, Australia)');
assert.equal(dupes.length, 2); assert.notEqual(dupes[0].id, dupes[1].id);
const cc = out.foods.find(f => f.id === 'c:cottage-cheese');
assert.ok(!('gi' in cc) && !('gl' in cc));
assert.equal(out.foods.find(f => f.id === 'c:apple-raw').gi, 44);
const rice = out.foods.find(f => f.kind === 'study' && f.category === 'CEREAL GRAINS');
assert.deepEqual(rice.portions, []); assert.ok(!('carbsPer100g' in rice) && !('carbSource' in rice));
for (const f of out.foods) for (const v of Object.values(f)) assert.ok(v !== null && !Number.isNaN(v), `${f.id} has null/NaN`);
```

- [ ] **Step 2: Run, expect FAIL.**
- [ ] **Step 3: Implement** `build.js` and `build-foods.js`. Delete `parse-table1.js`. Update the docs and `package.json`.
- [ ] **Step 4: Run** `npm test` (all pass), then `npm run build:data`. Expect a counts line and a `public/foods.json` that starts with `{"version": 2`.
- [ ] **Step 5: Commit** — `git commit -m "data: build foods.json v2 with portions; retire parse-table1"`

---

### Task 6: Website reads v2 data

**Files:**
- Modify: `public/lib.js` (add exports)
- Modify: `public/app.js` (init, search ordering, `createCard`, history)
- Modify: `public/sw.js` (`CACHE_NAME = 'gi-v8'`)
- Modify: `public/index.html` (About: one sentence on net carbs)
- Test: `tests/lib.test.js`

**Interfaces:**
- Consumes: `public/foods.json` v2 (Task 5).
- Produces (in `public/lib.js`, reused conceptually by the iOS app's Swift equivalents in plan 2):
  - `aboutCarbs(carbs: number) => string` — `< 3` → `"a few grams"`; otherwise `"about " + max(5, round(carbs / 5) * 5) + "g"`.
  - `formatPortion(p: Portion) => string` — `` `${p.label} · ${aboutCarbs(p.carbs)}` ``.
  - `canonicalFirst(hits: {item: OutputFood}[]) => same[]` — stable partition: canonical hits first, each group in Fuse order.
  - `migrateHistory(entries: object[], foods: OutputFood[]) => {id: string}[]` — entries with `id` that still exist are kept. Entries without `id` match by exact `name` to the first food in `foods` order. Unmatched entries are dropped, duplicates removed, order kept.

- [ ] **Step 1: Write the failing tests** (append to `tests/lib.test.js`)

```js
assert.equal(aboutCarbs(2.9), 'a few grams');
assert.equal(aboutCarbs(3), 'about 5g');
assert.equal(aboutCarbs(7.4), 'about 5g');
assert.equal(aboutCarbs(7.5), 'about 10g');
assert.equal(aboutCarbs(21.3), 'about 20g');
assert.equal(formatPortion({ label: 'Medium', carbs: 17.4 }), 'Medium · about 15g');
const A = { id: 'c:apple-raw', kind: 'canonical', name: 'Apple, raw' }, B = { id: 's1088', kind: 'study', name: 'Banana, raw' }, B2 = { id: 's1089', kind: 'study', name: 'Banana, raw' };
assert.deepEqual(canonicalFirst([{ item: B }, { item: A }, { item: B2 }]).map(h => h.item.id), ['c:apple-raw', 's1088', 's1089']);
assert.deepEqual(migrateHistory([{ name: 'Banana, raw', carbs: 15, serving: 250 }, { name: 'Gone food' }, { id: 'c:apple-raw' }, { name: 'Banana, raw' }], [A, B, B2]),
  [{ id: 's1088' }, { id: 'c:apple-raw' }]);
```

- [ ] **Step 2: Run, expect FAIL** — `npm test`.
- [ ] **Step 3: Implement the lib functions, then wire `app.js`:**
  - `init` reads `data.foods` from the v2 file and builds a `Map` of foods by id.
  - Searches pass through `canonicalFirst`.
  - `createCard`: the summary meta line shows the first portion via `formatPortion` (or nothing). The detail replaces "Serving" and "Carbs / serve" with a "Portions" list of `formatPortion` lines, or "Carbs: —" when `portions` is empty. GI shows "—" when absent (`classifyGI(undefined)` already returns null).
  - History stores `{id}` only. On load it runs `migrateHistory`, writes back, and renders from the foods map.
  - Bump `sw.js`.
  - Add the About sentence: "Carbs are net carbs (total carbohydrate minus fiber), shown as rough amounts."
- [ ] **Step 4: Verify.** Run `npm test`, which must pass. Then `npx serve public` and check these by hand:
  - A search for "apple" leads with "Apple, raw" and shows portions like "1 medium · about 20g".
  - A search for "cottage" shows "Cottage cheese" with GI "—".
  - A cereal-grain row shows "Carbs: —".
  - With an old `gi-history` value set in devtools (`[{"name":"Apples, raw","gi":44,"carbs":15,"serving":431}]`), a reload shows it under Recently viewed with the new portions.
- [ ] **Step 5: Commit** — `git commit -m "web: show net carbs per portion from foods.json v2"`. Push to `main`. Deploys are routine per Mike's instructions. Then confirm https://gi.puddingtime.net serves version 2.
