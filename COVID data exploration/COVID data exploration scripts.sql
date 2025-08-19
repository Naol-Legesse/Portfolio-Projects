
----------------------------- data is collected in time range of FEB 20/2020 - APR 30/2021 (about a year and a month)--------------------------------


-- 1) check both tables
select * from PortfolioProject..CovidDeaths
order by 3,4

select * from PortfolioProject..CovidVaccinations
order by 3,4


-- 2) looking at total cases and total death and percentages
--also the current likelihood of dying from it in ethiopia
select location,date,total_cases,new_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercent,population
from PortfolioProject..CovidDeaths
where location like '%ethio%'
order by 1,2

-- 3) looking at total cases vs poulation and the prevalence
select location,date,total_cases,population,(total_cases/population)*100 as prevalence
from PortfolioProject..CovidDeaths
where location like '%ethio%'
order by 1,2 


-- 4) look for countries with highest report of infection compared to population
--use where to specify the group of countries to be assessed
--use where to specify the time period to be considered
select location,population,MAX(total_cases) as HighestCases,(Max(total_cases)/population)*100 as HighestReport
from PortfolioProject..CovidDeaths
--where date between '2023-06-16' and '2024-6-16'
--location in ('Ethiopia','Eritrea','Sudan','South Sudan','Kenya')
group by location,population
order by HighestReport desc


-- 5) GLOBAL figures
-- 5.1) how many people tested +ve and how many died of covid since it started
select date,SUM(total_cases) as TotalCasesByThisDay,SUM(total_deaths) as TotalDeathsByThisDay,
(SUM(total_deaths)/SUM(total_cases))*100 as DeathPercentByThisDay
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by date asc


-- 5.2) how many people died of COVID since it started
select date,SUM(total_deaths)
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by date ASC


-- 5.3) how many new cases, new deaths and Death percentage worldwide each day
-- use NULLIF(value,0) to avoid division by 0 problem.
select date, SUM(new_cases) as NewCasesToday, SUM(new_deaths) as NewDeathsToday,
(SUM(new_deaths)/NULLIF (SUM(new_cases),0))*100 as DeathpercentToday
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by date



-- 6) break down data by CONTINENT
-- 6.1) look at death counts by continent
select continent,MAX(total_deaths) as TotalDeathInContinent from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathInContinent desc
--cast used because total_cases column was varchar(255) type and had to be changed to int for the MAX operator


-- 6.2) look for total cases of COVID by continent since it started
select continent,MAX(total_cases) as TotalCasesInContinent from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalCasesInContinent desc



-- 7) break down data by countries
-- 7.1) look for countries with highest death count per population
select location,MAX(total_deaths) as TotalDeath from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by TotalDeath desc


-- 7.2) look for countries with highest COVID prevalence per population
select location,population,max(total_cases) as MaxCases, (MAX(total_cases)/population)*100 as prevalence
--MAX(total_cases) as prevalence
from PortfolioProject..CovidDeaths
where continent is not null
group by location,population
order by Prevalence desc


-- 7.3) looking at Total population vs vaccinations
-- CTE or a temp table can be used here... the CTE version used below (to extract the % of vaccinated people)
-- the CTE or TEMP TABLE is used for calculation of the PercentVaccinated (otherwise not needed)

with CTE_PercentVaccinated (location, date, population, NewVaccination, RollingSumOfVaccinations) as
(
select dez.location,dez.date,dez.population,vax.new_vaccinations,SUM(vax.new_vaccinations) over (partition by dez.location order by dez.location,dez.date) as 
RollingSumOfVaccinations
from PortfolioProject..CovidDeaths as dez
join PortfolioProject..CovidVaccinations as vax
	on Dez.location = vax.location and dez.date = vax.date
where dez.continent is not null
)
select *,(RollingSumOfVaccinations/population)*100 as TotalVaccinatedPercent from CTE_PercentVaccinated


-- the tempTable version used below
drop table if exists #temp1
create table #temp1
(location varchar(50),
date datetime,
population float,
DailyVaccination float,
TotalVaccination float
)

insert into #temp1
select dez.location,dez.date,dez.population,vax.new_vaccinations,SUM(vax.new_vaccinations) over (partition by dez.location order by dez.location,dez.date) as 
RollingSumOfVaccinations
from PortfolioProject..CovidDeaths as dez
join PortfolioProject..CovidVaccinations as vax
	on Dez.location = vax.location and dez.date = vax.date
where dez.continent is not null
order by location,date

select *,(TotalVaccination/population)*100 as PercentVaccinated from #temp1



------------------------------------- CREATE VIEW FOR FUTURE VISUALIZATIONS

-- 1) Country view for the Total Vaccination count AND percentage of Vaccinated people per country
create view TotalVaccinationANDpercentVaccinated as
select dez.location,dez.date,dez.population,vax.new_vaccinations,SUM(vax.new_vaccinations) over (partition by dez.location order by dez.location,dez.date) as 
RollingSumOfVaccinations
from PortfolioProject..CovidDeaths as dez
join PortfolioProject..CovidVaccinations as vax
	on Dez.location = vax.location and dez.date = vax.date
where dez.continent is not null


-- 2) Country view for countries with highest death count per population
create view DeathCountByCountry as
select location,MAX(total_deaths) as TotalDeath from PortfolioProject..CovidDeaths
where continent is not null
group by location
--order by TotalDeath


-- 3) view for countries with highest COVID prevalence per population
create view HighCovidPrevalenceCountries as
select location,population,max(total_cases) as MaxCases, (MAX(total_cases)/population)*100 as prevalence
--MAX(total_cases) as prevalence
from PortfolioProject..CovidDeaths
where continent is not null
group by location,population
--order by Prevalence desc



-- 4) CONTINENTAL view for death counts by continent
create view DeathCountByContinent as
select continent,MAX(total_deaths) as TotalDeathInContinent from PortfolioProject..CovidDeaths
where continent is not null
group by continent
--cast used because total_cases column was varchar(255) type and had to be changed to int for the MAX operator
--order by TotalDeathInContinent

-- 5) Continental view for total cases of COVID by continent since it started
create view CaseCountByContinent as
select continent,MAX(total_cases) as TotalCasesInContinent from PortfolioProject..CovidDeaths
where continent is not null
group by continent
--order by TotalCasesInContinent desc


-- 6) GLOBAL view for how many people tested +ve and died of covid since it started
create view HowManyGotTheCOVIDever as
select date,SUM(total_cases) as TotalCasesByThisDay,SUM(total_deaths) as TotalDeathsByThisDay,
(SUM(total_deaths)/SUM(total_cases))*100 as DeathPercentByThisDay
from PortfolioProject..CovidDeaths
where continent is not null
group by date
--order by date asc


-- 7) Global how many people died of COVID since it started
create view GlobalCovidDeathEver as
select date,SUM(total_deaths) as TotalCovidDeath
from PortfolioProject..CovidDeaths
where continent is not null
group by date
--order by date asc


-- 8)GLOBAL view for how many new cases and COVID deaths worldwide each day
-- use NULLIF(value,0) to avoid division by 0 problem.
create view HowManyNewCasesWorldwideEachDay as
select date, SUM(new_cases) as NewCasesToday, SUM(new_deaths) as NewDeathsToday,
(SUM(new_deaths)/NULLIF (SUM(new_cases),0))*100 as DeathpercentToday
from PortfolioProject..CovidDeaths
where continent is not null
group by date
--order by date asc

