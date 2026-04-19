# GI Lookup PWA — Design Spec

## Overview

A mobile-first Progressive Web App for looking up glycemic index (GI) and glycemic load (GL) values. Designed as a fast, ad-free, offline-capable alternative to existing GI apps. Hosted on Cloudflare Workers.

## Data

- **Source:** 2021 Atkinson et al. international GI/GL tables (~4,000 foods)
- **Format:** Static JSON file bundled with the app
- **Fields per item:**
  - Food name
  - Food category
  - GI value
  - GI classification (low ≤55, medium 56–69, high ≥70)
  - GL value
  - Serving size (g)
  - Carbohydrates per serve (g)

The dataset is static. GI values are determined by lab testing and the international tables are only updated every few years.

- **Data sourcing:** The 2021 Atkinson et al. systematic review (DOI: 10.1093/ajcn/nqac031) publishes the full international GI/GL tables as supplementary material. This data needs to be extracted, cleaned, and converted to JSON. Community datasets on GitHub (e.g., bitmoremedia/mygi) can serve as cross-references or supplements.

## Architecture

- **Stack:** Vanilla HTML/CSS/JS. No framework, no bundler, no build step.
  - `index.html` — app shell and markup
  - `styles.css` — all styles
  - `app.js` — search logic, rendering, interactions
  - `foods.json` — the full dataset
  - `sw.js` — service worker for offline caching
  - `manifest.json` — PWA manifest for Add to Home Screen
- **Search:** Client-side fuzzy search via Fuse.js (loaded from CDN, cached by service worker). Searches food name and category.
- **Hosting:** Cloudflare Workers serving static assets. Single `wrangler deploy`.

## Visual Design

- **Palette:** Warm & Earthy — cream/linen background (#faf6f1), warm browns (#5c4a3a, #3a3028), muted accents (#9a8a7a)
- **Typography:** Georgia, falling back to system serifs. No web font downloads.
- **GI color coding:** The GI number is colored by classification:
  - Low (≤55): sage green (#7a9a5a)
  - Medium (56–69): warm amber (#c4a23a)
  - High (≥70): terracotta (#c26a4a)
- **Cards:** White cards with subtle box-shadow on the cream background
- **Overall feel:** Clean, pleasant, like a well-designed cookbook page

## Interaction

- **Default state:** Search bar with a simple prompt. No categories, no clutter.
- **Search:** Results filter live as you type with ~150ms debounce. No submit button.
- **Result cards:** Each card shows:
  - Food name
  - Serving size and carbs per serve (secondary text)
  - GI value (large, color-coded) with classification label
- **Expanded detail:** Tapping a result card expands it inline to show GL value, food category, and full serving info.
- **Clear:** Clearing the search returns to the welcome state.

## Mobile-First

- Designed for phone use (grocery store, kitchen)
- Full-width search bar, large tap targets, comfortable text sizes
- Works fine on desktop but phone is the priority
- PWA: installable via Add to Home Screen, works fully offline after first load

## PWA Features

- **Service worker:** Caches all static assets (HTML, CSS, JS, JSON, Fuse.js) for offline use
- **Manifest:** App name, icons, theme color, standalone display mode
- **Offline:** Fully functional without network after initial load
