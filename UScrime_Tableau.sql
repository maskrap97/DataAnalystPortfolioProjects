/*
SQL queries for Tableau data visualization project

US Crime in each state from 1960-2019 (Property/Violent included)
*/

-- Create table to perform SQL queries from

CREATE TABLE UScrime.state
(  
State varchar(50), Year year, Population int,
PropertyRate float, BurglaryRate float, LarcenyRate float,
MotorRate float, ViolentRate float, AssaultRate float,
MurderRate float, RapeRate float, RobberyRate float,
PropertyTotal int, BurglaryTotal int, LarcenyTotal int,
MotorTotal int, ViolentTotal int, AssaultTotal int, 
MurderTotal int, RapeTotal int, RobberyTotal int
);

-- *insert csv file containing crime data*
-- Data sourced from (https://corgis-edu.github.io/corgis/csv/state_crime/)

-- Select all the data from the table and a list of distinct states

SELECT * FROM UScrime.state;
SELECT DISTINCT UScrime.state.State
FROM UScrime.state;

-- Select total crime in each state (Property + Violent)

SELECT UScrime.state.State, UScrime.state.`Year`, UScrime.state.Population, 
UScrime.state.PropertyTotal + UScrime.state.ViolentTotal as TotalCrime
FROM UScrime.state
WHERE State NOT IN ('District of Columbia', 'United States')
ORDER BY 1, 2;

-- Select total crime rate in each state (Property + Violent per 100,000 in Population)

WITH CTE_total (State, Year, Population, TotalCrime) as
( 
SELECT UScrime.state.State, UScrime.state.`Year`, UScrime.state.Population, 
UScrime.state.PropertyTotal + UScrime.state.ViolentTotal as TotalCrime
FROM UScrime.state
)

SELECT CTE_total.State, CTE_total.`Year`, CTE_total.TotalCrime/(CTE_total.Population/100000) as TotalCrimeRate
FROM CTE_total
WHERE CTE_total.State NOT IN ('District of Columbia', 'United States')
ORDER BY 1, 2;

-- Select overall violent crime rate in each state (per 100,000 in population)

SELECT UScrime.state.State , UScrime.state.`Year` , UScrime.state.Population,
UScrime.state.ViolentRate 
FROM UScrime.state
WHERE State NOT IN ('District of Columbia', 'United States')
ORDER BY 1, 2;

-- Select total murders in each state

SELECT UScrime.state.State, UScrime.state.`Year`, UScrime.state.Population,
UScrime.state.MurderTotal 
FROM UScrime.state
WHERE State NOT IN ('District of Columbia', 'United States')
ORDER BY 1, 2;

-- Select average total crime in each state from 1960-2019

SELECT UScrime.state.State, 
AVG(UScrime.state.PropertyTotal + UScrime.state.ViolentTotal) as TotalCrime
FROM UScrime.state
WHERE State NOT IN ('District of Columbia', 'United States')
GROUP BY UScrime.state.State
ORDER BY TotalCrime desc;

-- Select average total crime rate in each state from 1960-2019

WITH CTE_total (State, Year, Population, TotalCrime) as
( 
SELECT UScrime.state.State, UScrime.state.`Year`, UScrime.state.Population, 
UScrime.state.PropertyTotal + UScrime.state.ViolentTotal as TotalCrime
FROM UScrime.state
)

SELECT CTE_total.State, AVG(CTE_total.TotalCrime/(CTE_total.Population/100000)) as TotalCrimeRate
FROM CTE_total
WHERE CTE_total.State NOT IN ('District of Columbia', 'United States')
GROUP BY CTE_total.State
ORDER BY 2 desc;

-- Select average violent crime rate in each state from 1960-2019

SELECT UScrime.state.State, AVG(UScrime.state.ViolentRate)
FROM UScrime.state
WHERE State NOT IN ('District of Columbia', 'United States')
GROUP BY State
ORDER BY 2 desc;

-- Select average total murders per year in each state from 1960-2019

SELECT UScrime.state.State, AVG(UScrime.state.MurderTotal)
FROM UScrime.state
WHERE State NOT IN ('District of Columbia', 'United States')
GROUP BY State 
ORDER BY 2 desc;


