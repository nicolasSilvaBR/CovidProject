/*
Covid 19 Data Exploration (19/12/2021) 
By Nicolas Silva

Skills used: 
	Joins, 
	CTE's, 
	Temp Tables, 
	Windows Functions, 
	Aggregate Functions, 
	Creating Views, 
	Converting Data Types

Database Name: CovidProject
Tables Names:[dbo].[Covid_Deaths],
			 [dbo].[Covid_Vacinnations]

*/

Select top 1000 *
From CovidProject..Covid_Deaths
Where continent is not null 
order by 3,4
go

-- Select Data to be starting with
Select 
	Location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
From CovidProject..Covid_Deaths
Where continent is not null 
order by 1,2
go

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select
	Location, 
	Format(date,'dd/MM/yyyy')as date, 
	total_cases, 
	new_cases,
	population, 
	total_deaths,
	-- Showing differents ways to Cast and Convert Data Types
	CAST(
		(cast(total_deaths as float)/Convert(float,total_cases))*100 as numeric(10,2))as DeathPercentage
From CovidProject..Covid_Deaths
Where continent is not null 
and Location like 'Brazil'
order by date
go 

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
Select
	Format(date,'dd/MM/yyyy')as RegisteredDate,
	Location, 
	population,	
	total_cases,
	Cast((total_cases /population) *100 as numeric(10,2))  as InfectionPercentage		 
From CovidProject..Covid_Deaths
Where continent is not null 
go

-- Countries Summary of: Population, TotalCases,Infection Percentage
SET ARITHABORT on
SET ANSI_WARNINGS on
Select
	Location, 
	population,	
	Max(Convert(float,total_cases))as TotalCases,
	cast((Max(Convert(float,total_cases)) / CONVERT(float,population))*100 as numeric(10,2))as InfectionPercentage	 
From CovidProject..Covid_Deaths
Where continent is not null 
group by
	Location,
	population
order by InfectionPercentage 

SET ANSI_WARNINGS ON
go

-- Countries Summary of: Population, TotalCases,Infection Percentage
Select
	Location, 
	population,
	Max(Convert(float,total_cases))as TotalCases,
	ISNULL(max(total_cases) / NULLIF(population, 0), 0)*100 AS InfectionPercentage
From CovidProject..Covid_Deaths
Where continent is not null 
group by
	Location, 
	population
order by InfectionPercentage desc
go


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
Select 
	continent, 
	MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidProject..Covid_Deaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS
Select 
	SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidProject..Covid_Deaths
where continent is not null 
--Group By date
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(int,vac.new_vaccinations)) 
		OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidProject..Covid_Deaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join Covid_Vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
