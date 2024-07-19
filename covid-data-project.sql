SELECT location,date ,total_cases,new_cases,total_deaths,population
FROM public.coviddeaths
ORDER BY 1,2

-- Total cases vs Total Deaths
	
-- Whats the likely-hood of death?
--- By 2024 June the death rate on reported covid cases was about 1.14% in the United states
SELECT location,date ,total_cases,total_deaths,(total_deaths::float/total_cases::float)*100 AS death_rate
FROM public.coviddeaths
WHERE location ilike '%states%'
ORDER BY 1,2
	
--- By 2024 June the death rate on reported covid cases was about 1.65% in kenya
SELECT location,date ,total_cases,total_deaths,(total_deaths::float/total_cases::float)*100 AS death_rate
FROM public.coviddeaths
WHERE location ilike '%kenya%'
ORDER BY 1,2

	
-- Total cases vs population
-- What percentage of the population got infected with covid?
	
--- By as recent as June 2024 roughly 30.5% of the United States population was infected by Covid 
SELECT location,date ,total_cases,population,(total_cases::float/population)*100 AS case_rate
FROM public.coviddeaths
WHERE location ilike '%states%'
ORDER BY 1,2

--- By as recent as June 2024 roughly 0.6% of the Kenya population was infected by Covid 
SELECT location,date,total_cases,population,(total_cases::float/population)*100 AS percent_population_infected
FROM public.coviddeaths
WHERE location ilike '%kenya%'
ORDER BY 1,2

-- Which Countries with Highest Infection Rate compared to population
SELECT continent,location,population, MAX(total_cases) AS HighestInfectionCount,MAX((total_cases::float/population))*100 AS percent_population_infected
FROM public.coviddeaths
GROUP BY continent,location, population
ORDER BY percent_population_infected DESC


-- Which continent with highest death count per population
SELECT continent, MAX(total_deaths) AS total_death_count
FROM public.coviddeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC
	
-- Which countries with highest death count per population?
SELECT location, MAX(total_deaths) AS total_death_count
FROM public.coviddeaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count DESC


	
-- Global Numbers
	
SELECT 
	   ---date, 
       SUM(new_cases) AS total_cases,
       SUM(new_deaths) AS total_deaths, 
       CASE 
           WHEN SUM(new_cases) = 0 THEN 0
           ELSE SUM(new_deaths)::float / SUM(new_cases)::float * 100 
       END AS death_percentage
FROM public.coviddeaths
--GROUP BY date
ORDER BY 1,2;



-- Join Covid deaths and vaccination 


-- Total population vs vaccinations
--- What is the total number of vaccinated people globally?

SELECT death.date,death.continent,death.location,death.population,vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (Partition by death.location ORDER BY death.location,death.date) AS cumulative_vaccinations
FROM public.coviddeaths death
JOIN public.covidvaccinations vac
ON death.location = vac.location
AND death.date = vac.date
WHERE death.continent is not null
order by 2,3

	
-- using CTE, to show the percentage of vaccinated population per country
WITH populationVsvaccination AS (
    SELECT 
        death.date,
        death.continent,
        death.location,
        death.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.date) AS cumulative_vaccinations
    FROM 
        public.coviddeaths death
    JOIN 
        public.covidvaccinations vac
    ON 
        death.location = vac.location
    AND 
        death.date = vac.date
    WHERE 
        death.continent IS NOT NULL
    ORDER BY 
        death.continent, death.location
)
SELECT 
    continent,
    location,
    date,
    population,
    new_vaccinations,
    cumulative_vaccinations,
    (cumulative_vaccinations::float / population::float) * 100 AS vaccination_percentage
FROM 
    populationVsvaccination;

-- Drop the temporary table if it exists
DROP TABLE IF EXISTS temp_percent_population_vaccinated;

-- Create the temporary table
CREATE TEMPORARY TABLE temp_percent_population_vaccinated (
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATE,
    population NUMERIC,
    new_vaccinations NUMERIC,
    cumulative_vaccinated NUMERIC
);

-- Insert data into the temporary table
INSERT INTO temp_percent_population_vaccinated
SELECT 
    death.continent,
    death.location,
    death.date,
    death.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.date) AS cumulative_vaccinated
FROM 
    public.coviddeaths death
JOIN 
    public.covidvaccinations vac
ON 
    death.location = vac.location
AND 
    death.date = vac.date
WHERE 
    death.continent IS NOT NULL
ORDER BY 
    death.continent, death.location;

-- Select data from the temporary table with vaccination percentage
SELECT 
    continent,
    location,
    date,
    population,
    new_vaccinations,
    cumulative_vaccinated,
    (cumulative_vaccinated::float / population::float) * 100 AS vaccination_percentage
FROM 
    temp_percent_population_vaccinated;


-- create view for visualization

CREATE VIEW percent_population_vaccinated AS
SELECT 
    death.continent,
    death.location,
    death.date,
    death.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.date) AS cumulative_vaccinated
FROM 
    public.coviddeaths death
JOIN 
    public.covidvaccinations vac
ON 
    death.location = vac.location
AND 
    death.date = vac.date
WHERE 
    death.continent IS NOT NULL
ORDER BY 
    death.continent, death.location;





















