# How the title-race odds work

`race` (also `contention`) answers "who can still win the league, who is out, and how likely is each team?"
It has two parts: exact arithmetic that is always right, and an optional simulation (`odds`) that is an estimate.

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
- **A small prior keeps early ratings sensible.** Each team starts with four pseudo-games of exactly
  average form, so a couple of lucky results don't produce wild ratings. The more games a team plays, the
  less this matters.

### 2. Admit the ratings are uncertain

A rating is an estimate. A team with 15 goals scored is much less certain than one with 60. The simulation
is split into 100 batches. Before each batch, every team's attack and defence are nudged by a random amount
sized to how little data supports them (roughly `1 ÷ √goals`, so 15 goals gives about ±26% and 40 goals about
±16%). Within a batch the ratings are fixed; across batches they vary. This stops the model from claiming more
certainty than the results justify.

### 3. Play out the season

Up to 10,000 seasons are simulated (fewer when many fixtures remain, to keep it to a second or two).
Each starts from today's table. For every remaining fixture it draws a home and away score, awards the points
and updates goal difference. Teams are ranked on points, then goal difference, then goals scored, then a
random tiebreak.

### 4. Read the results

| Column | Meaning |
|---|---|
| **Chance** | Share of simulated seasons in which the team finishes inside the line (top 1 for the title) |
| **Exp pts** | Average final points |
| **Finish** | The range of positions that covers 80% of the simulated seasons (10th to 90th percentile) |

Teams the exact maths has already settled show 100% or 0%, so the two parts never disagree.
The random seed comes from the data, so the same table gives the same numbers each time.

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
- **Goals are all it sees.** No injuries, transfers, suspensions, tactics or fixture congestion. Last season
  isn't used either, so early in the season the prior just pulls teams toward average.
- **Goals are treated as independent,** the standard simplification. I expected it to undercount draws, but it
  doesn't here: the model gives a typical match about a 25% chance of a draw against 25.6% of draws in the
  5,256 matches tested. A correction for low scores (the Dixon-Coles adjustment) was tried and made the score
  very slightly worse, so it is switched off.
- **One home advantage for the whole league,** though some teams are much stronger at home.
- **A match in progress is half-counted.** Live standings include its current score but it is not simulated
  to the end, a small bias that only matters while a game is on.
- **Tiebreaks are simplified** to goal difference then goals scored; many leagues use head-to-head first.
- **Zone lines are approximate.** European places can move with cup results.
- **Sampling noise:** at 10,000 runs a 50% figure is good to about half a point; early in the season there are
  fewer runs and it is a little noisier.

## Ideas for making it better

1. Use last season's strength as the starting point for early-season ratings (the simulation helps most early,
   and this is where it has the most room).
2. Let team strength drift over the rest of the season, instead of staying fixed.
3. Separate home and away ratings per team.
4. Finish any match that is in progress.
5. Tune the half-life and prior size against the same backtest, and extend it to more seasons and leagues.
