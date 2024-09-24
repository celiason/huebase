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

## Next steps
- Make this searchable by color (e.g., "show me red birds")
- Deploy as a public webapp for people to interact with

## Author
Chad M. Eliason

