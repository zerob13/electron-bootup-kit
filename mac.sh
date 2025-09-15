#!/usr/bin/env bash
set -euo pipefail

# Flags
CHECK_ONLY=false
VERBOSE=false
SKIP_LIST=()

print_usage() {
  echo "Usage: ./mac.sh [--check-only] [--skip <pkg>] [--verbose]"
  echo "  pkgs: node | git | python | xcode"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-only) CHECK_ONLY=true; shift ;;
    --skip) SKIP_LIST+=("$2"); shift 2 ;;
    --verbose|-v) VERBOSE=true; shift ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "Unknown option: $1"; print_usage; exit 1 ;;
  esac
done

color() { local c="$1"; shift; printf "\033[%sm%s\033[0m\n" "$c" "$*"; }
info()  { color 36 "[INFO]  $*"; }
step()  { color 32 "==> $*"; }
warn()  { color 33 "[WARN]  $*"; }
err()   { color 31 "[ERROR] $*"; }
dbg()   { if $VERBOSE; then color 90 "[DEBUG] $*"; fi }

should_skip() {
  local name="$1"
  for s in "${SKIP_LIST[@]:-}"; do
    [[ "$s" == "$name" || "$s" == "all" ]] && return 0
  done
  return 1
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

ensure_homebrew() {
  if ! command_exists brew; then
    warn "Homebrew not found."
    info "Please install Homebrew first: https://brew.sh/"
    return 1
  fi
  return 0
}

test_xcode_app() { [[ -d "/Applications/Xcode.app" ]]; }
test_clt_installed() {
  xcode-select -p >/dev/null 2>&1
}

open_app_store_xcode() {
  local url="macappstore://itunes.apple.com/app/id497799835"
  local http_url="https://apps.apple.com/app/xcode/id497799835"
  warn "Xcode not detected. Opening App Store page for Xcode..."
  if command_exists open; then
    open "$url" || true
  fi
  info "If the App Store didn’t open, install from: $http_url"
}

install_brew_pkg() {
  local pkg="$1"
  if $CHECK_ONLY; then info "[dry-run] Would install: $pkg"; return; fi
  step "Installing $pkg via Homebrew"
  brew install "$pkg"
}

install_node() {
  if $CHECK_ONLY; then info "[dry-run] Would install Node.js LTS"; return; fi
  install_brew_pkg node
}

install_git() {
  if $CHECK_ONLY; then info "[dry-run] Would install Git"; return; fi
  install_brew_pkg git
}

install_python() {
  if $CHECK_ONLY; then info "[dry-run] Would install Python 3"; return; fi
  install_brew_pkg python
}

print_versions() {
  step "Verifying installed tool versions"
  if command_exists node; then node -v; else warn "Node.js not found"; fi
  if command_exists npm; then echo "npm $(npm -v)"; else warn "npm not found"; fi
  if command_exists git; then git --version; else warn "Git not found"; fi
  if command_exists python3; then python3 -V; else warn "Python3 not found"; fi
}

main() {
  step "macOS Electron prerequisites setup"

  if ! ensure_homebrew; then
    err "Homebrew is required for this script. Exiting."
    exit 1
  fi

  # Xcode handling
  if ! should_skip xcode; then
    if ! test_xcode_app; then
      open_app_store_xcode
      warn "Install Xcode from the App Store, then re-run this script if you need the full IDE."
      # Continue: CLT may be sufficient for most Electron dev; try to ensure CLT
    fi
    if ! test_clt_installed; then
      warn "Xcode Command Line Tools not detected."
      if $CHECK_ONLY; then
        info "[dry-run] Would run: xcode-select --install"
      else
        step "Triggering Xcode Command Line Tools installer"
        xcode-select --install || true
        info "If a GUI prompt appeared, complete the installation then re-run this script."
      fi
    fi
  else
    info "Skip requested: Xcode/Command Line Tools"
  fi

  # Node
  if should_skip node; then
    info "Skip requested: Node.js"
  elif command_exists node; then
    info "Node.js already installed. Skipping."
  else
    install_node
  fi

  # Git
  if should_skip git; then
    info "Skip requested: Git"
  elif command_exists git; then
    info "Git already installed. Skipping."
  else
    install_git
  fi

  # Python 3
  if should_skip python; then
    info "Skip requested: Python"
  elif command_exists python3; then
    info "Python3 already installed. Skipping."
  else
    install_python
  fi

  print_versions
  step "Setup completed"
  info "If CLT was just installed, re-run this script after it finishes."
}

main "$@"
