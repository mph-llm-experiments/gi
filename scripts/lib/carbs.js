// Carbs per 100g from a study row's test portion, and whether to trust it.
// Test weights are sometimes dry, sometimes cooked (Table 1 footnote 3), so the
// ratio is only used for categories where foods are tested as eaten.

export const TRUSTED_CATEGORIES = new Set([
  'FRUIT AND FRUIT PRODUCTS',
  'DAIRY PRODUCTS AND ALTERNATIVES',
  'BEVERAGES',
  'BREADS',
]);

// Plausible net carbs per 100g, as eaten
export const PLAUSIBLE_RANGE = {
  'FRUIT AND FRUIT PRODUCTS': [1, 85],
  'DAIRY PRODUCTS AND ALTERNATIVES': [2, 70],
  'BEVERAGES': [2, 70],
  'BREADS': [25, 70],
};

export function carbsPer100g(testCarbs, testGrams) {
  if (!Number.isFinite(testCarbs) || !Number.isFinite(testGrams)) return null;
  if (testCarbs <= 0 || testGrams <= 0) return null;
  return Math.round((testCarbs / testGrams) * 1000) / 10;
}

export function trustedCarbsPer100g(row) {
  if (!TRUSTED_CATEGORIES.has(row.category)) return null;
  const value = carbsPer100g(row.testCarbs, row.testGrams);
  if (value == null || value > 100) return null;
  const [min, max] = PLAUSIBLE_RANGE[row.category];
  return value >= min && value <= max ? value : null;
}
