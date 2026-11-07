# pitchside releases

Installers and binaries for **pitchside**, football scores and league tables in your terminal.

**macOS (Apple Silicon)**

```sh
curl -fsSL https://raw.githubusercontent.com/josejmorales/pitchside-releases/main/install.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/josejmorales/pitchside-releases/main/install.ps1 | iex
```

Then run `pitchside` and add your free [football-data.org](https://www.football-data.org/client/register)
key with `apikey set`. Update any time with `pitchside update`.

Every download is checked against the release's `SHA256SUMS` before it is installed.
