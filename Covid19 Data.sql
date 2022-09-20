
-- Covid19 data exploration
-- Using: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types.
-- NB: Had some limittions on data during importing it especially involing data types; all columns were imported as nvarchar, so I had to move around it.




-- Exploring Data

SELECT * FROM Covid19Data.dbo.CovidDeaths
WHERE continent is not null AND location = 'Africa'
ORDER BY 3,4

SELECT * FROM Covid19Data.dbo.CovidVac
ORDER BY 3,4



-- Liklihood of dying if infected with Covid in Egypt

SELECT location, cast(date as date), total_cases, total_deaths, 
(cast(total_deaths as float)/nullif(cast(total_cases as float),0))*100 AS DeathPercentage 
FROM Covid19Data.dbo.CovidDeaths
WHERE location like 'Egypt'
ORDER BY 1,2

-- Total cases Vs Population

SELECT location, cast(date as date) AS Date, population ,total_cases,
(cast(total_cases as float)/nullif(cast(population as float),0))*100 AS InfectionPercentage 
FROM Covid19Data.dbo.CovidDeaths
WHERE location like 'Egypt'
ORDER BY 1,2

-- World infection rate vs population

SELECT location, 
population ,
MAX(cast(total_cases as float)) AS TotalCases,
MAX((cast(total_cases as float)/nullif(cast(population as float),0))*100) AS InfectionPercentage
FROM Covid19Data.dbo.CovidDeaths
GROUP BY location, population
HAVING MAX(total_cases) is not null AND MAX((cast(total_cases as float)/nullif(cast(population as float),0))*100) is not null
ORDER BY InfectionPercentage DESC


-- Deaths Stats By Country

SELECT location, 
population ,
MAX(cast(total_deaths as float)) AS TotalDeaths,
MAX((cast(total_deaths as float)/nullif(cast(population as float),0))*100) AS DeathPercentage
FROM Covid19Data.dbo.CovidDeaths
WHERE continent is not null AND continent <> ''
GROUP BY location, population
HAVING MAX(total_cases) is not null 
AND MAX((cast(total_cases as float)/nullif(cast(population as float),0))*100) is not null
ORDER BY 1 


-- Deaths Stats By Continent

SELECT location, 
population ,
MAX(cast(total_deaths as float)) AS TotalDeaths,
MAX((cast(total_deaths as float)/nullif(cast(population as float),0))*100) AS DeathPercentage
FROM Covid19Data.dbo.CovidDeaths
WHERE (continent is null OR continent = '')
AND location in ('Africa','Asia','North America','South America','Oceania','Europe')
GROUP BY location, population
HAVING MAX(total_cases) is not null AND MAX((cast(total_cases as float)/nullif(cast(population as float),0))*100) is not null
ORDER BY 3 DESC


-- Global Numbers

SELECT CAST(date as date) as Date, SUM(CAST(new_cases as int)) AS TotalCases, SUM(CAST(new_deaths as int)) AS TotalDeaths,
(SUM(CAST(new_deaths as float))/NULLIF(SUM(CAST(new_cases as int)),0))*100 AS DeathPercentage
FROM Covid19Data.dbo.CovidDeaths
WHERE continent is not null AND continent <> ''
GROUP BY Date
order by 1,2,3


--Total Population Vs Total Vaccination


-- USING CTE 
WITH PopVac (Continent, Location, Date, Population, NewVaccination, RollingPeopleVaccinated)
AS
(
SELECT d.continent, d.location, cast(d.date as date) AS Date, d.population, v.new_vaccinations, 
SUM(CONVERT(float, v.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.location, cast(d.date as date)) AS RollingPeopleVaccinated
FROM Covid19Data.dbo.CovidDeaths d 
INNER JOIN Covid19Data.dbo.CovidVac v
	ON d.date  = v.date
	AND d.location = v.location
WHERE d.continent is not null AND d.continent <> ''
)
SELECT *, RollingPeopleVaccinated/NULLIF(Population ,0) AS PercentageVaccinated FROM PopVac
ORDER BY 2,3


-- USING TEMP TABLE
DROP TABLE if EXISTS #PopVaccinatedPercentage
CREATE TABLE #PopVaccinatedPercentage
(
Continent nvarchar(255), 
Location nvarchar(255), 
Date datetime, 
Population float, 
NewVaccination float, 
RollingPeopleVaccinated float
)

INSERT INTO #PopVaccinatedPercentage
SELECT d.continent, d.location, cast(d.date as date) AS Date, d.population, v.new_vaccinations, 
SUM(CONVERT(float, v.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.location, cast(d.date as date)) AS RollingPeopleVaccinated
FROM Covid19Data.dbo.CovidDeaths d INNER JOIN Covid19Data.dbo.CovidVac v
ON d.date  = v.date
AND d.location = v.location
WHERE d.continent is not null AND d.continent <> ''

SELECT *, RollingPeopleVaccinated/NULLIF(Population ,0) AS PercentageVaccinated 
FROM #PopVaccinatedPercentage
ORDER BY 2,3


-- Creating view

Create VIEW PercentPopulationVaccinated as 
SELECT location, 
population,
MAX(cast(total_deaths as float)) AS TotalDeaths,
MAX((cast(total_deaths as float)/nullif(cast(population as float),0))*100) AS DeathPercentage
FROM Covid19Data.dbo.CovidDeaths
WHERE continent is not null AND continent <> ''
GROUP BY location, population
HAVING MAX(total_cases) is not null 
AND MAX((cast(total_cases as float)/nullif(cast(population as float),0))*100) is not null

SELECT * FROM PercentPopulationVaccinated 