-- Select data --
select location, date, total_cases, new_cases, total_deaths, population 
from portfolio_project.covid_deaths cd
where continent is not null 
or continent!='0'
order by location, "date" 

-- Total cases vs total deaths --
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage 
from portfolio_project.covid_deaths cd
where location ilike '%spain%'
order by location, "date"

-- Total cases vs total population --
select location, date, population, total_cases, total_deaths, (total_cases/population)*100 as cases_percentage 
from portfolio_project.covid_deaths cd
where location ilike '%spain%'
order by location, "date"

-- Countries with highest infection rate by population --
select location, population, max(total_cases) as total_infection_count, max((total_cases/population))*100 as percent_pupulation_infected 
from portfolio_project.covid_deaths cd
--where location ilike '%spain%'
where continent is not null 
or continent!='0'
group by population, "location" 
order by percent_pupulation_infected desc


-- Countries with highest death count by population --
select location, population, max(total_deaths) as total_deaths_count
from portfolio_project.covid_deaths cd
--where location ilike '%spain%'
where continent is not null 
or continent!='0'
group by population, "location" 
order by total_deaths_count desc

-- Breaking it down by continent --
with cte_locations
as (select continent,location, max(total_deaths) as total_deaths_count_per_country
	from portfolio_project.covid_deaths cd
	where continent!=''
	and location not ilike '%income%'
	and location not like 'International'
	group by continent, location
	order by continent asc)
select continent, sum(total_deaths_count_per_country) as total_deaths_per_continent
from cte_locations
group by continent
order by 2 desc


-- Global numbers --
-- Death rate per day --
select date, sum(new_cases) as new_cases_perday, sum(new_deaths) as new_deaths_perday, sum(new_deaths)/nullif(sum(new_cases),0)*100 as death_rate_perday
from portfolio_project.covid_deaths cd
where continent!=''
group by date
order by 1,2

-- Vaccinations by total population, by location and date --
with cte_vacc_pop
as (select cd.continent, cd."location", cd."date", cd.population, cv.new_vaccinations
	, sum (cast(nullif(cv.new_vaccinations,'') as int)) over (partition by cd."location" order by cd.location, cd.date) as rolling_people_vaccinated
	from portfolio_project.covid_deaths cd 
	join portfolio_project.covid_vaccinations cv 
		on cd."location"=cv."location" 
		and cd.date=cv."date"
	where cd.continent!=''
	order by 2, 3)
select *, (rolling_people_vaccinated/population)*100 as vaccinations_percentage
from cte_vacc_pop


-- CREATING VIEW TO STORE DATE FOR LATER VISUALIZATIONS --
create view percent_population_vaccinated as
with cte_vacc_pop
as (select cd.continent, cd."location", cd."date", cd.population, cv.new_vaccinations
	, sum (cast(nullif(cv.new_vaccinations,'') as int)) over (partition by cd."location" order by cd.location, cd.date) as rolling_people_vaccinated
	from portfolio_project.covid_deaths cd 
	join portfolio_project.covid_vaccinations cv 
		on cd."location"=cv."location" 
		and cd.date=cv."date"
	where cd.continent!=''
	order by 2, 3)
select *, (rolling_people_vaccinated/population)*100 as vaccinations_percentage
from cte_vacc_pop

alter view percent_population_vaccinated
set schema portfolio_project