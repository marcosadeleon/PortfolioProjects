/*
Covid-19 Data Exploration

Skills used:
    CTE's
    Temp Tables
    Creating Views
    Converting Data Types
    Aggregate Functions
    Join
*/

CREATE DATABASE CovidPortfolioProject;
USE CovidPortfolioProject;

-- View and Verify Imports
SELECT * FROM coviddeaths;
SELECT * FROM covidvaccinations;

-----------------------------------------------------------------------------------------------------------------------------------------------

-- What is the likelihood that I will die if I get Covid (in the United States)?
-- Total Deaths vs Cases

SELECT
    location,
    MAX(total_cases) as TotalCasesToDate,
    -- alternatively: SUM(new_cases) as TotalCasesToDate,
    Max(total_deaths) as TotalDeathsToDate,
    ROUND((Max(total_deaths)/MAX(total_cases))*100,2) as OverallDeathPercentage
FROM
	coviddeaths
WHERE
	location LIKE '%states%';

-----------------------------------------------------------------------------------------------------------------------------------------------

-- What is the likelihood that I contract Covid (in the United States)?
-- Total Cases vs Population

SELECT
    location,
    MAX(total_cases) as TotalCasesToDate,
    population,
	ROUND((SUM(new_cases)/population)*100,2) as PercentPopulationInfected
FROM
	coviddeaths
WHERE
	location LIKE '%states%';

-----------------------------------------------------------------------------------------------------------------------------------------------

-- In what month were there the most reported cases of Covid in the United States?

SELECT
	YEAR(CAST(str_to_date(date, '%m/%d/%Y') AS date)) as year,
	MONTH(CAST(str_to_date(date, '%m/%d/%Y') AS date)) as month,
	SUM(new_cases) as Cases_ThisMonth,
	ROUND((SUM(new_cases)/population)*100,2) as PercentPopulationInfected_ThisMonth
FROM
	coviddeaths
WHERE
	location LIKE '%states%'
GROUP BY
	year, month
ORDER BY
	PercentPopulationInfected_ThisMonth DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------

-- Return a table that shows the cumulative increase of reported Covid cases and what % of the population has been infected

SELECT
	YEAR(CAST(str_to_date(date, '%m/%d/%Y') AS date)) as year,
	MONTH(CAST(str_to_date(date, '%m/%d/%Y') AS date)) as month,
	MAX(total_cases) as TotalCases_Cumulative,
        ROUND((MAX(total_cases)/population)*100,2) as PercentPopulationInfected_Cumulative    
FROM
	coviddeaths
WHERE
	location LIKE '%states%'
GROUP BY
	year, month;

-----------------------------------------------------------------------------------------------------------------------------------------------

-- What percentage of United States population has recieved at least one Covid Vaccine?

SELECT
    coviddeaths.location,
    coviddeaths.population,
    MAX(people_vaccinated) as TotalPeopleVaccinated,
    ROUND((MAX(people_vaccinated)/population)*100,2) as VaccinationPercentageToDate
FROM
	coviddeaths
JOIN
	covidvaccinations vac
ON
	coviddeaths.date = covidvaccinations.date
AND
	coviddeaths.location = vac.location
WHERE
	coviddeaths.location LIKE '%states%';
  
  -----------------------------------------------------------------------------------------------------------------------------------------------
  
-- Return a table that shows the cumulative increase the United States population receiving a Covid vaccine and what % of the population has been vaccinated

SELECT
        YEAR(CAST(str_to_date(coviddeaths.date, '%m/%d/%Y') AS date)) as year,
	MONTH(CAST(str_to_date(coviddeaths.date, '%m/%d/%Y') AS date)) as month,
        MAX(covidvaccinations.people_vaccinated) as TotalPeopleVaccinated_Cumulative,
        ROUND(MAX(covidvaccinations.people_vaccinated)/coviddeaths.population*100,2) as TotalVaccinationPercentage_Cumulative
FROM
	coviddeaths	
JOIN
	covidvaccinations
ON
	coviddeaths.date = covidvaccinations.date
AND
	coviddeaths.location = covidvaccinations.location
WHERE
	coviddeaths.location LIKE '%states%'
GROUP BY
	year, month;

-----------------------------------------------------------------------------------------------------------------------------------------------

-- Using CTE to perform calculation on previous query

WITH
	PopVaccinated(Year, Month, population, TotalPeopleVaccinated_Cumulative)
AS
(
SELECT
	YEAR(CAST(str_to_date(coviddeaths.date, '%m/%d/%Y') AS date)) as year,
	MONTH(CAST(str_to_date(coviddeaths.date, '%m/%d/%Y') AS date)) as month,
        coviddeaths.population,
        MAX(covidvaccinations.people_vaccinated) as TotalPeopleVaccinated_Cumulative
        -- ROUND(MAX(covidvaccinations.people_vaccinated)/coviddeaths.population*100,2) as TotalVaccinationPercentage_Cumulative
FROM
	coviddeaths	
JOIN
	covidvaccinations
ON
	coviddeaths.date = covidvaccinations.date
WHERE
	coviddeaths.location LIKE '%states%'
GROUP BY
	year, month
)
SELECT *, ROUND(TotalPeopleVaccinated_Cumulative/population*100,2) as TotalVaccinationPercentage_Cumulative
FROM PopVaccinated;

-----------------------------------------------------------------------------------------------------------------------------------------------

-- Using temp table to perform calculation on previous query

DROP TABLE IF EXISTS UnitedStatesVaccinationbyMonth;

CREATE TABLE UnitedStatesVaccinationbyMonth(
Year int,
Month int,
population numeric,
TotalPeopleVaccinated_Cumulative numeric
);

INSERT INTO
	UnitedStatesVaccinationbyMonth
SELECT
	YEAR(CAST(str_to_date(coviddeaths.date, '%m/%d/%Y') AS date)) as year,
	MONTH(CAST(str_to_date(coviddeaths.date, '%m/%d/%Y') AS date)) as month,
	coviddeaths.population,
        MAX(covidvaccinations.people_vaccinated) as TotalPeopleVaccinated_Cumulative
        -- ROUND((MAX(covidvaccinations.people_vaccinated))/coviddeaths.population*100,2) as TotalVaccinationPercentage_Cumulative
FROM
	coviddeaths
JOIN
	covidvaccinations
ON
	coviddeaths.date = covidvaccinations.date
AND
	coviddeaths.location = covidvaccinations.location
WHERE
	coviddeaths.location LIKE '%states%'
GROUP BY
	year, month;

SELECT *, ROUND(TotalPeopleVaccinated_Cumulative/population*100,2) as TotalVaccinationPercentage_Cumulative
FROM UnitedStatesVaccinationbyMonth;

-----------------------------------------------------------------------------------------------------------------------------------------------

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT
	YEAR(CAST(str_to_date(coviddeaths.date, '%m/%d/%Y') AS date)) as year,
	MONTH(CAST(str_to_date(coviddeaths.date, '%m/%d/%Y') AS date)) as month,
        MAX(covidvaccinations.people_vaccinated) as TotalPeopleVaccinated_Cumulative,
        ROUND(MAX(covidvaccinations.people_vaccinated)/coviddeaths.population*100,2) as TotalVaccinationPercentage_Cumulative
FROM
	coviddeaths	
JOIN
	covidvaccinations
ON
	coviddeaths.date = covidvaccinations.date
AND
	coviddeaths.location = covidvaccinations.location
WHERE
	coviddeaths.location LIKE '%states%'
GROUP BY
	year, month;

-----------------------------------------------------------------------------------------------------------------------------------------------

-- After reviewing data for United States specifically in all queries above, now interested in global numbers

-- Comparing by country
    -- % of population infected
    -- % death if disease contracted
    -- % of population vaccinated
SELECT 
	coviddeaths.location,
        coviddeaths.population,
	ROUND((MAX(coviddeaths.total_cases)/coviddeaths.population)*100,2) as PercentPopulationInfected,
        ROUND((MAX(coviddeaths.total_deaths)/MAX(coviddeaths.total_cases))*100,2) as DeathPercentageIfContracted,
	ROUND((MAX(covidvaccinations.people_vaccinated)/MAX(coviddeaths.population))*100,2) as PercentPopulationVaccinated
FROM
	coviddeaths
JOIN
	covidvaccinations
ON
	coviddeaths.date = covidvaccinations.date
AND
	coviddeaths.location = covidvaccinations.location
GROUP BY
	coviddeaths.location
ORDER BY
	population DESC;
    
-----------------------------------------------------------------------------------------------------------------------------------------------
    
-- Identifying the month and year that each country achieved 50% population vaccinated

SELECT
	coviddeaths.location,
        YEAR(CAST(str_to_date(coviddeaths.date, '%m/%d/%Y') AS date)) as year,
	MONTH(CAST(str_to_date(coviddeaths.date, '%m/%d/%Y') AS date)) as month,
	ROUND((MIN(covidvaccinations.people_vaccinated)/coviddeaths.population)*100,2) as PercentPopulationVaccinated
FROM
	coviddeaths
JOIN
	covidvaccinations
ON
	coviddeaths.date = covidvaccinations.date
AND
	coviddeaths.location = covidvaccinations.location
WHERE
    (covidvaccinations.people_vaccinated/coviddeaths.population)*100 > 50
GROUP BY
	coviddeaths.location
ORDER BY
	year, month;
