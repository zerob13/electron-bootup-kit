# Electron Bootup Kit

Fast, one-command setup for Electron development prerequisites on macOS and Windows.

This repo provides two scripts that verify and install the tooling Electron depends on. It prefers your system package manager and stays idempotent: already-installed tools are skipped and summarized.

What it installs
- macOS: Homebrew check (no auto-install), Xcode (App Store link) and Command Line Tools, Node.js LTS, npm, npx, Git, Python 3.
- Windows: Package manager check (Chocolatey or Winget), Visual Studio 2022 Build Tools (C++ workload + Windows 11 SDK), Node.js LTS, npm, npx, Git, Python 3.

Assumptions
- macOS has Homebrew. Windows has Chocolatey or Winget. If neither is available on Windows (or Homebrew on macOS), the scripts print a friendly message and the official install URL so you can install them manually.
- You can grant admin privileges when prompted (sudo on macOS, elevated PowerShell on Windows).
- Electron itself is installed per-project via npm/yarn/pnpm. These scripts do not install Electron globally.

Usage
- macOS
  - Ensure Homebrew is installed (the script checks and will print https://brew.sh/ if missing).
  - Run:
    - `chmod +x mac.sh`
    - `./mac.sh [--check-only] [--skip node|git|python|xcode] [--verbose]`
  - Behavior:
    - If Xcode.app is missing, the script opens the App Store page for Xcode and suggests installing it; it also triggers the Command Line Tools installer when needed.
- Windows (PowerShell)
  - Ensure Chocolatey or Winget is installed. If neither is detected, the script prints:
    - Chocolatey: https://chocolatey.org/install
    - Winget: https://learn.microsoft.com/windows/package-manager/winget/
  - Open an elevated PowerShell (Run as Administrator), then:
    - `Set-ExecutionPolicy Bypass -Scope Process -Force`
    - `./windows.ps1 [-CheckOnly] [-Skip node,git,python,vs] [-NoConfirm] [-PackageManager auto|choco|winget] [-Verbose]`

What the scripts do
- Detect package manager; if missing, print install instructions and exit.
- Validate privileges; request sudo/elevation only when needed.
- Install prerequisites with sensible defaults:
  - macOS: `xcode-select --install` (if not present), `brew install node git python`.
  - Windows: Node/Git/Python via Chocolatey or Winget; Visual Studio 2022 Build Tools via Winget with `--override` (C++ tools + Windows 11 SDK 22621), or Chocolatey fallback with equivalent parameters.
- Architecture aware (Windows): skips VS Build Tools auto-install on non-x64 architectures with guidance to install manually.
- Verify by printing versions: Node, npm, Git, Python, and detect VS Build Tools presence.

Notes on Visual Studio Build Tools (Windows)
- Electron native modules require MSVC, Windows SDK, and MSBuild. The script installs `Microsoft.VisualStudio.2022.BuildTools` using Winget with an installer override to include the C++ tools and Windows 11 SDK, or uses Chocolatey’s `visualstudio2022buildtools` with equivalent package parameters.
- If VS Build Tools are already installed, the script skips reinstallation.

Non-goals
- No global installation of `electron`. Install it per project: `npm i -D electron`.
- No modification of shell configuration files beyond what’s necessary for path availability.

Troubleshooting
- Proxy/corporate network: use environment variables `HTTP_PROXY` and `HTTPS_PROXY`; configure npm proxy as needed.
- Xcode CLT installer may show a GUI prompt; accept it to continue. If Xcode.app is missing, install from the App Store.
- If PowerShell policy blocks the script, run `Set-ExecutionPolicy Bypass -Scope Process -Force` in the same session.

Roadmap (short)
- Implemented: `--check-only`/`-CheckOnly` dry run.
- Implemented: `--skip/-Skip` for fine-grained control.
- Implemented: `--verbose/-Verbose` logging.
- Implemented: CI smoke checks (GitHub Actions) to validate install steps in dry-run mode.
