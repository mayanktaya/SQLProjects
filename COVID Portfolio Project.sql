-- 1. General Data Queries

-- Querying the CovidDeaths table and ordering by the 3rd and 4th columns
Select *
From PortfolioProject..CovidDeaths
order by 3,4 

-- Querying the CovidVaccinations table and ordering by the 3rd and 4th columns
 Select *
 From PortfolioProject..CovidVaccinations
 order by 3,4 

-- Selecting specific columns from CovidDeaths table and ordering by location and date
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2 

-- 2. Country-Specific Analysis

-- Calculating the death percentage from total cases and total deaths, and ordering by location and date
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
order by 1,2

-- Filtering data for India and calculating death percentage, ordered by location and date
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%india%'
order by 1,2

-- 3. Population and Infection Rates

-- Calculating the percentage of the population infected in India, ordered by location and date
Select Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location like '%india%'
order by 1,2

-- Finding countries with the highest contraction rate by population, ordered by percentage of population infected
Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc

-- 4. Global and Continental Analysis

-- Finding countries with the highest death count, ordered by total death count
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by Location
order by TotalDeathCount desc

-- Finding continents with the highest death count per population, ordered by total death count
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc

-- Calculating global death percentage by date
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, Sum(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
order by 1,2

-- Calculating global death percentage overall
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, Sum(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2

-- 5. Vaccination Data Analysis

-- Joining CovidDeaths and CovidVaccinations tables on location and date
Select *
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date

-- Calculating total vaccinations over time by population and date
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location order by dea.location, dea.date) as TotalVaccinationsOverTime
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- 6. Using Common Table Expressions (CTEs)

-- Using CTE to calculate total vaccinations over time by population
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, TotalVaccinationsOverTime) as
(
    Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location order by dea.location, dea.date) as TotalVaccinationsOverTime
    From PortfolioProject..CovidDeaths dea
    Join PortfolioProject..CovidVaccinations vac
        on dea.location = vac.location
        and dea.date = vac.date
    where dea.continent is not null
)
Select *, (TotalVaccinationsOverTime/Population)*100 as PercentPopulationVaccinated
From PopvsVac

-- 7. Temporary Tables 

-- Creating and populating a temporary table for percent population vaccinated
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    TotalVaccinationsOverTime numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location order by dea.location, dea.date) as TotalVaccinationsOverTime
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date

-- Selecting data from the temporary table with percent population vaccinated
Select *, (TotalVaccinationsOverTime/Population)*100 as PercentPopulationVaccinated
From #PercentPopulationVaccinated

-- 8. Creating Views

-- Creating a view to store percent population vaccinated data for later visualizations
Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location order by dea.location, dea.date) as TotalVaccinationsOverTime
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null

-- Selecting data from the view
Select *
From PercentPopulationVaccinated
