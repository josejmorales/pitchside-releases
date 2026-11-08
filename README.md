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

Pick your computer and follow that section from top to bottom:

- [Mac](#mac-apple-silicon-m1-or-newer) (Apple Silicon: M1 or newer)
- [Windows](#windows-10-or-11-64-bit) (10 or 11, 64-bit)

---

## Mac (Apple Silicon: M1 or newer)

### Install

1. Open **Terminal**: press `Cmd + Space`, type `Terminal`, press Enter.
2. Paste this line (`Cmd + V`) and press Enter:

   ```sh
   curl -fsSL https://raw.githubusercontent.com/josejmorales/pitchside-releases/main/install.sh | bash
   ```

3. When it says it has finished, **close Terminal and open it again** (`Cmd + Space`, `Terminal`, Enter).
4. Type `pitchside` and press Enter.

You don't need to change any settings: the installer adds pitchside to your PATH for you (it writes one line
to `~/.zshrc`, or `~/.bash_profile` if you use bash), which is why step 3 needs a fresh window.

### First run

Pitchside explains what it needs and opens the football-data.org sign-up page in your browser. Enter your
name and email, tick their terms box and submit; your free key arrives by email (check spam if it's slow).
Leave pitchside open, then paste the key when it arrives. It checks the key and asks which league you follow most. Then try `table`, `scores`, `today` or `scorers`, and type `help`
to see everything. See [What you can do](#what-you-can-do) below.

### Update

In Terminal, type `pitchside update`. (Pitchside also tells you at startup when a new version is out.)

### Uninstall

In Terminal, type `pitchside uninstall`. It shows what it will remove and asks before deleting anything:

- the program,
- the small cache files pitchside saved (always removed),
- the line the installer added to `~/.zshrc` or `~/.bash_profile` (so nothing is left on your PATH),
- and, only if you say yes, your settings (API key and league order), which you may want to keep if you plan to reinstall.

Prefer to do it by hand? In Terminal:

```sh
rm ~/.local/bin/pitchside          # the program
rm -r ~/.config/pitchside          # your key, settings and cache
```

Then open `~/.zshrc` (or `~/.bash_profile`) and delete the line ending in `# added by the pitchside installer`.
You can also leave that line; it does no harm.

### Trouble on Mac

- **"command not found: pitchside":** close Terminal and open a new window. If it still isn't found, run
  `source ~/.zshrc` and try again.
- **The installer printed a line starting with `export PATH=`:** you use a shell other than zsh or bash.
  Add that line to your shell's startup file, then open a new window.
- **Mac says it can't be opened:** tell whoever sent you this; it shouldn't happen with the install line above.

---

## Windows 10 or 11 (64-bit)

### Install

1. Open **PowerShell**: click the Start menu, type `PowerShell`, press Enter. (Windows Terminal also works.)
2. Paste this line (right-click in the window to paste) and press Enter:

   ```powershell
   irm https://raw.githubusercontent.com/josejmorales/pitchside-releases/main/install.ps1 | iex
   ```

3. When it says it has finished, **close PowerShell and open it again** (Start menu, `PowerShell`, Enter).
4. Type `pitchside` and press Enter.

You don't need to change any settings: the installer adds pitchside to your PATH for you (it installs to
`%LOCALAPPDATA%\pitchside`), which is why step 3 needs a fresh window.

### First run

Pitchside explains what it needs and opens the football-data.org sign-up page in your browser. Enter your
name and email, tick their terms box and submit; your free key arrives by email (check spam if it's slow).
Leave pitchside open, then paste the key when it arrives. It checks the key and asks which league you follow most. Then try `table`, `scores`, `today` or `scorers`, and type `help`
to see everything. See [What you can do](#what-you-can-do) below.

### Update

In PowerShell, type `pitchside update`. (Pitchside also tells you at startup when a new version is out.)

### Uninstall

In PowerShell, type `pitchside uninstall`. It shows what it will remove and asks before deleting anything:

- the program,
- the small cache files pitchside saved (always removed),
- pitchside's folder from your PATH,
- and, only if you say yes, your settings (API key and league order), which you may want to keep if you plan to reinstall.

Prefer to do it by hand? In PowerShell:

```powershell
Remove-Item -Recurse "$env:LOCALAPPDATA\pitchside"      # the program
Remove-Item -Recurse "$HOME\.config\pitchside"          # your key, settings and cache
```

Then remove it from your PATH: search Windows for *Edit the environment variables for your account*, select
`Path`, and delete the `pitchside` entry. You can also leave it; it does no harm.

### Trouble on Windows

- **"pitchside is not recognized":** close PowerShell and open a new window.
- **Windows warns about the file:** the app isn't signed yet, so Windows Defender or SmartScreen may
  question it. Choose *More info*, then *Run anyway*, or tell whoever sent you this.

---

## What you can do

Some commands to start with (type `help` for the full list):

| Command | What it shows |
|---|---|
| `table` | The league table, with live scores |
| `scores` | Results and fixtures for the current matchday |
| `today`, `tomorrow` | Every match on that day across your leagues |
| `scorers` | The top scorers |
| `race` | Who can still win the title (or qualify, or get relegated), with an optional simulated `odds` |
| `leagues edit` | Reorder your leagues and hide the ones you don't follow |

Switch league by name: `league laliga`, or ask for one directly: `table bundesliga`.

## Going deeper

- [How the odds work](how-the-odds-work.md): the maths behind `race`, the simulation behind
  `race … odds`, the single-match chances in `scores odds`, and what the estimates can and can't tell you.

Every download is checked against the release's `SHA256SUMS` before it is installed.
