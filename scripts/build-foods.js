// Builds public/foods.json from Table 1, data/category-portions.json and data/portions.json.
import { readFileSync, writeFileSync } from 'node:fs';
import { parseTable1 } from './lib/table1.js';
import { loadCanonical, validateCanonical } from './lib/canonical.js';
import { loadCategoryRules } from './lib/category-portions.js';
import { buildFoods } from './lib/build.js';

const rows = parseTable1(readFileSync(new URL('../data/supplementary/table1.txt', import.meta.url), 'utf-8'));
const canonical = loadCanonical();

const problems = validateCanonical(canonical, rows);
if (problems.length) {
  console.error('data/portions.json has problems:\n  ' + problems.join('\n  '));
  process.exit(1);
}

const out = buildFoods(rows, canonical, loadCategoryRules());
writeFileSync(new URL('../public/foods.json', import.meta.url), JSON.stringify(out, null, 2) + '\n');

const study = out.foods.filter(f => f.kind === 'study');
const withPortions = study.filter(f => f.portions.length).length;
console.log(`foods.json v${out.version}: ${out.foods.length} foods — ${out.foods.length - study.length} canonical, ${withPortions} study with portions, ${study.length - withPortions} study without`);
