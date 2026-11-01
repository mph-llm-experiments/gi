import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { parseTable1 } from '../scripts/lib/table1.js';

const text = readFileSync(new URL('../data/supplementary/table1.txt', import.meta.url), 'utf-8');
const rows = parseTable1(text);

describe('parseTable1', () => {
  it('reads raw apples with test portion columns intact', () => {
    const apple = rows.find(r => r.row === 1078);
    assert.equal(apple.name, 'Apples, raw');
    assert.equal(apple.category, 'FRUIT AND FRUIT PRODUCTS');
    assert.equal(apple.gi, 44);
    assert.equal(apple.gl, 7);
    assert.equal(apple.testCarbs, 50);
    assert.equal(apple.testGrams, 431);
  });
  it('reads a 25g test portion', () => {
    const s = rows.find(r => r.row === 1174);
    assert.equal(s.testCarbs, 25);
    assert.equal(s.testGrams, 925);
  });
  it('row numbers are unique', () => {
    assert.equal(new Set(rows.map(r => r.row)).size, rows.length);
  });
  it('keeps roughly the current food count', () => {
    assert.ok(rows.length >= 2000 && rows.length <= 2100, `got ${rows.length}`);
  });
  it('normalizes the pasta category', () => {
    assert.ok(!rows.some(r => r.category === 'PASTA and NOODLES'));
  });
});
