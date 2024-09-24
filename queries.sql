SELECT region patch, COUNT(DISTINCT taxonomy.species) nspecies 
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
GROUP BY region
LIMIT 10;

SELECT region patch, COUNT(DISTINCT taxonomy.species) nspecies 
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
WHERE patches.region NOT LIKE '%streaks'
GROUP BY patch
LIMIT 10;

SELECT family, CONCAT(genus, ' ', species) sciname, region AS patch, MAX(spectra.reflectance) AS maxrefl
FROM spectra
LEFT JOIN metadata ON spectra.spec_id = metadata.spec_id
LEFT JOIN taxonomy ON metadata.tax_id = taxonomy.tax_id
LEFT JOIN patches ON metadata.patch_id = patches.patch_id
GROUP BY family, genus, species, patch
ORDER BY maxrefl DESC
LIMIT 10;

SELECT spec_id,
    ROUND(AVG(CASE WHEN wl BETWEEN 300 AND 400 THEN reflectance END)::numeric,2) AS "300-400",
    ROUND(AVG(CASE WHEN wl BETWEEN 400 AND 500 THEN reflectance END)::numeric,2) AS "400-500",
    ROUND(AVG(CASE WHEN wl BETWEEN 500 AND 600 THEN reflectance END)::numeric,2) AS "500-600",
    ROUND(AVG(CASE WHEN wl BETWEEN 600 AND 700 THEN reflectance END)::numeric,2) AS "600-700"
FROM spectra
GROUP BY spec_id
LIMIT 5;

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
LIMIT 5;

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

