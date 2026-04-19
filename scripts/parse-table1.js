import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const text = readFileSync(resolve(__dirname, '../data/supplementary/table1.txt'), 'utf-8');
const lines = text.split('\n');

const KNOWN_CATEGORIES = [
  'BAKERY PRODUCTS', 'BEVERAGES', 'BREADS', 'BREAKFAST CEREALS',
  'CEREAL GRAINS', 'COOKIES', 'CRACKERS',
  'DAIRY PRODUCTS AND ALTERNATIVES',
  'FRUIT AND FRUIT PRODUCTS',
  'INFANT FORMULA AND WEANING FOODS',
  'LEGUMES', 'MEAL REPLACEMENT & WEIGHT MANAGEMENT PRODUCTS',
  'NUTRITIONAL SUPPORT PRODUCTS', 'NUTS',
  'PASTA and NOODLES', 'PASTA AND NOODLES',
  'SNACK FOODS AND CONFECTIONERY', 'SOUPS',
  'SUGARS AND SYRUPS', 'VEGETABLES',
  'REGIONAL OR TRADITIONAL FOODS',
];

// Lines to skip
const SKIP_PATTERNS = [
  /^Supplemental Table/,
  /^Atkinson FS/,
  /^Food Number/,
  /^\s*Country of/,
  /^\s*food\s/,
  /^\s*production/,
  /^\s*test\d/,
  /^\s*SEM/,
  /^\s*\(Glu/,
  /^\s*number\)/,
  /^\s*portion\)/,
  /^\s*method/,
  /^\s*\(type/,
  /^\s*\(Test/,
  /^\s*collection/,
  /^\s*GI.{0,5}±/,
  /^\s*Year of/,
  /^\s*Sample$/,
  /^\s*analysis/,
  /^\s*Ref\.$/,
  /^\s*\(g\)/,
  /^\s*period/,
  /^\s*Avail/,
  /^\s*Timepoints/,
  /^\s*food & time/,
  /^\s*Reference/,
];

function isSkipLine(line) {
  const trimmed = line.trim();
  if (!trimmed) return true;
  if (/^\d+$/.test(trimmed)) return true; // page numbers
  return SKIP_PATTERNS.some(p => p.test(trimmed));
}

function isNumberedLine(line) {
  return /^\s{0,5}\d{1,4}\s{2,}/.test(line);
}

function isDataLine(line) {
  return isNumberedLine(line) && line.includes('±');
}

function isMeanLine(line) {
  return /mean of/i.test(line) && !line.includes('±');
}

function isCategoryLine(line) {
  const trimmed = line.trim();
  return KNOWN_CATEGORIES.some(c => trimmed === c);
}

function isSubcategoryLine(line) {
  const trimmed = line.trim();
  // Subcategories like "Cakes", "Beer", "Carbonated beverages/soft drinks"
  // They're short text lines without data, not all-caps categories
  if (!trimmed || trimmed.length > 80) return false;
  if (isCategoryLine(line)) return false;
  if (isDataLine(line)) return false;
  if (/Average available/.test(trimmed)) return false;
  // Check if it looks like a subcategory header (short, no numbers except in parentheses)
  if (/^[A-Z][a-z]/.test(trimmed) && !trimmed.includes('±') && trimmed.length < 60) {
    // Check it's not a food name continuation
    return true;
  }
  return false;
}

// Extract data from a numbered data line using column splitting
function parseDataLine(line) {
  const parts = line.trim().split(/\s{3,}/);

  // Find the part with ±
  const giIdx = parts.findIndex(p => /\d+\s*±\s*\d+/.test(p));
  if (giIdx === -1) return null;

  const giMatch = parts[giIdx].match(/(\d+)\s*±/);
  if (!giMatch) return null;
  const gi = parseInt(giMatch[1]);

  // GL is the next part after GI±SEM (if it's a number)
  const glPart = parts[giIdx + 1];
  const gl = glPart && /^\d+$/.test(glPart.trim()) ? parseInt(glPart.trim()) : null;

  // Row number
  const rowNum = parseInt(parts[0]);

  // Food name: parts between row number and the country/year before GI
  // The year is at giIdx - 1, country at giIdx - 2
  const yearIdx = giIdx - 1;
  const countryIdx = giIdx - 2;

  let foodNameParts = [];
  for (let i = 1; i < countryIdx; i++) {
    foodNameParts.push(parts[i]);
  }
  const nameOnLine = foodNameParts.join(' ').trim();

  // Avail carb (test portion carbs) is at giIdx + 3
  // Test portion (g) is at giIdx + 4
  const carbsPart = parts[giIdx + 3];
  const servingPart = parts[giIdx + 4];
  const carbs = carbsPart && /^[\d.]+$/.test(carbsPart.trim()) ? Math.round(parseFloat(carbsPart.trim())) : null;
  const serving = servingPart && /^[\d.]+$/.test(servingPart.trim()) ? Math.round(parseFloat(servingPart.trim())) : null;

  return { rowNum, nameOnLine, gi, gl, carbs, serving };
}

// Extract food name text from left portion of a line
function extractNameText(line) {
  let text = line.substring(0, 72).trim();
  // Remove row numbers at start
  text = text.replace(/^\d{1,4}\s+/, '');
  // Remove sample collection artifacts from the right
  text = text.replace(/\s+(Capillary|Venous|whole blood|Standard|Enzymatic|HemoCue|YSI).*$/i, '');
  // Remove trailing footnote superscripts
  text = text.replace(/\d+$/, '').trim();
  return text;
}

// Collect food name: use data line name + optionally one preceding line.
// Only look backward if the data line has no food name text.
function collectFoodName(lines, dataLineIdx, nameOnLine) {
  const parts = [];

  // Only look backward if the data line's food name area is empty
  if (!nameOnLine) {
    for (let j = dataLineIdx - 1; j >= Math.max(0, dataLineIdx - 2); j--) {
      const prevLine = lines[j];
      const trimmed = prevLine.trim();

      if (!trimmed) break;
      if (isNumberedLine(prevLine)) break;
      if (isCategoryLine(prevLine)) break;
      if (isMeanLine(prevLine)) break;
      if (isSkipLine(prevLine)) break;
      if (/Average available/.test(trimmed)) break;
      if (/^(Capillary|Venous|whole blood|plasma|serum),?$/i.test(trimmed)) continue;

      const nameText = extractNameText(prevLine);
      if (nameText) parts.unshift(nameText);
    }
  }

  if (nameOnLine) parts.push(nameOnLine);

  // Look forward ONE line for a short continuation (closing parenthesis, location)
  const nextLine = lines[dataLineIdx + 1];
  if (nextLine) {
    const trimmed = nextLine.trim();
    if (trimmed && !isNumberedLine(nextLine) && !isCategoryLine(nextLine)
        && !isMeanLine(nextLine) && !isSkipLine(nextLine)) {
      const nameText = extractNameText(nextLine);
      if (nameText && nameText.length < 50
          && !/^(Capillary|Venous|whole blood|plasma|serum),?$/i.test(trimmed)) {
        parts.push(nameText);
      }
    }
  }

  let name = parts.join(' ').trim().replace(/\s+/g, ' ');

  // Clean up artifacts
  // Remove leading parenthetical metadata (manufacturer, test conditions, subject info)
  // Repeatedly strip leading (...) groups that look like metadata
  while (/^\([^)]{0,80}\)\s+/.test(name)) {
    const stripped = name.replace(/^\([^)]*\)\s*/, '');
    // Only strip if there's still content after
    if (stripped.length > 5) {
      name = stripped;
    } else {
      break;
    }
  }
  // Remove trailing footnote numbers
  name = name.replace(/\d{1,2}$/, '').trim();

  return name;
}

// Main parsing
let category = '';
let categoryCarbs = null;
const foods = [];

for (let i = 0; i < lines.length; i++) {
  const line = lines[i];

  // Track category
  if (isCategoryLine(line)) {
    category = line.trim();
    // Normalize category name
    category = category.replace('PASTA and NOODLES', 'PASTA AND NOODLES');
    continue;
  }

  // Track standardized carb portion
  const carbMatch = line.match(/Average available carbohydrate portion\s*=\s*(\d+)\s*g/);
  if (carbMatch) {
    categoryCarbs = parseInt(carbMatch[1]);
    continue;
  }

  // Parse data rows
  if (!isDataLine(line)) continue;

  const data = parseDataLine(line);
  if (!data) continue;

  const name = collectFoodName(lines, i, data.nameOnLine);
  if (!name) continue;

  const food = {
    name,
    category: category || 'Unknown',
    gi: data.gi,
  };

  if (data.gl != null) food.gl = data.gl;
  if (categoryCarbs != null) food.carbs = categoryCarbs;
  if (data.serving != null) food.serving = data.serving;

  foods.push(food);
}

// Filter out entries with malformed names
const filtered = foods.filter(f =>
  f.name.length >= 3 && !f.name.startsWith('(') && !f.name.startsWith(',')
);

// Sort by name
filtered.sort((a, b) => a.name.localeCompare(b.name));
const skippedBad = foods.length - filtered.length;

// Write output
const outPath = resolve(__dirname, '../public/foods.json');
writeFileSync(outPath, JSON.stringify(filtered, null, 2));

console.log(`Parsed ${foods.length} foods, kept ${filtered.length} (skipped ${skippedBad} malformed names)`);
console.log('Categories:', [...new Set(foods.map(f => f.category))].sort().join(', '));

// Show some stats
const withGL = filtered.filter(f => f.gl != null).length;
const withServing = filtered.filter(f => f.serving != null).length;
console.log(`With GL: ${withGL}, With serving: ${withServing}`);

// Show a few examples
console.log('\nFirst 5 foods:');
filtered.slice(0, 5).forEach(f => console.log(`  ${f.name}: GI=${f.gi}, GL=${f.gl ?? '—'}, carbs=${f.carbs ?? '—'}g`));
