# Data Provenance

The food dataset (`public/foods.json`) is derived from the supplementary tables of:

> Atkinson FS, Brand-Miller JC, Foster-Powell K, Buyken AE, Goletzke J. International tables of glycemic index and glycemic load values 2021. *American Journal of Clinical Nutrition*. 2021. [DOI: 10.1093/ajcn/nqac031](https://doi.org/10.1093/ajcn/nqac031)

This data is **not covered by the MIT license** that applies to the source code. The glycemic index and glycemic load values are scientific facts from published research. The compilation, selection, and descriptions originate from the above publication and are subject to its copyright terms.

If you wish to generate the dataset yourself, download the supplementary PDF from the paper and use the included parser script:

```bash
pdftotext -layout SupplementalTable1.pdf table1.txt
node scripts/parse-table1.js
```
