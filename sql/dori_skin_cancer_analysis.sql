/* ============================================================
   DORI SKIN CANCER ANALYSIS
   Dermalife Oncology & Research Institute
   ============================================================ */


/* ============================================================
   SECTION 1: DATA QUALITY CHECKS
   ============================================================ */


-- Check for patients with more than one lesion record
SELECT
    patient_id,
    COUNT(*) AS num_lesion_records
FROM table2
GROUP BY patient_id
HAVING COUNT(*) > 1;


-- Check whether lesion_id values are globally unique

SELECT
    COUNT(*) AS total_lesions,
    COUNT(DISTINCT lesion_id) AS unique_lesion_ids
FROM table2;


-- Check for lesion records with no matching patient
SELECT
    t2.patient_id
FROM table2 t2
LEFT JOIN table1 t1
    ON t2.patient_id = t1.patient_id
WHERE t1.patient_id IS NULL;


-- Check for NULL values in important patient columns
SELECT
    COUNT(*) FILTER (WHERE age IS NULL) AS null_age,
    COUNT(*) FILTER (WHERE gender IS NULL) AS null_gender,
    COUNT(*) FILTER (
        WHERE skin_cancer_history IS NULL
    ) AS null_skin_cancer_history
FROM table1;


-- Check for NULL values in important lesion columns
SELECT
    COUNT(*) FILTER (
        WHERE diagnostic IS NULL
    ) AS null_diagnostic,

    COUNT(*) FILTER (
        WHERE region IS NULL
    ) AS null_region,

    COUNT(*) FILTER (
        WHERE diameter_1 IS NULL
    ) AS null_diameter_1,

    COUNT(*) FILTER (
        WHERE diameter_2 IS NULL
    ) AS null_diameter_2,

    COUNT(*) FILTER (
        WHERE grew IS NULL
    ) AS null_grew,

    COUNT(*) FILTER (
        WHERE biopsed IS NULL
    ) AS null_biopsed
FROM table2;


-- Check for duplicate patient IDs
SELECT
    patient_id,
    COUNT(*) AS num_records
FROM table1
GROUP BY patient_id
HAVING COUNT(*) > 1;


-- Check region values for inconsistent spelling,
-- casing or whitespace
SELECT DISTINCT
    region,
    LENGTH(region) AS char_length
FROM table2
ORDER BY region;


-- Check diagnosis values for inconsistent spelling,
-- casing or whitespace
SELECT DISTINCT
    diagnostic,
    LENGTH(diagnostic) AS char_length
FROM table2
ORDER BY diagnostic;


/*
   NOTE:
   The foreign key was already created during database setup,
   so it does not need to be created again here.

   Original setup statement:

   ALTER TABLE table2
   ADD CONSTRAINT table2_patient_id_fkey
   FOREIGN KEY (patient_id)
   REFERENCES table1 (patient_id);
*/



/* ============================================================
   TASK 1: PATIENT DEMOGRAPHIC RISK ANALYSIS

   Goal:
   Understand which demographic groups are most affected
   by skin cancer conditions.
   ============================================================ */


-- TASK 1, Q1:
-- Which age group has the highest number of
-- skin cancer (malignant) diagnoses?

SELECT
    CASE
        WHEN t1.age < 30 THEN 'Under 30'
        WHEN t1.age BETWEEN 30 AND 44 THEN '30-44'
        WHEN t1.age BETWEEN 45 AND 59 THEN '45-59'
        WHEN t1.age BETWEEN 60 AND 74 THEN '60-74'
        WHEN t1.age >= 75 THEN '75+'
        ELSE 'Unknown'
    END AS age_group,
    COUNT(*) AS malignant_diagnoses
FROM table1 t1
JOIN table2 t2
    ON t1.patient_id = t2.patient_id
WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
GROUP BY age_group
ORDER BY malignant_diagnoses DESC;



-- TASK 1, Q2:
-- What is the distribution of diagnoses
-- between male and female patients?

SELECT
    t1.gender,
    t2.diagnostic,
    COUNT(*) AS num_cases
FROM table1 t1
JOIN table2 t2
    ON t1.patient_id = t2.patient_id
GROUP BY
    t1.gender,
    t2.diagnostic
ORDER BY
    t1.gender,
    num_cases DESC;



-- TASK 1, Q3:
-- Which body regions record the highest number
-- of patients with malignant diagnoses?

SELECT
    region,
    COUNT(*) AS malignant_cases
FROM table2
WHERE diagnostic IN ('BCC', 'SCC', 'MEL')
GROUP BY region
ORDER BY malignant_cases DESC;



-- TASK 1, Q4:
-- How many patients have a previous
-- history of skin cancer?

SELECT
    COUNT(*) AS patients_with_skin_cancer_history
FROM table1
WHERE skin_cancer_history = true;



/* ============================================================
   TASK 2: LESION GROWTH & DIAGNOSIS ANALYSIS

   Goal:
   Analyse lesion characteristics and identify indicators
   of dangerous skin conditions.
   ============================================================ */


-- TASK 2, Q1:
-- Which diagnosis category appears most frequently?

SELECT
    diagnostic,
    COUNT(*) AS num_lesions
FROM table2
GROUP BY diagnostic
ORDER BY num_lesions DESC;



-- TASK 2, Q2:
-- How many lesions were reported as growing over time?

SELECT
    COUNT(*) AS growing_lesions
FROM table2
WHERE grew = true;



-- TASK 2, Q3:
-- Which symptoms are most commonly associated with lesions?

SELECT
    'itch' AS symptom,
    COUNT(*) AS num_lesions
FROM table2
WHERE itch = true

UNION ALL

SELECT
    'hurt',
    COUNT(*)
FROM table2
WHERE hurt = true

UNION ALL

SELECT
    'changed',
    COUNT(*)
FROM table2
WHERE changed = true

UNION ALL

SELECT
    'bleed',
    COUNT(*)
FROM table2
WHERE bleed = true

UNION ALL

SELECT
    'elevation',
    COUNT(*)
FROM table2
WHERE elevation = true

ORDER BY num_lesions DESC;



-- TASK 2, Q4:
-- How many lesions were biopsed before
-- diagnosis confirmation?

SELECT
    COUNT(*) AS biopsed_lesions
FROM table2
WHERE biopsed = true;



-- TASK 2, Q5:
-- Which diagnosis type has the highest
-- average lesion diameter?

-- TASK 2, Q5:
-- Which diagnosis type has the highest
-- average lesion diameter?

SELECT
    diagnostic,
    ROUND(
        AVG((diameter_1 + diameter_2) / 2.0)::numeric,
        2
    ) AS avg_lesion_diameter
FROM table2
GROUP BY diagnostic
ORDER BY avg_lesion_diameter DESC;



/* ============================================================
   TASK 3: ENVIRONMENTAL HEALTHCARE ANALYSIS

   Goal:
   Understand how environmental conditions relate
   to diagnosis patterns.
   ============================================================ */


-- TASK 3, Q1:
-- Which body region has the highest number
-- of diagnosed cases?

SELECT
    region,
    COUNT(*) AS total_cases
FROM table2
GROUP BY region
ORDER BY total_cases DESC;



-- TASK 3, Q2:
-- How many patients lack access to piped water?

SELECT
    COUNT(*) AS patients_without_piped_water
FROM table1
WHERE has_piped_water = false;



-- TASK 3, Q3:
-- How many patients do not have access
-- to sewage systems?

SELECT
    COUNT(*) AS patients_without_sewage_system
FROM table1
WHERE has_sewage_system = false;



-- TASK 3, Q4:
-- Which body regions report the highest
-- number of biopsed lesions?

SELECT
    region,
    COUNT(*) AS biopsed_count
FROM table2
WHERE biopsed = true
GROUP BY region
ORDER BY biopsed_count DESC;



-- TASK 3, Q5:
-- Is there a relationship between poor sanitation access
-- and severe (malignant) diagnosis outcomes?

SELECT
    'Piped Water' AS sanitation_type,
    t1.has_piped_water AS has_access,
    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
    ) AS malignant_cases,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
        ) / COUNT(*),
        1
    ) AS malignancy_rate_pct

FROM table1 t1
JOIN table2 t2
    ON t1.patient_id = t2.patient_id

GROUP BY t1.has_piped_water


UNION ALL


SELECT
    'Sewage System' AS sanitation_type,
    t1.has_sewage_system AS has_access,
    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
    ) AS malignant_cases,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
        ) / COUNT(*),
        1
    ) AS malignancy_rate_pct

FROM table1 t1
JOIN table2 t2
    ON t1.patient_id = t2.patient_id

GROUP BY t1.has_sewage_system

ORDER BY sanitation_type, has_access;



/* ============================================================
   TASK 4: LIFESTYLE & BEHAVIOURAL RISK ANALYSIS

   Goal:
   Evaluate how lifestyle habits relate to
   skin cancer diagnosis and lesion severity.
   ============================================================ */


-- TASK 4, Q1:
-- How many patients are smokers?

SELECT
    COUNT(*) AS num_smokers
FROM table1
WHERE smoke = true;



-- TASK 4, Q2:
-- How many patients consume alcohol regularly?

SELECT
    COUNT(*) AS num_drinkers
FROM table1
WHERE drink = true;



-- TASK 4, Q3:
-- Which diagnosis types are most common among smokers?

SELECT
    t2.diagnostic,
    COUNT(*) AS num_cases
FROM table1 t1
JOIN table2 t2
    ON t1.patient_id = t2.patient_id
WHERE t1.smoke = true
GROUP BY t2.diagnostic
ORDER BY num_cases DESC;



-- TASK 4, Q4:
-- What percentage of smokers also consume alcohol?

SELECT
    COUNT(*) AS total_smokers,

    COUNT(*) FILTER (
        WHERE drink = true
    ) AS smokers_who_also_drink,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE drink = true
        ) / COUNT(*),
        1
    ) AS pct_smokers_who_drink

FROM table1
WHERE smoke = true;



-- TASK 4, Q5:
-- Are patients who both smoke and drink more likely
-- to have a malignant diagnosis?

SELECT
    CASE
        WHEN t1.smoke = true
             AND t1.drink = true
        THEN 'Smoke and drink'

        ELSE 'Other patients'
    END AS lifestyle_group,

    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
    ) AS malignant_cases,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
        ) / COUNT(*),
        1
    ) AS malignancy_rate_pct

FROM table1 t1
JOIN table2 t2
    ON t1.patient_id = t2.patient_id

GROUP BY lifestyle_group
ORDER BY malignancy_rate_pct DESC;



-- TASK 4, Q6:
-- Which lifestyle factor has the strongest relationship
-- with severe diagnosis outcomes?

SELECT
    CASE
        WHEN t1.smoke = true
             AND t1.drink = true
        THEN 'Smoke and drink'

        WHEN t1.smoke = true
             AND t1.drink = false
        THEN 'Smoke only'

        WHEN t1.smoke = false
             AND t1.drink = true
        THEN 'Drink only'

        ELSE 'Neither'
    END AS lifestyle_group,

    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
    ) AS malignant_cases,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
        ) / COUNT(*),
        1
    ) AS malignancy_rate_pct

FROM table1 t1
JOIN table2 t2
    ON t1.patient_id = t2.patient_id

GROUP BY lifestyle_group
ORDER BY malignancy_rate_pct DESC;



/* ============================================================
   ADDITIONAL ANALYSIS

   These analyses go beyond the direct business questions
   and explore patterns identified in the initial results.
   ============================================================ */


-- ADDITIONAL ANALYSIS 1:
-- Malignancy rate by age group

SELECT
    CASE
        WHEN t1.age < 30 THEN 'Under 30'
        WHEN t1.age BETWEEN 30 AND 44 THEN '30-44'
        WHEN t1.age BETWEEN 45 AND 59 THEN '45-59'
        WHEN t1.age BETWEEN 60 AND 74 THEN '60-74'
        WHEN t1.age >= 75 THEN '75+'
        ELSE 'Unknown'
    END AS age_group,

    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
    ) AS malignant_cases,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
        ) / COUNT(*),
        1
    ) AS malignancy_rate_pct

FROM table1 t1
JOIN table2 t2
    ON t1.patient_id = t2.patient_id

GROUP BY age_group
ORDER BY malignancy_rate_pct DESC;



-- ADDITIONAL ANALYSIS 2:
-- Malignancy rate by gender

SELECT
    t1.gender,

    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
    ) AS malignant_cases,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
        ) / COUNT(*),
        1
    ) AS malignancy_rate_pct

FROM table1 t1
JOIN table2 t2
    ON t1.patient_id = t2.patient_id

GROUP BY t1.gender
ORDER BY malignancy_rate_pct DESC;



-- ADDITIONAL ANALYSIS 3:
-- Previous skin cancer history and malignancy rate

SELECT
    t1.skin_cancer_history,

    COUNT(*) AS total_patients,

    COUNT(*) FILTER (
        WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
    ) AS malignant_cases,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE t2.diagnostic IN ('BCC', 'SCC', 'MEL')
        ) / COUNT(*),
        1
    ) AS malignancy_rate_pct

FROM table1 t1
JOIN table2 t2
    ON t1.patient_id = t2.patient_id

GROUP BY t1.skin_cancer_history
ORDER BY malignancy_rate_pct DESC;



-- ADDITIONAL ANALYSIS 4:
-- Growing vs non-growing lesions and malignancy rate

SELECT
    grew,

    COUNT(*) AS total_lesions,

    COUNT(*) FILTER (
        WHERE diagnostic IN ('BCC', 'SCC', 'MEL')
    ) AS malignant_cases,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE diagnostic IN ('BCC', 'SCC', 'MEL')
        ) / COUNT(*),
        1
    ) AS malignancy_rate_pct

FROM table2
GROUP BY grew
ORDER BY malignancy_rate_pct DESC;


-- ADDITIONAL ANALYSIS 5:
-- Malignancy rate by body region

SELECT
    region,

    COUNT(*) AS total_lesions,

    COUNT(*) FILTER (
        WHERE diagnostic IN ('BCC', 'SCC', 'MEL')
    ) AS malignant_cases,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE diagnostic IN ('BCC', 'SCC', 'MEL')
        ) / COUNT(*),
        1
    ) AS malignancy_rate_pct

FROM table2
GROUP BY region
ORDER BY malignancy_rate_pct DESC;



-- ADDITIONAL ANALYSIS 6:
-- Biopsy rate by malignancy status

SELECT
    CASE
        WHEN diagnostic IN ('BCC', 'SCC', 'MEL')
            THEN 'Malignant'
        ELSE 'Non-malignant'
    END AS diagnosis_group,

    COUNT(*) AS total_lesions,

    COUNT(*) FILTER (
        WHERE biopsed = true
    ) AS biopsed_lesions,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE biopsed = true
        ) / COUNT(*),
        1
    ) AS biopsy_rate_pct

FROM table2
GROUP BY diagnosis_group
ORDER BY biopsy_rate_pct DESC;


