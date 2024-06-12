/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From CovidDeaths
Where continent is not null 
order by 3,4;


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
order by 1,2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
-- Where location like 'germany'
Where continent is not null 
order by 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths
-- Where location like 'germany'
order by 1,2;


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
-- Where location like 'germany'
Group by Location, Population
order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population

SELECT Location, MAX(TotalDeathCount) as TotalDeathCount
FROM (
    SELECT Location, CAST(Total_deaths AS UNSIGNED) as TotalDeathCount
    FROM CovidDeaths
    WHERE continent IS NOT NULL
) as Converted
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent, MAX(TotalDeathCount) AS TotalDeathCount
FROM (
    SELECT continent, CAST(Total_deaths AS UNSIGNED) AS TotalDeathCount
    FROM CovidDeaths
    WHERE continent IS NOT NULL
) AS Converted
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS

SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths, 
    (SUM(new_deaths) / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY total_cases, total_deaths;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
    sub.continent, 
    sub.location, 
    sub.date, 
    sub.population, 
    sub.new_vaccinations,
    sub.RollingPeopleVaccinated,
    (sub.RollingPeopleVaccinated / sub.population) * 100 AS VaccinationPercentage
FROM (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
) AS sub
ORDER BY sub.location, sub.date;


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT 
    Continent, 
    Location, 
    Date, 
    Population, 
    New_Vaccinations, 
    RollingPeopleVaccinated, 
    (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM PopvsVac
ORDER BY Location, Date;


-- Using Temp Table to perform Calculation on Partition By in previous query


DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT 
    Continent, 
    Location, 
    Date, 
    Population, 
    New_vaccinations, 
    RollingPeopleVaccinated,
    (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM PercentPopulationVaccinated
ORDER BY Location, Date;


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinatedView AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
