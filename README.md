# GI Lookup

A simple, ad-free PWA for looking up glycemic index (GI) and glycemic load (GL) values. Built for mobile use at the grocery store.

**https://gi.puddingtime.net**

## Data

Food data is from the 2021 international tables of glycemic index and glycemic load values, parsed from Supplemental Table 1 (ISO 26642:2010 methodology):

> Atkinson FS, Brand-Miller JC, Foster-Powell K, Buyken AE, Goletzke J. International tables of glycemic index and glycemic load values 2021. *American Journal of Clinical Nutrition*. 2021. [DOI: 10.1093/ajcn/nqac031](https://doi.org/10.1093/ajcn/nqac031)

The dataset contains ~2,044 foods with GI, GL, category, and standardized carbohydrate portions.

## Self-hosting

The app is just static files in `public/`. No build step, no server required.

- **Netlify/Vercel/etc.**: Point at the repo with `public/` as the publish directory
- **GitHub Pages**: Set Pages to serve from `public/`
- **Locally**: `npx serve public`
- **Anywhere else**: Copy the `public/` folder to any web server (nginx, Apache, S3, etc.)

The service worker assumes the app is served from `/`. If you host at a subpath, update the asset paths in `sw.js`.
