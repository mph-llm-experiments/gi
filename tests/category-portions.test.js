import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { loadCategoryRules, portionsForStudyRow } from '../scripts/lib/category-portions.js';

const rules = loadCategoryRules();
const fruit = (name, testCarbs = 50, testGrams = 431) => ({ row: 1, name, category: 'FRUIT AND FRUIT PRODUCTS', gi: 44, gl: 7, testCarbs, testGrams });
const labels = (row) => portionsForStudyRow(row, rules).map(p => p.label);

describe('portionsForStudyRow', () => {
  it('gives whole fruit small/medium/large', () => {
    assert.deepEqual(labels(fruit('Apples, raw')), ['Small', 'Medium', 'Large']);
    assert.equal(portionsForStudyRow(fruit('Apples, raw'), rules)[1].carbs, 17.4);
  });
  it('routes juice, canned, dried and spreads to their own sizes', () => {
    assert.deepEqual(labels(fruit('Apple juice, Granny Smith, unsweetened', 50, 443)), ['Small glass', 'Large glass']);
    assert.deepEqual(labels(fruit('Apples, canned in juice', 50, 338)), ['½ cup', '1 cup']);
    assert.deepEqual(labels(fruit('Apples, dried', 50, 82)), ['Small handful', 'Handful']);
    assert.deepEqual(labels(fruit('Orange marmalade, bitter orange', 50, 75)), ['1 tsp', '1 tbsp']);
  });
  it('gives untrusted categories no portions', () => {
    assert.deepEqual(portionsForStudyRow({ ...fruit('Rice'), category: 'CEREAL GRAINS' }, rules), []);
  });
  it('ends every category with a fallback rule', () => {
    for (const list of Object.values(rules)) assert.equal(list.at(-1).match, null);
  });
});
