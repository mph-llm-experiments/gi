import Fuse from './vendor/fuse.esm.min.js';
import { classifyGI, getGIColor } from './lib.js';

const MAX_RESULTS = 25;
const DEBOUNCE_MS = 150;

let fuse;
let debounceTimer;

const searchInput = document.getElementById('search');
const welcomeEl = document.getElementById('welcome');
const resultsEl = document.getElementById('results');
const noResultsEl = document.getElementById('no-results');

async function init() {
  const res = await fetch('foods.json');
  const foods = await res.json();

  fuse = new Fuse(foods, {
    keys: ['name', 'category'],
    threshold: 0.3,
    minMatchCharLength: 2,
  });

  welcomeEl.querySelector('strong').textContent =
    foods.length.toLocaleString();

  searchInput.addEventListener('input', () => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(handleSearch, DEBOUNCE_MS);
  });
}

function handleSearch() {
  const query = searchInput.value.trim();

  if (!query) {
    show(welcomeEl);
    return;
  }

  const hits = fuse.search(query, { limit: MAX_RESULTS });

  if (hits.length === 0) {
    show(noResultsEl);
    return;
  }

  renderResults(hits);
  show(resultsEl);
}

function show(el) {
  welcomeEl.hidden = el !== welcomeEl;
  resultsEl.hidden = el !== resultsEl;
  noResultsEl.hidden = el !== noResultsEl;
}

function renderResults(hits) {
  resultsEl.innerHTML = '';

  const count = document.createElement('div');
  count.className = 'results-count';
  count.textContent =
    hits.length === MAX_RESULTS
      ? `Showing first ${MAX_RESULTS} results`
      : `${hits.length} result${hits.length === 1 ? '' : 's'}`;
  resultsEl.appendChild(count);

  for (const { item } of hits) {
    resultsEl.appendChild(createCard(item));
  }
}

function createCard(food) {
  const classification = classifyGI(food.gi);
  const color = getGIColor(classification);
  const label = classification
    ? classification.charAt(0).toUpperCase() + classification.slice(1) + ' GI'
    : '—';

  const card = document.createElement('div');
  card.className = 'result-card';

  const servingText = food.serving ? `${food.serving}g serve` : '';
  const carbsText = food.carbs ? `${food.carbs}g carbs` : '';
  const metaParts = [servingText, carbsText].filter(Boolean).join(' · ');

  card.innerHTML = `
    <div class="result-summary">
      <div class="result-info">
        <div class="result-name">${escapeHtml(food.name)}</div>
        ${metaParts ? `<div class="result-meta">${metaParts}</div>` : ''}
      </div>
      <div class="result-gi">
        <div class="gi-value" style="color: ${color}">${food.gi ?? '—'}</div>
        <div class="gi-label">${label}</div>
      </div>
    </div>
    <div class="result-detail">
      <div class="detail-inner">
        <div class="detail-item">
          <span class="detail-label">Glycemic Load</span>
          <span class="detail-value">${food.gl ?? '—'}</span>
        </div>
        <div class="detail-item">
          <span class="detail-label">Category</span>
          <span class="detail-value">${escapeHtml(food.category || '—')}</span>
        </div>
        <div class="detail-item">
          <span class="detail-label">Serving</span>
          <span class="detail-value">${food.serving ? food.serving + 'g' : '—'}</span>
        </div>
        <div class="detail-item">
          <span class="detail-label">Carbs / serve</span>
          <span class="detail-value">${food.carbs ? food.carbs + 'g' : '—'}</span>
        </div>
      </div>
    </div>
  `;

  card.addEventListener('click', () => {
    card.classList.toggle('expanded');
  });

  return card;
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

init();
