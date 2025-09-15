# Repository Guidelines

## Project Structure & Module Organization
- Root scripts: `mac.sh` (macOS) and `windows.ps1` (Windows) install Electron prerequisites.
- Docs: `README.md` (usage) and `task.md` (roadmap/milestones).
- No Node project here; these scripts prepare your machine for Electron projects.

## Build, Test, and Development Commands
- macOS run: `chmod +x mac.sh && ./mac.sh`
  - Installs/validates Xcode CLT, Node LTS, Git, Python 3 via Homebrew; prints versions.
- Windows run (elevated PowerShell): `Set-ExecutionPolicy Bypass -Scope Process -Force; ./windows.ps1`
  - Installs/validates Node LTS, Git, Python, and VS 2022 Build Tools via Chocolatey; prints versions.
- Lint (suggested): `shellcheck mac.sh` and `pwsh -Command Invoke-ScriptAnalyzer windows.ps1`

## Coding Style & Naming Conventions
- Bash: use `#!/usr/bin/env bash`, `set -euo pipefail`, 2‑space indentation, lowercase function names, `main` entrypoint.
- PowerShell: `CmdletBinding()` advanced functions, PascalCase for functions/parameters, 2‑space indentation, `$PSStyle`/Write-Host for clear statuses.
- Flags (planned in README): `--check-only/--verbose/--skip` on macOS; `-CheckOnly/-Verbose/-Skip` on Windows. Keep parity across scripts.

## Testing Guidelines
- Smoke checks: verify `node -v`, `npm -v`, `git --version`, `python(3) -V` and a minimal node-gyp detection step.
- Dry run: implement and test `--check-only`/`-CheckOnly` to list actions without changes.
- Static analysis: run ShellCheck/PSScriptAnalyzer locally; fix warnings of severity Error/Warning.

## Commit & Pull Request Guidelines
- Commit messages must be in English and follow Conventional Commits: `<type>(<scope>): <subject>`.
- Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `revert`; optional scopes like `mac`, `windows`, `deps`.
- Subject uses imperative mood, lowercase, <= 72 chars; add body when helpful; mark breaking changes with `BREAKING CHANGE:`.
- Examples: `feat(mac): add --check-only`, `chore(deps): bump shellcheck to 0.10.0`, `fix(windows): skip reinstall when present`.
- PRs must include: purpose summary, list of changes, tested OS/version, sample output (before/after), and any required elevation notes.
- Link issues and keep changes minimal and idempotent.

## Security & Configuration Tips
- Do not auto-install Homebrew/Chocolatey; print official install URLs if missing (as implemented).
- Request elevation only when needed; avoid modifying shell profiles.
- Support proxies via `HTTP_PROXY`/`HTTPS_PROXY` and npm config; document any env usage in README.
