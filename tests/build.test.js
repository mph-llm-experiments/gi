import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { parseTable1 } from '../scripts/lib/table1.js';
import { loadCanonical } from '../scripts/lib/canonical.js';
import { loadCategoryRules } from '../scripts/lib/category-portions.js';
import { buildFoods } from '../scripts/lib/build.js';

const text = readFileSync(new URL('../data/supplementary/table1.txt', import.meta.url), 'utf-8');
const out = buildFoods(parseTable1(text), loadCanonical(), loadCategoryRules());
const byId = id => out.foods.find(f => f.id === id);

describe('buildFoods', () => {
  it('emits version 2 with unique ids, canonical first', () => {
    assert.equal(out.version, 2);
    const ids = out.foods.map(f => f.id);
    assert.equal(new Set(ids).size, ids.length);
    assert.equal(out.foods[0].kind, 'canonical');
  });
  it('keeps duplicate-named study rows distinct', () => {
    const dupes = out.foods.filter(f => f.kind === 'study' && f.name === 'Banana, lady finger (Moraitis, Australia)');
    assert.equal(dupes.length, 2);
    assert.notEqual(dupes[0].id, dupes[1].id);
  });
  it('omits GI for canonical foods without study links', () => {
    const cc = byId('c:cottage-cheese');
    assert.ok(!('gi' in cc) && !('gl' in cc));
  });
  it('takes canonical GI from linked study rows', () => {
    assert.equal(byId('c:apple-raw').gi, 44);
  });
  it('strips source-only fields from portions', () => {
    assert.deepEqual(Object.keys(byId('c:apple-raw').portions[0]).sort(), ['carbs', 'label']);
  });
  it('gives untrusted study rows no portions or ratio', () => {
    const rice = out.foods.find(f => f.kind === 'study' && f.category === 'CEREAL GRAINS');
    assert.deepEqual(rice.portions, []);
    assert.ok(!('carbsPer100g' in rice) && !('carbSource' in rice));
  });
  it('gives trusted study rows a ratio and portions', () => {
    const apple = byId('s1078');
    assert.equal(apple.carbsPer100g, 11.6);
    assert.equal(apple.carbSource, 'study');
    assert.equal(apple.portions.length, 3);
  });
  it('never writes null or NaN', () => {
    for (const f of out.foods) for (const v of Object.values(f)) {
      assert.ok(v !== null && !Number.isNaN(v), `${f.id} has null/NaN`);
    }
  });
});
