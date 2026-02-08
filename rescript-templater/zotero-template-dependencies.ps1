<#
.SYNOPSIS
  Bootstrap all required and optional prerequisites for the Zotero Plugin Templater on Windows,
  ensure all executables and modules are in your PATH.

.DESCRIPTION
  • Installs system tools via winget: PowerShell 7+, Git, PostgreSQL, Deno, Dhall CLI, Erlang/OTP, Elixir
  • Adds Deno and Rust/Cargo bins to PATH immediately and persistently
  • (Optional) Installs PowerShell modules: Pester; pulls TomlPS from GitHub if not in PSGallery
  • (Optional) Installs Node.js LTS, AssemblyScript, axe-cli, Rust toolchain, wasm-pack

.PARAMETER Optional
  Switch to install optional developer tools (TOML modules, Node.js, Rust, wasm-pack, axe-cli).

.EXAMPLE
  # Required only
  .\bootstrap-prereqs.ps1

  # Required + optional
  .\bootstrap-prereqs.ps1 -Optional
#>

param(
  [switch]$Optional
)

# helper for colored logs
function Write-Log {
  param($Text, [ConsoleColor]$Color = 'White')
  $old = $Host.UI.RawUI.ForegroundColor
  $Host.UI.RawUI.ForegroundColor = $Color
  Write-Host $Text
  $Host.UI.RawUI.ForegroundColor = $old
}

# check for Administrator privileges
if (
  -not (
    (New-Object Security.Principal.WindowsPrincipal `
      ([Security.Principal.WindowsIdentity]::GetCurrent())
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  )
) {
  Write-Log "Please re-run this script as Administrator." Red
  exit 1
}

# ensure winget exists
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Log "winget not found. Please install App Installer from Microsoft Store." Red
  exit 1
}

# install via winget if missing
function Install-Winget {
  param($Id, $CheckCmd, $Friendly)
  if (-not (Get-Command $CheckCmd -ErrorAction SilentlyContinue)) {
    Write-Log "Installing $Friendly..." Cyan
    winget install --id $Id --silent --accept-package-agreements --accept-source-agreements |
      Out-Null
    Write-Log "→ $Friendly installed." Green
  }
  else {
    Write-Log "$Friendly already on PATH." DarkGray
  }
}

# persistently add a folder to User PATH and to current session
function Add-ToPath {
  param($Folder)
  if (-not (Test-Path $Folder)) { return }
  $userPath = [Environment]::GetEnvironmentVariable('Path','User').Split(';')
  if ($userPath -notcontains $Folder) {
    Write-Log "Adding $Folder to User PATH..." Cyan
    $newPath = ([Environment]::GetEnvironmentVariable('Path','User') + ';' + $Folder)
    [Environment]::SetEnvironmentVariable('Path',$newPath,'User')
  }
  # immediate for current session
  if ($Env:Path.Split(';') -notcontains $Folder) {
    $Env:Path = "$Env:Path;$Folder"
  }
}

# Install PowerShell module if missing
function Install-PsModule {
  param($Name)
  if (-not (Get-Module -ListAvailable -Name $Name)) {
    Write-Log "Installing PowerShell module $Name..." Cyan
    Install-Module -Name $Name -Scope AllUsers -Force -Repository PSGallery |
      Out-Null
    Write-Log "→ Module $Name installed." Green
  }
  else {
    Write-Log "Module $Name already available." DarkGray
  }
}

# Clone TomlPS from GitHub if not on PSGallery
function Ensure-TomlPS {
  if (-not (Get-Module -ListAvailable -Name TomlPS)) {
    $modPath = Join-Path (Split-Path $PROFILE -Parent) "Modules\TomlPS"
    if (-not (Test-Path $modPath)) {
      Write-Log "Cloning TomlPS into $modPath..." Cyan
      git clone https://github.com/jdroberson/TomlPS.git $modPath | Out-Null
      Write-Log "→ TomlPS cloned." Green
    }
    Import-Module TomlPS -ErrorAction SilentlyContinue
  }
}

# -----------------------------
# 1. Required system tools
# -----------------------------
Write-Log "`nInstalling required system tools…" Yellow

Install-Winget 'Microsoft.PowerShell'  'pwsh'   'PowerShell 7+'
Install-Winget 'Git.Git'               'git'    'Git'
Install-Winget 'PostgreSQL.PostgreSQL' 'psql'   'PostgreSQL 12+'
Install-Winget 'Deno.Deno'             'deno'   'Deno'
Install-Winget 'DhallLang.Dhall'       'dhall'  'Dhall CLI'
Install-Winget 'Erlang.ErlangOtp'      'erl'    'Erlang/OTP'
Install-Winget 'ElixirLang.Elixir'     'elixir' 'Elixir'

# Deno’s bin folder
Add-ToPath "$HOME\.deno\bin"

# -----------------------------
# 2. Optional developer tools
# -----------------------------
if ($Optional) {
  Write-Log "`nInstalling optional dev tools…" Yellow

  # PowerShell modules
  Install-PsModule 'Pester'
  try {
    Install-PsModule 'powershell-toml'
  } catch {
    Ensure-TomlPS
  }

  # Node.js & npm
  Install-Winget 'OpenJS.NodeJS.LTS' 'npm' 'Node.js LTS'
  if (Get-Command npm -ErrorAction SilentlyContinue) {
    Write-Log "Installing AssemblyScript and axe-cli via npm…" Cyan
    npm install -g assemblyscript axe-cli | Out-Null
    Write-Log "→ assemblyscript + axe-cli installed." Green
  }

  # Rust toolchain & wasm-pack
  if (-not (Get-Command rustup.exe -ErrorAction SilentlyContinue)) {
    Write-Log "Installing Rust toolchain..." Cyan
    $tmp = "$env:TEMP\rustup-init.exe"
    Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile $tmp -UseBasicParsing
    & $tmp -y | Out-Null
    Remove-Item $tmp
    Write-Log "→ Rust toolchain installed." Green
  }
  Add-ToPath "$HOME\.cargo\bin"

  if (Get-Command cargo.exe -ErrorAction SilentlyContinue) {
    Write-Log "Installing wasm-pack via cargo…" Cyan
    cargo install wasm-pack | Out-Null
    Write-Log "→ wasm-pack installed." Green
  }
}

# -----------------------------
# 3. Summary
# -----------------------------
Write-Log "`nBootstrap complete!" Green
Write-Log "Restart your PowerShell session to refresh PATH and modules." Yellow
