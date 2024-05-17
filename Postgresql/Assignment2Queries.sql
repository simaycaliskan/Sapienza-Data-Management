---- **** ASSIGNMENT 2: QUERY OPTIMIZATION **** ----

--- Query 2: Get the songs and their final rankings which got more than 10% of the poll votes

--Non-Optimized Version 
select sdw.country, sdw.song_name, sdw.final_place , prc.percentages, sdw.winner_flag 
from song_data_winner sdw  
inner join poll_results_all_years prc on sdw."year" = prc."year" and sdw."country" = prc."Contestant" 
where prc.percentages > 10;

-- Optimization: Adding indices changed the Hash Join to Nested Loop. This made us reduce the cost from
-- 9.53 - 68.85 to 4.44 - 26.11; and time from 1.048 to 0.092.
drop index idx_year_country_sdw;
drop index idx_year_country_prc;
CREATE INDEX idx_year_country_sdw ON song_data_winner ("year", "country");
CREATE INDEX idx_year_country_prc ON poll_results_all_years ("year", "Contestant");

select sdw.country, sdw.song_name, sdw.final_place , prc.percentages, sdw.winner_flag 
from song_data_winner sdw  
inner join poll_results_all_years prc on sdw."year" = prc."year" and sdw."country" = prc."Contestant" 
where prc.percentages > 10;

--- Query 3: Regional analysis of the winner countries

--Non-Optimized Version 
SELECT combined_data.region, COUNT(*) AS count
FROM (
    SELECT sd.country, sd.final_place, cd.region, sd.year
    FROM song_data sd
    JOIN country_data cd ON sd.country = cd.country
) AS combined_data
WHERE combined_data.final_place = 1
GROUP BY combined_data.region
ORDER BY count DESC;

-- Optimization: Changing the query syntax by filtering the data before performing the join operation.
WITH combined_data AS (
    SELECT sd.country, sd.final_place, cd.region, sd.year
    FROM song_data sd
    JOIN country_data cd ON sd.country = cd.country
    WHERE sd.final_place = 1
)
SELECT combined_data.region, COUNT(*) AS count
FROM combined_data
GROUP BY combined_data.region
ORDER BY count DESC;

   
--- Query 7: The countries to whom Italy gave 12 points to in any of the years

--Non-Optimized Version 
-- Televote
select t1.*, wd.winner from
(select "Contestant", "year" , "Jury/Televote" , "Total score", "Jury score", "Televoting score"
from results_all_years 
where "Italy"=12 and "Jury/Televote" ='Televote') as t1
left join winner_data wd 
on t1.year = wd.years and t1."Contestant"=wd.winner 
order by year

-- Jury
select t1.*, wd.winner from
(select "Contestant", "year" , "Jury/Televote" , "Total score", "Jury score", "Televoting score"
from results_all_years 
where "Italy"=12 and "Jury/Televote" ='Jury'
) as t1
left join winner_data wd 
on t1.year = wd.years and t1."Contestant"=wd.winner 
order by year

--Optimization: Creating an index on Jury/Televote column while also changing the syntax
-- reduced the time.
drop index idx_jury_televote;  
create index idx_jury_televote on results_all_years ("Jury/Televote")
-- Televote
SELECT t1.*, wd.winner
FROM (
    SELECT "Contestant", "year", "Jury/Televote", "Total score", "Jury score", "Televoting score"
    FROM results_all_years 
    WHERE "Italy" = 12 AND "Jury/Televote" = 'Televote'
) AS t1
LEFT JOIN winner_data wd ON t1."year" = wd.years AND t1."Contestant" = wd.winner 
ORDER BY t1."year";

-- Jury
SELECT t1.*, wd.winner
FROM (
    SELECT "Contestant", "year", "Jury/Televote", "Total score", "Jury score", "Televoting score"
    FROM results_all_years 
    WHERE "Italy" = 12 AND "Jury/Televote" = 'Jury'
) AS t1
LEFT JOIN winner_data wd ON t1."year" = wd.years AND t1."Contestant" = wd.winner 
ORDER BY t1."year";

  

--- Query 9: Calculate the total points countries gave Italy.

--Non-Optimized Version 
select "Contestant", sum("Austria")  from results_all_years 
where "Contestant" = 'Italy' and "Jury/Televote" ='Televote'
group by "Contestant" 

-- Optimization: The previous version could only work by writing every country one by one and then
-- executing the query again and again. The following syntax does this in a single query.
CREATE OR REPLACE FUNCTION get_points_for_italy()
RETURNS TABLE (giving_country TEXT, total_points INT) AS
$$
DECLARE
    country_name TEXT;
    sql_query TEXT;
    result RECORD;
BEGIN
    -- Create a temporary table to store the results
    CREATE TEMPORARY TABLE temp_results (giving_country TEXT, total_points INT);
    
    -- Loop through each country column
    FOR country_name IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'results_all_years' AND ordinal_position BETWEEN 5 AND 30
    LOOP
        -- Construct the dynamic SQL query
        sql_query := 'SELECT ''' || country_name || ''' AS giving_country, SUM("' || country_name || '") AS total_points FROM results_all_years WHERE "Jury/Televote" =''Televote'' and "Contestant" = ''Italy'';';

        -- Execute the dynamic SQL query
        EXECUTE sql_query INTO result;
        
        -- Insert the result into the temporary table
        INSERT INTO temp_results VALUES (result.giving_country, result.total_points);
    END LOOP;
    
    -- Return the contents of the temporary table
    RETURN QUERY SELECT * FROM temp_results;
    
    -- Drop the temporary table
    DROP TABLE temp_results;
END $$ LANGUAGE plpgsql;

SELECT * FROM get_points_for_italy();


--- Query 13: Determine the most successfull countries last 5 years based on their final place

--Non-Optimized Version 
SELECT country , COUNT(*) AS top_10_appearances
FROM song_data
WHERE "year" >2017  AND final_place <= 10
GROUP BY country
HAVING COUNT(*) > 1 
order by top_10_appearances desc

-- Optimization: Adding the following index reduced the time.
drop index idx_year_final_place;
create index idx_year_final_place on song_data ("year", final_place);
SELECT country , COUNT(*) AS top_10_appearances
FROM song_data
WHERE "year" >2017  AND final_place <= 10
GROUP BY country
HAVING COUNT(*) > 1 
order by top_10_appearances desc




-- To check all the indices a table has
SELECT * FROM pg_indexes WHERE tablename = 'song_data';