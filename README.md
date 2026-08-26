# AI Readiness Lab

C-level AI readiness workbench that researches company and competitor AI signals, identifies
practical enterprise AI pilots, scores readiness, and generates executive-ready reports.

> Tell us your company. We research your market, show where AI pressure is building, identify
> practical AI pilots, score readiness, and turn one selected idea into a scoped, risk-aware,
> technically grounded plan.

## Run from source

Use `run.bat` on Windows, `run.command` on macOS, or `run.sh` on Linux. The
launcher installs a pinned Python toolchain and Node.js when needed, builds the
interface only when its lockfile changes, waits for the backend health check,
and opens the app. Re-run it safely at any time. It also accepts `doctor`,
`repair`, `docker`, `logs`, and `stop`.

```powershell
.\run.bat          # Windows
```

```bash
./run.command      # macOS
./run.sh           # Linux
```

Use `.\run.ps1` from PowerShell. Add an action after the launcher, such as
`.\run.ps1 doctor` or `./run.sh docker`.

## Download & run (no Python needed)

AI Readiness Lab ships as a double-clickable desktop app — no Python, Node, or terminal required.

1. Download the installer for your platform from the [latest release](../../releases/latest):
   - **Windows** — `ai-readiness-lab-windows.zip` → unzip → run `AI Readiness Lab.exe`
   - **macOS** — `ai-readiness-lab-macos.dmg` → open → drag to Applications → launch
   - **Linux** — `ai-readiness-lab-linux.tar.gz` → extract → run `AI Readiness Lab`
2. The app opens in its own window. Explore immediately with **sample data**, or click
   **Enable live research** and paste an [Anthropic API key](https://console.anthropic.com/settings/keys)
   to research real companies. The key is stored in your OS keychain and never leaves your machine
   except to call Claude.

Installers are built automatically for all three platforms by the
[release workflow](.github/workflows/release.yml) (push a `v*` tag or run it manually).

### Build the desktop app yourself

```bash
./scripts/build_desktop.sh      # builds the UI, bundles everything with PyInstaller
# → dist/"AI Readiness Lab"/
```

## Status

Phases 0–6 complete: executive shell, streaming research (DuckDuckGo default), peer taxonomy,
opportunity map, and open-ended strategy Q&A — plus native desktop packaging with seamless
in-app key setup. See the implementation plan for what's next.

## Documentation

- **[Product Spec](docs/PRODUCT_SPEC.md)** — vision, positioning, product modes, research design,
  data models, and report structure (the *what* and *why*).
- **[Implementation Plan](docs/IMPLEMENTATION_PLAN.md)** — phases, steps, acceptance criteria,
  build order, milestones, and risks (the *how* and *when*).
- **[AGENTS.md](AGENTS.md)** — shared repository guidance for coding agents.
- **[CLAUDE.md](CLAUDE.md)** — thin Claude Code import of the shared guidance.

## Intended audience

CTOs, CIOs, COOs, CDOs, VPs, transformation leaders, and executive AI sponsors.

## Development & testing

```bash
cd backend
pip install -r requirements.txt   # includes pytest and playwright
pytest                            # run all backend tests

# Playwright browser — one-time download after pip install
python -m playwright install chromium
```

The backend test suite includes UI smoke tests that launch the real FastAPI app in a thread
and drive the frontend in headless Chromium. They skip cleanly if Playwright or its browser
isn't installed, so a plain `pytest` run works on any fresh checkout.
