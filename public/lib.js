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

// Rough carb amounts: nearest 5g, never below "about 5g"; under 3g is "a few grams"
export function aboutCarbs(carbs) {
  if (carbs < 3) return 'a few grams';
  return `about ${Math.max(5, Math.round(carbs / 5) * 5)}g`;
}

export function formatPortion(portion) {
  return `${portion.label} · ${aboutCarbs(portion.carbs)}`;
}

// Stable partition: everyday (canonical) foods ahead of study rows
export function canonicalFirst(hits) {
  return [
    ...hits.filter(h => h.item.kind === 'canonical'),
    ...hits.filter(h => h.item.kind !== 'canonical'),
  ];
}

// History entries become {id}. Old entries (name only) match the first food with that name.
export function migrateHistory(entries, foods) {
  const ids = new Set(foods.map(f => f.id));
  const firstByName = new Map();
  for (const f of foods) if (!firstByName.has(f.name)) firstByName.set(f.name, f.id);

  const out = [];
  const seen = new Set();
  for (const entry of entries) {
    const id = entry.id ? (ids.has(entry.id) ? entry.id : null) : firstByName.get(entry.name);
    if (!id || seen.has(id)) continue;
    seen.add(id);
    out.push({ id });
  }
  return out;
}
