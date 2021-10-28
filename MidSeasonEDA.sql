/*
NCAA Football 2021 Midseason Data Exploration

Skills used include joins, case statements, group by, order by, agreggate functions and CTEs
*/

-- CREATE TABLE CFB.TotalOffense (
-- Rank int, Team varchar(100), G int,
-- WL varchar(3), Plays int, YDS int,
-- YdsperPlay decimal(3,2), OffTDs int, YPG decimal(5,2)
-- )

-- CREATE TABLE CFB.TotalDefense (
-- Rank int, Team varchar(100), G int,
-- WL varchar(3), Plays int, YDS int,
-- YdsperPlay decimal(3,2), OffTDs int, OppTDs int,
-- YPG decimal(5,2)
-- )

-- *insert csv files into TotalOffense and TotalDefense tables*

-- Select all the data from the tables

SELECT * FROM CFB.TotalOffense;
SELECT * FROM CFB.TotalDefense;

-- Create case statements for wins and losses, rank teams based on record

SELECT CFB.TotalDefense.Team, CFB.TotalDefense.WL, 
CASE 
WHEN CFB.TotalDefense.WL LIKE '0%' THEN 0
WHEN CFB.TotalDefense.WL LIKE '1%' THEN 1
WHEN CFB.TotalDefense.WL LIKE '2%' THEN 2
WHEN CFB.TotalDefense.WL LIKE '3%' THEN 3
WHEN CFB.TotalDefense.WL LIKE '4%' THEN 4
WHEN CFB.TotalDefense.WL LIKE '5%' THEN 5
WHEN CFB.TotalDefense.WL LIKE '6%' THEN 6
WHEN CFB.TotalDefense.WL LIKE '7%' THEN 7
WHEN CFB.TotalDefense.WL LIKE '8%' THEN 8
END as WINS,
CASE 
WHEN CFB.TotalDefense.WL LIKE '%0' THEN 0
WHEN CFB.TotalDefense.WL LIKE '%1' THEN 1
WHEN CFB.TotalDefense.WL LIKE '%2' THEN 2
WHEN CFB.TotalDefense.WL LIKE '%3' THEN 3
WHEN CFB.TotalDefense.WL LIKE '%4' THEN 4
WHEN CFB.TotalDefense.WL LIKE '%5' THEN 5
WHEN CFB.TotalDefense.WL LIKE '%6' THEN 6
WHEN CFB.TotalDefense.WL LIKE '%7' THEN 7
WHEN CFB.TotalDefense.WL LIKE '%8' THEN 8
END as LOSSES
FROM CFB.TotalDefense
ORDER BY WINS desc, LOSSES;

-- Combine total offensive and defensive rank

SELECT CFB.TotalOffense.Team, CFB.TotalOffense.Rank as OffenseRank,
CFB.TotalDefense.Rank as DefenseRank, 
(CFB.TotalOffense.Rank + CFB.TotalDefense.Rank)/2 as CombinedRank 
FROM CFB.TotalOffense 
JOIN CFB.TotalDefense ON CFB.TotalDefense.Team = CFB.TotalOffense.Team 
ORDER BY CombinedRank, CFB.TotalOffense.Rank;

-- Rank teams based on touchdown differential

SELECT DISTINCT CFB.TotalOffense.Team, CFB.TotalOffense.OffTDs as OffTDs,
CFB.TotalDefense.OffTDs as DefTDs, (CFB.TotalOffense.OffTDs-CFB.TotalDefense.OffTDs) as TDdiff
FROM CFB.TotalOffense
JOIN CFB.TotalDefense ON CFB.TotalOffense.Team = CFB.TotalDefense.Team 
ORDER BY TDdiff desc;

-- Rank teams based on yards per play differential

SELECT CFB.TotalOffense.Team, CFB.TotalOffense.YdsperPlay as YdsperPlayOff, 
CFB.TotalDefense.YdsperPlay as YdsperPlayDef, 
(CFB.TotalOffense.YdsperPlay-CFB.TotalDefense.YdsperPlay) as YdsperPlayDiff
FROM CFB.TotalOffense
JOIN CFB.TotalDefense ON CFB.TotalOffense.Team = CFB.TotalDefense.Team 
ORDER BY YdsperPlayDiff desc;

-- CTE and case statement that compares average combined offensive
-- and defensive rank for each conference

WITH CTE_combined (Team, OffensiveRank, DefenseRank, CombinedRank,
Conference) as (
SELECT CFB.TotalOffense.Team, CFB.TotalOffense.Rank as OffenseRank,
CFB.TotalDefense.Rank as DefenseRank, 
(CFB.TotalOffense.Rank + CFB.TotalDefense.Rank)/2 as CombinedRank,
CASE 
	WHEN CFB.TotalOffense.Team LIKE '%Big 12%' THEN 'Big 12'
	WHEN CFB.TotalOffense.Team LIKE '%Big Ten%' THEN 'Big Ten'
	WHEN CFB.TotalOffense.Team LIKE '%SEC%' THEN 'SEC'
	WHEN CFB.TotalOffense.Team LIKE '%ACC%' THEN 'ACC'
	WHEN CFB.TotalOffense.Team LIKE '%Pac-12%' THEN 'Pac-12'
	ELSE 'Group of 5'
END as Conference
FROM CFB.TotalOffense 
JOIN CFB.TotalDefense ON CFB.TotalDefense.Team = CFB.TotalOffense.Team 
ORDER BY CombinedRank, CFB.TotalOffense.Rank)

SELECT Conference, AVG(CombinedRank)
FROM CTE_combined
GROUP BY Conference
ORDER BY AVG(CombinedRank);

-- CTE and case statement that compares average touchdown differential
-- for each conference

WITH CTE_TDdiff (Team, OffTDs, DefTDs, TDdiff, Conference) as (
SELECT DISTINCT CFB.TotalOffense.Team, CFB.TotalOffense.OffTDs,
CFB.TotalDefense.OffTDs, (CFB.TotalOffense.OffTDs-CFB.TotalDefense.OffTDs) as TDdiff,
CASE 
	WHEN CFB.TotalOffense.Team LIKE '%Big 12%' THEN 'Big 12'
	WHEN CFB.TotalOffense.Team LIKE '%Big Ten%' THEN 'Big Ten'
	WHEN CFB.TotalOffense.Team LIKE '%SEC%' THEN 'SEC'
	WHEN CFB.TotalOffense.Team LIKE '%ACC%' THEN 'ACC'
	WHEN CFB.TotalOffense.Team LIKE '%Pac-12%' THEN 'Pac-12'
	ELSE 'Group of 5'
END as Conference
FROM CFB.TotalOffense 
JOIN CFB.TotalDefense ON CFB.TotalDefense.Team = CFB.TotalOffense.Team 
ORDER BY TDdiff desc)

SELECT Conference, AVG(TDdiff)
FROM CTE_TDdiff
GROUP BY Conference
ORDER BY AVG(TDdiff) desc;

-- CTE and case statement that compares the average yards per play differential
-- for each conference

WITH CTE_yppDiff (Team, YdsperPlayOff, YdsperPlayDef, YdsperPlayDiff, Conference)
as (
SELECT CFB.TotalOffense.Team, CFB.TotalOffense.YdsperPlay as YdsperPlayOff, 
CFB.TotalDefense.YdsperPlay as YdsperPlayDef, 
(CFB.TotalOffense.YdsperPlay-CFB.TotalDefense.YdsperPlay) as YdsperPlayDiff,
CASE 
	WHEN CFB.TotalOffense.Team LIKE '%Big 12%' THEN 'Big 12'
	WHEN CFB.TotalOffense.Team LIKE '%Big Ten%' THEN 'Big Ten'
	WHEN CFB.TotalOffense.Team LIKE '%SEC%' THEN 'SEC'
	WHEN CFB.TotalOffense.Team LIKE '%ACC%' THEN 'ACC'
	WHEN CFB.TotalOffense.Team LIKE '%Pac-12%' THEN 'Pac-12'
	ELSE 'Group of 5'
END as Conference
FROM CFB.TotalOffense
JOIN CFB.TotalDefense ON CFB.TotalOffense.Team = CFB.TotalDefense.Team 
ORDER BY YdsperPlayDiff desc
)

SELECT Conference, AVG(YdsperPlayDiff) 
FROM CTE_yppDiff
GROUP BY Conference
ORDER BY AVG(YdsperPlayDiff) desc;





