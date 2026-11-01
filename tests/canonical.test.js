import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { parseTable1 } from '../scripts/lib/table1.js';
import { loadCanonical, validateCanonical } from '../scripts/lib/canonical.js';

const rows = parseTable1(readFileSync(new URL('../data/supplementary/table1.txt', import.meta.url), 'utf-8'));
const foods = loadCanonical();
const cc = foods.find(f => f.slug === 'cottage-cheese');

describe('canonical foods', () => {
  it('are valid', () => {
    assert.deepEqual(validateCanonical(foods, rows), []);
    assert.ok(foods.length >= 55);
  });
  it('include cottage cheese from USDA, a few grams per portion', () => {
    assert.equal(cc.carbSource, 'usda');
    assert.ok(Number.isInteger(cc.fdcId));
    assert.ok(cc.portions.find(p => p.label === '½ cup').carbs < 10);
  });
  it('use cooked weights for rice', () => {
    const rice = foods.find(f => f.slug === 'white-rice-cooked');
    const cup = rice.portions.find(p => /1 cup/.test(p.label));
    assert.ok(cup.carbs > 35 && cup.carbs < 55);
  });
  it('link apples to the study row', () => {
    assert.deepEqual(foods.find(f => f.slug === 'apple-raw').studyRows, [1078]);
  });
});

describe('validateCanonical', () => {
  it('requires fdcId for usda foods', () => {
    assert.match(validateCanonical([{ ...cc, fdcId: undefined }], rows)[0], /fdcId/);
  });
  it('requires 2–3 portions', () => {
    assert.match(validateCanonical([{ ...cc, portions: [cc.portions[0]] }], rows)[0], /portions/);
  });
  it('rejects unknown study rows', () => {
    assert.match(validateCanonical([{ ...cc, studyRows: [999999] }], rows)[0], /999999/);
  });
  it('rejects duplicate slugs and bad carbs', () => {
    assert.match(validateCanonical([cc, cc], rows).join('\n'), /duplicate/);
    assert.match(validateCanonical([{ ...cc, portions: [{ label: 'a', carbs: -1 }, { label: 'b', carbs: 4.25 }] }], rows).join('\n'), /carbs/);
  });
});
