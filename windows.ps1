Param(
  [switch]$CheckOnly,
  [string[]]$Skip = @(),
  [switch]$NoConfirm,
  [ValidateSet('auto','choco','winget')]
  [string]$PackageManager = 'auto',
  [switch]$VerboseMode
)

$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$m) Write-Host "[INFO]  $m" -ForegroundColor Cyan }
function Write-Step { param([string]$m) Write-Host "==> $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function Write-Err  { param([string]$m) Write-Host "[ERROR] $m" -ForegroundColor Red }
function Write-Dbg  { param([string]$m) if ($VerboseMode) { Write-Host "[DEBUG] $m" -ForegroundColor DarkGray } }

function Should-Skip { param([string]$name) return ($Skip -contains $name -or $Skip -contains 'all') }

function Test-Admin {
  try {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch { return $false }
}

function Test-CommandExists { param([string]$cmd) $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue) }

function Refresh-Env {
  # Try Chocolatey refreshenv first
  try {
    if (Test-Path "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1") {
      Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" -ErrorAction SilentlyContinue
      if (Get-Command refreshenv -ErrorAction SilentlyContinue) { refreshenv; return }
    }
  } catch { }
  # Fallback: reload PATH from machine+user
  try {
    $machine = [System.Environment]::GetEnvironmentVariable('Path','Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path','User')
    if ($machine -and $user) { $env:Path = "$machine;$user" }
  } catch { }
}

function Ensure-PackageManagers {
  param([ref]$UseChoco, [ref]$UseWinget)
  $hasChoco = Test-CommandExists 'choco'
  $hasWinget = Test-CommandExists 'winget'
  Write-Dbg "Detected choco=$hasChoco, winget=$hasWinget, preference=$PackageManager"

  switch ($PackageManager) {
    'choco'  { $UseChoco.Value = $hasChoco; $UseWinget.Value = $false }
    'winget' { $UseChoco.Value = $false; $UseWinget.Value = $hasWinget }
    default  { $UseChoco.Value = $hasChoco; $UseWinget.Value = $hasWinget }
  }

  if (-not $UseChoco.Value -and -not $UseWinget.Value) {
    Write-Warn "No package manager detected."
    Write-Info "Chocolatey is recommended: https://chocolatey.org/install"
    Write-Info "Winget install instructions: https://learn.microsoft.com/windows/package-manager/winget/"
    throw "Neither Chocolatey nor Winget is available. Install one and re-run."
  }
}

function Test-NodeInstalled { Test-CommandExists 'node' }
function Test-GitInstalled { Test-CommandExists 'git' }
function Test-PythonInstalled {
  if (Test-CommandExists 'python') { return $true }
  if (Test-CommandExists 'py') { return $true }
  return $false
}

function Get-CPUArch {
  # Returns: AMD64, ARM64, x86
  return $env:PROCESSOR_ARCHITECTURE
}

function Test-VSBuildToolsInstalled {
  # Use vswhere if present
  $vswhere = "$Env:ProgramFiles(x86)\Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path $vswhere) {
    $path = & $vswhere -products Microsoft.VisualStudio.Product.BuildTools -property installationPath -nologo -format value 2>$null | Select-Object -First 1
    if ($path -and (Test-Path $path)) { return $true }
  }
  # Fallback to winget list
  if (Test-CommandExists 'winget') {
    try {
      $out = winget list --id Microsoft.VisualStudio.2022.BuildTools --source winget 2>$null
      if ($LASTEXITCODE -eq 0 -and $out -match 'Microsoft.VisualStudio.2022.BuildTools') { return $true }
    } catch { }
  }
  # Fallback to choco list
  if (Test-CommandExists 'choco') {
    try {
      $out = choco list --local-only 2>$null | Select-String -Pattern '^visualstudio2022buildtools'
      if ($out) { return $true }
    } catch { }
  }
  return $false
}

function Install-Node {
  param([bool]$UseChoco,[bool]$UseWinget)
  if ($CheckOnly) { Write-Info "[dry-run] Would install Node.js LTS"; return }
  if ($UseChoco) {
    Write-Step "Installing Node.js LTS via Chocolatey"
    if (-not $NoConfirm) { Write-Info "You may be prompted to confirm; pass -NoConfirm to auto-accept." }
    $args = @('install','nodejs-lts')
    if ($NoConfirm) { $args += '-y' }
    choco @args
  } elseif ($UseWinget) {
    Write-Step "Installing Node.js LTS via Winget"
    if (-not $NoConfirm) { Write-Info "You may be prompted to confirm; pass -NoConfirm to auto-accept." }
    $args = @('install','-e','--id','OpenJS.NodeJS.LTS')
    if ($NoConfirm) { $args += @('--accept-source-agreements','--accept-package-agreements','-h') }
    winget @args
  }
}

function Install-Git {
  param([bool]$UseChoco,[bool]$UseWinget)
  if ($CheckOnly) { Write-Info "[dry-run] Would install Git"; return }
  if ($UseChoco) {
    Write-Step "Installing Git via Chocolatey"
    if (-not $NoConfirm) { Write-Info "You may be prompted to confirm; pass -NoConfirm to auto-accept." }
    $args = @('install','git')
    if ($NoConfirm) { $args += '-y' }
    choco @args
  } elseif ($UseWinget) {
    Write-Step "Installing Git via Winget"
    if (-not $NoConfirm) { Write-Info "You may be prompted to confirm; pass -NoConfirm to auto-accept." }
    $args = @('install','-e','--id','Git.Git')
    if ($NoConfirm) { $args += @('--accept-source-agreements','--accept-package-agreements','-h') }
    winget @args
  }
}

function Install-Python {
  param([bool]$UseChoco,[bool]$UseWinget)
  if ($CheckOnly) { Write-Info "[dry-run] Would install Python 3"; return }
  if ($UseChoco) {
    Write-Step "Installing Python 3 via Chocolatey"
    if (-not $NoConfirm) { Write-Info "You may be prompted to confirm; pass -NoConfirm to auto-accept." }
    $args = @('install','python')
    if ($NoConfirm) { $args += '-y' }
    choco @args
  } elseif ($UseWinget) {
    Write-Step "Installing Python 3 via Winget"
    if (-not $NoConfirm) { Write-Info "You may be prompted to confirm; pass -NoConfirm to auto-accept." }
    # Use the meta-id that tracks latest 3.x
    $args = @('install','-e','--id','Python.Python.3')
    if ($NoConfirm) { $args += @('--accept-source-agreements','--accept-package-agreements','-h') }
    winget @args
  }
}

function Install-VSBuildTools {
  param([bool]$PreferWinget,[bool]$UseChoco)
  $arch = Get-CPUArch
  if ($arch -ne 'AMD64') {
    Write-Warn "Non-x64 architecture detected ($arch). Skipping automatic Visual Studio Build Tools install."
    Write-Info "Please install manually if needed: https://visualstudio.microsoft.com/visual-cpp-build-tools/"
    return
  }
  if ($CheckOnly) { Write-Info "[dry-run] Would install Visual Studio 2022 Build Tools with C++ and Windows 11 SDK"; return }

  if ($PreferWinget -and (Test-CommandExists 'winget')) {
    Write-Step "Installing Visual Studio 2022 Build Tools via Winget (this can take a while)"
    Write-Info  "The installer runs in passive mode and may prompt."
    $override = "--wait --passive --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.22621"
    $args = @('install','--id','Microsoft.VisualStudio.2022.BuildTools','--force','--override',$override)
    if ($NoConfirm) { $args += @('--accept-source-agreements','--accept-package-agreements') }
    winget @args
    return
  }

  if ($UseChoco -and (Test-CommandExists 'choco')) {
    Write-Step "Installing Visual Studio 2022 Build Tools via Chocolatey (this can take a while)"
    Write-Info  "Includes C++ tools and Windows 11 SDK components."
    $params = '"--add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --passive --norestart"'
    $args = @('install','visualstudio2022buildtools','--package-parameters',$params)
    if ($NoConfirm) { $args += '-y' }
    choco @args
    return
  }

  Write-Warn "Could not install Visual Studio Build Tools automatically (no suitable package manager)."
  Write-Info  "Manual download: https://visualstudio.microsoft.com/visual-cpp-build-tools/"
}

function Print-Versions {
  Write-Step "Verifying installed tool versions"
  if (Test-NodeInstalled) { try { node -v } catch { Write-Warn "node not accessible in PATH" } } else { Write-Warn "Node.js not found" }
  try { npm -v | Out-Null; Write-Host "npm $(npm -v)" } catch { Write-Warn "npm not found" }
  if (Test-GitInstalled) { try { git --version } catch { Write-Warn "git not accessible in PATH" } } else { Write-Warn "Git not found" }
  if (Test-PythonInstalled) {
    try { python --version } catch { try { py -V } catch { Write-Warn "python not accessible in PATH" } }
  } else { Write-Warn "Python 3 not found" }
  # VS Build Tools
  if (Test-VSBuildToolsInstalled) { Write-Info "Visual Studio 2022 Build Tools detected" } else { Write-Warn "VS 2022 Build Tools not detected" }
}

function Main {
  Write-Step "Windows Electron prerequisites setup"

  if (-not (Test-Admin)) {
    Write-Err "This script must be run in an elevated PowerShell (Run as Administrator)."
    Write-Info "Right-click PowerShell and choose 'Run as Administrator', then re-run: ./windows.ps1"
    exit 1
  }

  $UseChoco = $false; $UseWinget = $false
  Ensure-PackageManagers ([ref]$UseChoco) ([ref]$UseWinget)

  # Determine managers per package
  $mgrNodeGitPy = if ($PackageManager -eq 'auto') { if ($UseChoco) { 'choco' } elseif ($UseWinget) { 'winget' } else { 'none' } } else { $PackageManager }
  $preferWingetForVS = $UseWinget # prefer winget for VS if available
  $vsInstaller = if ($preferWingetForVS) { 'winget' } elseif ($UseChoco) { 'choco' } else { 'none' }

  Write-Info "Package manager for Node/Git/Python: $mgrNodeGitPy"
  Write-Info "Installer for VS Build Tools: $vsInstaller"

  # Node.js
  if (Should-Skip 'node') { Write-Info "Skip requested: Node.js" }
  elseif (Test-NodeInstalled) { Write-Info "Node.js already installed. Skipping." }
  else {
    if ($mgrNodeGitPy -eq 'none') { Write-Err "No package manager available for Node.js install" }
    else { Install-Node -UseChoco:($mgrNodeGitPy -eq 'choco') -UseWinget:($mgrNodeGitPy -eq 'winget') }
  }

  # Git
  if (Should-Skip 'git') { Write-Info "Skip requested: Git" }
  elseif (Test-GitInstalled) { Write-Info "Git already installed. Skipping." }
  else {
    if ($mgrNodeGitPy -eq 'none') { Write-Err "No package manager available for Git install" }
    else { Install-Git -UseChoco:($mgrNodeGitPy -eq 'choco') -UseWinget:($mgrNodeGitPy -eq 'winget') }
  }

  # Python
  if (Should-Skip 'python') { Write-Info "Skip requested: Python" }
  elseif (Test-PythonInstalled) { Write-Info "Python already installed. Skipping." }
  else {
    if ($mgrNodeGitPy -eq 'none') { Write-Err "No package manager available for Python install" }
    else { Install-Python -UseChoco:($mgrNodeGitPy -eq 'choco') -UseWinget:($mgrNodeGitPy -eq 'winget') }
  }

  # VS Build Tools
  if (Should-Skip 'vs' -or Should-Skip 'vstools' -or Should-Skip 'buildtools') { Write-Info "Skip requested: Visual Studio Build Tools" }
  elseif (Test-VSBuildToolsInstalled) { Write-Info "Visual Studio 2022 Build Tools already installed. Skipping." }
  else { Install-VSBuildTools -PreferWinget:$preferWingetForVS -UseChoco:$UseChoco }

  Refresh-Env
  Print-Versions
  Write-Step "Setup completed"
  Write-Info "If you just installed VS Build Tools, a reboot may be recommended."
}

try {
  Main
} catch {
  Write-Err ("Failed: " + $_.Exception.Message)
  if ($VerboseMode -and $_.Exception.StackTrace) { Write-Dbg $_.Exception.StackTrace }
  exit 1
}
