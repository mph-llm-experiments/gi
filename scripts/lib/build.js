// Assembles public/foods.json (v2): canonical everyday foods, then study rows.
import { trustedCarbsPer100g } from './carbs.js';
import { portionsForStudyRow } from './category-portions.js';

function median(values) {
  const s = [...values].sort((a, b) => a - b);
  const mid = Math.floor(s.length / 2);
  return s.length % 2 ? s[mid] : (s[mid - 1] + s[mid]) / 2;
}

const byName = (a, b) => a.name.localeCompare(b.name);

export function buildFoods(rows, canonical, rules) {
  const rowsById = new Map(rows.map(r => [r.row, r]));

  const canonicalFoods = [...canonical].sort(byName).map(c => {
    const food = { id: `c:${c.slug}`, kind: 'canonical', name: c.name, category: c.category };
    const gis = (c.studyRows ?? []).map(r => rowsById.get(r)?.gi).filter(Number.isFinite);
    if (gis.length) food.gi = Math.round(median(gis));
    food.carbSource = c.carbSource;
    if (c.fdcId != null) food.fdcId = c.fdcId;
    food.portions = c.portions.map(({ label, carbs }) => ({ label, carbs }));
    return food;
  });

  const studyFoods = [...rows].sort((a, b) => byName(a, b) || a.row - b.row).map(r => {
    const food = { id: `s${r.row}`, kind: 'study', name: r.name, category: r.category, gi: r.gi };
    if (r.gl != null) food.gl = r.gl;
    const per100 = trustedCarbsPer100g(r);
    const portions = portionsForStudyRow(r, rules);
    if (per100 != null) food.carbsPer100g = per100;
    if (portions.length) food.carbSource = 'study';
    food.portions = portions;
    return food;
  });

  return { version: 2, foods: [...canonicalFoods, ...studyFoods] };
}
