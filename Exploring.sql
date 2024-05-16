-- Exploratory Data Analysis
-- Iker Sánchez

USE world_layoffs;

SELECT *
FROM layoffs_staging2;

-- Best and worst cases of layoffs in percentage terms
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Total layoffs per company
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Layoffs date intervals
SELECT MIN(date), MAX(date)
FROM layoffs_staging2;

-- Total layoffs of each industry
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Total layoffs by country
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;


-- Total layoffs by year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;


-- Total layoffs per stage (whether it is a startup, class A, B, etc. up until post-IPO such as Google)
-- IPO stands for Initial Public Offer, which refers to the first time a company goes public for the first time in the equity market
-- The "Higher" the letter of the stage, the more relative growth in terms of development the company has.
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;


-- Progression of Layoff by month
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE  SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

WITH ROLLING_TOTAL AS
(

SELECT SUBSTRING(`date`, 1, 7) AS `YMONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE  SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `YMONTH`
ORDER BY 1 ASC

) SELECT `YMONTH`, total_off, SUM(total_off) OVER(ORDER BY `YMONTH`) AS rolling_total 
FROM ROLLING_TOTAL;	
-- The rolling_total column sums the values of the column total_off (total employees laid off each month)
-- row by row (from top to bottom) ORDER clause is just so it can sum it in a desired order


SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY company ASC; -- This will list lay offs for each company, each year


-- We can also see which companies were the ones that laid off the most people each year.
WITH Company_year AS
(

SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off) AS laid_off
FROM layoffs_staging2
GROUP BY company, `year`

), Company_Year_Rank AS 
(

 SELECT *, 
DENSE_RANK() OVER(PARTITION BY `year` ORDER BY laid_off DESC) AS rank_off 
FROM Company_year
WHERE `year` IS NOT NULL

) SELECT *
FROM Company_Year_Rank
WHERE rank_off <= 5;




-- We can also query the ranking based on which company raised the most funds in each industry as follows:
WITH funds_per_company AS(

SELECT industry, company, SUM(funds_raised_millions) AS funds
FROM layoffs_staging2
GROUP BY industry, company

) SELECT industry, company, funds, DENSE_RANK() OVER (PARTITION BY industry ORDER BY funds DESC) AS funds_rank
FROM funds_per_company
WHERE industry IS NOT NULL;









