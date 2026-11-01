// Hand-curated everyday foods (data/portions.json): net carbs per household portion.
import { readFileSync } from 'node:fs';

const EXTRA_CATEGORIES = ['MEAT, FISH AND EGGS', 'CHEESE', 'FATS AND OILS', 'VEGETABLES'];
const SLUG = /^[a-z0-9]+(-[a-z0-9]+)*$/;

export function loadCanonical() {
  return JSON.parse(readFileSync(new URL('../../data/portions.json', import.meta.url), 'utf-8'));
}

export function validateCanonical(foods, rows) {
  const problems = [];
  const rowIds = new Set(rows.map(r => r.row));
  const categories = new Set([...rows.map(r => r.category), ...EXTRA_CATEGORIES]);
  const seen = new Set();

  for (const f of foods) {
    const at = f.slug ?? '(no slug)';
    if (!SLUG.test(f.slug ?? '')) problems.push(`${at}: slug must be kebab-case`);
    if (seen.has(f.slug)) problems.push(`${at}: duplicate slug`);
    seen.add(f.slug);
    if (!f.name) problems.push(`${at}: missing name`);
    if (!categories.has(f.category)) problems.push(`${at}: unknown category "${f.category}"`);
    if (f.carbSource !== 'usda' && f.carbSource !== 'study') problems.push(`${at}: carbSource must be usda or study`);
    if (f.carbSource === 'usda' && !Number.isInteger(f.fdcId)) problems.push(`${at}: usda foods need an integer fdcId`);

    const portions = f.portions ?? [];
    if (portions.length < 2 || portions.length > 3) problems.push(`${at}: needs 2–3 portions, has ${portions.length}`);
    if (new Set(portions.map(p => p.label)).size !== portions.length) problems.push(`${at}: portion labels must be unique`);
    for (const p of portions) {
      const ok = Number.isFinite(p.carbs) && p.carbs >= 0 && p.carbs <= 150 && Math.round(p.carbs * 10) === p.carbs * 10;
      if (!ok) problems.push(`${at}: portion "${p.label}" carbs ${p.carbs} must be 0–150 with at most one decimal`);
    }

    for (const r of f.studyRows ?? []) {
      if (!rowIds.has(r)) problems.push(`${at}: study row ${r} not found`);
    }
  }
  return problems;
}
