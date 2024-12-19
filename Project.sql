select * from goals
select * from matches
select * from players
select * from stadiums
select * from teams

--1)Count the Total Number of Teams
select distinct count(team_name) from teams

--2)Find the Number of Teams per Country
select distinct country,count(team_name) from teams group by country order by count(team_name) desc

--3)Calculate the Average Team Name Length
select avg(length(team_name)) from teams 

--4)Calculate the Average Stadium Capacity in Each Country round it off and sort by the total stadiums in the country.
select ceil(avg(capacity)) as avg_capacity ,count(name) as total_no_stadiums from stadiums group by country order by count(name) desc

--5)Calculate the Total Goals Scored.
select distinct count(goal_id) as tottal_goals_scored from goals

--6)Find the total teams that have city in their names
select count(team_name) as total_teams_city from teams where team_name like '%City%'

--7) Use Text Functions to Concatenate the Team's Name and Country
select team_name || ' , ' || country as team_details from teams

/*8) What is the highest attendance recorded in the dataset, and which match 
(including home and away teams, and date) does it correspond to?*/
select match_id,date,home_team,away_team, attendance from matches where attendance = (select max(attendance) from matches)

/*9)What is the lowest attendance recorded in the dataset, and which match (including home and away teams, and date) 
does it correspond to set the criteria as greater than 1 as some matches had 0 attendance because of covid.*/
select match_id,date,home_team,away_team, attendance from matches where attendance = (select min(attendance) 
from matches where attendance>1)

/*10) Identify the match with the highest total score (sum of home and away team scores) in the dataset. 
Include the match ID, home and away teams, and the total score.*/
select match_id,date,home_team,away_team,(home_team_score + away_team_score) as total_score 
from matches order by total_score desc limit 1

/*11)Find the total goals scored by each team, distinguishing between home and away goals.
Use a CASE WHEN statement to differentiate home and away goals within the subquery*/
select team,
	sum(home_goals) as home_goals,
	sum(away_goals) as away_goals
from (
	select 
		home_team as team,
		case when home_team is not null then home_team_score else 0 end as home_goals,
        0 AS away_goals
	from 
		matches
	union all
	select
		away_team as team,
		0 as home_goals,
        case when away_team is not null then away_team_score else 0 end as away_goals
	from 
		matches) as subquery
	group by team;	

/*12) windows function - Rank teams based on their total scored goals (home and away combined) using a window function.
In the stadium Old Trafford.*/
select 
	team,total_goals,
	rank() over (order by total_goals desc) as rank
from
	(select 
		home_team as team,
		sum(home_team_score) as total_goals
	from 
		matches where stadium = 'Old Trafford' 
		group by home_team
	union all 
		select 
			away_team as team,
			sum(away_team_score) as total_goals
	from 
		matches where stadium = 'Old Trafford' 
		group by away_team) as combined_goals
	group by team,total_goals 
	order by rank;

/*13) TOP 5 l players who scored the most goals in Old Trafford, ensuring null values are not included in the result 
(especially pertinent for cases where a player might not have scored any goals).*/
select a.player_id ,
count(goal_id) as player_goals
from players as a left join goals as b on a.player_id = b.pid 
left join matches as c on b.match_id = c.match_id  where c.stadium = 'Old Trafford'
group by player_id having count(goal_id)>0 order by player_goals desc limit 5

/*14)Write a query to list all players along with the total number of goals they have scored. 
Order the results by the number of goals scored in descending order to easily identify the top 6 scorers*/
select a.player_id,
count(goal_id) as player_goals
from players as a left join goals as b on a.player_id = b.pid group by player_id order by count(goal_id) desc limit 6

/*15)Identify the Top Scorer for Each Team - Find the player from each team who has scored the most goals in all matches combined. This question requires joining the Players, Goals, and possibly the Matches tables, 
and then using a subquery to aggregate goals by players and teams*/
select
    team,
    pid,
    total_goals
from (
    select 
        p.team,
        g.pid,
        count(g.goal_id) as total_goals,
        rank() over (partition by p.team order by count(g.goal_id) desc) as rank
    from
        players p
    join 
        goals g on p.player_id = g.pid
    join
        matches m on g.match_id = m.match_id
    group by
        p.team, g.pid
) as ranked_goals
where
    rank = 1;

/*16)Find the Total Number of Goals Scored in the Latest Season - Calculate the total number of goals scored in the latest season 
available in the dataset.This question involves using a subquery to first identify the latest season
from the Matches table, then summing the goals from the Goals table that occurred in matches from that season.*/
select
    sum(home_team_score + away_team_score) as total_goals
	from 
		matches 
	where 
		season = (select max(season) from Matches)

/*Find Matches with Above Average Attendance - Retrieve a list of matches that had an attendance higher than 
the average attendance across all matches. This question requires a subquery to calculate the average attendance first, 
then use it to filter matches.*/
select 
	match_id,
	attendance 
from 
	matches 
where 
	attendance > (select avg(attendance) as avgerage from matches)
	
/*18)Find the Number of Matches Played Each Month - Count how many matches were played in each month across all seasons. 
This question requires extracting the month from the match dates and grouping the results by this value. as January Feb march*/
select 
    to_char(date, 'Month') as month,
    count(*) as match_count
from matches
group by TO_CHAR(date, 'Month')
order by TO_DATE(TO_CHAR(date, 'Month'), 'Month')
