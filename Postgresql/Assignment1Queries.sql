---- ASSIGNMENT 1: QUERIES ----
-- Query 1: Get the names of the female singers who won the competition and the year they won.  
select artist_name, "year" 
from song_data_winner sdw  
where sdw.winner_flag = 1 and sdw.gender = 'Female';


-- Query 2: Get the songs and their final rankings which got more than 10% of the poll votes
-- Calculating the percentages in the poll votes table
ALTER TABLE poll_results_all_years  
ADD COLUMN Total_Votes INT;
UPDATE poll_results_all_years  
SET Total_Votes =  COALESCE(my_eurovision_scoreboard_points, 0) 
                + COALESCE(eurovision_world_points, 0) 
                + COALESCE(eurojury_jury_points, 0) 
                + COALESCE(eurojury_online_points, 0) 
                + COALESCE(discord_points, 0) 
                + COALESCE(wiwiblogs_points, 0) 
                + COALESCE(ogae_points, 0);

ALTER TABLE poll_results_all_years  
ADD COLUMN Total_Votes_per_Year INT;
UPDATE poll_results_all_years  as prc
SET Total_Votes_per_Year = (
    SELECT SUM(Total_Votes)
    FROM poll_results_all_years  as sub
    WHERE sub.year = prc.year
    GROUP BY sub.year
);

ALTER TABLE poll_results_all_years  
ADD COLUMN Percentages INT;
UPDATE poll_results_all_years  
SET Percentages = (total_votes::FLOAT / total_votes_per_year) * 100;

-- Actual query
select sdw.country, sdw.song_name, sdw.final_place , prc.percentages, sdw.winner_flag 
from song_data_winner sdw  
inner join poll_results_all_years prc on sdw."year" = prc."year" and sdw."country" = prc."Contestant" 
where prc.percentages > 10;


-- Query 3: Regional analysis of the winner countries
SELECT combined_data.region, COUNT(*) AS count
FROM (
    SELECT sd.country, sd.final_place, cd.region, sd.year
    FROM song_data sd
    JOIN country_data cd ON sd.country = cd.country
) AS combined_data
WHERE combined_data.final_place = 1
GROUP BY combined_data.region
ORDER BY count DESC;


-- Query 4: The songs which got more than 2 percantage of poll results but did not qualify for the final
select sdw."year" , sdw."country" , sdw."song_name", prc.percentages 
from poll_results_all_years prc inner join song_data_winner sdw on prc."year"=sdw."year" and prc."Contestant" = sdw.country 
where prc.percentages > 2 and sdw.qualified_10 = '0';



-- Query 5: Average percentage of poll results every country get but only for the countries which got more than 3%
SELECT sd.country, AVG(prc.percentages) AS avg_percentage
FROM song_data sd
INNER JOIN poll_results_all_years prc ON sd."year" = prc."year" AND sd.country = prc."Contestant"
GROUP BY sd.country
HAVING AVG(prc.percentages) > 3
ORDER BY AVG(prc.percentages)  DESC;


-- Query 6: Categorizing the performance of each country based on their median final_place

   WITH MedianData AS (
    SELECT
        country,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY final_place) AS median_final_place
    FROM
        song_data
    GROUP BY
        country
)
SELECT
    country,
    CASE
        WHEN median_final_place <= 10 THEN 'Top 10'
        WHEN median_final_place <= 20 THEN 'Top 20'
        ELSE 'Below Top 20'
    END AS performance_category
FROM
    MedianData;
   
 
-- Query 7: The countries to whom Italy gave 12 points to in any of the years
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

-- Query 8: How "Out of Europe" countries vote
SELECT "Contestant", 
COUNT("Georgia") as Geo_point_count, Sum("Georgia") AS Geo_total_giving_points,
COUNT("Azerbaijan") as Aze_point_count, Sum("Azerbaijan") AS Aze_total_giving_points,
COUNT("Israel") as Isr_point_count, Sum("Israel") AS Isr_total_giving_points,
COUNT("Australia") as Aus_point_count, Sum("Australia") AS Aus_total_giving_points
FROM results_all_years ray 
GROUP BY "Contestant"


-- Query 9:Calculate the total points countries gave Italy. (works only by changing the country
-- and re-running the query, see optimized version for better syntax)
select "Contestant", sum("Austria")  from results_all_years 
where "Contestant" = 'Italy' and "Jury/Televote" ='Televote'
group by "Contestant" 



-- Query 10: Analyze the popularity of different music genres for the songs which ended up in top 5.
select "style" , final_place, count("style") as winner_count
from song_data_winner
where final_place <6
group by "style", final_place
order by final_place, winner_count desc


-- Query 11: Impact of Language: Investigate the impact of singing in different languages on 
-- a country's performance. 

-- 383 english, 11 Italian, 11 French, 10 Portuguese
select "language" , count(*) as lang_count from song_data_winner
group by "language" 
order by lang_count desc

--Is there any winner song that is not English?
-- Yes there are 4 songs out of 14
select "year" , country , artist_name , song_name , "language" 
from song_data_winner sdw 
where winner_flag =1 and "language" != 'English'
order by "year" 


-- Query 12: Host Country Advantage: Calculate the average ranking the host countries got 
-- throughout the years. Analyze whether host countries tend to receive higher scores compared to other countries.
-- No relationship was observed
SELECT AVG(final_place) AS avg_final_place
FROM (
    SELECT sdw.final_place
    FROM song_data_winner sdw
    INNER JOIN contest_data cd ON sdw."year" = cd."year" AND sdw.country = cd.host
    ORDER BY cd."year"
);

-- to better examine trends over the years
select cd.host, cd."year" , sdw.final_place  from song_data_winner sdw 
inner join contest_data cd 
on sdw."year" = cd."year" and  sdw.country = cd.host 
order by "year"


-- Query 13: Determine the most successfull countries last 5 years based on their final place
SELECT country , COUNT(*) AS top_10_appearances
FROM song_data
WHERE "year" >2017  AND final_place <= 10
GROUP BY country
HAVING COUNT(*) > 1 
order by top_10_appearances desc

