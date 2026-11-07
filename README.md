# pitchside

Live football scores, league tables, top scorers and today's matches, right in your terminal.

```
pitchside [PL]> table
pitchside [PL]> today
pitchside [PL]> scorers laliga
```

You'll need a **free API key** from [football-data.org](https://www.football-data.org/client/register)
(it only asks for a name and an email address). The first time you run pitchside it walks you through
getting one, so there's nothing to set up beforehand.

## Install

First open a terminal window:

- **Mac:** press `Cmd + Space`, type `Terminal`, press Enter.
- **Windows:** open the Start menu, type `PowerShell`, press Enter. (Windows Terminal looks best.)

Then paste the line for your system and press Enter.

**Mac (Apple Silicon: M1 or newer)**

```sh
curl -fsSL https://raw.githubusercontent.com/josejmorales/pitchside-releases/main/install.sh | bash
```

**Windows 10/11 (64-bit)**

```powershell
irm https://raw.githubusercontent.com/josejmorales/pitchside-releases/main/install.ps1 | iex
```

When it finishes, **close the window and open a new one**, then type:

```
pitchside
```

## First run

Pitchside explains what it needs, opens the sign-up page for your free key, checks the key when you
paste it, and asks which league you follow most. After that, try `table`, `scores`, `today` or
`scorers`, and type `help` to see everything. `leagues edit` lets you reorder your leagues and hide
the ones you don't follow.

## Updating

Type `pitchside update` any time. (Pitchside also tells you when a new version is out.)

## Trouble?

- **"command not found" / "not recognized":** close the terminal and open a new one.
- **Windows warns about the file:** the app isn't signed yet, so Windows Defender or SmartScreen may
  question it. Choose *More info*, then *Run anyway*, or tell whoever sent you this.
- **Mac says it can't be opened:** tell whoever sent you this; it shouldn't happen with the install line above.
- **Uninstall (Mac):** `rm ~/.local/bin/pitchside` and, to forget your key, `rm -r ~/.config/pitchside`.
- **Uninstall (Windows):** delete the `pitchside` folder in `%LOCALAPPDATA%` and, to forget your key,
  the `.config\pitchside` folder in your user folder.

Every download is checked against the release's `SHA256SUMS` before it is installed.
