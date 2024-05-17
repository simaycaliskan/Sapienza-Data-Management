---------------DATA PREPARATION------------------------------

-- POLL RESULTS --

ALTER table "2016_poll_results" add year int;
ALTER table "2017_poll_results" add year int;
ALTER table "2018_poll_results" add year int;
ALTER table "2019_poll_results" add year int;
ALTER table "2021_poll_results" add year int;
ALTER table "2022_poll_results" add year int;
ALTER table "2023_poll_results" add year int;

update "2016_poll_results" set year = 2016;
update "2017_poll_results" set year = 2017;
update "2018_poll_results" set year = 2018;
update "2019_poll_results" set year = 2019;
update "2021_poll_results" set year = 2021;
update "2022_poll_results" set year = 2022;
update "2023_poll_results" set year = 2023;


create table poll_results_all_years as 
SELECT * FROM "2016_poll_results" 
union all
SELECT * FROM "2017_poll_results"
union all
SELECT * FROM "2018_poll_results"
union all
SELECT * FROM "2019_poll_results"
union all
SELECT * FROM "2021_poll_results"
union all
SELECT * FROM "2022_poll_results"
union all
SELECT * FROM "2023_poll_results";



select count(*) from poll_results_all_years --284


------------------------------------------------------------------

-- JURY RESULTS --

ALTER table "2016_jury_results" add year int;
ALTER table "2017_jury_results" add year int;
ALTER table "2018_jury_results" add year int;
ALTER table "2019_jury_results" add year int;
ALTER table "2021_jury_results" add year int;
ALTER table "2022_jury_results" add year int;
ALTER table "2023_jury_results" add year int;

update "2016_jury_results" set year = 2016;
update "2017_jury_results" set year = 2017;
update "2018_jury_results" set year = 2018;
update "2019_jury_results" set year = 2019;
update "2021_jury_results" set year = 2021;
update "2022_jury_results" set year = 2022;
update "2023_jury_results" set year = 2023;



create table jury_results_all_years as 
SELECT *
FROM
    (SELECT * FROM "2016_jury_results") AS "2016_jury_results"
NATURAL FULL JOIN
    (SELECT * FROM "2017_jury_results") AS "2017_jury_results"
NATURAL FULL JOIN
     (SELECT * FROM "2018_jury_results") AS "2018_jury_results"
NATURAL FULL JOIN
    (SELECT * FROM "2019_jury_results") AS "2019_jury_results"
NATURAL FULL JOIN
     (SELECT * FROM "2021_jury_results") AS "2021_jury_results"
NATURAL FULL JOIN
    (SELECT * FROM "2022_jury_results") AS "2022_jury_results"
NATURAL FULL JOIN
    (SELECT * FROM "2023_jury_results") AS "2023_jury_results";

select count(*) from jury_results_all_years --181


------------------------------------------------------------------------
-- TELEVOTE RESULTS --

ALTER table "2016_televote_results" add year int;
ALTER table "2017_televote_results" add year int;
ALTER table "2018_televote_results" add year int;
ALTER table "2019_televote_results" add year int;
ALTER table "2021_televote_results" add year int;
ALTER table "2022_televote_results" add year int;
ALTER table "2023_televote_results" add year int;

update "2016_televote_results" set year = 2016;
update "2017_televote_results" set year = 2017;
update "2018_televote_results" set year = 2018;
update "2019_televote_results" set year = 2019;
update "2021_televote_results" set year = 2021;
update "2022_televote_results" set year = 2022;
update "2023_televote_results" set year = 2023;


create table televote_results_all_years as 
(SELECT *
FROM
    (SELECT * FROM "2016_televote_results") AS "2016_televote_results"
NATURAL FULL JOIN
    (SELECT * FROM "2017_televote_results") AS "2017_televote_results"
NATURAL FULL JOIN
     (SELECT * FROM "2018_televote_results") AS "2018_televote_results"
NATURAL FULL JOIN
    (SELECT * FROM "2019_televote_results") AS "2019_televote_results"
NATURAL FULL JOIN
     (SELECT * FROM "2021_televote_results") AS "2021_televote_results"
NATURAL FULL JOIN
    (SELECT * FROM "2022_televote_results") AS "2022_televote_results"
NATURAL FULL JOIN
    (SELECT * FROM "2023_televote_results") AS "2023_televote_results");

 
select count(*) from televote_results_all_years --181

-------------------------------------------------------------------------------

-- CONCAT JURY AND TELEVOTE RESULTS INTO ONE TABLE --

ALTER table jury_results_all_years  add "Jury/Televote" varchar(100);
ALTER table televote_results_all_years  add "Jury/Televote" varchar(100);

update "jury_results_all_years" set "Jury/Televote" = 'Jury';
update "televote_results_all_years" set "Jury/Televote" = 'Televote';

create table Results_all_years as 
(SELECT *
FROM
(SELECT * FROM "jury_results_all_years") AS "jury_results_all_years"
NATURAL FULL JOIN
(SELECT * FROM "televote_results_all_years") AS "televote_results_all_years");

select count(*) from Results_all_years -- 362


-------------------------------------------------------------------------------
-- We noticed the name of the "Czech Republic" is changed to "Czechia" in 2023.
-- After checking the other table's too, we changed "Czechia" data into "Czech Republic" and
-- deleted the data related to the old name.

UPDATE Results_all_years
SET "Czech Republic" = 
    CASE 
        WHEN year = 2023 THEN "Czechia"
        ELSE "Czech Republic" 
    END;

ALTER TABLE Results_all_years DROP COLUMN "Czechia";


-----------------------------------------------------------------
-- Fix the winner data and add the missing value of 2023 --

create table winner_data as
select "year"-1 as years, host as winner from contest_data cd;

update winner_data set winner='Ukraine'
where years = 2022;

update winner_data set years=2019
where years = 2020;

INSERT INTO winner_data (years, winner)
VALUES (2023, 'Sweden');


------------------------------------------------------------------

-- Adding winner flag to song_data_winner table

create table song_data_winner as
SELECT *
from song_data sd  
left JOIN winner_data wd
  ON wd.years = sd."year" and wd.winner = sd.country ;
  
    
ALTER TABLE song_data_winner ADD winner_flag INT DEFAULT 0;

UPDATE song_data_winner
SET winner_flag = CASE
                    WHEN winner IS NOT NULL THEN 1
                    ELSE 0
                  END;
                 
               
ALTER TABLE song_data_winner drop years;
ALTER TABLE song_data_winner drop winner;


