USE ipl;

#Q1. WHAT ARE THE TOP 5 PLAYERS WITH THE MOST PLAYER OF THE MATCH AWARDS?

SELECT player_of_match, COUNT(*) as awards_count 
FROM matches
GROUP BY player_of_match
ORDER BY awards_count DESC LIMIT 5;

#Q2. HOW MANY MATCHES WERE WON BY EACH TEAM IN EACH SEASON?
SELECT season, winner as team, COUNT(*) as matches_won
FROM matches
GROUP BY season,team
order by season;

#Q3. WHAT IS THE AVERAGE STRIKE RATE OF BATSMEN IN THE IPL DATASET?
SELECT AVG(strike_rate) AS avg_strike_rate 
							FROM (SELECT batter, (SUM(total_runs) /count(ball))*100 as strike_rate
									FROM deliveries
									GROUP BY batter) AS batter_stats;
								
#Q.4 WHAT IS THE NUMBER OF MATCHES WON BY EACH TEAM BATTING FIRST VERSUS BATTING SECOND?

SELECT 
    winner AS team,
    SUM(CASE WHEN toss_winner = winner AND toss_decision = 'bat' THEN 1 ELSE 0 END) AS wins_batting_first,
    SUM(CASE WHEN (toss_winner = winner AND toss_decision = 'field') OR (toss_winner != winner AND toss_decision = 'bat') THEN 1 ELSE 0 END) AS wins_batting_second
FROM 
    matches
GROUP BY 
    winner;
    
#Q.5 WHICH BATSMAN HAS THE HIGHEST STRIKE RATE (MINIMUM 150 RUNS SCORED)?

SELECT batter, (SUM(batsman_runs)/count(*))*100 as strike_rate
FROM deliveries
GROUP BY batter
HAVING SUM(batsman_runs) >=150
ORDER BY strike_rate DESC
LIMIT 1;

#Q.6 HOW MANY TIMES HAS EACH BATSMAN BEEN DISMISSED BY THE BOWLER 'Pravin Kumar'?
SELECT batter, count(*) as total_dismissals
FROM deliveries
WHERE player_dismissed is not null and bowler = 'P Kumar'
GROUP BY batter;

#Q.7 WHAT IS THE AVERAGE PERCENTAGE OF BOUNDARIES (FOURS AND SIXES COMBINED) HIT BY EACH BATSMAN?

SELECT batter, 
ROUND(AVG(case when batsman_runs = 4 or batsman_runs = 6 THEN 1 ELSE 0 END)*100,2) as avg_boundaries
FROM deliveries
GROUP BY batter
ORDER BY avg_boundaries desc;

#Q.8 WHAT IS THE AVERAGE NUMBER OF BOUNDARIES HIT BY EACH TEAM IN EACH SEASON?
#sol1:
SELECT season, batting_team, AVG(boundaries) as avg_boundaries
FROM ( SELECT season, match_id,batting_team,
		SUM(case when batsman_runs = 4 or batsman_runs = 6 THEN 1 ELSE 0 END) AS boundaries
		FROM deliveries,matches
        WHERE deliveries.match_id = matches.id
        GROUP BY season,match_id,batting_team) as team_boundaries
 GROUP BY season, batting_team;       

#Sol2:
SELECT season,batting_team, AVG(boundaries) 
FROM (SELECT season, match_id, batting_team,
		SUM(CASE WHEN batsman_runs = 4 or batsman_runs = 6 THEN 1 ELSE 0 END) AS boundaries
		FROM deliveries
		JOIN matches ON matches.id = deliveries.match_id
		GROUP BY season,match_id,batting_team) as team_boundaries
GROUP BY season,batting_team;

#Q.9 WHAT IS THE HIGHEST PARTNERSHIP (RUNS) FOR EACH TEAM IN EACH SEASON?

SELECT season,batting_team,MAX(partnership_runs) as highest_partnership
FROM (SELECT matches.season,deliveries.batting_team,
		SUM(deliveries.batsman_runs + deliveries.extra_runs) AS partnership_runs
		FROM deliveries
		JOIN matches on deliveries.match_id = matches.id
		GROUP BY matches.season,deliveries.batting_team,deliveries.match_id,deliveries.over) AS partnerships
GROUP BY season,batting_team;

WITH PartnershipRuns AS (
    SELECT 
        m.season,
        d.batting_team,
        d.match_id,
        d.batter,
        d.non_striker,
        SUM(d.batsman_runs + d.extra_runs) AS partnership_runs
    FROM deliveries d
    JOIN matches m ON d.match_id = m.id
    GROUP BY 
        m.season, 
        d.batting_team, 
        d.match_id, 
        d.batter, 
        d.non_striker
),
MaxPartnerships AS (
    SELECT
        season,
        batting_team,
        MAX(partnership_runs) AS highest_partnership
    FROM PartnershipRuns
    GROUP BY 
        season, 
        batting_team
)
SELECT 
    season, 
    batting_team, 
    highest_partnership
FROM MaxPartnerships
ORDER BY season, batting_team;

select season,batting_team,max(total_runs) as highest_partnership
from(select season,batting_team,partnership,sum(total_runs) as total_runs
from(select season,match_id,batting_team,over_no,
sum(batsman_runs) as partnership,sum(batsman_runs)+sum(extra_runs) as total_runs
from deliveries,matches where deliveries.match_id=matches.id
group by season,match_id,batting_team,over_no) as team_scores
group by season,batting_team,partnership) as highest_partnership
group by season,batting_team;


#Q.10 HOW MANY EXTRAS (WIDES & NO-BALLS) WERE BOWLED BY EACH TEAM IN EACH MATCH?

SELECT m.id as 'match_no',d.bowling_team,
SUM(d.extra_runs) as extras
FROM matches m
JOIN deliveries d on d.match_id = m.id
WHERE extra_runs >0
GROUP BY m.id,d.bowling_team;

#Q.11 WHICH BOWLER HAS THE BEST BOWLING FIGURES (MOST WICKETS TAKEN) IN A SINGLE MATCH?

SELECT m.id, d.bowler, count(*) as wicket_taken
FROM matches m
JOIN deliveries d on d.match_id = m.id
WHERE d.player_dismissed is not null
GROUP BY m.id, d.bowler
ORDER BY wicket_taken DESC LIMIT 1;

#Q.12 HOW MANY MATCHES RESULTED IN A WIN FOR EACH TEAM IN EACH CITY?

SELECT city, winning_team, COUNT(*) AS wins
FROM (
    SELECT city, 
           CASE 
               WHEN team1 = winner THEN team1
               WHEN team2 = winner THEN team2
               ELSE 'draw'
           END as winning_team
    FROM matches
    WHERE result != 'tie'
) AS match_results
GROUP BY city, winning_team;

select m.city,case when m.team1=m.winner then m.team1
when m.team2=m.winner then m.team2
else 'draw'
end as winning_team,
count(*) as wins
from matches as m
join deliveries as d on d.match_id=m.id
where m.result!='Tie'
group by m.city,winning_team;

#Q.13 HOW MANY TIMES DID EACH TEAM WIN THE TOSS IN EACH SEASON?

SELECT season, CASE WHEN team1 = toss_winner then team1
ELSE  team2
END as team,
count(*) as toss_wins
FROM matches
GROUP BY season,team;

select season,toss_winner,count(*) as toss_wins
from matches group by season,toss_winner;

#Q.14 HOW MANY MATCHES DID EACH PLAYER WIN THE "PLAYER OF THE MATCH" AWARD?

SELECT player_of_match, COUNT(*) as total_wins
FROM matches
WHERE player_of_match IS NOT NULL
GROUP BY player_of_match
ORDER BY total_wins DESC;

#Q.15 WHAT IS THE AVERAGE NUMBER OF RUNS SCORED IN EACH OVER OF THE INNINGS IN EACH MATCH?

SELECT m.id, d.inning, d.over_no,
AVG(d.total_runs) as avg_runs_per_over
FROM matches m
JOIN deliveries d on d.match_id = m.id
GROUP BY m.id, d.inning, d.over_no;

#Q.16 WHICH TEAM HAS THE HIGHEST TOTAL SCORE IN A SINGLE MATCH?

SELECT m.id, m.season, d.batting_team,
SUM(d.total_runs) as 'total_score'
FROM matches m
JOIN deliveries d on d.match_id = m.id
GROUP BY m.id,m.season,d.batting_team
ORDER BY total_score DESC LIMIT 1;

#Q.17 WHICH BATSMAN HAS SCORED THE MOST RUNS IN A SINGLE MATCH?

SELECT m.id, m.season, d.batter as batsman,
SUM(d.batsman_runs) as runs
FROM matches m
JOIN deliveries d ON d.match_id = m.id
GROUP BY m.id, m.season, d.batter
ORDER BY runs DESC LIMIT 1;