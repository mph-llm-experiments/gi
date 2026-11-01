import Fuse from './vendor/fuse.esm.min.js';
import { classifyGI, getGIColor, formatPortion, canonicalFirst, migrateHistory } from './lib.js';

const MAX_RESULTS = 25;
const DEBOUNCE_MS = 150;
const HISTORY_KEY = 'gi-history';
const MAX_HISTORY = 20;

let fuse;
let foodsById = new Map();
let debounceTimer;

const searchInput = document.getElementById('search');
const welcomeEl = document.getElementById('welcome');
const resultsEl = document.getElementById('results');
const noResultsEl = document.getElementById('no-results');
const loadingEl = document.getElementById('loading');
const clearBtn = document.getElementById('clear-search');
const historyEl = document.getElementById('history');
const aboutEl = document.getElementById('about');
const aboutLink = document.getElementById('about-link');
const aboutBack = document.getElementById('about-back');
const mainEl = document.querySelector('main');

function getHistory() {
  try {
    return JSON.parse(localStorage.getItem(HISTORY_KEY)) || [];
  } catch {
    return [];
  }
}

function saveHistory(history) {
  try {
    localStorage.setItem(HISTORY_KEY, JSON.stringify(history));
  } catch {
    // storage unavailable; history is a convenience
  }
}

function addToHistory(food) {
  const filtered = getHistory().filter(entry => entry.id !== food.id);
  filtered.unshift({ id: food.id });
  if (filtered.length > MAX_HISTORY) filtered.length = MAX_HISTORY;
  saveHistory(filtered);
}

function clearHistoryData() {
  localStorage.removeItem(HISTORY_KEY);
}

function renderHistory() {
  const history = getHistory();
  historyEl.innerHTML = '';

  if (history.length === 0) return;

  const heading = document.createElement('div');
  heading.className = 'history-heading';
  heading.textContent = 'Recently viewed';
  historyEl.appendChild(heading);

  for (const { id } of history) {
    const food = foodsById.get(id);
    if (food) historyEl.appendChild(createCard(food));
  }

  const clearHistoryBtn = document.createElement('button');
  clearHistoryBtn.className = 'clear-history';
  clearHistoryBtn.textContent = 'Clear history';
  clearHistoryBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    clearHistoryData();
    renderHistory();
  });
  historyEl.appendChild(clearHistoryBtn);
}

async function init() {
  const res = await fetch('foods.json');
  const { foods } = await res.json();
  foodsById = new Map(foods.map(f => [f.id, f]));
  saveHistory(migrateHistory(getHistory(), foods));

  fuse = new Fuse(foods, {
    keys: ['name', 'category'],
    threshold: 0.3,
    minMatchCharLength: 2,
  });

  welcomeEl.querySelector('strong').textContent =
    foods.length.toLocaleString();

  // Hide loading, show welcome
  loadingEl.hidden = true;
  welcomeEl.hidden = false;

  searchInput.addEventListener('input', () => {
    clearBtn.hidden = !searchInput.value;
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(handleSearch, DEBOUNCE_MS);
  });

  clearBtn.addEventListener('click', () => {
    searchInput.value = '';
    clearBtn.hidden = true;
    show(welcomeEl);
    searchInput.focus();
  });

  renderHistory();

  aboutLink.addEventListener('click', (e) => {
    e.preventDefault();
    mainEl.hidden = true;
    aboutEl.hidden = false;
  });

  aboutBack.addEventListener('click', (e) => {
    e.preventDefault();
    aboutEl.hidden = true;
    mainEl.hidden = false;
  });
}

function handleSearch() {
  const query = searchInput.value.trim();

  if (!query) {
    show(welcomeEl);
    return;
  }

  const hits = canonicalFirst(fuse.search(query, { limit: MAX_RESULTS }));

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
  loadingEl.hidden = true;
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

  hits.forEach(({ item }, i) => {
    const card = createCard(item);
    card.style.animationDelay = `${i * 0.03}s`;
    resultsEl.appendChild(card);
  });
}

function createCard(food) {
  const classification = classifyGI(food.gi);
  const color = getGIColor(classification);
  const label = classification
    ? classification.charAt(0).toUpperCase() + classification.slice(1) + ' GI'
    : '—';

  const card = document.createElement('div');
  card.className = 'result-card';

  const portions = food.portions ?? [];
  const metaParts = portions.length ? formatPortion(portions[0]) : '';
  const portionsHtml = portions.length
    ? portions.map(p => `<div>${escapeHtml(formatPortion(p))}</div>`).join('')
    : '—';

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
        <div class="detail-content">
          <div class="detail-item">
            <span class="detail-label">Glycemic Load</span>
            <span class="detail-value">${food.gl ?? '—'}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">Category</span>
            <span class="detail-value">${escapeHtml(food.category || '—')}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">Net carbs</span>
            <span class="detail-value">${portionsHtml}</span>
          </div>
        </div>
      </div>
    </div>
  `;

  card.addEventListener('click', () => {
    const wasExpanded = card.classList.contains('expanded');
    card.classList.toggle('expanded');
    if (!wasExpanded) {
      addToHistory(food);
      renderHistory();
    }
  });

  return card;
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

init().catch(() => {
  loadingEl.hidden = true;
  welcomeEl.hidden = false;
  welcomeEl.innerHTML = '<p>Failed to load food data. Please reload.</p>';
});

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js');
}
