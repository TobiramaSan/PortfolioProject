select *
From portprjt ..['covid deaths$']
where continent is not null
order by 3,4


--select *
--From portprjt ..['covid vacc$']
--order by 3,4

--select data that we are going to be using
select Location, date, total_cases, new_cases, total_deaths, population
From portprjt..['covid deaths$']
where continent is not null
order by 1,2

--looking at total cases vs total deaths
--the 'as' helps rename new column that is formed 
--'where location like %states%' is used to find the rows in the data that are 'states" 
--shows the likelihood of dying if youn contract covid in your country
select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercetage
From portprjt..['covid deaths$']
where location like '%states%'
and continent is not null
order by 1,2

--looking at the total cases vs the population
--shows what percentage of population has gotten covid
select Location, date, population, total_cases, (total_cases/population)*100 as CovidPercetage
From portprjt..['covid deaths$']
where location like '%states%'
order by 1,2

--looking at countries with highest infection rates compared to populations
select Location, population, MAX(total_cases) as HigestInfectionCount, MAX(total_cases/population)*100 as CovidPercetage
From portprjt..['covid deaths$']
group by Location, population
order by CovidPercetage desc
-- 'desc' means in descending order

--showing the countries with the highest death count per population
select Location, MAX(cast(total_deaths as int)) as HighestDeathCount
From portprjt..['covid deaths$']
where continent is not null
group by Location, population
order by HighestDeathCount desc
-- 'desc' means in descending order
-- notice how there are some rows under "locations' that are not actual locations? this is caused by the grouping of continent
-- we can solve this by adding 'where countinent is not null' to our queries involving locations 

--lets break things down by continent
select continent, MAX(cast(total_deaths as int)) as HighestDeathCount
From portprjt..['covid deaths$']
where continent is not null
group by continent  
order by HighestDeathCount desc

--showing the continents with highest death counts
select continent, MAX(cast(total_deaths as int)) as HighestDeathCount
From portprjt..['covid deaths$']
where continent is not null
group by continent  
order by HighestDeathCount desc


--visualizing preparations eg adding drill downs,etc
--FINDING GLOBAL NUMBERS
select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as GlobalDeathPercent
--total_deaths, (total_deaths/total_cases)*100 as DeathPercetage
From portprjt..['covid deaths$']
--where location like '%states%'
where continent is not null
group by date
order by 1,2


--FINFING THE TOTAL NUMBER OF INFECTED PEOPLE VS DEATHS IN THE WORLD
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as GlobalDeathPercent
--total_deaths, (total_deaths/total_cases)*100 as DeathPercetage
From portprjt..['covid deaths$']
--where location like '%states%'
where continent is not null
order by 1,2




--VACCINATIONS
--Looking at the total population vs vaccinations
select *
from portprjt..['covid vacc$'] vac
join portprjt..['covid deaths$'] dea
	on dea.location =vac.location
	and dea.date = vac.date

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from portprjt..['covid vacc$'] vac
join portprjt..['covid deaths$'] dea
	on dea.location =vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER(Partition by dea.location order by dea.location, dea.date)
as RollingVaccinatedPeople
--this adds up the new vaccinations as they're being recorded and brings them on a new colunm
from portprjt..['covid vacc$'] vac
join portprjt..['covid deaths$'] dea
	on dea.location =vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--USING CTE
--CTE is used when we need to reference a new table multiple times in a single query
--CTE is used as an alternative to creating a view in the database
--performing the same calculation multiple times over across multiple query components
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER(Partition by dea.location order by dea.location, dea.date)
as RollingVaccinatedPeople 
--, (RollingVaccinatedPeople/population)*100
--THE ABOVE LINE WILL GIVE US AN ERROR BECAUSE WE ARE REFERENCING A NEW TABLE IN THE QUERY WITHOUT USING A CTE 
from portprjt..['covid vacc$'] vac
join portprjt..['covid deaths$'] dea
	on dea.location =vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--with CTE

With PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinatedPeople)
as 
--The number of columns in the CTE shoukd be the same with the number of columns in the query
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER(Partition by dea.location order by dea.location, dea.date)
as RollingVaccinatedPeople
--, (RollingVaccinatedPeople/population)*100
--THE ABOVE LINE WILL GIVE US AN ERROR BECAUSE WE ARE REFERENCING A NEW TABLE IN THE QUERY WITHOUT USING A CTE 
from portprjt..['covid vacc$'] vac
join portprjt..['covid deaths$'] dea
	on dea.location =vac.location
	and dea.date = vac.date
where dea.continent is not null
--remove the "order by" or just comment it out
--order by 2,3
)
select*, (RollingVaccinatedPeople/population)*100
from PopvsVac



--TEMP TABLE
--To drop a table that already exists, you say:
drop table if exists #PercentPopulationVacc

Create Table #PercentPopulationVacc
--Since we're basically creating a new table, we must specify the data types
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinatedPeople numeric
)
insert into #PercentPopulationVacc
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--use bigint instead of int if the Msg 8115 error stating that Arithemetic overflow error converting expression to data type int
, SUM(Convert(bigint, vac.new_vaccinations )) OVER(Partition by dea.location order by dea.location, dea.date)
as RollingVaccinatedPeople
--, (RollingVaccinatedPeople/population)*100
--THE ABOVE LINE WILL GIVE US AN ERROR BECAUSE WE ARE REFERENCING A NEW TABLE IN THE QUERY WITHOUT USING A CTE  
from portprjt..['covid vacc$'] vac
join portprjt..['covid deaths$'] dea
	on dea.location =vac.location
	and dea.date = vac.date
where dea.continent is not null
--remove the "order by" or just comment it out
--order by 2,3
select*, (RollingVaccinatedPeople/population)*100
from #PercentPopulationVacc


drop table if exists #PercentPopulationVacc

Create Table #PercentPopulationVacc
--Since we're basically creating a new table, we must specify the data types
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaccinatedPeople numeric
)
insert into #PercentPopulationVacc
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--use bigint instead of int if the Msg 8115 error stating that Arithemetic overflow error converting expression to data type int
, SUM(Convert(bigint, vac.new_vaccinations )) OVER(Partition by dea.location order by dea.location, dea.date)
as RollingVaccinatedPeople
--, (RollingVaccinatedPeople/population)*100
--THE ABOVE LINE WILL GIVE US AN ERROR BECAUSE WE ARE REFERENCING A NEW TABLE IN THE QUERY WITHOUT USING A CTE  
from portprjt..['covid vacc$'] vac
join portprjt..['covid deaths$'] dea
	on dea.location =vac.location
	and dea.date = vac.date
--where dea.continent is not null
--remove the "order by" or just comment it out
--order by 2,3
select*, (RollingVaccinatedPeople/population)*100
from #PercentPopulationVacc

--creating views to store data for visualizations
create view PercentPopulationVaccine as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
--use bigint instead of int if the Msg 8115 error stating that Arithemetic overflow error converting expression to data type int
, SUM(Convert(bigint, vac.new_vaccinations )) OVER(Partition by dea.location order by dea.location, dea.date)
as RollingVaccinatedPeople
--, (RollingVaccinatedPeople/population)*100
--THE ABOVE LINE WILL GIVE US AN ERROR BECAUSE WE ARE REFERENCING A NEW TABLE IN THE QUERY WITHOUT USING A CTE  
from portprjt..['covid vacc$'] vac
join portprjt..['covid deaths$'] dea
	on dea.location =vac.location
	and dea.date = vac.date
where dea.continent is not null
--remove the "order by" or just comment it out
--order by 2,3

select*
from PercentPopulationVaccine