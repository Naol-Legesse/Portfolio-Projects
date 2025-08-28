-- Download the dataset from "https://ourworldindata.org/covid-deaths"


-- The dataset shows COVID-19 related data from January 01/2020 to July 16/2024 (about 4 and half years)


-- Divide the dataset into CovidDeaths and CovidVaccinations excel files


-- Import both files into a database in SQL Server (I used my "PortfolioProject" database)


-- Switch from master to the database containing the table
Use PortfolioProject


-- Confirm both tables
Select * from CovidDeaths
Select * from CovidVaccinations



	---- START WITH THE CovidDeaths TABLE ----

-- Select the important data from the tables
Select continent, location, date, population, total_cases, total_deaths
From CovidDeaths
Where continent is not null
Order by location



	---- GLOBAL FIGURES ----

-- Global COVID-19 cases and deaths per day
-- use NULLIF(value,0) to avoid division by 0 problem.
Select date, SUM(total_cases) as total_cases_by_the_day, SUM(total_deaths) as total_deaths_by_the_day, (SUM(total_deaths)/NULLIF(SUM(total_cases,0)))*100 as daily_death_percentage_by_the_day
From CovidDeaths
Where continent is not null and location not like 'Low income' and location not like 'Lower middle income' 
and location not like 'Upper middle income' and location not like 'High income' and location not like 'World'
Group by date
Order by date

-- Overall number of cases and deaths of COVID-19
-- use NULLIF(value,0) to avoid division by 0 problem.
Select SUM(new_cases) as global_total_cases, SUM(new_deaths) as global_total_deaths, (SUM(new_deaths)/NULLIF(SUM(new_cases),))*100 as global_death_percentage
From CovidDeaths
Where continent is not null and location not like 'Low income' and location not like 'Lower middle income' 
and location not like 'Upper middle income' and location not like 'High income' and location not like 'World'

-- incidence of COVID-19 with rolling sum of new_cases
Select date, SUM(new_cases) as daily_new_cases, SUM(new_deaths) as daily_new_deaths, SUM(total_cases) as total_cases_so_far, SUM(total_deaths) as total_deaths_so_far
From CovidDeaths
Where continent is not null and location not like 'Low income' and location not like 'Lower middle income' 
and location not like 'Upper middle income' and location not like 'High income' and location not like 'World'
Group by date
Order by date



	---- CONTINENTAL FIGURES ----

-- COVID-19 Prevalence and Death per continent
Select location, MAX(total_cases) as total_cases, MAX(total_deaths) as total_deaths
From CovidDeaths
Where continent is null --(because in the dataset continent data is aggregated and is placed like countries under "location")
and location not like 'Low income' and location not like 'Lower middle income' 
and location not like 'Upper middle income' and location not like 'High income' and location not like 'World'
Group by location
Order by total_cases desc



	---- COUNTRY FIGURES ----

-- COVID-19 daily cases and deaths per country
Select location, date, population, total_cases, total_deaths, (total_deaths/population)*100 as daily_death_among_population_percentage
From CovidDeaths
Where continent is not null
Order by location

-- Countries with highest COVID-19 prevalvence per population
Select location, population, MAX(total_cases) as total_cases, (MAX(total_cases)/population)*100 as total_disease_prevalence_percentage
From CovidDeaths
Where continent is not null
Group by location, population
Order by total_disease_prevalence_percentage desc

-- Countries with highest COVID-19 death rates per population
Select location, population, MAX(total_deaths) as total_deaths, (MAX(total_deaths)/population)*100 as total_death_percentage
From CovidDeaths
Where continent is not null
Group by location, population
Order by total_death_percentage desc

-- Likelihood to die (Fatality) after getting COVID-19 per country
-- use NULLIF(value,0) to avoid division by 0 problem.
Select location, MAX(total_cases) as total_cases, MAX(total_deaths) as total_deaths, (MAX(total_deaths)/NULLIF(MAX(total_cases),0))*100 as death_percentage_among_cases
From CovidDeaths
Where continent is not null
Group by location
Order by death_percentage_among_cases desc

-- COVID-19 Prevalence and Death in African countries
Select location, MAX(total_cases) as total_cases, MAX(total_deaths) as total_deaths
From CovidDeaths
Where continent like '%Africa%'
Group by location
Order by total_cases desc

-- COVID-19 Prevalence and Death in Ethiopia
Select location, MAX(total_cases) as total_cases, MAX(total_deaths) as total_deaths
From CovidDeaths
Where location like 'Ethiopia'
Group by location



	---- USE THE CovidVaccinations TABLE ----

-- Countries with highest vaccination count
Select location, SUM(CAST(new_vaccinations AS BIGINT)) total_vaccinations
From CovidVaccinations
Where continent is not null and location not like 'Low income' and location not like 'Lower middle income' 
and location not like 'Upper middle income' and location not like 'High income' and location not like 'World'
Group by location
Order by total_vaccinations desc



	---- JOIN THE CovidDeaths TABLE WITH THE CovidVaccinations TABLE ----

-- Daily vaccinations and rolling sum of vaccinations for each country
Select CovidDeaths.date, CovidDeaths.location, CovidVaccinations.new_vaccinations, SUM(CONVERT(BIGINT, CovidVaccinations.new_vaccinations)) 
OVER (Partition by CovidDeaths.location Order by CovidDeaths.date) as rolling_sum_of_vaccinations
From CovidDeaths join CovidVaccinations on CovidDeaths.location = CovidVaccinations.location and CovidDeaths.date = CovidVaccinations.date
Where CovidDeaths.continent is not null and CovidDeaths.location not like 'Low income' and CovidDeaths.location not like 'Lower middle income' 
and CovidDeaths.location not like 'Upper middle income' and CovidDeaths.location not like 'High income' and CovidDeaths.location not like 'World'
Order by CovidDeaths.location

-- Daily vaccinations and rolling percentage of vaccinations for each country
/* using CTE for the additional calculation of percentage */
With roll_vac_CTE (date, location, population, new_vaccinations,  rolling_sum_of_vaccinations)
As (
Select CovidDeaths.date, CovidDeaths.location, CovidDeaths.population, CovidVaccinations.new_vaccinations, SUM(CONVERT(BIGINT, CovidVaccinations.new_vaccinations)) 
OVER (Partition by CovidDeaths.location Order by CovidDeaths.date) as rolling_sum_of_vaccinations
From CovidDeaths join CovidVaccinations on CovidDeaths.location = CovidVaccinations.location and CovidDeaths.date = CovidVaccinations.date
Where CovidDeaths.continent is not null and CovidDeaths.location not like 'Low income' and CovidDeaths.location not like 'Lower middle income' 
and CovidDeaths.location not like 'Upper middle income' and CovidDeaths.location not like 'High income' and CovidDeaths.location not like 'World'
)

Select *, (rolling_sum_of_vaccinations/population)*100 as rolling_percentage_of_vaccinations
From roll_vac_CTE

-- Daily vaccinations and rolling percentage of vaccinations for each country
/* using TEMP TABLE for the additional calculation of percentage */
Drop Table If Exists #roll_vac_temp_table
Create table #roll_vac_temp_table (
date datetime,
location nvarchar(50),
population numeric,
new_vaccinations numeric,
rolling_sum_of_vaccinations numeric
)

Insert into #roll_vac_temp_table
Select CovidDeaths.date, CovidDeaths.location, CovidDeaths.population, CovidVaccinations.new_vaccinations, SUM(CONVERT(BIGINT, CovidVaccinations.new_vaccinations)) 
OVER (Partition by CovidDeaths.location Order by CovidDeaths.date) as rolling_sum_of_vaccinations
From CovidDeaths join CovidVaccinations on CovidDeaths.location = CovidVaccinations.location and CovidDeaths.date = CovidVaccinations.date
Where CovidDeaths.continent is not null and CovidDeaths.location not like 'Low income' and CovidDeaths.location not like 'Lower middle income' 
and CovidDeaths.location not like 'Upper middle income' and CovidDeaths.location not like 'High income' and CovidDeaths.location not like 'World'

Select *, rolling_sum_of_vaccinations/population as rolling_percentage_of_vaccinations
From #roll_vac_temp_table



	---- CREATE VIEWS FOR FUTURE VISUALIZATIONS ----

-- 1. Global COVID-19 cases and deaths per day
-- use NULLIF(value,0) to avoid division by 0 problem.
Create View Global_daily_data as
Select date, SUM(total_cases) as total_cases, SUM(total_deaths) as total_deaths, SUM(total_deaths)/NULLIF(SUM(total_cases),0) as daily_death_percentage
From CovidDeaths
Where continent is not null and location not like 'Low income' and location not like 'Lower middle income' 
and location not like 'Upper middle income' and location not like 'High income' and location not like 'World'
Group by date

-- 2. COVID-19 Prevalence and Death per continent
Create View Continental_data as
Select location, MAX(total_cases) as total_cases, MAX(total_deaths) as total_deaths
From CovidDeaths
Where continent is null --(because in the dataset continent data is aggregated and is placed like countries under "location")
and location not like 'Low income' and location not like 'Lower middle income' 
and location not like 'Upper middle income' and location not like 'High income' and location not like 'World'
Group by location

-- 3. Countries with highest infection rates per population
Create View Top_infected_countries as
Select location, population, MAX(total_cases) as total_cases, (MAX(total_cases)/population)*100 as total_disease_prevalence_percentage
From CovidDeaths
Where continent is not null and location not like 'Low income' and location not like 'Lower middle income' 
and location not like 'Upper middle income' and location not like 'High income' and location not like 'World'
Group by location, population

-- 4. Countries with highest death rates per population
Create View Top_death_countries as
Select location, population, MAX(total_deaths) as total_deaths, (MAX(total_deaths)/population)*100 as total_death_percentage
From CovidDeaths
Where continent is not null and location not like 'Low income' and location not like 'Lower middle income' 
and location not like 'Upper middle income' and location not like 'High income' and location not like 'World'
Group by location, population

-- 5. Likelihood to die (Fatality) after getting COVID-19 per country
-- use NULLIF(value,0) to avoid division by 0 problem.
Create View Top_fatality_countries as
Select location, MAX(total_cases) as total_cases, MAX(total_deaths) as total_deaths, (MAX(total_deaths)/NULLIF(MAX(total_cases),0))*100 as death_percentage_among_cases
From CovidDeaths
Where continent is not null and location not like 'Low income' and location not like 'Lower middle income' 
and location not like 'Upper middle income' and location not like 'High income' and location not like 'World'
Group by location

-- 6. COVID-19 Prevalence and Death in Ethiopia
Create View Ethiopia_covid_data as
Select location, MAX(total_cases) as total_cases, MAX(total_deaths) as total_deaths
From CovidDeaths
Where location like 'Ethiopia'
Group by location

-- 7. Countries with highest vaccination count
Create View Top_vaccination_countries as
Select location, SUM(CAST(new_vaccinations AS BIGINT)) total_vaccinations
From CovidVaccinations
Where continent is not null and location not like 'Low income' and location not like 'Lower middle income' 
and location not like 'Upper middle income' and location not like 'High income' and location not like 'World'
Group by location

-- 8. Daily vaccinations and rolling percentage of vaccinations for each country *using CTE*
Create View Rolling_vaccination_data as
With roll_vac_CTE (date, location, population, new_vaccinations,  rolling_sum_of_vaccinations)
As (
Select CovidDeaths.date, CovidDeaths.location, CovidDeaths.population, CovidVaccinations.new_vaccinations, SUM(CONVERT(BIGINT, CovidVaccinations.new_vaccinations)) 
OVER (Partition by CovidDeaths.location Order by CovidDeaths.date) as rolling_sum_of_vaccinations
From CovidDeaths join CovidVaccinations on CovidDeaths.location = CovidVaccinations.location and CovidDeaths.date = CovidVaccinations.date
Where CovidDeaths.continent is not null and CovidDeaths.location not like 'Low income' and CovidDeaths.location not like 'Lower middle income' 
and CovidDeaths.location not like 'Upper middle income' and CovidDeaths.location not like 'High income' and CovidDeaths.location not like 'World'
)

Select *, (rolling_sum_of_vaccinations/population)*100 as rolling_percentage_of_vaccinations
From roll_vac_CTE
