# Color database for birds

## Motivation
I have been working on a project using thousands of reflectance spectra my colleagues and I measured over the last several years. I'm using information on the bird's color that we can extract from spectra to better understand why birds have certain colors and how they have changed over time. The spreadsheets were getting huge, so I decided I wanted to try my hand at creating and working with a database. The flavor I chose to use was `PostgreSQL` and I've been excited about the `SQLalchemy` package in `python` that let's me interact with the database.

## Database schema
Here's a look at the way I've setup the database:

![](/docs/schema_kingfisher.png)

## Some cool queries to try

### Patches per species
Let's say we want to look at the number of unique patches measured for females birds of each species:
```sql
SELECT CONCAT(genus, ' ', species) sciname, sex, COUNT(DISTINCT patches.patch) npatches
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
WHERE sex LIKE 'f'
GROUP BY genus, species, sex
LIMIT 5;
```

```
       sciname        | sex | npatches 
----------------------+-----+----------
 Actenoides concretus | f   |       22
 Actenoides hombroni  | f   |       22
 Actenoides lindsayi  | f   |       22
 Actenoides monachus  | f   |       22
 Alcedo atthis        | f   |       22
(5 rows)
```

### Spectra per patch
See how many species we have color data for, grouped by patch:
```sql
SELECT patch, COUNT(DISTINCT taxonomy.species) nspecies 
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
GROUP BY patch
LIMIT 10;
```

```
   patch   | nspecies 
-----------+----------
 back      |       72
 backhead  |       72
 belly     |       72
 breast    |       72
 cheek     |       72
 chin      |       72
 crown     |       72
 eyering   |       72
 flank     |       72
 fronthead |       72
(10 rows)
```

<!-- ### Filtering out patches with not much data
Many of these patches only have a few measurements (e.g., the 'black-streaks' patch), so let's filter those out:

```sql
SELECT region patch, COUNT(DISTINCT taxonomy.species) nspecies 
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
WHERE patches.region NOT LIKE '%streaks'
GROUP BY patch
LIMIT 10;
```

```
            patch             | nspecies 
------------------------------+----------
 anterior-auricular           |       67
 anterior-flank               |       67
 anterior-malar               |       67
 anterior-supercilium (lores) |       67
 base-retrices                |       67
 belly                        |       67
 breast                       |       67
 breast-patches               |       67
 crown                        |       67
 eye-ring                     |       67
(10 rows)
```

That's better. -->

### Top-5 brightest patches on a bird

```sql
SELECT spectra.spec_id AS spec, family, CONCAT(genus, ' ', species) sciname, patch, ROUND(MAX(spectra.reflectance)::numeric,2) AS maxrefl
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
GROUP BY spec, family, genus, species, patch
ORDER BY maxrefl DESC
LIMIT 5;
```

```
 spec |   family    |         sciname         |    patch    | maxrefl 
------+-------------+-------------------------+-------------+---------
 1602 | Alcedinidae | Todiramphus leucopygius | breast      |   99.01
 2003 | Alcedinidae | Syma torotoro           | crown       |   88.68
  857 | Alcedinidae | Ceyx erithaca           | vent        |   83.01
 2006 | Alcedinidae | Syma torotoro           | lore        |   82.55
 1443 | Alcedinidae | Halcyon smyrnensis      | primaries   |   82.42
(5 rows)
```

We can see that the brightest body region measured was the breast patch of the kingfisher _Todiramphus leucopygius_ with a whopping 99% reflectance value! This corresponds to spectrum #1602 that we can easily take a look at more closely if we'd like (e.g., using `WHERE spec_id = 1602`).

### Looking at the data for a single measurement

```sql
SELECT * 
FROM spectra
WHERE spec_id = 1602
LIMIT 10;
```

```
 spec_id | wl  |   reflectance    
---------+-----+------------------
    1602 | 300 | 39.0076943699732
    1602 | 301 |  40.230294117647
    1602 | 302 | 41.8364884135472
    1602 | 303 | 42.9932442067736
    1602 | 304 | 44.8255674709562
    1602 | 305 |  44.811599642538
    1602 | 306 |  46.176344950849
    1602 | 307 | 47.6265058087578
    1602 | 308 | 48.4918677390527
    1602 | 309 | 50.1353261840929
(10 rows)
```


### Average reflectance values by wavelength bins and recast
Sometimes we might not want to have a massive table with only 2 columns (wavelength and reflectance). Instead, let's say we want to see wavelength values in a single column and then all other columns correspond to different wavelengths. We can achieve this kind of thing with the `CASE WHEN` function. Note that I'm rounding by 2 decimal places here to clean things up a bit.
```sql
SELECT spec_id,
    ROUND(AVG(CASE WHEN wl BETWEEN 300 AND 400 THEN reflectance END)::numeric,2) AS "300-400",
    ROUND(AVG(CASE WHEN wl BETWEEN 400 AND 500 THEN reflectance END)::numeric,2) AS "400-500",
    ROUND(AVG(CASE WHEN wl BETWEEN 500 AND 600 THEN reflectance END)::numeric,2) AS "500-600",
    ROUND(AVG(CASE WHEN wl BETWEEN 600 AND 700 THEN reflectance END)::numeric,2) AS "600-700"
FROM spectra
GROUP BY spec_id
LIMIT 5;
```

Looking at the output below, it's cool to see that we've effectively "binned" the reflectance values by averaging across several wavelengths, but the results are kinda meaningless without context. That is, we don't know what spec_id 1 corresponds to.

```
 spec_id | 300-400 | 400-500 | 500-600 | 600-700 
---------+---------+---------+---------+---------
       0 |    3.74 |    3.59 |    7.27 |    6.79
       1 |    3.50 |    3.44 |    5.07 |    5.98
       2 |   18.34 |   35.15 |   46.70 |   52.91
       3 |    9.31 |   11.94 |   14.00 |   15.96
       4 |    4.73 |    5.24 |    8.06 |    9.05
(5 rows)
```

### Pull 5 spectra for the "vent" patch in this recasted form
What if we want to pull these reshaped spectra for only a certain patch? We can combine the reshaping with `WHERE` filtering and then use `GROUP BY` and pick the patch and spec ID.
```sql
SELECT spectra.spec_id spec, patch,
    ROUND(AVG(CASE WHEN wl BETWEEN 300 AND 400 THEN reflectance END)::numeric,2) AS "300-400",
    ROUND(AVG(CASE WHEN wl BETWEEN 400 AND 500 THEN reflectance END)::numeric,2) AS "400-500",
    ROUND(AVG(CASE WHEN wl BETWEEN 500 AND 600 THEN reflectance END)::numeric,2) AS "500-600",
    ROUND(AVG(CASE WHEN wl BETWEEN 600 AND 700 THEN reflectance END)::numeric,2) AS "600-700"
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
WHERE patch LIKE 'vent'
GROUP BY patch, spec
LIMIT 5;
```

Here's the output:

```
LIMIT 5;
 spec | patch | 300-400 | 400-500 | 500-600 | 600-700 
------+-------+---------+---------+---------+---------
   21 | vent  |   11.53 |   22.80 |   31.34 |   37.08
   43 | vent  |   17.72 |   31.20 |   40.42 |   45.72
   65 | vent  |   18.55 |   33.14 |   41.38 |   44.31
   87 | vent  |   23.17 |   45.69 |   56.22 |   61.87
  109 | vent  |   20.11 |   40.92 |   53.26 |   59.51
(5 rows)
```

Ah, much better.

<!-- Now we can finally add in the taxonomy information (family, genus, species)-

```sql
SELECT spectra.spec_id AS spec,
    family,
    CONCAT(genus, ' ', species) AS sciname,
    patch,
    ROUND(AVG(CASE WHEN wl BETWEEN 300 AND 400 THEN reflectance END)::numeric,2) AS "300-400",
    ROUND(AVG(CASE WHEN wl BETWEEN 400 AND 500 THEN reflectance END)::numeric,2) AS "400-500",
    ROUND(AVG(CASE WHEN wl BETWEEN 500 AND 600 THEN reflectance END)::numeric,2) AS "500-600",
    ROUND(AVG(CASE WHEN wl BETWEEN 600 AND 700 THEN reflectance END)::numeric,2) AS "600-700"
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
WHERE patch LIKE 'vent'
GROUP BY patch, spec, family, sciname
LIMIT 5;
```

```
 spec |  family   | sciname | patch | 300-400 | 400-500 | 500-600 | 600-700 
------+-----------+---------+-------+---------+---------+---------+---------
   20 | Icteridae | Psa os  | vent  |    0.36 |    0.99 |    3.76 |    9.70
   58 | Icteridae | Psa os  | vent  |    0.03 |    0.55 |    4.20 |   11.22
   96 | Icteridae | Psa de  | vent  |    0.28 |    1.65 |    2.86 |    4.34
  134 | Icteridae | Psa de  | vent  |    1.53 |    1.93 |    4.16 |    9.69
  172 | Icteridae | Psa vi  | vent  |    3.21 |    3.45 |    7.90 |   15.52
  210 | Icteridae | Psa vi  | vent  |    0.42 |    0.96 |    2.87 |    8.04
(5 rows)
``` -->


## Next steps
- Make this searchable by color (e.g., "show me red birds")
- Deploy as a public webapp for people to interact with

## Author
Chad M. Eliason

