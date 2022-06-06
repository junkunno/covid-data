-----------SQL ANALYSIS OF COVID PANDEMIC DATA---------------------- 

-- Selecting the database to use in SQL Server
USE CovidData; 

-- RUNNING QUERIES SPECIFIC TO INFORMATION ABOUT JAMAICA
	-- Percentage of Population Infected (Rounded 2 decimal places)
	-- Case fatality rate (Rounded 2 decimal places) 
SELECT
	location,
	date,
	total_cases,
	new_cases, 
	total_deaths,
	population,
	ROUND((total_cases/population)*100, 2) AS '%_pop_infection_rate', 
	ROUND((total_deaths/total_cases)*100, 2) AS 'case_fatality_rate'
FROM covid_deaths
WHERE location ='Jamaica'
Order By 1,2;



	-- Looking at total vaccinations, people fully vaccinated & their median age for Jamaica
SELECT 
	location,
	date,
	total_vaccinations,
	people_vaccinated,
	total_boosters,
	median_age
FROM
	vaccinations
WHERE location ='Jamaica' AND date >= '2021-03-14'
Order By date ASC;


--JOINING TABLES--
-- Finding The total deaths, total  # vaccinations &  percentage of population fully vaccinated in Jamaica
SELECT
	covid_deaths.location,
	MAX(covid_deaths.total_deaths) AS total_deaths,
	MAX(CAST(vaccinations.total_vaccinations AS INT)) as total_vaccinations, --Must cast column as INT
	MAX(CAST(vaccinations.people_fully_vaccinated AS INT)) as fully_vaccinated,
	ROUND(MAX(vaccinations.people_fully_vaccinated/covid_deaths.population*100),2) AS '%_fully_vaccinated'
FROM vaccinations
JOIN covid_deaths
	ON vaccinations.location = covid_deaths.location AND
	covid_deaths.date = vaccinations.date 
WHERE vaccinations.location = 'Jamaica'
GROUP BY covid_deaths.location


--SMALL SNAPSHOTS OF GLOBAL DATA--


	--Total deeaths for each country
SELECT 
	MAX(total_deaths) as total_deaths,
	location
FROM 
	covid_deaths
WHERE 
	continent IS NOT NULL
GROUP BY location
ORDER BY  total_deaths DESC;


	-- Countries with Highest Case infection Rate
SELECT TOP 100
	location,
	population,
	MAX(CAST(total_cases AS INT)) AS 'total_cases', -- highest infection rate based on total population
	population,
	ROUND(MAX((CAST(total_cases as int)/population))*100, 2) AS '%_of_pop_that_caught_covid'
FROM dbo.covid_deaths
-- Excluding results that are not countries
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY '%_of_pop_that_caught_covid' DESC;


	--Countries with the highest number of deaths & highest case fatality rate
SELECT 
	location,
	population,
	MAX(total_cases) AS 'total_cases',
	ROUND(AVG((total_cases/population)*100), 2) AS '%_pop_infection_rate',
	ROUND(AVG((total_deaths/total_cases)*100), 2) AS 'case_fatality_rate'
	FROM covid_deaths
	-- Excluding results that are not countries
WHERE continent IS NOT NULL AND population IS NOT NULL 
GROUP by location, population
ORDER BY 'case_fatality_rate' DESC;


	--Global cases, deaths & fatality rate
SELECT
	SUM(new_cases) AS 'total_global_cases',
	SUM(CAST(new_deaths AS INT)) AS 'total_deaths',
	ROUND(SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100, 2) AS 'fatality_rate'
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2,3;


	-- Looking at total vaccinations administered & median age of people who recevied the vaccine accross countries
SELECT 
	location,
	median_age,
	MAX(total_vaccinations) AS total_vaccinations
FROM
	vaccinations
WHERE continent is NOT NULL AND median_age IS NOT NULL AND total_vaccinations IS NOT NULL
GROUP BY location, median_age
ORDER BY 'total_vaccinations' 



--Joining Tables 
	-- Looking at Total Populations vs Vaccinations
	 -- NEED TO USE CTE
 WITH PopvsVac (continent, location, date, population, total_deaths, new_vaccinations,  rolling_sum_of_vaccinations)
 AS
 (
	SELECT 
		covid_deaths.continent,
		covid_deaths.location,
		covid_deaths.date,
		covid_deaths.population,
		covid_deaths.total_deaths,
		vaccinations.new_vaccinations,
		SUM(CAST(vaccinations.new_vaccinations AS BIGINT)) 
		OVER (Partition by vaccinations.location 
				ORDER BY vaccinations.location, vaccinations.date) AS rolling_sum_of_vaccinations

	FROM
	covid_deaths
	JOIN Vaccinations 
	ON covid_deaths.location = vaccinations.location
	AND covid_deaths.date = vaccinations.date
	WHERE covid_deaths.continent is NOT NULL AND vaccinations.new_vaccinations IS NOT NULL
	--ORDER BY 2,3
)
SELECT 
*,
(rolling_sum_of_vaccinations/population)*100 AS global_percentage_of_vaccinations
FROM PopvsVac

--------------- CREATING VIEWS FOR VISUALIZATIONS TO BE CREATED IN TABLEAU--------------------------------

		-- View for Case fatility & infection rate for Jamaica-- 
CREATE VIEW jam_case_fatality_infection_rate  AS
SELECT
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population,
	ROUND((total_cases/population)*100, 2) AS '%_pop_infection_rate', 
	ROUND((total_deaths/total_cases)*100, 2) AS 'case_fatality_rate'
FROM covid_deaths
WHERE location ='Jamaica';

		-- View for total deaths, vaccinations etc. For Jamaica-- 
CREATE VIEW snapshot_for_jamaica AS
SELECT
	covid_deaths.location,
	MAX(covid_deaths.total_deaths) AS total_deaths,
	MAX(CAST(vaccinations.total_vaccinations AS INT)) as total_vaccinations, --Must cast column as INT
	MAX(CAST(vaccinations.people_fully_vaccinated AS INT)) as fully_vaccinated,
	ROUND(MAX(vaccinations.people_fully_vaccinated/covid_deaths.population*100),2) AS '%_fully_vaccinated'
FROM vaccinations
JOIN covid_deaths
	ON vaccinations.location = covid_deaths.location AND
	covid_deaths.date = vaccinations.date 
WHERE vaccinations.location = 'Jamaica'
GROUP BY covid_deaths.location

--------------- GLOBAL VIEWS------------------
	--VIEW OF GLOBAL SNAPSHOT 
CREATE VIEW global_snapshot AS
SELECT TOP 100
	location,
	population,
	MAX(CAST(total_cases AS INT)) AS 'total_cases', -- highest infection rate based on total population
	ROUND(MAX((CAST(total_cases as int)/population))*100, 2) AS '%_of_pop_that_caught_covid'
FROM dbo.covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
