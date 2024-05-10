-- IKER SÁNCHEZ PALACIOS
USE world_layoffs;
SELECT * FROM layoffs;

-- The next steps will be followed:
-- 1. Remove duplicates
-- 2. Standardizing data
-- 3. Null Values or Blank values
-- 4. Remove any columns


-- --------------------------------- 0. Create a copy for wrangling data (layoff_staging) --------------------------------- 

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * 
FROM layoffs;


-- --------------------------------------------------- 1. Duplicates ---------------------------------------------------

WITH duplicate_CTE AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
) -- Common Table Expression with duplicates
SELECT * 
FROM duplicate_CTE 
WHERE row_num > 1; -- We can't delete rows from here, thus we make a copy of this CTE as an actual table to remove duplicates


CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci; -- Made out from right clickng layoffs_staging >> Copy to clipboard >> Create Statement


SELECT * 
FROM layoffs_staging2;-- Empty copy of CTE structure


INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging; -- Inserting CTE's content into empty copy


SELECT * FROM layoffs_staging2
WHERE row_num > 1; -- Has duplicates

DELETE 
FROM layoffs_staging2
WHERE row_num > 1; -- We can now delete them

SELECT * FROM layoffs_staging2
WHERE row_num > 1; -- Has no duplicates; we'll get rid of row_num column at the end



-- --------------------------------------------------- 2. Standardizing the data ---------------------------------------------------
SELECT company, TRIM(company)
FROM layoffs_staging2; -- This column has spaces before (and probably after) each name. We have to trim them 


UPDATE layoffs_staging2
SET company = TRIM(company); -- Now the original name will be replaced by the trimmed version


SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1; -- Notice that Crypto = Crypto Currency = CryptoCurrency, but they're treated as different. Must be homogenized

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE '%crypto%'; -- We set them now as equals


UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE '%United%States%'; -- Country has a similar problem. There's a '.' in a record

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; -- Done

SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2; -- date column needs to be updated since its format is currently just flat text

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); -- Done

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE; -- We can now (and must) change the datatype on the table. ONLY DO WITH DUMMY TABLES


-- --------------------------------------------------- 3. Null and Blank values ---------------------------------------------------

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT * 
FROM layoffs_staging2
WHERE company = 'Airbnb'; -- Some Airbnb records have null values in the industry column, but other recods have the correct values. We can fill those nulls


UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ''; -- We first change each blank record to null so we can easily replace it

SELECT  * 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL; -- This Join matches rows of the same company where one table has the industry and the other one doesn't



UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL; -- This updates the null values with the real values found in other rows


SELECT * 
FROM layoffs_staging2
WHERE company LIKE '%Bally%'; -- This record is unique for company Bally's Interactive company, so we have no other reference to get the data from

-- Data like total_laid_off and percentage_laid_off can't be computed nor gotten from other column. Thus, we can't populate these columns
-- Given that we can't fill those gaps with the data at our disposition, we proceed to delete it. total_laid_off and percentage_laid_off

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off IS NULL
AND total_laid_off IS NULL; -- We can't just trust the data of those 2 columns if null values appear on both, since the db is all about layoffs. 
-- Rows with nulls on these two columns will be deleted

DELETE
FROM layoffs_staging2
WHERE percentage_laid_off IS NULL
AND total_laid_off IS NULL; -- Done

-- -------------------------------------- 4. Remove any columns (if needed) -------------------------------------- 

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- --------------------------------------- Clean Data --------------------------------------------
SELECT * 
FROM layoffs_staging2;