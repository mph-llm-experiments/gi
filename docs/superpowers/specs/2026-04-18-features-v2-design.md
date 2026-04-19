# GI Lookup PWA — v2 Features Design Spec

## Overview

Three new features for the existing GI Lookup PWA: clear search button, persistent history, and an about page.

## 1. Clear Search

- An "x" button inside the search input, visible only when there's text
- Tapping it clears the input and returns to the welcome state (with history)
- Positioned at the right edge of the search input, styled subtly (warm brown, no border)
- Uses the `.search-container` as a positioning parent

## 2. History

- **Trigger:** Expanding a result card (clicking to show detail) adds that food to history
- **Storage:** `localStorage` under key `gi-history`, stored as a JSON array of food objects (`{ name, gi, gl, category, carbs, serving }`)
- **Deduplication:** If a food is already in history, move it to the top (most recent) rather than duplicating
- **Cap:** Maximum 20 items; oldest items are dropped when the cap is exceeded
- **Display:** On the welcome screen, below the welcome text, show a "Recently viewed" section:
  - Section heading: "Recently viewed" in `--text-secondary` color, small uppercase like `.tagline`
  - Each item rendered as a compact result card (same markup/style as search result cards — food name, GI value, expandable detail)
  - Most recent first
  - "Clear history" link at the bottom of the section, subtle text link
- **Empty state:** If no history, the section is not shown at all
- **Interaction:** History cards expand/collapse the same way search result cards do

## 3. About Page

- **Navigation:** An "About" text link in the header, below the tagline, styled as a subtle link (same color as tagline, underlined on hover)
- **View switching:** Tapping "About" hides the main content (`<main>`) and shows an `#about` section. A "Back" link at the top returns to the main view.
- **Content:**
  - Brief description of the app
  - Data attribution: "Data from Atkinson FS, Brand-Miller JC, Foster-Powell K, Buyken AE, Goletzke J. International tables of glycemic index and glycemic load values 2021. American Journal of Clinical Nutrition. 2021."
  - Note: "GI values determined using ISO 26642:2010 methodology."
  - Link back to the paper (DOI: 10.1093/ajcn/nqac031)
- **Style:** Same warm/earthy typography, max-width 480px, comfortable reading line length

## Files Modified

- `public/index.html` — add about section markup, clear button, history container
- `public/styles.css` — styles for clear button, history section, about page
- `public/app.js` — clear button logic, history read/write/render, about page show/hide
- `public/sw.js` — bump cache version

## No Changes To

- `public/lib.js` — no new pure functions needed
- `public/foods.json` — dataset unchanged
- `wrangler.toml` — deployment config unchanged
