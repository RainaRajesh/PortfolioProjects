/* 

Project:	SQL Data Exploration

Source:		Raw data on confirmed cases and deaths for all countries is sourced from the COVID-19 Data Repository 
			by the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University.

Dataset:	Coronavirus Pandemic (COVID-19) - Statistics and Research - Our World in Data 
Link:		(https://ourworldindata.org/coronavirus#coronavirus-country-profiles)

Skills:		JOIN, Common Table Expression (CTE), Temporary Tables (TEMP TABLES), VIEW, Functions, Data type manipulation 

Tools:		MS Excel, MS SQL Server 2019

*/

-- Query the imported tables
-- covid_deaths table

SELECT * 
FROM CovidDataWorld..covid_deaths
ORDER BY location, date

-- covid_vaccinations table

SELECT *
FROM CovidDataWorld..covid_vaccinations
ORDER BY location, date

-- location includes continent names, and continent is NULL for those locations
-- Create queries to not use data where the continent as NULL
-- covid_deaths table

SELECT * 
FROM CovidDataWorld..covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- covid_vaccinations table

SELECT * 
FROM CovidDataWorld..covid_vaccinations
WHERE continent IS NOT NULL
ORDER BY location, date

-- The data I would focus on in covid_deaths table
-- location, date, new_cases, total_cases, total_deaths, population
-- Country focus: Australia

Select location, date, new_cases, total_cases, total_deaths, population
FROM CovidDataWorld..covid_deaths
Where location like '%Australia%' 
order by date

-- Death Rate as a percent of Total Cases
-- Round to 2 digits

Select date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) as death_rate
FROM CovidDataWorld..covid_deaths
Where location like '%Australia%' 
order by death_rate DESC

-- MAX Infection Rate reached as a percent of Population in Australia

Select ROUND(MAX((total_cases/population)*100),2) as max_infection_rate
FROM CovidDataWorld..covid_deaths
Where location like '%Australia%' 

-- Comparing it to other countries

SELECT location, population, ROUND(MAX(total_cases/population)*100,2) as max_infection_rate
FROM CovidDataWorld..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY max_infection_rate DESC

-- Death Count grouped by Country
-- total_deaths is stored as nvarchar in the dataset

SELECT location, MAX(CAST(total_deaths as int)) as death_count
FROM CovidDataWorld..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY death_count DESC

-- Death Count grouped by Continent

SELECT continent, MAX(CAST(total_deaths as int)) as death_count
FROM CovidDataWorld..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY death_count DESC

-- Global numbers
-- Total number of cases

SELECT SUM(new_cases) as case_count
FROM CovidDataWorld..covid_deaths
WHERE continent IS NOT NULL

-- Death Count as a percentage of Total Cases globally
-- new_deaths is stored as nvarchar in the dataset

SELECT SUM(CAST(new_deaths as int)) as death_count, SUM(new_cases) as case_count, ROUND(((SUM(CAST(new_deaths as int))/SUM(new_cases))*100), 2) as death_rate
FROM CovidDataWorld..covid_deaths
WHERE continent IS NOT NULL

-- JOIN
-- Join the two tables on location and date

SELECT *
FROM CovidDataWorld..covid_deaths as dth
JOIN CovidDataWorld..covid_vaccinations as vcn
ON dth.location = vcn.location
and dth.date = vcn.date
WHERE dth.continent IS NOT NULL

-- Population and Vaccinations grouped by Country

SELECT dth.location, dth.population, SUM(CAST(vcn.new_vaccinations as float)) AS vaccination_count
FROM CovidDataWorld..covid_deaths as dth
JOIN CovidDataWorld..covid_vaccinations as vcn
ON dth.location = vcn.location
and dth.date = vcn.date
WHERE dth.continent IS NOT NULL
GROUP BY dth.location, dth.population
ORDER BY vaccination_count DESC

-- People fully vaccinated as a % of population
-- Grouped by Country

SELECT dth.location, dth.population, MAX(CAST(vcn.people_fully_vaccinated as float)) AS full_vaccination_count, 
	ROUND((MAX(CAST(vcn.people_fully_vaccinated as float))/dth.population*100), 2) AS full_vaccination_rate
FROM CovidDataWorld..covid_deaths AS dth
JOIN CovidDataWorld..covid_vaccinations AS vcn
	ON dth.location = vcn.location
	AND dth.date = vcn.date
WHERE dth.continent IS NOT NULL
GROUP BY dth.location, dth.population
ORDER BY full_vaccination_count DESC, full_vaccination_rate DESC

-- OVER, PARTITION BY clauses 
-- Rolling count of population that has received at least one dose
-- Filtered for Australia, United States

SELECT dth.location, dth.population, dth.date, vcn.new_vaccinations,
	SUM(CONVERT(float, vcn.new_vaccinations)) OVER(
	PARTITION BY dth.location
	ORDER BY dth.location, dth.date
	) AS single_dose_count_rolling
FROM CovidDataWorld..covid_deaths as dth
JOIN CovidDataWorld..covid_vaccinations as vcn
	ON dth.location = vcn.location
	AND dth.date = vcn.date
WHERE dth.continent IS NOT NULL AND (dth.location LIKE '%Australia%' OR dth.location LIKE '%States%')
ORDER BY dth.location, dth.date


-- Using Common Table Expressions (CTE) for the previous query
-- Adding percentage of population vaccinated

WITH cte_new_vcn (location, population, date, new_vaccinations, single_dose_count_rolling) AS (
	SELECT dth.location, dth.population, dth.date, vcn.new_vaccinations,
	SUM(CONVERT(float, vcn.new_vaccinations)) OVER(
	PARTITION BY dth.location
	ORDER BY dth.location, dth.date
	) AS single_dose_count_rolling
	FROM CovidDataWorld..covid_deaths as dth
	JOIN CovidDataWorld..covid_vaccinations as vcn
		ON dth.location = vcn.location
		AND dth.date = vcn.date
	WHERE dth.continent IS NOT NULL AND (dth.location LIKE '%Australia%' OR dth.location LIKE '%States%')
)

-- Query the created CTE

SELECT *, ROUND(((single_dose_count_rolling/cte_new_vcn.population)*100), 2) AS single_dose_percent
FROM cte_new_vcn
ORDER BY cte_new_vcn.location, cte_new_vcn.date

-- Temp Table
-- Good practice to DROP the table if already created

DROP TABLE IF EXISTS #vcn_data

-- Create Table

CREATE TABLE #vcn_data (
	location NVARCHAR (255),
	population NUMERIC,
	date DATETIME,
	new_vcns NUMERIC,
	vcn_count_rolling NUMERIC, 
)

-- Insert data into created table

INSERT INTO #vcn_data
SELECT dth.location, dth.population, dth.date, vcn.new_vaccinations,
	SUM(CONVERT(float, vcn.new_vaccinations)) OVER(
	PARTITION BY dth.location
	ORDER BY dth.location, dth.date
	) AS single_dose_count_rolling
FROM CovidDataWorld..covid_deaths as dth
JOIN CovidDataWorld..covid_vaccinations as vcn
	ON dth.location = vcn.location
	AND dth.date = vcn.date
WHERE dth.continent IS NOT NULL AND (dth.location LIKE '%Australia%' OR dth.location LIKE '%States%') 
	
-- Query the created temporary table

SELECT *, ROUND(((vcn_count_rolling/population) * 100), 2) AS single_dose_percent
FROM #vcn_data
ORDER BY location

-- DROP the earlier created temporary table

DROP TABLE IF EXISTS #vcn_data

-- Create VIEW

CREATE VIEW vcn_data_view AS
	SELECT dth.location, dth.population, dth.date, vcn.new_vaccinations, 
		SUM(CONVERT(float, vcn.new_vaccinations)) OVER (
		PARTITION BY dth.location
		ORDER BY dth.location, dth.date
		) AS single_dose_count_rolling
	FROM CovidDataWorld..covid_deaths as dth
	JOIN CovidDataWorld..covid_vaccinations as vcn
		ON dth.location = vcn.location
		AND dth.date = vcn.date
	WHERE dth.continent IS NOT NULL AND (dth.location LIKE '%Australia%' OR dth.location LIKE '%States%')

-- Query the created VIEW

SELECT *
FROM vcn_data_view
ORDER BY vcn_data_view.location



