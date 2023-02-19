/*
COVID-19 Deaths & Vaccinations Data Exploration 

Data Range: 1/1/2020 - 4/30/2021

Skills used: Joins, CTE's, Temp Tables, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT * 
FROM [DA-PortfolioProject1]..CovidDeaths
WHERE continent IS NOT NULL
order by 3, 4

-- Select Starting Data

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [DA-PortfolioProject1]..CovidDeaths
ORDER BY 1, 2

-- Total Cases vs Total Deaths
-- Indicates likelihood (in percantage) of dying from virus contraction in South Africa

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS Death_Percentage
FROM [DA-PortfolioProject1]..CovidDeaths
WHERE location like '%south af%'
ORDER BY 1, 2

-- Total Cases vs Population
-- Indicates the percentage of the population infected with COVID-19

SELECT location, date, population, total_cases, (total_cases/population)*100 AS Population_Percentage
FROM [DA-PortfolioProject1]..CovidDeaths
WHERE location like '%south afr%'
ORDER BY 1, 2

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS Population_Percentage
FROM [DA-PortfolioProject1]..CovidDeaths
GROUP BY population, location
ORDER BY Population_Percentage DESC

-- Highest Death Counts per Continent

SELECT location, MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM [DA-PortfolioProject1]..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_Death_Count DESC

-- Highest Death Counts per Country 

SELECT location, MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM [DA-PortfolioProject1]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC

-- Global Numbers

SELECT date, SUM(new_cases) AS Total_Cases, SUM(cast(new_deaths as int)) AS Total_Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100
AS Death_Percentage
FROM [DA-PortfolioProject1]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2 DESC

SELECT SUM(new_cases) AS Total_Cases, SUM(cast(new_deaths as int)) AS Total_Deaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM [DA-PortfolioProject1]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2 

-- Total Population vs Vaccinations
-- Shows the Percentage of Population that has received at least one Vaccine

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations,
SUM(CONVERT(int, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location,
deaths.date) AS Rolling_Vacc_Count
FROM [DA-PortfolioProject1]..CovidDeaths deaths
JOIN [DA-PortfolioProject1]..CovidVaccinations vacc
	ON deaths.date = vacc.date
	AND deaths.location = vacc.location
WHERE deaths.continent IS NOT NULL 
ORDER BY 2, 3


-- Using CTE for Calculation on Partition By using previous query

WITH PopVsVacc (continent, location, date, population, new_vaccinations, Rolling_Vacc_Count)
AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations,
SUM(CONVERT(int, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location,
deaths.date) AS Rolling_Vacc_Count
FROM [DA-PortfolioProject1]..CovidDeaths deaths
JOIN [DA-PortfolioProject1]..CovidVaccinations vacc
	ON deaths.date = vacc.date
	AND deaths.location = vacc.location
WHERE deaths.continent IS NOT NULL 
)
SELECT *, (Rolling_Vacc_Count/population)*100
FROM PopVsVacc


-- Creating Temp Table for Percentage of Vaccinations per Population

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime, 
population numeric, 
new_vaccinations numeric, 
Rolling_Vacc_Count numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations,
SUM(CONVERT(int, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location,
deaths.date) AS Rolling_Vacc_Count
FROM [DA-PortfolioProject1]..CovidDeaths deaths
JOIN [DA-PortfolioProject1]..CovidVaccinations vacc
	ON deaths.date = vacc.date
	AND deaths.location = vacc.location
--WHERE deaths.continent IS NOT NULL 

SELECT *, (Rolling_Vacc_Count/population)*100
FROM #PercentPopulationVaccinated


-- Creating Views to store data for visualizations 

CREATE VIEW PercentPopulationVaccinated AS
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations,
SUM(CONVERT(int, vacc.new_vaccinations)) OVER (PARTITION BY deaths.location ORDER BY deaths.location,
deaths.date) AS Rolling_Vacc_Count
FROM [DA-PortfolioProject1]..CovidDeaths deaths
JOIN [DA-PortfolioProject1]..CovidVaccinations vacc
	ON deaths.date = vacc.date
	AND deaths.location = vacc.location
WHERE deaths.continent IS NOT NULL 

CREATE VIEW Global_Counts AS
SELECT SUM(new_cases) AS Total_Cases, SUM(cast(new_deaths as int)) AS Total_Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100
AS Death_Percentage
FROM [DA-PortfolioProject1]..CovidDeaths
WHERE continent IS NOT NULL

CREATE VIEW Deaths_per_Continent AS
SELECT location, MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM [DA-PortfolioProject1]..CovidDeaths
WHERE continent IS NULL
GROUP BY location

CREATE VIEW Deaths_per_Country AS
SELECT location, MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM [DA-PortfolioProject1]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
