-- 1. What range of years for baseball games played does the provided database cover? 

-- Answer: 1871-2016, 146 years

select table_name, column_name 
from information_schema.columns
where column_name ILIKE '%year%';

select min(year) earliest_year, max(year) latest_year
from homegames;

select min(yearid) earliest_year, max(yearid) latest_year
from teams;


-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

-- Answer: Eddie Gaedel, 43, 1 game, St. Louis Browns

with shortest_player as (
    select playerid, namefirst, namelast, height 
    from people 
    where height = (select min(height) from people)  
)
select sp.namefirst, sp.namelast, sp.height, 
       sum(a.g_all) as total_games, 
       t.name as team_name
from shortest_player sp
left join appearances a 
	on sp.playerid = a.playerid
left join teams t 
	on a.teamid = t.teamid and a.yearid = t.yearid  
group by sp.namefirst, sp.namelast, sp.height, t.name;



-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

-- Answer : David Price

select 
	p.namefirst, p.namelast, sum(distinct s.salary) total_salary
from people p
inner join collegeplaying c 
	on p.playerid = c.playerid
inner join schools sch 
	on c.schoolid = sch.schoolid
inner join salaries s
	on p.playerid = s.playerid
where sch.schoolname ILIKE '%vanderbilt%'
and s.lgid in ('AL', 'NL')
group by p.namefirst, p.namelast
order by total_salary desc;



-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

select 
	p.namefirst, p.namelast, f.teamid,
	case 
		when f.pos = 'OF' then 'Outfield'
		when f.pos in ('SS', '1B', '2B', '3B') then 'Infield'
		when f.pos in ('P', 'C') then 'Battery'
	end as position_group,
	sum(f.po) as total_putouts
from fielding f
inner join people p on f.playerid = p.playerid
where f.yearid = 2016
group by p.namefirst, p.namelast, f.teamid, position_group
order by total_putouts desc; 


select 
	case 
		when pos = 'OF' then 'Outfield'
		when pos in ('SS', '1B', '2B', '3B') then 'Infield'
		when pos in ('P', 'C') then 'Battery'
	end as position_group,
	sum(po) as total_putouts
from fielding 
where yearid = 2016
group by position_group
order by total_putouts desc; 


-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

select 
	floor(yearid / 10) * 10 as decade, 
	round(avg(lg_so_per_g), 2) as avg_so,
	round(avg(lg_hr_per_g), 2) as avg_hr
from (
	select 
		yearid, 
		sum(so) * 1.0 / (sum(g) / 2) as lg_so_per_g,
		sum(hr) * 1.0 / (sum(g) / 2) as lg_hr_per_g
	from teams
	where yearid >= 1920
	group by yearid 
) as league_totals	
group by floor(yearid / 10) * 10 
order by decade desc;


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

select 
	p.namefirst as namefirst,
	p.namelast as namelast,
	concat(round(sum(b.sb) * 100.0 / (sum(b.sb) + 
	sum(b.cs)), 2), '%') as sb_success
from batting b 
join people p on b.playerid = p.playerid
where 
	b.yearid = 2016
	and (b.sb + b.cs) >= 20
group by b.playerid, p.namefirst, p.namelast
order by sb_success desc
limit 1;


-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

select 
	yearid, wswin, name, w
from teams	
where yearid between 1970 and 2016
and wswin = 'N'
order by w desc
limit 1;

select 
	yearid, wswin, name, w
from teams	
where yearid between 1970 and 2016
and wswin = 'Y'
order by w
limit 1;

-- Answer: 1981 season was shortened due to a players strike

select 
	yearid, wswin, name, w
from teams	
where yearid between 1970 and 2016
and wswin = 'Y'
and yearid <> 1981
order by w
limit 1;


with mostwins as (
	select yearid, max(w) as max_wins
	from teams
	where yearid between 1970 and 2016
	and yearid <> 1981
	group by yearid
),
wswinners as (
	select 
		t.yearid, t.teamid, t.name as team_name, t.w as wins,
		case 
			when t.wswin = 'Y' then 1
			else 0
	end as occurence	
	from teams t
	join mostwins m on t.yearid = m.yearid and t.w = m.max_wins
)
select
	sum(occurence) as occurences,
	count(distinct yearid) as ws,
	round(sum(occurence) * 100.0 / count(distinct yearid), 2) as percentage
from wswinners;


-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

with attendance2016 as (
	select 
		h.park, h.team, 
		sum(h.attendance) as total_attendance,
		sum(h.games) as total_games,
		sum(h.attendance) * 1.0 / sum(h.games) as avg_attendance 
	from homegames h
	where h.year = 2016
	group by h.park, h.team
	having sum(h.games) >= 10
)
select 
	p.park_name,
	t.name as team_name,
	round(a.avg_attendance, 0) as avg_attendance
from attendance2016 a 
join parks p on a.park = p.park
join teams t on a.team = t.teamid
and t.yearid = 2016
order by a.avg_attendance desc 
limit 5;

----

with attendance2016 as (
	select 
		h.park, h.team, 
		sum(h.attendance) as total_attendance,
		sum(h.games) as total_games,
		sum(h.attendance) * 1.0 / sum(h.games) as avg_attendance 
	from homegames h
	where h.year = 2016
	group by h.park, h.team
	having sum(h.games) >= 10
)
select 
	p.park_name,
	t.name as team_name,
	round(a.avg_attendance, 0) as avg_attendance
from attendance2016 a 
join parks p on a.park = p.park
join teams t on a.team = t.teamid
and t.yearid = 2016
order by a.avg_attendance asc
limit 5;


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

with tsnwinners as (
	select distinct
		am.playerid, am.lgid, t.name as team_name
	from awardsmanagers am	
	join managers m on am.playerid = m.playerid
	and  am.yearid = m.yearid
	join teams t on m.teamid = t.teamid
	and m.yearid = t.yearid
	where am.awardid = 'TSN Manager of the Year'
	and am.lgid in ('AL', 'NL')
)
select 	
	concat(p.namefirst, ' ', p.namelast) as full_name,
	tw.team_name, tw.lgid
from tsnwinners tw
join people p on tw.playerid = p.playerid
where tw.playerid in(
	select playerid
	from tsnwinners
	group by playerid
	having count(distinct lgid) = 2
)
order by full_name, lgid;


-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

with playercareerhr as (
	select
		playerid, sum(hr) as career_hr
	from batting
	group by playerid
),
player2016hr as (
	select
		playerid, sum(hr) as hr_2016
	from batting
	where yearid = 2016
	group by playerid
	having sum(hr) >= 1
),
playeryearsplayed as (
	select
		playerid,
		count(distinct yearid) as years_played
	from batting
	group by playerid
	having count(distinct yearid) >= 10
)
select 
	p.namefirst as first_name,
	p.namelast as last_name,
	ph.hr_2016 as hr_2016
from player2016hr ph
join playercareerhr pc on ph.playerid = pc.playerid
join playeryearsplayed py on ph.playerid = py.playerid
join people p on ph.playerid = p.playerid
where ph.hr_2016 = pc.career_hr
order by hr_2016 desc;


---

with playercareerhr as (
    select
        playerid,
        max(hr) as careermaxhr
    from batting
    group by playerid
),
player2016hr as (
    select
        playerid,
        hr as hr2016
    from batting
    where yearid = 2016 and hr >= 1
),
playeryearsinleague as (
    select
        playerid,
        count(distinct yearid) as yearsplayed
    from batting
    group by playerid
    having count(distinct yearid) >= 10
)
select
    p.namefirst as firstname,
    p.namelast as lastname,
    ph.hr2016 as homeruns2016
from people p
join player2016hr ph on p.playerid = ph.playerid
join playercareerhr pch on p.playerid = pch.playerid
join playeryearsinleague pyl on p.playerid = pyl.playerid
where ph.hr2016 = pch.careermaxhr;


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

select
    t.yearid as year,
    t.teamid as team,
    t.w as wins,
    sum(s.salary) as total_salary
from teams t
join salaries s on t.yearid = s.yearid and t.teamid = s.teamid
where t.yearid >= 2000
group by t.yearid, t.teamid, t.w
order by t.yearid, t.teamid


select
    t.yearid as year,
    t.teamid as team,
    t.w as wins,
    sum(s.salary) as total_salary
from teams t
join salaries s on t.yearid = s.yearid and t.teamid = s.teamid
where t.yearid >= 2000
and t.w > 70
group by t.yearid, t.teamid, t.w
order by t.w


select
    t.yearid as year,
    t.teamid as team,
    t.w as wins,
    sum(s.salary) as total_salary
from teams t
join salaries s on t.yearid = s.yearid and t.teamid = s.teamid
where t.yearid >= 2000
group by t.yearid, t.teamid, t.w
order by t.w

-- There's an overall postive trend but years over time play into that. I did notice a peak at 85 wins with 231,978,889 in 2013 with the New York Yankees.



-- 12. In this question, you will explore the connection between number of wins and attendance.



--     <ol type="a">
--       <li>Does there appear to be any correlation between attendance at home games and number of wins? </li>

select
    yearid as year,
    teamid as team,
    w as wins,
    attendance as home_attendance
from teams
where attendance is not null
and w > 50
and yearid > 1950
order by w, yearid 


--       <li>Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.</li>
--     </ol>




-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

  
