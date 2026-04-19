import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { classifyGI, classifyGL, getGIColor } from '../public/lib.js';

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
