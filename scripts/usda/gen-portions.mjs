import { info } from './fdc.mjs';
import { writeFileSync } from 'node:fs';
// Regenerates data/portions.json from USDA SR Legacy. Net carbs = carbohydrate by difference − total dietary fiber.
const F='FRUIT AND FRUIT PRODUCTS', D='DAIRY PRODUCTS AND ALTERNATIVES', M='MEAT, FISH AND EGGS', C='CHEESE', G='CEREAL GRAINS', P='PASTA AND NOODLES', B='BREADS', V='VEGETABLES', L='LEGUMES', N='NUTS';
const R=(a,b)=>Array.from({length:b-a+1},(_,i)=>a+i);
// [slug, name, category, fdcId, [[label, grams]...], studyRows]
const LIST = [
 ['apple-raw','Apple, raw',F,171688,[['1 small',149],['1 medium',182],['1 large',223]],[1078]],
 ['banana-raw','Banana, raw',F,173944,[['1 small',101],['1 medium',118],['1 large',136]],[1088]],
 ['blueberries','Blueberries',F,171711,[['½ cup',74],['1 cup',148]],[1092]],
 ['strawberries','Strawberries',F,167762,[['½ cup',72],['1 cup',144]],[1174]],
 ['raspberries','Raspberries',F,167755,[['½ cup',62],['1 cup',123]],[]],
 ['grapes','Grapes',F,174683,[['10 grapes',49],['1 cup',151]],[1133,1134,1135]],
 ['orange','Orange',F,169097,[['1 small',96],['1 medium',131],['1 large',184]],[1150]],
 ['pear','Pear',F,169118,[['1 small',148],['1 medium',178]],[1161]],
 ['peach','Peach',F,169928,[['1 small',130],['1 medium',150],['1 large',175]],[1155]],
 ['mango','Mango',F,169910,[['½ cup',83],['1 cup',165]],[1142]],
 ['pineapple','Pineapple',F,169124,[['½ cup',83],['1 cup',165]],[1164]],
 ['cherries','Cherries, sweet',F,171719,[['10 cherries',82],['1 cup',154]],[]],
 ['kiwi','Kiwi',F,168153,[['1 kiwi',69],['2 kiwis',138]],[]],
 ['watermelon','Watermelon',F,167765,[['1 cup',152],['1 wedge',286]],[1145,1146,1147]],
 ['cantaloupe','Cantaloupe',F,169092,[['½ cup',80],['1 cup',160]],[]],
 ['cottage-cheese','Cottage cheese',D,172182,[['½ cup',113],['1 cup',226]],[]],
 ['greek-yogurt-plain','Greek yogurt, plain',D,170894,[['½ cup',113],['1 container',170]],[]],
 ['yogurt-plain','Yogurt, plain',D,171284,[['½ cup',123],['1 cup',245]],[1046]],
 ['milk-2-percent','Milk, 2%',D,171267,[['½ cup',122],['1 cup',244]],[942]],
 ['cheddar','Cheddar cheese',C,173414,[['1 oz',28],['1 cup shredded',113]],[]],
 ['mozzarella','Mozzarella cheese',C,170845,[['1 oz',28],['1 cup shredded',112]],[]],
 ['egg','Egg',M,171287,[['1 large egg',50],['2 large eggs',100]],[]],
 ['chicken-breast','Chicken breast, cooked',M,171477,[['3 oz',85],['½ breast',86]],[]],
 ['ground-beef','Ground beef, cooked',M,174032,[['3 oz',85],['1 patty',77]],[]],
 ['salmon','Salmon, cooked',M,175168,[['3 oz',85],['½ fillet',178]],[]],
 ['tofu-firm','Tofu, firm',L,172475,[['½ cup',126],['¼ block',81]],[]],
 ['white-rice-cooked','White rice, cooked',G,168878,[['½ cup cooked',79],['1 cup cooked',158]],[]],
 ['brown-rice-cooked','Brown rice, cooked',G,169704,[['½ cup cooked',101],['1 cup cooked',202]],[]],
 ['pasta-cooked','Pasta, cooked',P,169737,[['½ cup cooked',62],['1 cup cooked',124],['2 cups cooked',248]],[1466,1467,1468,1469]],
 ['oatmeal-cooked','Oatmeal, cooked',G,173905,[['½ cup cooked',117],['1 cup cooked',234]],[430,431]],
 ['quinoa-cooked','Quinoa, cooked',G,168917,[['½ cup cooked',93],['1 cup cooked',185]],[568]],
 ['white-bread','White bread',B,174924,[['1 slice',29],['2 slices',58]],R(235,240)],
 ['whole-wheat-bread','Whole wheat bread',B,172688,[['1 slice',32],['2 slices',64]],[]],
 ['flour-tortilla','Flour tortilla',B,175037,[['1 small (6")',30],['1 large (10")',72]],[]],
 ['bagel-plain','Bagel, plain',B,175049,[['1 small',69],['1 medium',105]],[]],
 ['baked-potato','Baked potato',V,170093,[['1 small',138],['1 medium',173],['1 large',299]],[]],
 ['sweet-potato-baked','Sweet potato, baked',V,168483,[['1 small',60],['1 medium',114],['1 large',180]],[1874]],
 ['corn-sweet','Sweet corn',V,169999,[['1 ear',103],['½ cup',75],['1 cup',149]],[1801,1802]],
 ['broccoli','Broccoli',V,170379,[['½ cup',46],['1 cup',91]],[]],
 ['carrots','Carrots',V,170393,[['1 medium',61],['1 cup chopped',128]],[1804]],
 ['spinach','Spinach, raw',V,168462,[['1 cup',30],['2 cups',60]],[]],
 ['lettuce','Lettuce',V,169249,[['1 cup',36],['2 cups',72]],[]],
 ['tomato','Tomato',V,170457,[['1 medium',123],['1 cup cherry tomatoes',149]],[]],
 ['cucumber','Cucumber',V,168409,[['½ cup slices',52],['1 cucumber',301]],[]],
 ['bell-pepper','Bell pepper',V,170108,[['½ cup chopped',75],['1 pepper',164]],[]],
 ['green-beans','Green beans',V,169961,[['½ cup',50],['1 cup',100]],[]],
 ['black-beans','Black beans, cooked',L,173735,[['½ cup',86],['1 cup',172]],[]],
 ['chickpeas','Chickpeas, cooked',L,173757,[['½ cup',82],['1 cup',164]],[1285]],
 ['lentils','Lentils, cooked',L,172421,[['½ cup',99],['1 cup',198]],R(1291,1298)],
 ['almonds','Almonds',N,170567,[['1 oz (about 23)',28],['¼ cup',36]],[]],
 ['peanuts','Peanuts, roasted',N,173806,[['1 oz',28],['¼ cup',37]],[]],
 ['walnuts','Walnuts',N,170187,[['1 oz',28],['¼ cup',29]],[]],
 ['peanut-butter','Peanut butter',N,172470,[['1 tbsp',16],['2 tbsp',32]],[]],
 ['hummus','Hummus',L,174289,[['2 tbsp',30],['¼ cup',62]],[1288]],
 ['raisins','Raisins',F,168165,[['1 small box',43],['¼ cup',36]],[]],
 ['orange-juice','Orange juice',F,169098,[['½ cup',124],['1 cup',248]],[]],
 ['apple-juice','Apple juice',F,173933,[['½ cup',124],['1 cup',248]],[]],
 ['honey','Honey','SUGARS AND SYRUPS',169640,[['1 tsp',7],['1 tbsp',21]],[]],
];
const out = LIST.map(([slug,name,category,fdcId,ps,studyRows]) => {
  const f = info(String(fdcId)); if (!f.desc) throw new Error('missing '+fdcId);
  return { slug, name, category, carbSource:'usda', fdcId, usdaDescription: f.desc, studyRows,
    portions: ps.map(([label,grams]) => ({ label, grams, carbs: Math.round(f.net100*grams/10)/10 })) };
});
writeFileSync(new URL('../../data/portions.json', import.meta.url), JSON.stringify(out, null, 2) + '\n');
for (const o of out) console.log(o.slug.padEnd(20), o.usdaDescription.slice(0,50).padEnd(50), o.portions.map(p=>p.label+'='+p.carbs).join(', '));
