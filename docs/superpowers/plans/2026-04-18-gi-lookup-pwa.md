# GI Lookup PWA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a mobile-first PWA for looking up glycemic index and load values, deployed on Cloudflare Workers.

**Architecture:** Single-page vanilla JS app with a static JSON dataset (~4,000 foods). Client-side fuzzy search via Fuse.js. Service worker for full offline support. Cloudflare Workers serves static assets.

**Tech Stack:** Vanilla HTML/CSS/JS (ES modules), Fuse.js for search, Wrangler for Cloudflare deployment, Node test runner for unit tests.

---

## File Structure

```
gi/
├── public/                  # Static assets served by Workers
│   ├── index.html           # App shell and markup
│   ├── styles.css           # Warm & Earthy theme
│   ├── app.js               # Search, rendering, interactions
│   ├── lib.js               # Pure functions (classify, color, format)
│   ├── foods.json           # Full static dataset
│   ├── sw.js                # Service worker for offline caching
│   ├── manifest.json        # PWA manifest
│   ├── icon.svg             # App icon
│   └── vendor/
│       └── fuse.esm.min.js  # Fuse.js (local copy, no CDN dependency)
├── scripts/
│   └── build-data.js        # CSV → JSON converter for real data
├── tests/
│   └── lib.test.js          # Tests for pure functions
├── package.json
├── wrangler.toml
└── .gitignore
```

---

### Task 1: Project Scaffolding

**Files:**
- Create: `package.json`
- Create: `wrangler.toml`
- Create: `.gitignore`
- Create: `public/foods.json` (sample data)

- [ ] **Step 1: Create package.json**

```json
{
  "name": "gi",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "npx wrangler dev",
    "deploy": "npx wrangler deploy",
    "test": "node --test tests/",
    "setup:vendor": "mkdir -p public/vendor && cp node_modules/fuse.js/dist/fuse.mjs public/vendor/fuse.esm.min.js"
  },
  "devDependencies": {
    "wrangler": "^3"
  },
  "dependencies": {
    "fuse.js": "^7.0.0"
  }
}
```

- [ ] **Step 2: Create wrangler.toml**

```toml
#:schema node_modules/wrangler/config-schema.json
name = "gi"
compatibility_date = "2026-04-01"

[assets]
directory = "./public"
```

- [ ] **Step 3: Create .gitignore**

```
node_modules/
.wrangler/
.superpowers/
public/vendor/
```

- [ ] **Step 4: Create sample foods.json**

Create `public/foods.json` with 15 representative foods for development. This is replaced with the full dataset in Task 7.

```json
[
  {
    "name": "White bread",
    "category": "Bakery Products",
    "gi": 75,
    "gl": 11,
    "serving": 30,
    "carbs": 14
  },
  {
    "name": "Whole wheat bread",
    "category": "Bakery Products",
    "gi": 74,
    "gl": 9,
    "serving": 30,
    "carbs": 12
  },
  {
    "name": "Apple, raw",
    "category": "Fruit",
    "gi": 36,
    "gl": 5,
    "serving": 120,
    "carbs": 13
  },
  {
    "name": "Banana, ripe",
    "category": "Fruit",
    "gi": 51,
    "gl": 13,
    "serving": 120,
    "carbs": 25
  },
  {
    "name": "Watermelon, raw",
    "category": "Fruit",
    "gi": 76,
    "gl": 4,
    "serving": 120,
    "carbs": 6
  },
  {
    "name": "White rice, boiled",
    "category": "Cereal Grains",
    "gi": 73,
    "gl": 30,
    "serving": 150,
    "carbs": 40
  },
  {
    "name": "Brown rice, boiled",
    "category": "Cereal Grains",
    "gi": 68,
    "gl": 23,
    "serving": 150,
    "carbs": 33
  },
  {
    "name": "Rolled oats porridge",
    "category": "Cereal Grains",
    "gi": 55,
    "gl": 13,
    "serving": 250,
    "carbs": 24
  },
  {
    "name": "Sweet potato, boiled",
    "category": "Root Vegetables",
    "gi": 46,
    "gl": 11,
    "serving": 150,
    "carbs": 25
  },
  {
    "name": "Potato, boiled",
    "category": "Root Vegetables",
    "gi": 78,
    "gl": 15,
    "serving": 150,
    "carbs": 20
  },
  {
    "name": "Lentils, boiled",
    "category": "Legumes",
    "gi": 32,
    "gl": 5,
    "serving": 150,
    "carbs": 17
  },
  {
    "name": "Chickpeas, canned",
    "category": "Legumes",
    "gi": 42,
    "gl": 9,
    "serving": 150,
    "carbs": 22
  },
  {
    "name": "Spaghetti, white, boiled",
    "category": "Pasta",
    "gi": 49,
    "gl": 24,
    "serving": 180,
    "carbs": 48
  },
  {
    "name": "Corn flakes",
    "category": "Breakfast Cereals",
    "gi": 81,
    "gl": 21,
    "serving": 30,
    "carbs": 26
  },
  {
    "name": "Milk, full fat",
    "category": "Dairy",
    "gi": 27,
    "gl": 3,
    "serving": 250,
    "carbs": 12
  }
]
```

- [ ] **Step 5: Install dependencies and set up vendor**

Run:
```bash
npm install
npm run setup:vendor
```

Expected: `node_modules/` populated, `public/vendor/fuse.esm.min.js` created.

- [ ] **Step 6: Commit**

```bash
git add package.json package-lock.json wrangler.toml .gitignore public/foods.json
git commit -m "scaffold project with sample data and wrangler config"
```

---

### Task 2: Utility Functions (TDD)

**Files:**
- Create: `public/lib.js`
- Create: `tests/lib.test.js`

- [ ] **Step 1: Write failing tests**

Create `tests/lib.test.js`:

```js
import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { classifyGI, classifyGL, getGIColor } from '../public/lib.js';

describe('classifyGI', () => {
  it('returns "low" for GI ≤ 55', () => {
    assert.equal(classifyGI(55), 'low');
    assert.equal(classifyGI(1), 'low');
    assert.equal(classifyGI(32), 'low');
  });

  it('returns "medium" for GI 56–69', () => {
    assert.equal(classifyGI(56), 'medium');
    assert.equal(classifyGI(69), 'medium');
    assert.equal(classifyGI(62), 'medium');
  });

  it('returns "high" for GI ≥ 70', () => {
    assert.equal(classifyGI(70), 'high');
    assert.equal(classifyGI(100), 'high');
    assert.equal(classifyGI(75), 'high');
  });

  it('returns null for missing values', () => {
    assert.equal(classifyGI(null), null);
    assert.equal(classifyGI(undefined), null);
  });
});

describe('classifyGL', () => {
  it('returns "low" for GL ≤ 10', () => {
    assert.equal(classifyGL(10), 'low');
    assert.equal(classifyGL(1), 'low');
  });

  it('returns "medium" for GL 11–19', () => {
    assert.equal(classifyGL(11), 'medium');
    assert.equal(classifyGL(19), 'medium');
  });

  it('returns "high" for GL ≥ 20', () => {
    assert.equal(classifyGL(20), 'high');
    assert.equal(classifyGL(35), 'high');
  });

  it('returns null for missing values', () => {
    assert.equal(classifyGL(null), null);
  });
});

describe('getGIColor', () => {
  it('returns sage green for low', () => {
    assert.equal(getGIColor('low'), '#7a9a5a');
  });

  it('returns warm amber for medium', () => {
    assert.equal(getGIColor('medium'), '#c4a23a');
  });

  it('returns terracotta for high', () => {
    assert.equal(getGIColor('high'), '#c26a4a');
  });

  it('returns default brown for null', () => {
    assert.equal(getGIColor(null), '#5c4a3a');
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `npm test`

Expected: FAIL — `lib.js` does not exist yet.

- [ ] **Step 3: Implement lib.js**

Create `public/lib.js`:

```js
export function classifyGI(gi) {
  if (gi == null) return null;
  if (gi <= 55) return 'low';
  if (gi <= 69) return 'medium';
  return 'high';
}

export function classifyGL(gl) {
  if (gl == null) return null;
  if (gl <= 10) return 'low';
  if (gl <= 19) return 'medium';
  return 'high';
}

const GI_COLORS = {
  low: '#7a9a5a',
  medium: '#c4a23a',
  high: '#c26a4a',
};

export function getGIColor(classification) {
  return GI_COLORS[classification] ?? '#5c4a3a';
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `npm test`

Expected: All 10 tests pass.

- [ ] **Step 5: Commit**

```bash
git add public/lib.js tests/lib.test.js
git commit -m "add GI/GL classification utilities with tests"
```

---

### Task 3: HTML Shell

**Files:**
- Create: `public/index.html`
- Create: `public/icon.svg`

- [ ] **Step 1: Create the app icon**

Create `public/icon.svg`:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" rx="64" fill="#faf6f1"/>
  <rect x="16" y="16" width="480" height="480" rx="52" fill="none" stroke="#e8ddd0" stroke-width="4"/>
  <text x="256" y="300" text-anchor="middle" font-family="Georgia, serif" font-size="220" font-weight="700" fill="#5c4a3a">GI</text>
</svg>
```

- [ ] **Step 2: Create index.html**

Create `public/index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="theme-color" content="#faf6f1">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="default">
  <title>GI Lookup</title>
  <link rel="icon" href="icon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="icon.svg">
  <link rel="manifest" href="manifest.json">
  <link rel="stylesheet" href="styles.css">
</head>
<body>
  <header>
    <h1>GI Lookup</h1>
    <p class="tagline">Glycemic Index Reference</p>
  </header>

  <main>
    <div class="search-container">
      <input
        type="search"
        id="search"
        placeholder="Search foods…"
        autocomplete="off"
        autofocus
      >
    </div>

    <div id="welcome" class="welcome">
      <p>Search over <strong>4,000</strong> foods for glycemic index and load values.</p>
    </div>

    <div id="results" class="results" hidden></div>

    <div id="no-results" class="no-results" hidden>
      <p>No foods found. Try a different search.</p>
    </div>
  </main>

  <script type="module" src="app.js"></script>
</body>
</html>
```

- [ ] **Step 3: Verify it loads**

Run: `npx wrangler dev`

Open `http://localhost:8787` in a browser. Expected: page loads with title, tagline, search bar, and welcome text. No styles yet (plain HTML). Stop the dev server.

- [ ] **Step 4: Commit**

```bash
git add public/index.html public/icon.svg
git commit -m "add HTML shell and app icon"
```

---

### Task 4: CSS — Warm & Earthy Theme

**Files:**
- Create: `public/styles.css`

- [ ] **Step 1: Create styles.css**

Create `public/styles.css`:

```css
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

:root {
  --bg: #faf6f1;
  --bg-card: #ffffff;
  --text: #3a3028;
  --text-secondary: #9a8a7a;
  --text-heading: #5c4a3a;
  --border: #e8ddd0;
  --shadow: rgba(0, 0, 0, 0.06);
  --gi-low: #7a9a5a;
  --gi-medium: #c4a23a;
  --gi-high: #c26a4a;
}

html {
  font-size: 16px;
}

body {
  font-family: Georgia, 'Times New Roman', Times, serif;
  background: var(--bg);
  color: var(--text);
  min-height: 100dvh;
  -webkit-font-smoothing: antialiased;
}

header {
  text-align: center;
  padding: 2rem 1rem 0.5rem;
}

header h1 {
  font-size: 1.75rem;
  color: var(--text-heading);
  font-weight: 600;
  letter-spacing: 0.5px;
}

.tagline {
  font-size: 0.75rem;
  color: var(--text-secondary);
  text-transform: uppercase;
  letter-spacing: 2px;
  margin-top: 0.25rem;
}

main {
  max-width: 480px;
  margin: 0 auto;
  padding: 1rem;
}

/* Search */
.search-container {
  margin-bottom: 1.25rem;
}

#search {
  width: 100%;
  padding: 0.85rem 1rem;
  font-family: Georgia, 'Times New Roman', Times, serif;
  font-size: 1rem;
  color: var(--text);
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 8px;
  box-shadow: 0 1px 3px var(--shadow);
  outline: none;
  transition: border-color 0.2s;
}

#search:focus {
  border-color: var(--text-secondary);
}

#search::placeholder {
  color: var(--text-secondary);
  opacity: 0.7;
}

/* Welcome state */
.welcome {
  text-align: center;
  padding: 3rem 1rem;
  color: var(--text-secondary);
  font-size: 0.95rem;
  line-height: 1.6;
}

.welcome strong {
  color: var(--text-heading);
}

/* No results */
.no-results {
  text-align: center;
  padding: 2rem 1rem;
  color: var(--text-secondary);
  font-size: 0.95rem;
}

/* Result cards */
.results {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.result-card {
  background: var(--bg-card);
  border-radius: 8px;
  box-shadow: 0 1px 3px var(--shadow);
  overflow: hidden;
  cursor: pointer;
  transition: box-shadow 0.2s;
}

.result-card:active {
  box-shadow: 0 1px 6px rgba(0, 0, 0, 0.1);
}

.result-summary {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.875rem 1rem;
  gap: 0.75rem;
}

.result-info {
  flex: 1;
  min-width: 0;
}

.result-name {
  font-size: 0.95rem;
  font-weight: 500;
  color: var(--text);
  line-height: 1.3;
}

.result-meta {
  font-size: 0.75rem;
  color: var(--text-secondary);
  margin-top: 0.2rem;
}

.result-gi {
  text-align: right;
  flex-shrink: 0;
}

.gi-value {
  font-size: 1.4rem;
  font-weight: 700;
  line-height: 1;
}

.gi-label {
  font-size: 0.6rem;
  color: var(--text-secondary);
  text-transform: uppercase;
  letter-spacing: 1px;
  margin-top: 0.2rem;
}

/* Expanded detail */
.result-detail {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.25s ease-out;
}

.result-card.expanded .result-detail {
  max-height: 200px;
  transition: max-height 0.3s ease-in;
}

.detail-inner {
  padding: 0 1rem 0.875rem;
  border-top: 1px solid var(--border);
  padding-top: 0.75rem;
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem 1.5rem;
}

.detail-item {
  display: flex;
  flex-direction: column;
}

.detail-label {
  font-size: 0.6rem;
  text-transform: uppercase;
  letter-spacing: 1px;
  color: var(--text-secondary);
}

.detail-value {
  font-size: 0.9rem;
  color: var(--text);
  margin-top: 0.1rem;
}

/* Results count */
.results-count {
  font-size: 0.75rem;
  color: var(--text-secondary);
  margin-bottom: 0.75rem;
  padding-left: 0.25rem;
}
```

- [ ] **Step 2: Verify styling**

Run: `npx wrangler dev`

Open `http://localhost:8787`. Expected: cream background, serif text, styled search bar, centered layout, warm earthy tones. Stop the dev server.

- [ ] **Step 3: Commit**

```bash
git add public/styles.css
git commit -m "add Warm & Earthy CSS theme"
```

---

### Task 5: Search and Rendering

**Files:**
- Create: `public/app.js`

- [ ] **Step 1: Create app.js**

Create `public/app.js`:

```js
import Fuse from './vendor/fuse.esm.min.js';
import { classifyGI, getGIColor } from './lib.js';

const MAX_RESULTS = 25;
const DEBOUNCE_MS = 150;

let fuse;
let debounceTimer;

const searchInput = document.getElementById('search');
const welcomeEl = document.getElementById('welcome');
const resultsEl = document.getElementById('results');
const noResultsEl = document.getElementById('no-results');

async function init() {
  const res = await fetch('foods.json');
  const foods = await res.json();

  fuse = new Fuse(foods, {
    keys: ['name', 'category'],
    threshold: 0.3,
    minMatchCharLength: 2,
  });

  welcomeEl.querySelector('strong').textContent =
    foods.length.toLocaleString();

  searchInput.addEventListener('input', () => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(handleSearch, DEBOUNCE_MS);
  });
}

function handleSearch() {
  const query = searchInput.value.trim();

  if (!query) {
    show(welcomeEl);
    return;
  }

  const hits = fuse.search(query, { limit: MAX_RESULTS });

  if (hits.length === 0) {
    show(noResultsEl);
    return;
  }

  renderResults(hits);
  show(resultsEl);
}

function show(el) {
  welcomeEl.hidden = el !== welcomeEl;
  resultsEl.hidden = el !== resultsEl;
  noResultsEl.hidden = el !== noResultsEl;
}

function renderResults(hits) {
  resultsEl.innerHTML = '';

  const count = document.createElement('div');
  count.className = 'results-count';
  count.textContent =
    hits.length === MAX_RESULTS
      ? `Showing first ${MAX_RESULTS} results`
      : `${hits.length} result${hits.length === 1 ? '' : 's'}`;
  resultsEl.appendChild(count);

  for (const { item } of hits) {
    resultsEl.appendChild(createCard(item));
  }
}

function createCard(food) {
  const classification = classifyGI(food.gi);
  const color = getGIColor(classification);
  const label = classification
    ? classification.charAt(0).toUpperCase() + classification.slice(1) + ' GI'
    : '—';

  const card = document.createElement('div');
  card.className = 'result-card';

  const servingText = food.serving ? `${food.serving}g serve` : '';
  const carbsText = food.carbs ? `${food.carbs}g carbs` : '';
  const metaParts = [servingText, carbsText].filter(Boolean).join(' · ');

  card.innerHTML = `
    <div class="result-summary">
      <div class="result-info">
        <div class="result-name">${escapeHtml(food.name)}</div>
        ${metaParts ? `<div class="result-meta">${metaParts}</div>` : ''}
      </div>
      <div class="result-gi">
        <div class="gi-value" style="color: ${color}">${food.gi ?? '—'}</div>
        <div class="gi-label">${label}</div>
      </div>
    </div>
    <div class="result-detail">
      <div class="detail-inner">
        <div class="detail-item">
          <span class="detail-label">Glycemic Load</span>
          <span class="detail-value">${food.gl ?? '—'}</span>
        </div>
        <div class="detail-item">
          <span class="detail-label">Category</span>
          <span class="detail-value">${escapeHtml(food.category || '—')}</span>
        </div>
        <div class="detail-item">
          <span class="detail-label">Serving</span>
          <span class="detail-value">${food.serving ? food.serving + 'g' : '—'}</span>
        </div>
        <div class="detail-item">
          <span class="detail-label">Carbs / serve</span>
          <span class="detail-value">${food.carbs ? food.carbs + 'g' : '—'}</span>
        </div>
      </div>
    </div>
  `;

  card.addEventListener('click', () => {
    card.classList.toggle('expanded');
  });

  return card;
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

init();
```

- [ ] **Step 2: Verify search and rendering**

Run: `npx wrangler dev`

Open `http://localhost:8787`. Test the following:

1. Type "rice" — should show "White rice, boiled" and "Brown rice, boiled"
2. Type "fruit" — should match foods in the Fruit category
3. Type "xyzzy" — should show "No foods found"
4. Clear the search — should return to the welcome state
5. Click a result card — should expand to show GL, category, serving, carbs
6. Click it again — should collapse
7. GI numbers should be colored: green (≤55), amber (56–69), terracotta (≥70)

Stop the dev server.

- [ ] **Step 3: Commit**

```bash
git add public/app.js
git commit -m "add search and result rendering with Fuse.js"
```

---

### Task 6: PWA — Service Worker and Manifest

**Files:**
- Create: `public/sw.js`
- Create: `public/manifest.json`

- [ ] **Step 1: Create manifest.json**

Create `public/manifest.json`:

```json
{
  "name": "GI Lookup",
  "short_name": "GI Lookup",
  "description": "Glycemic index and load reference",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#faf6f1",
  "theme_color": "#faf6f1",
  "icons": [
    {
      "src": "icon.svg",
      "sizes": "any",
      "type": "image/svg+xml"
    }
  ]
}
```

- [ ] **Step 2: Create sw.js**

Create `public/sw.js`:

```js
const CACHE_NAME = 'gi-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/styles.css',
  '/app.js',
  '/lib.js',
  '/foods.json',
  '/vendor/fuse.esm.min.js',
  '/manifest.json',
  '/icon.svg',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((cached) => cached || fetch(event.request))
  );
});
```

- [ ] **Step 3: Register the service worker in app.js**

Add the following at the bottom of `public/app.js`, after the `init()` call:

```js
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js');
}
```

- [ ] **Step 4: Verify PWA**

Run: `npx wrangler dev`

Open `http://localhost:8787`. In Chrome DevTools:
1. **Application → Manifest**: should show "GI Lookup" with the correct theme color
2. **Application → Service Workers**: should show sw.js registered
3. **Application → Cache Storage**: should show `gi-v1` with all assets cached
4. **Network → Offline checkbox**: toggle offline, reload — app should still work

Stop the dev server.

- [ ] **Step 5: Commit**

```bash
git add public/sw.js public/manifest.json public/app.js
git commit -m "add PWA service worker and manifest for offline support"
```

---

### Task 7: Data Pipeline

**Files:**
- Create: `scripts/build-data.js`

This task creates a conversion script that transforms CSV source data into the `foods.json` format. The full dataset comes from the 2021 Atkinson et al. systematic review supplementary tables (DOI: 10.1093/ajcn/nqac031).

- [ ] **Step 1: Create build-data.js**

Create `scripts/build-data.js`:

```js
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const INPUT = process.argv[2];
if (!INPUT) {
  console.error('Usage: node scripts/build-data.js <input.csv>');
  console.error('');
  console.error('Expected CSV columns (header row required):');
  console.error('  food_name, food_category, gi, gl, serving_g, carbs_g');
  console.error('');
  console.error('Columns are matched case-insensitively. Extra columns are ignored.');
  process.exit(1);
}

const raw = readFileSync(resolve(INPUT), 'utf-8');
const lines = raw.split('\n').map((l) => l.trim()).filter(Boolean);

const headerLine = lines.shift();
const headers = headerLine.split(',').map((h) => h.trim().toLowerCase());

function col(name) {
  const aliases = {
    food_name: ['food_name', 'food', 'name', 'food name'],
    food_category: ['food_category', 'category', 'food category', 'group'],
    gi: ['gi', 'glycemic_index', 'glycemic index', 'gi_value'],
    gl: ['gl', 'glycemic_load', 'glycemic load', 'gl_value'],
    serving_g: ['serving_g', 'serving', 'serve_g', 'serve size (g)', 'serving size'],
    carbs_g: ['carbs_g', 'carbs', 'carbs_per_serve', 'available carbohydrate'],
  };
  for (const alias of aliases[name]) {
    const idx = headers.indexOf(alias);
    if (idx !== -1) return idx;
  }
  return -1;
}

const nameIdx = col('food_name');
const catIdx = col('food_category');
const giIdx = col('gi');
const glIdx = col('gl');
const servIdx = col('serving_g');
const carbIdx = col('carbs_g');

if (nameIdx === -1 || giIdx === -1) {
  console.error('Error: CSV must have at least food_name and gi columns.');
  console.error('Found headers:', headers.join(', '));
  process.exit(1);
}

const foods = [];
let skipped = 0;

for (const line of lines) {
  const fields = line.split(',').map((f) => f.trim().replace(/^"|"$/g, ''));

  const name = fields[nameIdx];
  const gi = parseFloat(fields[giIdx]);

  if (!name || isNaN(gi)) {
    skipped++;
    continue;
  }

  const food = { name, gi: Math.round(gi) };

  if (catIdx !== -1 && fields[catIdx]) food.category = fields[catIdx];
  if (glIdx !== -1 && fields[glIdx]) food.gl = Math.round(parseFloat(fields[glIdx]));
  if (servIdx !== -1 && fields[servIdx]) food.serving = Math.round(parseFloat(fields[servIdx]));
  if (carbIdx !== -1 && fields[carbIdx]) food.carbs = Math.round(parseFloat(fields[carbIdx]));

  foods.push(food);
}

foods.sort((a, b) => a.name.localeCompare(b.name));

const outPath = resolve(__dirname, '../public/foods.json');
writeFileSync(outPath, JSON.stringify(foods, null, 2));

console.log(`Wrote ${foods.length} foods to ${outPath}`);
if (skipped) console.log(`Skipped ${skipped} rows (missing name or GI)`);
```

- [ ] **Step 2: Test the script with sample CSV**

Create a temporary test file:

```bash
cat > /tmp/test-gi.csv << 'CSV'
food_name,food_category,gi,gl,serving_g,carbs_g
Apple raw,Fruit,36,5,120,13
White rice boiled,Cereal Grains,73,30,150,40
CSV
```

Run: `node scripts/build-data.js /tmp/test-gi.csv`

Expected: "Wrote 2 foods to .../public/foods.json"

Verify the output looks correct:
```bash
cat public/foods.json
```

Expected: sorted JSON array with both foods and all fields populated.

- [ ] **Step 3: Restore sample data**

The test above overwrites `public/foods.json`. Restore the 15-item sample data from Task 1 Step 4 (copy the JSON content back), or use `git checkout public/foods.json`.

- [ ] **Step 4: Commit**

```bash
git add scripts/build-data.js
git commit -m "add CSV-to-JSON data conversion script"
```

- [ ] **Step 5: Source and convert the real dataset**

The full GI/GL dataset can be obtained from either:

1. **Atkinson et al. 2021 supplementary tables** — download the supplementary Excel file from the journal article (DOI: 10.1093/ajcn/nqac031), export the relevant sheet as CSV, then run:
   ```bash
   node scripts/build-data.js path/to/exported.csv
   ```

2. **Community dataset** — clone the [bitmoremedia/mygi](https://github.com/bitmoremedia/mygi) repo and convert its JSON files to the expected CSV format, or adapt `build-data.js` to read their JSON directly.

After converting, verify the output:
```bash
node -e "const f=JSON.parse(require('fs').readFileSync('public/foods.json'));console.log(f.length+' foods loaded')"
```

Expected: ~4,000 foods loaded.

- [ ] **Step 6: Update service worker cache version**

After replacing the dataset, bump the cache version in `public/sw.js`:

```js
const CACHE_NAME = 'gi-v2';
```

- [ ] **Step 7: Commit**

```bash
git add public/foods.json public/sw.js
git commit -m "add full GI/GL dataset from international tables"
```

---

### Task 8: Deploy to Cloudflare

**Files:**
- Modify: `wrangler.toml` (if custom domain desired)

- [ ] **Step 1: Verify locally**

Run: `npx wrangler dev`

Open `http://localhost:8787`. Full end-to-end check:
1. Search works with debounce
2. Results are color-coded
3. Cards expand/collapse
4. Welcome/no-results states work
5. PWA installs (check DevTools → Application → Manifest)
6. Offline mode works (DevTools → Network → Offline → reload)

- [ ] **Step 2: Deploy**

Run: `npx wrangler deploy`

Expected: deployed to `gi.<your-subdomain>.workers.dev`. The URL is printed in the output.

- [ ] **Step 3: Verify production**

Open the deployed URL on your phone:
1. Search works
2. Add to Home Screen (share menu → Add to Home Screen)
3. Open from Home Screen — should launch in standalone mode (no browser chrome)
4. Toggle airplane mode — app should still work

- [ ] **Step 4: Commit any final changes**

```bash
git add -A
git commit -m "final deployment config"
```
