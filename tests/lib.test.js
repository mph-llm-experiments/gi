import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { classifyGI, classifyGL, getGIColor, aboutCarbs, formatPortion, canonicalFirst, migrateHistory } from '../public/lib.js';

describe('classifyGI', () => {
  it('returns "low" for GI ≤ 55', () => {
    assert.equal(classifyGI(55), 'low');
    assert.equal(classifyGI(1), 'low');
    assert.equal(classifyGI(32), 'low');
  });

  it('returns "medium" for GI 56–69', () => {
    assert.equal(classifyGI(56), 'medium');
    assert.equal(classifyGI(69), 'medium');
    assert.equal(classifyGI(62), 'medium');
  });

  it('returns "high" for GI ≥ 70', () => {
    assert.equal(classifyGI(70), 'high');
    assert.equal(classifyGI(100), 'high');
    assert.equal(classifyGI(75), 'high');
  });

  it('returns null for missing values', () => {
    assert.equal(classifyGI(null), null);
    assert.equal(classifyGI(undefined), null);
  });
});

describe('classifyGL', () => {
  it('returns "low" for GL ≤ 10', () => {
    assert.equal(classifyGL(10), 'low');
    assert.equal(classifyGL(1), 'low');
  });

  it('returns "medium" for GL 11–19', () => {
    assert.equal(classifyGL(11), 'medium');
    assert.equal(classifyGL(19), 'medium');
  });

  it('returns "high" for GL ≥ 20', () => {
    assert.equal(classifyGL(20), 'high');
    assert.equal(classifyGL(35), 'high');
  });

  it('returns null for missing values', () => {
    assert.equal(classifyGL(null), null);
  });
});

describe('getGIColor', () => {
  it('returns sage green for low', () => {
    assert.equal(getGIColor('low'), '#7a9a5a');
  });

  it('returns warm amber for medium', () => {
    assert.equal(getGIColor('medium'), '#c4a23a');
  });

  it('returns terracotta for high', () => {
    assert.equal(getGIColor('high'), '#c26a4a');
  });

  it('returns default brown for null', () => {
    assert.equal(getGIColor(null), '#5c4a3a');
  });
});

describe('aboutCarbs', () => {
  it('rounds to the nearest 5g with a 5g floor', () => {
    assert.equal(aboutCarbs(3), 'about 5g');
    assert.equal(aboutCarbs(7.4), 'about 5g');
    assert.equal(aboutCarbs(7.5), 'about 10g');
    assert.equal(aboutCarbs(21.3), 'about 20g');
  });
  it('says "a few grams" under 3g', () => {
    assert.equal(aboutCarbs(2.9), 'a few grams');
    assert.equal(aboutCarbs(0), 'a few grams');
  });
});

describe('formatPortion', () => {
  it('joins label and rough carbs', () => {
    assert.equal(formatPortion({ label: 'Medium', carbs: 17.4 }), 'Medium · about 15g');
  });
});

const A = { id: 'c:apple-raw', kind: 'canonical', name: 'Apple, raw' };
const B = { id: 's1088', kind: 'study', name: 'Banana, raw' };
const B2 = { id: 's1089', kind: 'study', name: 'Banana, raw' };

describe('canonicalFirst', () => {
  it('moves canonical hits first, keeping order within groups', () => {
    assert.deepEqual(canonicalFirst([{ item: B }, { item: A }, { item: B2 }]).map(h => h.item.id), ['c:apple-raw', 's1088', 's1089']);
  });
});

describe('migrateHistory', () => {
  it('maps old name entries to ids, drops unknown and duplicates', () => {
    assert.deepEqual(
      migrateHistory([{ name: 'Banana, raw', carbs: 15, serving: 250 }, { name: 'Gone food' }, { id: 'c:apple-raw' }, { name: 'Banana, raw' }], [A, B, B2]),
      [{ id: 's1088' }, { id: 'c:apple-raw' }],
    );
  });
  it('drops ids that no longer exist', () => {
    assert.deepEqual(migrateHistory([{ id: 'sgone' }], [A]), []);
  });
});
