# How the odds work

`race` (also `contention`) answers "who can still win the league, who is out, and how likely is each team?"
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

- **Recent games count more.** A game's weight halves every 100 days, so late-season ratings follow
  current form.
- **Early on, last season is the starting point.** With only a handful of games played, results say little.
  So each team begins from three quarters of the way to its rating from last season (the rest is "average"),
  and that starting point counts as eight games of evidence. A team promoted this year has no top-flight
  rating, so it starts weaker than average (it scores about 15% less and concedes about 15% more).
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

I tested it on three finished seasons (2023, 2024 and 2025) of the Premier League, La Liga, Serie A, Bundesliga
and Ligue 1: 15 league-seasons. For each one, the test went back to 25%, 50% and 75% of the way through the
season, used only the results up to that point, simulated the rest, and compared the odds with what actually
happened. The lines tested were top 1, top 4, the top half, and "safe from the bottom three", about 3,500
predictions in all.

**When the model said X%, how often did it happen?**

| Model said | Happened | Predictions |
|---|---|---|
| 0–2% | 0.2% | 1,273 |
| 2–10% | 2.3% | 301 |
| 10–20% | 14.5% | 165 |
| 20–30% | 20.5% | 127 |
| 30–40% | 35.9% | 117 |
| 40–50% | 42.7% | 89 |
| 50–60% | 57.5% | 106 |
| 60–70% | 76.1% | 109 |
| 70–80% | 73.2% | 123 |
| 80–90% | 85.4% | 144 |
| 90–98% | 95.3% | 232 |
| 98–100% | 99.9% | 670 |

- **Close to honest across the range.** Most bins land within a few points of the stated odds. The clearest
  miss is the 60–70% bin, where the event happened 76% of the time, so the model was underconfident there.
  The 2–10% and 20–30% bins ran a few points high.
- **It gets better as the season goes on.** The Brier score (an accuracy measure where lower is better and 0 is
  perfect) was 0.075 at 25% through, 0.057 at 50% and 0.042 at 75%.
- **Title picks at halfway:** the model's favourite won the league 11 times in 15. In the four misses the
  eventual champion had been given 21%, 19%, 30% and 40%, never a near-zero chance.

**Starting from last season.** Using last season as the starting point was tested separately on the 2024 and
2025 seasons (10 league-seasons, 3,072 predictions), with an extra snapshot only about three matchdays in:

| Through the season | Plain average start | Last season as the start | Better by |
|---|---|---|---|
| 10% | 0.1091 | 0.0947 | 13% |
| 25% | 0.0764 | 0.0704 | 8% |
| 50% | 0.0576 | 0.0560 | 3% |
| 75% | 0.0408 | 0.0398 | 2% |

(Brier score, lower is better.) The benefit is early in the season and fades, as expected. The settings were
chosen by comparing seven variants on the same seasons, and the assumption for promoted teams was estimated from
those seasons too, so expect the gain on genuinely new seasons to be somewhat smaller.

**Read this with care.** The predictions aren't independent: one season's table produces about 80 of them,
so the real sample is closer to 45 snapshots than 3,500. Three seasons in five leagues can show a model has
no obvious flaw, not that it is right. The test also used generic lines (top 1, top 4 and so on) rather than each season's exact European places.

**Is the simulation worth it?** I compared it with a deliberately simple rival: a logistic curve on the points
gap to the line, scaled by games left, fitted on the very predictions it was scored on so it had every
advantage. The overall Brier score was 0.058 for the simulation and 0.062 for the points-gap rule, about 6%
better. The gap is widest early on (0.075 against 0.082 at 25% through) and nearly gone at halfway
(0.0565 against 0.0575). Always predicting the line's base rate scored 0.149. So the simulation does beat a
simple table rule, but not by a lot: most of the value is in the exact maths and in knowing roughly how
many points are left, and the ratings add a modest amount on top.

## What it does not know

The odds are a rough guide, not a forecast.

- **The settings are untuned guesses.** The half-life and prior size gave good results in the test below, but
  they were chosen by reasoning, not fitted to data.
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
4. Tune the half-life and prior size against the same backtest, and extend it to more seasons and leagues.
