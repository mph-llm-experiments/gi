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

describe('portion routing from review', () => {
  const dairy = (name, testCarbs, testGrams) => ({ row: 1, name, category: 'DAIRY PRODUCTS AND ALTERNATIVES', gi: 40, gl: 5, testCarbs, testGrams });
  const bev = (name, testCarbs, testGrams) => ({ row: 1, name, category: 'BEVERAGES', gi: 40, gl: 5, testCarbs, testGrams });
  it('gives dates handfuls', () => {
    assert.deepEqual(labels(fruit('Dates, Ajwah cultivar, Tamer stage', 50, 70.1)), ['Small handful', 'Handful']);
  });
  it('gives jams made with juice spoons, and date spread spoons', () => {
    assert.deepEqual(labels(fruit('Apricot jam, organic apricot, with apple juice', 50, 129.9)), ['1 tsp', '1 tbsp']);
    assert.deepEqual(labels(fruit('Date spread, Divine', 50, 79.4)), ['1 tsp', '1 tbsp']);
  });
  it('treats nectarines as whole fruit and mandarin juice as juice', () => {
    assert.deepEqual(labels(fruit('Nectarines, raw', 50, 649)), ['Small', 'Medium', 'Large']);
    assert.deepEqual(labels(fruit('Apple and mandarin juice, pure, unsweetened', 50, 454.5)), ['Small glass', 'Large glass']);
  });
  it('drops values implausible for the food type', () => {
    assert.deepEqual(labels(fruit('Apricots, raw, NS', 50, 81.4)), []);
    assert.deepEqual(labels(fruit('Grape Nectar', 50, 63.9)), []);
    assert.deepEqual(labels(fruit('Green Jackfruit, prepared as a porridge with water', 50, 118.5)), []);
  });
  it('drops powders and mixes weighed dry', () => {
    assert.deepEqual(labels(bev('Milo dissolved in water', 50, 73)), []);
    assert.deepEqual(labels(dairy('Butterscotch, prepared from commercial mousse mix with water', 50, 82.5)), []);
  });
  it('gives condensed milk spoons and puddings cups', () => {
    assert.deepEqual(labels(dairy('Milk, condensed, sweetened', 50, 90.3)), ['1 tbsp', '2 tbsp']);
    assert.deepEqual(labels(dairy('Milk rice pudding, Apple & Cinnamon flavor', 50, 238)), ['½ cup', '1 cup']);
  });
  it('never returns a portion above 150g', () => {
    const r = { ...fruit('Raisins', 50, 60), category: 'FRUIT AND FRUIT PRODUCTS' };
    for (const p of portionsForStudyRow(r, rules)) assert.ok(p.carbs <= 150);
  });
});
