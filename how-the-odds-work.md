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

## What it does not know

The odds are a rough guide, not a forecast.

- **It has not been checked against real results yet.** "40%" is what the model says, not a verified 40%.
  The half-life, prior size and home advantage are reasonable guesses that haven't been tuned.
- **Goals are all it sees.** No injuries, transfers, suspensions, tactics or fixture congestion. Last season
  isn't used either, so early in the season the prior just pulls teams toward average.
- **Draws are probably slightly underestimated.** Independent Poisson goals produce fewer low-scoring draws
  than real football.
- **One home advantage for the whole league,** though some teams are much stronger at home.
- **A match in progress is half-counted.** Live standings include its current score but it is not simulated
  to the end, a small bias that only matters while a game is on.
- **Tiebreaks are simplified** to goal difference then goals scored; many leagues use head-to-head first.
- **Zone lines are approximate.** European places can move with cup results.
- **Sampling noise:** at 10,000 runs a 50% figure is good to about half a point; early in the season there are
  fewer runs and it is a little noisier.

## Ideas for making it better

1. Backtest on past seasons to see whether the percentages are calibrated, and tune the settings against that.
2. Use last season's strength as the starting point for early-season ratings.
3. Correct the draw rate (a small fix for 0–0 and 1–1 results).
4. Separate home and away ratings per team.
5. Finish any match that is in progress.
