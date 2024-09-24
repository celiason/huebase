# Here's the readme

## Motivation
I have been working on a project using thousands of reflectance spectra to understand bird color evolution. The spreadsheets were getting huge and I decided I wanted to try my hand at creating and working with a SQL database. The flavor I chose to use was `PostgreSQL` and I've been excited about the `SQLalchemy` package in `python` that let's me interact with the database.

## Database schema
Here's a look at the way I've setup the database:

![](/docs/Screenshot%202024-09-24%20at%208.23.40 AM.png)

## Some cool queries to try

### Patches per species
Let's say we want to look at the number of unique patches measured for each species:
```sql
SELECT CONCAT(genus, ' ', species) sciname, COUNT(DISTINCT patches.region) npatches
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
GROUP BY genus, species
LIMIT 5
```

```
 sciname | npatches 
---------+----------
 Age as  |       38
 Age cy  |       39
 Age hu  |       38
 Age ic  |       38
 Age ph  |       38
(5 rows)
```

### Spectra per species
See how many species we have color data for, grouped by patch:
```sql
SELECT region patch, COUNT(DISTINCT taxonomy.species) nspecies 
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
GROUP BY region
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
 black-streaks                |        1
 breast                       |       67
 breast-patches               |       67
 brown-streaks                |        3
(10 rows)
```

### Filtering out patches with not much data
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

That's better.

### Find the top 10 brightest patches

```sql
SELECT family, CONCAT(genus, ' ', species) sciname, region AS patch, MAX(spectra.reflectance) AS maxrefl
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
GROUP BY family, genus, species, patch
ORDER BY maxrefl DESC
LIMIT 10;
```

```
  family   | sciname |        patch        | maxrefl 
-----------+---------+---------------------+---------
 Icteridae | Cac ce  | upper-rump          | 70.4962
 Icteridae | Cac ur  | lower-rump          | 70.0699
 Icteridae | Psa wa  | outer-retrices      | 68.6656
 Icteridae | Ict ma  | median-coverts      | 65.7222
 Icteridae | Ict ni  | anterior-flank      | 63.0564
 Icteridae | Ict pu  | median-covert-edges | 62.7634
 Icteridae | Cac ha  | upper-rump          | 62.1286
 Icteridae | Cac ha  | lower-rump          | 61.0674
 Icteridae | Ict cu  | median-coverts      | 60.9681
 Icteridae | Ict pe  | secondary-edges     | 60.5897
(10 rows)
```

We can see that the top 3 birds are in the Icteridae family and 2 of the top 3 patches are on the rump of the bird (both > 70% reflectance).

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
       0 |    5.58 |    6.09 |    9.31 |   15.81
       1 |    6.67 |    6.65 |    7.74 |   10.73
       2 |    2.52 |    2.76 |    6.16 |   13.81
       3 |    5.85 |    4.40 |   15.12 |   19.02
       4 |    1.03 |    1.29 |    3.55 |    9.95
(5 rows)
```

### Pull 10 spectra for the "vent" patch in this recasted form
What if we want to pull these reshaped spectra for only a certain patch? We can combine the reshaping with `WHERE` filtering and then use `GROUP BY` and pick the patch and spec ID.
```sql
SELECT spectra.spec_id spec, patches.region patch,
    ROUND(AVG(CASE WHEN wl BETWEEN 300 AND 400 THEN reflectance END)::numeric,2) AS "300-400",
    ROUND(AVG(CASE WHEN wl BETWEEN 400 AND 500 THEN reflectance END)::numeric,2) AS "400-500",
    ROUND(AVG(CASE WHEN wl BETWEEN 500 AND 600 THEN reflectance END)::numeric,2) AS "500-600",
    ROUND(AVG(CASE WHEN wl BETWEEN 600 AND 700 THEN reflectance END)::numeric,2) AS "600-700"
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
WHERE patches.region LIKE 'vent'
GROUP BY patch, spec
LIMIT 10;
```

Here's the output:

```
 spec | patch | 300-400 | 400-500 | 500-600 | 600-700 
------+-------+---------+---------+---------+---------
   20 | vent  |    0.36 |    0.99 |    3.76 |    9.70
   58 | vent  |    0.03 |    0.55 |    4.20 |   11.22
   96 | vent  |    0.28 |    1.65 |    2.86 |    4.34
  134 | vent  |    1.53 |    1.93 |    4.16 |    9.69
  172 | vent  |    3.21 |    3.45 |    7.90 |   15.52
  210 | vent  |    0.42 |    0.96 |    2.87 |    8.04
  248 | vent  |    2.65 |    2.45 |    7.96 |   10.47
  286 | vent  |    1.65 |    2.95 |    6.87 |   10.08
  324 | vent  |    2.31 |    2.20 |    3.43 |    5.36
  362 | vent  |    2.37 |    2.46 |    5.97 |   10.00
(10 rows)
```

Ah, much better.

<!-- Now we can finally add in the taxonomy information (family, genus, species)-

```sql
SELECT spectra.spec_id AS spec,
    family,
    CONCAT(genus, ' ', species) AS sciname,
    patches.region patch,
    ROUND(AVG(CASE WHEN wl BETWEEN 300 AND 400 THEN reflectance END)::numeric,2) AS "300-400",
    ROUND(AVG(CASE WHEN wl BETWEEN 400 AND 500 THEN reflectance END)::numeric,2) AS "400-500",
    ROUND(AVG(CASE WHEN wl BETWEEN 500 AND 600 THEN reflectance END)::numeric,2) AS "500-600",
    ROUND(AVG(CASE WHEN wl BETWEEN 600 AND 700 THEN reflectance END)::numeric,2) AS "600-700"
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
WHERE patches.region LIKE 'vent'
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

