# Electron Bootup Kit

Fast, one-command setup for Electron development prerequisites on macOS and Windows.

This repo provides two scripts that verify and install the tooling Electron depends on. It prefers your system package manager and stays idempotent: already-installed tools are skipped and summarized.

What it installs
- macOS: Homebrew check (no auto-install), Xcode Command Line Tools, Node.js LTS, npm, npx, Git, Python 3.
- Windows: Chocolatey check (no auto-install), Visual Studio 2022 Build Tools (C++ workload + SDK), Node.js LTS, npm, npx, Git, Python 3.

Assumptions
- macOS has Homebrew; Windows has Chocolatey. If missing, the scripts print a friendly message and the official install URL so you can install them manually.
- You can grant admin privileges when prompted (sudo on macOS, elevated PowerShell on Windows).
- Electron itself is installed per-project via npm/yarn/pnpm. These scripts do not install Electron globally.

Usage
- macOS
  - Ensure Homebrew is installed (the script checks and will print https://brew.sh/ if missing).
  - Run:
    - `chmod +x mac.sh`
    - `./mac.sh`
  - Optional flags (planned): `--check-only`, `--verbose`, `--no-sudo`, `--skip <pkg>`
- Windows (PowerShell)
  - Ensure Chocolatey is installed (the script checks and will print https://chocolatey.org/install if missing).
  - Open an elevated PowerShell (Run as Administrator), then:
    - `Set-ExecutionPolicy Bypass -Scope Process -Force`
    - `./windows.ps1`
  - Optional flags (planned): `-CheckOnly`, `-Verbose`, `-Skip <pkg>`, `-NoConfirm`

What the scripts do
- Detect package manager; if missing, print install instructions and exit.
- Validate privileges; request sudo/elevation only when needed.
- Install prerequisites with sensible defaults:
  - macOS: `xcode-select --install` (if not present), `brew install node git python`.
  - Windows (Chocolatey): `choco install -y nodejs-lts git python visualstudio2022buildtools` with required VS components/workload for native addons.
- Configure environment for native modules:
  - macOS: ensure Python 3 is discoverable by node-gyp (e.g., `npm config set python python3` if needed).
  - Windows: install the C++ build tools and Windows SDK; refresh environment (`refreshenv`).
- Verify by printing versions: Node, npm, Git, Python, and a basic node-gyp check.

Notes on Visual Studio Build Tools (Windows)
- Electron native modules require MSVC, Windows SDK, and MSBuild. The script uses Chocolatey’s `visualstudio2022buildtools` with parameters to include the C++ build tools workload and SDK. This mirrors Electron’s official prerequisites.
- If VS Build Tools are already installed, the script skips reinstallation.

Non-goals
- No global installation of `electron`. Install it per project: `npm i -D electron`.
- No modification of shell configuration files beyond what’s necessary for path availability.

Troubleshooting
- Proxy/corporate network: planned flags to pass proxy settings to brew/choco and npm.
- Xcode CLT installer may show a GUI prompt; accept it to continue.
- If PowerShell policy blocks the script, run `Set-ExecutionPolicy Bypass -Scope Process -Force` in the same session.

Roadmap (short)
- Add `--check-only`/`-CheckOnly` dry run.
- Add `--skip/-Skip` for fine-grained control.
- Add `--verbose/-Verbose` logging.
- Add CI smoke checks to validate install steps.

