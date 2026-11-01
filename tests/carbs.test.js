import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { carbsPer100g, trustedCarbsPer100g } from '../scripts/lib/carbs.js';

const row = (category, testCarbs, testGrams) => ({ row: 1, name: 'x', category, gi: 50, gl: null, testCarbs, testGrams });

describe('carbsPer100g', () => {
  it('divides test carbs by test grams, one decimal', () => {
    assert.equal(carbsPer100g(50, 431), 11.6);
    assert.equal(carbsPer100g(25, 925), 2.7);
  });
  it('returns null for missing, zero or non-finite inputs', () => {
    assert.equal(carbsPer100g(50, 0), null);
    assert.equal(carbsPer100g(null, 431), null);
    assert.equal(carbsPer100g(50, NaN), null);
    assert.equal(carbsPer100g(-5, 100), null);
  });
});

describe('trustedCarbsPer100g', () => {
  it('trusts fruit within range', () => {
    assert.equal(trustedCarbsPer100g(row('FRUIT AND FRUIT PRODUCTS', 50, 431)), 11.6);
    assert.equal(trustedCarbsPer100g(row('DAIRY PRODUCTS AND ALTERNATIVES', 25, 520)), 4.8);
  });
  it('drops untrusted categories', () => {
    assert.equal(trustedCarbsPer100g(row('CEREAL GRAINS', 50, 70)), null);
  });
  it('drops impossible and implausible values', () => {
    assert.equal(trustedCarbsPer100g(row('BREADS', 50, 38)), null);
    assert.equal(trustedCarbsPer100g(row('BREADS', 50, 400)), null);
  });
});
