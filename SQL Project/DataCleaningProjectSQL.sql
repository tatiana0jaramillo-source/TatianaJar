
SELECT COUNT(*) AS total_filas
FROM layoffs; #dice cantidad total de filas del documento

-- Project Data Cleaning
SET SQL_SAFE_UPDATES = 0;
#SET SQL_SAFE_UPDATES = 1;

SELECT *
FROM layoffs;  # Original data

-- Steps for data cleaning in this project
-- 1. Remove Duplicates 
-- 2. Standardize the Data -  to find is there any issue with the data
-- 3. Null Values or blank values - No values
-- 4. Remove Any Columns or Rows

##we need to copy all original data in order to study and edit this data
#The reason is beacuse if we mfailed with ddata data, w e nedd to have the raw data avaibale 
#Always work the copy
CREATE TABLE layoffs_staging 
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- -- 1. Remove Duplicates 
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, "date") ## For those columns # date is a keyword in MYSQL
AS row_num FROM layoffs_staging;

# We are going to filter where row number is >1, meaning is duplicate

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, "date", stage, country, funds_raised_millions) AS row_num 
FROM layoffs_staging 
)

SELECT * 
FROM duplicate_cte 
WHERE row_num > 1; # Find the duplicated data, it give us our duplicated data

SELECT * 
FROM layoffs_staging 
WHERE company = "Casper"; # Here we check is there is any duplciated careful maybe there is no duplicate

# Eliminate duplicates

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num 
FROM layoffs_staging 
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

# Create Statement
# create new table, to add row num column
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
--
SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num 
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1; # This one give me duplicates, where the column row_num =2, thos are the one i want to delete

DELETE
FROM layoffs_staging2
WHERE row_num > 1; # This one delete duplicates

SELECT *
FROM layoffs_staging2;
# here we already deleted those with row_num=2

-- 2Standardizzing data
SELECT company, TRIM(Company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE "Crypto%"; # we have to change this one because there is a crypto cryptocurrency...and they are all the same

UPDATE layoffs_staging2
SET industry = "Crypto"
WHERE industry LIKE "Crypto%"; #  Crypto is standarized

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; #here we notices that we need to fix To fix United Stated vs United Stated.

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE "United States%"; #  US is standarized

# date, to date format
SELECT `date`,
STR_TO_DATE(`date`,"%m/%d/%Y") # from text to date
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`,"%m/%d/%Y"); # from text to date


SELECT `date`
FROM layoffs_staging2; # now we have data with the correct format in their column

#still date is text but date format
# chANGE DATA TYPE

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE ; # here date change from text to fate in definition column

SELECT *
FROM layoffs_staging2;  # we check how is our data now

SELECT *
FROM layoffs_staging2 
WHERE total_laid_off IS NULL # it gives where this colum is null
AND percentage_laid_off IS NULL; # but h ere is says where booth column are null

UPDATE layoffs_staging2 t1
SET industry = NULL
WHERE industry = "";

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ' ';

SELECT *
FROM layoffs_staging2
WHERE company = "Airbnb";

SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company =t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company =t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE company LIKE "Bally%";

SELECT *
FROM layoffs_staging2;

#We may able to populate total-laid_off, precentage_laid_off and funs...
# but we need total of employee in order to calculute those columns
# with no data, we can not populate those column
# in these project we are gonna delete because is a academic project
#WE ARE GONA DROP A COLUMN

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;