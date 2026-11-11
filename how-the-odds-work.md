# How the odds work

`race` answers "who can still win the league, who is out, and how likely is each team?"
It has two parts: exact arithmetic that is always right, and an optional simulation (`odds`) that is an estimate.
The same team ratings also give the chances of a single match: see [Odds for one match](#odds-for-one-match-scores-odds).

```
race title                 exact maths for the title
race relegation odds       adds simulated chances
race ucl odds bundesliga   top-four (or five) race in another league
```

Lines available: `title`, `ucl`, `europe`, `promotion`, `relegation`. Which ones exist depends on the league.

## Part 1: the exact maths (always on)

Each team has a points total today and a number of games left (a double round-robin season has
`2 × (teams − 1)` games). From that:

- **Max** is points now plus 3 for every game left: the most the team could possibly finish on.
- A team is **eliminated** from a line (say, the title) when enough other teams already have more points
  than its Max.
- A team has **clinched** a line when too few rivals could still reach its current points to catch it.
- **Magic number** is how many more points a team needs to be certain of the line. Every point the team
  wins, or that a rival can no longer reach, counts as one.
- **Gap** is points above (+) or below (−) the line right now.
- **Tiebreak only** means a team can reach the line only by finishing level on points, so goal difference or
  head-to-head would decide it.

Points are all this uses, so it is exact: if it says a team is out, they are out.

## Part 2: the simulation (`odds`)

The simulation plays the rest of the season thousands of times and counts how often each outcome happens.

### 1. Rate every team

Goals in a match are modelled as **Poisson** random numbers (the standard way to model rare events like goals).
Only the average for each side has to be decided:

```
home goals ≈ league average × home advantage × attack(home team) × defence(away team)
away goals ≈ league average × attack(away team) × defence(home team)
```

`attack` above 1 means the team scores more than average. `defence` above 1 means it concedes more than average,
so lower is better.

The ratings come from **every finished match in the season, fitted together**. That is what makes them
opponent-adjusted: scoring three against a strong defence raises a team's attack rating more than scoring
three against a weak one.

- **Recent games count more.** A game's weight halves every 150 days, so late-season ratings follow
  current form.
- **Early on, last season is the starting point.** With only a handful of games played, results say little.
  So each team begins from its rating from last season in full,
  and that starting point counts as twelve games of evidence. A team promoted this year has no top-flight
  rating, so it starts weaker than average (it scores about 20% less and concedes about 20% more).
  As real results arrive they take over, and by mid-season the effect is small (see the test below).
  Last season's ratings are fetched the first time you ask for `odds` in a league, then saved, so later runs
  need no extra request. Only a pair of numbers per team is saved, never match data. If last season can't be
  fetched, the model falls back to a plain average starting point (four pseudo-games).

### 2. Admit the ratings are uncertain

A rating is an estimate. A team with 15 goals scored is much less certain than one with 60. The simulation
is split into 500 batches. Before each batch, every team's attack and defence are nudged by a random amount
sized to how little data supports them (roughly `1 ÷ √goals`, so 15 goals gives about ±26% and 40 goals about
±16%). Within a batch the ratings are fixed; across batches they vary. This stops the model from claiming more
certainty than the results justify.

### 3. Play out the season

Up to 10,000 seasons are simulated (fewer when many fixtures remain, to keep it to a second or two).
Each starts from the table of finished games. For every remaining fixture it draws a home and away score,
awards the points and updates goal difference. Teams are ranked on points, then goal difference, then goals
scored, then a random tiebreak.

**Games in play are played out, not counted as final.** A match that is on right now starts from its current
score, and only the time left is simulated: each team's expected goals are scaled by the share of the match
remaining, and any goals drawn are added to the score so far. So a 2–0 lead with 10 minutes left is worth almost
three points, while the same lead after 20 minutes still leaves room for a comeback. The plain table and the
`Gap` and `Magic` columns still treat the live score as if the game ended now, and the odds only show
100% or 0% for a team that is settled whatever the live games do.

The free plan doesn't give the match minute, so the clock is estimated from the kick-off time, allowing 15
minutes for half-time (and half-time itself counts as exactly half over). A late kick-off or a long stoppage
will make that a few minutes out.

### 4. Read the results

| Column | Meaning |
|---|---|
| **Chance** | Share of simulated seasons in which the team finishes inside the line (top 1 for the title) |
| **Exp pts** | Average final points |
| **Finish** | The range of positions that covers 80% of the simulated seasons (10th to 90th percentile) |

**Δ MD9 (change since a matchday).** The odds are worked out a second time as they stood after an earlier
matchday: the table is rebuilt from the games played by then, the ratings are refitted using only those games,
and the rest of the season (including games since played) is simulated. The difference is the impact of the
results in between. By default it compares with the previous matchday; `since 5` compares with matchday 5.
Two runs of the same simulation differ by a point or two on their own, so changes under 3 points show as `·`.

Teams the exact maths has already settled show 100% or 0%, so the two parts never disagree.
The random seed comes from the data, so the same table gives the same numbers each time.

## Odds for one match (`scores odds`)

`scores odds` adds three columns to a matchday: the chance of a home win, a draw and an away win for every
game that hasn't finished.

- It uses the same ratings as the race odds: attack and defence fitted from this season's finished games,
  adjusted for opponents, with recent games counting more and last season as the starting point.
- Each team's expected goals come from the formula in Part 2, and the chance of each score comes from the
  Poisson distribution. Adding up every score where the home side wins, draws or loses gives the three numbers.
- Ratings are uncertain, so the answer is averaged over many plausible versions of the two teams' strengths.
  That keeps a mismatch from looking more certain than it is.
- **Games in play** start from the current score and use only the time left, the same way as in the season
  simulation. A draw becomes less likely as the clock runs down, and a lead becomes safer.

What it knows is results and the score. It does not know line-ups, injuries, suspensions or red cards. Unlike the
season odds, these single-match probabilities haven't been backtested yet: the test above checks the
season-long chances.

## How well does it work?

I tested it on 59 finished league-seasons: the Premier League, La Liga, Serie A, Bundesliga and Ligue 1, from
2014/15 to 2025/26 (results from football-data.co.uk; the one season cut short by COVID is left out). For each
one, the test went back to 25%, 50% and 75% of the way through the season, used only the results up to that
point, simulated the rest, and compared the odds with what actually happened. The lines tested were top 1,
top 4, the top half, and "safe from the bottom three", 13,800 predictions in all. `pitchside model` shows the
same numbers.

**When the model said X%, how often did it happen?**

| Model said | Happened | Predictions |
|---|---|---|
| 0–2% | 0.1% | 5,404 |
| 2–10% | 4.7% | 1,051 |
| 10–20% | 13.3% | 622 |
| 20–30% | 21.4% | 472 |
| 30–40% | 36.6% | 369 |
| 40–50% | 40.4% | 376 |
| 50–60% | 58.3% | 355 |
| 60–70% | 66.0% | 403 |
| 70–80% | 78.1% | 456 |
| 80–90% | 87.2% | 546 |
| 90–98% | 95.1% | 875 |
| 98–100% | 99.9% | 2,871 |

- **Close to honest across the range.** Most bins land within a few points of the stated odds. Chances of
  50% or more came off slightly more often than stated (the model is a little timid about favourites), and
  the 20–50% bins ran a few points high.
- **It gets better as the season goes on.** The Brier score (an accuracy measure where lower is better and 0 is
  perfect) was 0.070 at 25% through, 0.054 at 50% and 0.037 at 75%.
- **Against reading the table:** at 25% through, the model's pick for the champion was right 68% of the time
  against 54% for the league leader; at halfway 73% against 69%; at 75% the table was as good (88% against 90%).
  The model's value is the probabilities, not the picks.
- **How much room is left?** Given every team's true strength (which is cheating), the error would fall by only
  17% at 25% through, 11% at 50% and 5% at 75%. Most of what is left is luck in games not yet played.

**Starting from last season.** The same snapshots, plus one about three matchdays in, with and without last
season as the starting point:

| Through the season | Plain average start | Last season as the start | Better by |
|---|---|---|---|
| 10% | 0.1094 | 0.0854 | 22% |
| 25% | 0.0805 | 0.0702 | 13% |
| 50% | 0.0574 | 0.0538 | 6% |
| 75% | 0.0380 | 0.0366 | 4% |

(Brier score, lower is better.) The benefit is early in the season and fades, as expected.

**Tuning.** An earlier version used guessed settings (a 100-day half-life, three quarters of last season, eight
games of weight, promoted teams 15% weaker). I tried 25 alternatives and then the best four together:
12 games of weight, all of last season, a 150-day half-life and promoted teams 20% weaker. That cut the race-odds
error by 2.9% (95% interval 1.8% to 4.0%) in both the early and later years and in all five leagues. The settings
were chosen on those same leagues, so I checked them on three leagues they were never tuned on: they helped in the
Eredivisie (4.0%) and Portugal (2.4%) and hurt in the English Championship (1.8%), a league with a lot of yearly
turnover, where leaning on last season pays less. Overall that check was inconclusive (0.8% better, interval
2.2% better to 0.5% worse), so expect the real gain on new data to be smaller than 2.9%. Two things that did not
help: capping huge scores, and bookmaker odds. Odds for the next two rounds improved the error by only about 2%;
odds for every remaining game looked 11–29% better, but only because they were set right before each game and so
know things that hadn't happened yet.

**Read this with care.** The predictions aren't independent: one season's table produces about 230 of them, so
the real sample is the 59 league-seasons, not 13,800. The test also used generic lines (top 1, top 4 and so on)
rather than each season's exact European places.

**Is the simulation worth it?** I compared it with a deliberately simple rival: a logistic curve on the points
gap to the line, scaled by games left, fitted on the very predictions it was scored on so it had every
advantage. The overall Brier score was 0.054 for the simulation and 0.064 for the points-gap rule, about 16%
better. The gap is widest early on (0.070 against 0.089 at 25% through) and small by 75% (0.037 against
0.040). Always predicting the line's base rate scored 0.148. So the simulation does beat a
simple table rule, with the most value early in the season: much of it is in the exact maths and in knowing roughly how
many points are left, and the ratings add a modest amount on top.

## What it does not know

The odds are a rough guide, not a forecast.

- **The settings were tuned on five leagues.** They were fitted on the big five and checked on three others
  (see above); they may suit some leagues less well than others.
- **Results are nearly all it sees.** No injuries, transfers, suspensions, tactics or fixture congestion. Last
  season only sets the starting point, and squads change between seasons.
- **Goals are treated as independent,** the standard simplification. I expected it to undercount draws, but it
  doesn't here: the model gives a typical match about a 25% chance of a draw against 25.6% of draws in the
  5,256 matches tested. A correction for low scores (the Dixon-Coles adjustment) was tried and made the score
  very slightly worse, so it is switched off.
- **One home advantage for the whole league,** though some teams are much stronger at home.
- **The clock for a game in play is an estimate** (see above), and the model doesn't know about red cards or
  substitutions that change a game's course.
- **Tiebreaks are simplified** to goal difference then goals scored; many leagues use head-to-head first.
- **Zone lines are approximate.** European places can move with cup results.
- **Sampling noise:** at 10,000 runs a 50% figure is good to about half a point; early in the season there are
  fewer runs and it is a little noisier.

## Ideas for making it better

1. Let team strength drift over the rest of the season, instead of staying fixed.
2. Separate home and away ratings per team.
3. Backtest the single-match probabilities, as the season odds were.
