# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **Electron Bootup Kit** - a collection of setup scripts that install Electron development prerequisites on macOS and Windows. The project provides automated, idempotent installation of build tools, package managers, and runtime dependencies needed for Electron development.

## Project Structure

- `mac.sh` - macOS setup script (currently empty/placeholder)
- `windows.ps1` - Complete PowerShell script for Windows setup
- `README.md` - Comprehensive project documentation
- `task.md` - Development milestone breakdown and implementation plan

## Key Architecture

### Windows Script (`windows.ps1`)
The PowerShell script uses a modular function-based architecture:

- **Package Manager Detection**: Auto-detects and supports both Chocolatey and Winget
- **Privilege Management**: Ensures elevated PowerShell session for installations
- **Modular Installers**: Separate functions for Node.js, Git, Python, and VS Build Tools
- **Smart Detection**: Checks for existing installations to avoid redundant operations
- **Environment Refresh**: Reloads PATH after installations

### Supported Command Line Arguments (Windows)
- `-CheckOnly` - Dry run mode, shows what would be installed without making changes
- `-Skip <pkg>` - Skip specific packages (node, git, python, vs/vstools/buildtools)
- `-NoConfirm` - Auto-accept prompts and agreements
- `-PackageManager <choco|winget|auto>` - Force specific package manager
- `-VerboseMode` - Enable debug logging

## Development Commands

This project does not use traditional build/test/lint commands as it consists of shell scripts. Development workflow involves:

### Testing Scripts
- **macOS**: `chmod +x mac.sh && ./mac.sh -CheckOnly` (when implemented)
- **Windows**: `./windows.ps1 -CheckOnly` - Test script logic without installing packages

### Script Validation
- **Windows**: Test in clean Windows VM with PowerShell execution policy: `Set-ExecutionPolicy Bypass -Scope Process -Force`
- **macOS**: Verify Homebrew detection and Xcode Command Line Tools installation

## Prerequisites Installation Logic

### Windows Dependencies
1. **Package Managers**: Chocolatey (preferred) or Winget
2. **Core Tools**: Node.js LTS, Git, Python 3
3. **Build Tools**: Visual Studio 2022 Build Tools with C++ workload and Windows 11 SDK
4. **Architecture Support**: x64 only (ARM64 support planned)

### macOS Dependencies (Planned)
1. **Package Manager**: Homebrew (required)
2. **Build Tools**: Xcode Command Line Tools
3. **Core Tools**: Node.js LTS, Git, Python 3 via Homebrew

## Implementation Status

- **Windows Script**: Complete implementation with full feature set
- **macOS Script**: Placeholder file, needs implementation following task.md milestones
- **Cross-platform**: Both scripts share common goals but use platform-specific package managers

## Development Notes

- Scripts are designed to be idempotent - safe to run multiple times
- Windows script includes comprehensive error handling and logging
- Architecture detection prevents unsupported installations
- Environment path refresh ensures newly installed tools are immediately available