/*******************************************************
		Some quarries for data visualization
*******************************************************/

-- 1. Global numbers of new cases and new deaths
SELECT SUM(CONVERT(int, replace(new_cases,'.0',''))) AS total_cases, 
	SUM(CONVERT(int, replace(new_deaths,'.0',''))) AS total_deaths,
	SUM(CAST(new_deaths as float)) / SUM(CAST(new_cases as float))*100 AS death_percentage
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''

-- 2. Total death count per Continent
SELECT continent, 
	SUM(CONVERT(int, replace(total_deaths,'.0',''))) AS total_death_count
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''
GROUP BY continent 
ORDER BY total_death_count DESC

-- 3. Countries with highest infection rate compared to Population
SELECT location,
	CAST(replace(population,'.0','') as int) AS population,
	MAX(CONVERT(int, replace(total_cases,'.0',''))) AS highest_infection_count,
	MAX((CAST(total_cases as float) / NULLIF(CAST(population as float),0))*100) AS highest_infection_percentage
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''
GROUP BY location, population
ORDER BY highest_infection_percentage DESC

-- 4. Countries with highest infection rate compared to Population by date
SELECT location,
	date,
	CAST(replace(population,'.0','') as int) AS population,
	MAX(CONVERT(int, replace(total_cases,'.0',''))) AS highest_infection_count,
	MAX((CAST(total_cases as float) / NULLIF(CAST(population as float),0))*100) AS highest_infection_percentage
FROM [PortfolioProject-Covid19]..CovidDeaths
WHERE continent is not Null AND continent not like ''
GROUP BY location, population, date
ORDER BY highest_infection_percentage DESC