import { readFileSync } from 'node:fs';
// Usage: node scripts/usda/gen-portions.mjs <path to FoodData_Central_sr_legacy_food_csv_2018-04/>
const D = new URL('file://' + require_dir(process.argv[2]));
function require_dir(p) { if (!p) { console.error('Pass the SR Legacy CSV folder (https://fdc.nal.usda.gov/download-datasets)'); process.exit(1); } return p.endsWith('/') ? p : p + '/'; }
function csv(name) {
  const text = readFileSync(new URL(name, D), 'utf-8');
  const rows = []; let row = [], f = '', q = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (q) { if (c === '"') { if (text[i + 1] === '"') { f += '"'; i++; } else q = false; } else f += c; }
    else if (c === '"') q = true; else if (c === ',') { row.push(f); f = ''; }
    else if (c === '\n') { row.push(f); rows.push(row); row = []; f = ''; } else if (c !== '\r') f += c;
  }
  const [h, ...rest] = rows; return rest.map(r => Object.fromEntries(h.map((k, i) => [k, r[i]])));
}
export const foods = new Map(csv('food.csv').map(r => [r.fdc_id, r.description]));
const units = new Map(csv('measure_unit.csv').map(r => [r.id, r.name]));
const nut = new Map();
for (const r of csv('food_nutrient.csv')) if (r.nutrient_id === '1005' || r.nutrient_id === '1079') {
  const e = nut.get(r.fdc_id) || {}; e[r.nutrient_id] = +r.amount; nut.set(r.fdc_id, e);
}
const portions = new Map();
for (const r of csv('food_portion.csv')) {
  const u = units.get(r.measure_unit_id); const label = [r.amount, u === 'undetermined' ? '' : u, r.modifier, r.portion_description].filter(Boolean).join(' ');
  (portions.get(r.fdc_id) || portions.set(r.fdc_id, []).get(r.fdc_id)).push({ label, grams: +r.gram_weight });
}
export function info(id) {
  const n = nut.get(id) || {}; const net100 = Math.max(0, (n['1005'] ?? 0) - (n['1079'] ?? 0));
  return { id: +id, desc: foods.get(id), carb: n['1005'], fiber: n['1079'] ?? 0, net100, portions: portions.get(id) || [] };
}
export function search(re) { return [...foods].filter(([, d]) => re.test(d)).map(([id]) => info(id)); }
