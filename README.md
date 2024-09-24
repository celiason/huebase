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
SELECT species, region patch, COUNT(DISTINCT spectra.spec_id) nspecs
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
GROUP BY species, region;
```

### Spectra per species
See how many species we have color data for, grouped by patch:
```sql
SELECT region patch, COUNT(DISTINCT taxonomy.species) nspecies 
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
GROUP BY region;
```

### Filtering out patches with not much data
Many of these patches only have a few.. so let's try to filter those out:

```sql
SELECT region patch, COUNT(DISTINCT taxonomy.species) nspecies 
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
WHERE patches.region NOT LIKE '%streaks'
GROUP BY patch
LIMIT 5;
```
Outputs the following:

```
            patch             | nspecies 
------------------------------+----------
 anterior-auricular           |       67
 anterior-flank               |       67
 anterior-malar               |       67
 anterior-supercilium (lores) |       67
 base-retrices                |       67
(5 rows)
```

