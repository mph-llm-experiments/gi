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
