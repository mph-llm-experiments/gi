// Parses Supplemental Table 1 (pdftotext -layout output) into study rows.
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
  const testCarbs = carbsPart && /^[\d.]+$/.test(carbsPart.trim()) ? parseFloat(carbsPart.trim()) : null;
  const testGrams = servingPart && /^[\d.]+$/.test(servingPart.trim()) ? parseFloat(servingPart.trim()) : null;

  return { rowNum, nameOnLine, gi, gl, testCarbs, testGrams };
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

export function parseTable1(text) {
  const lines = text.split('\n');
  let category = '';
  const rows = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    if (isCategoryLine(line)) {
      category = line.trim().replace('PASTA and NOODLES', 'PASTA AND NOODLES');
      continue;
    }

    if (!isDataLine(line)) continue;

    const data = parseDataLine(line);
    if (!data) continue;

    const name = collectFoodName(lines, i, data.nameOnLine);
    if (!name) continue;

    rows.push({
      row: data.rowNum,
      name,
      category: category || 'Unknown',
      gi: data.gi,
      gl: data.gl,
      testCarbs: data.testCarbs,
      testGrams: data.testGrams,
    });
  }

  // Filter out entries with malformed names
  return rows.filter(r =>
    r.name.length >= 3 && !r.name.startsWith('(') && !r.name.startsWith(',')
  );
}
