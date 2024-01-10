-- Select the required columns (Total Cases, Total Deaths, Population...etc)
SELECT location, 
	date, 
	replace(total_cases,'.0','') AS total_cases, 
	replace(new_cases,'.0','') AS new_cases, 
	replace(total_deaths,'.0','') AS total_deaths,  
	replace(population,'.0','') AS population
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''
ORDER BY location, date


-- Visualizing the relationship between Total Cases and Total Deaths and calculate Deaths percentage
-- Visualize the likelihood of dying from Covid19 in each Country
SELECT location, 
	date, 
	replace(total_cases,'.0','') AS total_cases, 
	replace(total_deaths,'.0','') AS total_deaths, 
	(CAST(total_deaths as float) / NULLIF(CAST(total_cases as float),0))*100 AS deaths_percentage
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''
ORDER BY location, date


-- Visualizing the relationship between Total Cases and Population and calculate Infection percentage
SELECT location,
	date, 
	replace(total_cases,'.0','') AS total_cases, 
	replace(population,'.0','') AS population,
	(CAST(total_cases as float) / NULLIF(CAST(population as float),0))*100 AS infection_percentage
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''
ORDER BY location, date


-- Countries with highest infection rate compared to Population
SELECT location,
	CAST(replace(population,'.0','') as int) AS population,
	MAX(CONVERT(int, replace(total_cases,'.0',''))) AS highest_infection_count,
	MAX((CAST(total_cases as float) / NULLIF(CAST(population as float),0))*100) AS highest_infection_percentage
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''
GROUP BY location, population
ORDER BY highest_infection_percentage DESC


-- Countries with highest death rate compared to Population
SELECT location,
	MAX(CONVERT(int, replace(total_deaths,'.0',''))) AS highest_death_count,
	MAX((CAST(total_deaths as float) / NULLIF(CAST(population as float),0))*100) AS highest_death_percentage
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''
GROUP BY location
ORDER BY highest_death_percentage DESC

-- Total death count per Continent
SELECT continent, 
	SUM(CONVERT(int, replace(total_deaths,'.0',''))) AS total_death_count
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''
GROUP BY continent 
ORDER BY total_death_count DESC

-- Highest death rate per Continent
SELECT continent, 
	MAX(CONVERT(int, replace(total_deaths,'.0',''))) AS highest_death_count
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''
GROUP BY continent 
ORDER BY highest_death_count DESC


-- Global numbers of new cases and new deaths
SELECT SUM(CONVERT(float, replace(new_cases,'.0',''))) AS total_new_cases, 
	SUM(CONVERT(float, replace(new_deaths,'.0',''))) AS total_new_deaths,
	SUM(CAST(new_deaths as float)) / SUM(CAST(new_cases as float))*100 AS recent_death_percentage
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''


-- Exploring the two databases of Covid Deaths and Vaccinations
SELECT CD.continent,
	CD.location, 
	CD.date, 
	CAST(replace(CD.population, '.0', '') as int) AS population,
	CAST(replace(CV.new_vaccinations, '.0', '') as int) AS new_vaccinations_per_day,
	SUM(CAST(CV.new_vaccinations as float)) OVER (PARTITION BY CD.location
													  ORDER BY CD.location, CD.date) AS current_vaccination
FROM [PortfolioProject-Covid19]..CovidDeaths AS CD
INNER JOIN [PortfolioProject-Covid19]..CovidVaccinations AS CV
	ON CD.date = CV.date AND CD.location = CV.location
WHERE CD.continent is not Null AND CD.continent not like ''
ORDER BY CD.location, CD.date


-- Leveraging the CTE (Common Table Expression) feature to use the created columns in further calculations
-- CTE: new_vaccinated_people
WITH new_vaccinated_people (continent, location, date, population, new_vaccinations_per_day, current_vaccination)
AS
(SELECT CD.continent,
	CD.location, 
	CD.date, 
	CAST(replace(CD.population, '.0', '') as int) AS population,
	CAST(replace(CV.new_vaccinations, '.0', '') as int) AS new_vaccinations_per_day,
	SUM(CAST(CV.new_vaccinations as float)) OVER (PARTITION BY CD.location
													  ORDER BY CD.location, CD.date) AS current_vaccination
FROM [PortfolioProject-Covid19]..CovidDeaths AS CD
INNER JOIN [PortfolioProject-Covid19]..CovidVaccinations AS CV
	ON CD.date = CV.date AND CD.location = CV.location
WHERE CD.continent is not Null AND CD.continent not like ''
)
SELECT *, 
	-- IIF statement because some locations have multiple vaccinations for each individual, so the percentage is bigger than 100
	IIF((current_vaccination/population) >1, 1, (current_vaccination/population))*100 AS current_vaccination_percentages
FROM new_vaccinated_people
ORDER BY location, current_vaccination_percentages DESC


-- Creating a temporary table from the previous CTE (new_vaccinated_people) one
DROP TABLE IF EXISTS #new_vaccinated_population
CREATE TABLE #new_vaccinated_population (
continent varchar(50),
location varchar(50), 
date varchar(50), 
population int,
new_vaccinations_per_day int,
current_vaccination float
)

INSERT INTO #new_vaccinated_population
SELECT CD.continent,
	CD.location, 
	CD.date, 
	CAST(replace(CD.population, '.0', '') as int) AS population,
	CAST(replace(CV.new_vaccinations, '.0', '') as int) AS new_vaccinations_per_day,
	SUM(CAST(CV.new_vaccinations as float)) OVER (PARTITION BY CD.location
													  ORDER BY CD.location, CD.date) AS current_vaccination
FROM [PortfolioProject-Covid19]..CovidDeaths AS CD
INNER JOIN [PortfolioProject-Covid19]..CovidVaccinations AS CV
	ON CD.date = CV.date
	AND CD.location = CV.location
WHERE CD.continent is not Null 
	AND CD.continent not like ''

SELECT *,
	IIF((current_vaccination/population) >1, 1, (current_vaccination/population))*100 AS current_vaccination_percentages
FROM #new_vaccinated_population

-- Creating views for storing the data and for visualization
USE [PortfolioProject-Covid19] -- Marking Database Destination
GO
CREATE VIEW new_vaccinated_population AS
SELECT CD.continent,
	CD.location, 
	CD.date, 
	CAST(replace(CD.population, '.0', '') as int) AS population,
	CAST(replace(CV.new_vaccinations, '.0', '') as int) AS new_vaccinations_per_day,
	SUM(CAST(CV.new_vaccinations as float)) OVER (PARTITION BY CD.location
													  ORDER BY CD.location, CD.date) AS current_vaccination
FROM [PortfolioProject-Covid19]..CovidDeaths AS CD
INNER JOIN [PortfolioProject-Covid19]..CovidVaccinations AS CV
	ON CD.date = CV.date
	AND CD.location = CV.location
WHERE CD.continent is not Null
	AND CD.continent not like ''

SELECT *
FROM new_vaccinated_population
ORDER BY date DESC