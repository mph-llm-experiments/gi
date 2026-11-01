// Household portions for study rows, from per-category rules in data/category-portions.json.
import { readFileSync } from 'node:fs';
import { trustedCarbsPer100g } from './carbs.js';

export function loadCategoryRules() {
  const raw = JSON.parse(readFileSync(new URL('../../data/category-portions.json', import.meta.url), 'utf-8'));
  const rules = {};
  for (const [category, list] of Object.entries(raw)) {
    rules[category] = list.map(r => ({ ...r, re: r.match == null ? null : new RegExp(r.match, 'i') }));
  }
  return rules;
}

// Test portions weighed dry (powders, mixes) don't describe the food as eaten
const WEIGHED_DRY = /powder|dissolved|prepared (with|from)|\bmix\b/i;
const MAX_PORTION_CARBS = 150;

export function portionsForStudyRow(row, rules) {
  const per100 = trustedCarbsPer100g(row);
  const list = rules[row.category];
  if (per100 == null || !list || WEIGHED_DRY.test(row.name)) return [];
  const rule = list.find(r => r.re == null || r.re.test(row.name));
  if (rule.maxPer100g != null && per100 > rule.maxPer100g) return [];
  const portions = rule.sizes.map(({ label, grams }) => ({
    label,
    carbs: Math.round((per100 * grams) / 10) / 10,
  }));
  return portions.some(p => p.carbs > MAX_PORTION_CARBS) ? [] : portions;
}
