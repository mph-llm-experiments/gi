# Data Provenance

The study rows in the food dataset (`public/foods.json`) are derived from the supplementary tables of:

> Atkinson FS, Brand-Miller JC, Foster-Powell K, Buyken AE, Goletzke J. International tables of glycemic index and glycemic load values 2021. *American Journal of Clinical Nutrition*. 2021. [DOI: 10.1093/ajcn/nqab233](https://doi.org/10.1093/ajcn/nqab233)

This data is **not covered by the MIT license** that applies to the source code. The glycemic index and glycemic load values are scientific facts from published research. The compilation, selection, and descriptions originate from the above publication and are subject to its copyright terms.

If you wish to generate the dataset yourself, download the supplementary PDF from the paper and use the included parser script:

```bash
pdftotext -layout SupplementalTable1.pdf table1.txt
node scripts/build-foods.js
```

The everyday foods in `data/portions.json` (entries with `carbSource: "usda"`) take their carbohydrate and fiber values from USDA FoodData Central (SR Legacy), which is in the public domain. Each entry records its `fdcId`. `scripts/usda/gen-portions.mjs` regenerates the file from the SR Legacy CSV download.
