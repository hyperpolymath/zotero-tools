# SPDX-License-Identifier: AGPL-3.0-or-later
<#
.SYNOPSIS
    FormDB for Zotero - Windows Installer

.DESCRIPTION
    Sets up FormDB as a provenance-tracked mirror of your Zotero library.
    NEVER modifies your Zotero data - only creates a separate FormDB copy.

.PARAMETER Apply
    Actually perform the installation (default is dry-run preview)

.PARAMETER Uninstall
    Remove FormDB installation

.PARAMETER Force
    Skip confirmation prompts

.EXAMPLE
    # Preview what will happen
    .\install.ps1

    # Actually install
    .\install.ps1 -Apply

    # Uninstall
    .\install.ps1 -Uninstall
#>

param(
    [switch]$Apply,
    [switch]$Uninstall,
    [switch]$Force,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Configuration
$FormDBHome = if ($env:FORMDB_HOME) { $env:FORMDB_HOME } else { "$env:USERPROFILE\.formdb" }
$FormDBZotero = "$FormDBHome\zotero"
$FormDBRepo = "$FormDBHome\repo"
$RepoURL = "https://github.com/hyperpolymath/zotero-formdb.git"
$BinDir = "$env:USERPROFILE\.formdb\bin"

# Colors
function Write-Info { param($msg) Write-Host "i " -ForegroundColor Blue -NoNewline; Write-Host $msg }
function Write-Success { param($msg) Write-Host "[OK] " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Warn { param($msg) Write-Host "! " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Write-Err { param($msg) Write-Host "X " -ForegroundColor Red -NoNewline; Write-Host $msg }
function Write-Step { param($msg) Write-Host "> " -ForegroundColor Cyan -NoNewline; Write-Host $msg -ForegroundColor White }

# Uninstall
if ($Uninstall) {
    Write-Host "`nUninstalling FormDB for Zotero..." -ForegroundColor Yellow
    Write-Host "`nThis will remove:"
    Write-Host "  - $FormDBHome (FormDB data and repo)"
    Write-Host "  - CLI commands"
    Write-Host "`nYour Zotero library is NOT affected.`n"

    if (-not $Force) {
        $confirm = Read-Host "Continue? [y/N]"
        if ($confirm -notmatch '^[Yy]') {
            Write-Host "Cancelled."
            exit 0
        }
    }

    if (Test-Path $FormDBHome) { Remove-Item -Recurse -Force $FormDBHome }

    # Remove from PATH if present
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -like "*$BinDir*") {
        $newPath = ($userPath -split ';' | Where-Object { $_ -ne $BinDir }) -join ';'
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    }

    Write-Success "FormDB uninstalled"
    exit 0
}

# Find Zotero database
function Find-ZoteroDB {
    $paths = @(
        "$env:USERPROFILE\Zotero\zotero.sqlite",
        "$env:APPDATA\Zotero\Zotero\Profiles\*\zotero\zotero.sqlite",
        "$env:LOCALAPPDATA\Zotero\zotero.sqlite"
    )

    foreach ($pattern in $paths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { return $found.FullName }
    }

    # Search more broadly
    $found = Get-ChildItem -Path "$env:USERPROFILE" -Filter "zotero.sqlite" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { return $found.FullName }

    return $null
}

# Check prerequisites
function Test-Prerequisites {
    Write-Step "Checking prerequisites..."
    Write-Host ""

    $allOk = $true

    # Check Julia
    try {
        $juliaVersion = & julia --version 2>&1
        Write-Success "Julia found: $juliaVersion"
    } catch {
        Write-Err "Julia not found"
        Write-Host "  Install from: https://julialang.org/downloads/"
        $allOk = $false
    }

    # Check Git
    try {
        $null = & git --version 2>&1
        Write-Success "Git found"
    } catch {
        Write-Err "Git not found"
        Write-Host "  Install from: https://git-scm.com/download/win"
        $allOk = $false
    }

    # Check Zotero database
    $script:ZoteroDB = Find-ZoteroDB
    if ($ZoteroDB) {
        $dbSize = (Get-Item $ZoteroDB).Length / 1MB
        Write-Success "Zotero database found: $ZoteroDB ($([math]::Round($dbSize, 1)) MB)"
    } else {
        Write-Err "Zotero database not found"
        Write-Host "  Make sure Zotero is installed and has been run at least once"
        $allOk = $false
    }

    Write-Host ""
    return $allOk
}

# Show installation plan
function Show-Plan {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor White
    Write-Host "          FormDB for Zotero - Installation Plan                 " -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor White
    Write-Host ""

    Write-Host "What will be created:" -ForegroundColor White
    Write-Host "  $FormDBHome\"
    Write-Host "     +-- repo\          # FormDB source code"
    Write-Host "     +-- zotero\        # Your library mirror"
    Write-Host "     |   +-- journal.jsonl  # Provenance-tracked data"
    Write-Host "     +-- bin\           # CLI commands"
    Write-Host ""

    Write-Host "Commands that will be installed:" -ForegroundColor White
    Write-Host "  formdb-server    - Start the Zotero-compatible API server"
    Write-Host "  formdb-sync      - Sync changes from Zotero"
    Write-Host "  formdb-migrate   - Re-run full migration"
    Write-Host "  formdb-score     - PROMPT evidence quality scoring (v0.2.0)"
    Write-Host "  formdb-doi       - DOI immutability management (v0.3.0)"
    Write-Host "  formdb-publisher - Publisher registry management (v0.4.0)"
    Write-Host "  formdb-blindspot - Library blindspot analysis (v0.4.0)"
    Write-Host ""

    Write-Host "What will NOT be modified:" -ForegroundColor White
    Write-Host "  [OK] Your Zotero database (read-only access)"
    Write-Host "  [OK] Your Zotero settings"
    Write-Host "  [OK] Your Zotero sync"
    Write-Host ""

    Write-Host "Source:" -ForegroundColor White
    Write-Host "  Zotero DB: $ZoteroDB"
    Write-Host ""

    if (-not $Apply) {
        Write-Host "This is a DRY RUN. No changes will be made." -ForegroundColor Yellow
        Write-Host "Run with -Apply to actually install." -ForegroundColor Yellow
    }
    Write-Host ""
}

# Clone or update repo
function Install-Repo {
    Write-Step "Setting up FormDB repository..."

    if (-not $Apply) {
        Write-Host "  Would clone $RepoURL to $FormDBRepo"
        return
    }

    New-Item -ItemType Directory -Force -Path $FormDBHome | Out-Null

    if (Test-Path "$FormDBRepo\.git") {
        Write-Info "Updating existing repository..."
        Push-Location $FormDBRepo
        & git pull --quiet
        Pop-Location
        Write-Success "Repository updated"
    } else {
        Write-Info "Cloning repository..."
        & git clone --quiet $RepoURL $FormDBRepo
        Write-Success "Repository cloned"
    }
}

# Install Julia dependencies
function Install-JuliaDeps {
    Write-Step "Installing Julia dependencies..."

    if (-not $Apply) {
        Write-Host "  Would run: julia --project=$FormDBRepo\migration -e 'using Pkg; Pkg.instantiate()'"
        return
    }

    Push-Location "$FormDBRepo\migration"
    & julia --project=. -e 'using Pkg; Pkg.instantiate()'
    Pop-Location
    Write-Success "Julia dependencies installed"
}

# Run migration
function Invoke-Migration {
    Write-Step "Migrating Zotero library to FormDB..."

    if (-not $Apply) {
        Write-Host "  Would run migration from $ZoteroDB"
        Write-Host "  Output would go to $FormDBZotero\"
        return
    }

    New-Item -ItemType Directory -Force -Path $FormDBZotero | Out-Null

    Write-Info "This may take a minute for large libraries..."
    Write-Host ""

    Push-Location "$FormDBRepo\migration"
    & julia --project=. bin/migrate.jl --from $ZoteroDB --to $FormDBZotero --apply
    Pop-Location

    Write-Host ""
    Write-Success "Migration complete"

    if (Test-Path "$FormDBZotero\journal.jsonl") {
        $journalSize = (Get-Item "$FormDBZotero\journal.jsonl").Length / 1KB
        $entryCount = (Get-Content "$FormDBZotero\journal.jsonl" | Measure-Object -Line).Lines
        Write-Info "Journal: $([math]::Round($journalSize, 1)) KB ($entryCount entries)"
    }
}

# Install CLI commands
function Install-Commands {
    Write-Step "Installing CLI commands..."

    if (-not $Apply) {
        Write-Host "  Would create: $BinDir\formdb-server.bat"
        Write-Host "  Would create: $BinDir\formdb-sync.bat"
        Write-Host "  Would create: $BinDir\formdb-migrate.bat"
        Write-Host "  Would create: $BinDir\formdb-score.bat"
        Write-Host "  Would create: $BinDir\formdb-doi.bat"
        Write-Host "  Would create: $BinDir\formdb-publisher.bat"
        Write-Host "  Would create: $BinDir\formdb-blindspot.bat"
        return
    }

    New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

    # formdb-server.bat
    @"
@echo off
REM Start FormDB server with Zotero-compatible API
set FORMDB_HOME=%USERPROFILE%\.formdb
cd /d "%FORMDB_HOME%\repo\migration"
julia --project=. bin/server.jl --journal "%FORMDB_HOME%\zotero" %*
"@ | Set-Content "$BinDir\formdb-server.bat" -Encoding ASCII

    # formdb-sync.bat
    @"
@echo off
REM Sync from Zotero's local API to FormDB
set FORMDB_HOME=%USERPROFILE%\.formdb
cd /d "%FORMDB_HOME%\repo\migration"
julia --project=. bin/sync.jl --journal "%FORMDB_HOME%\zotero" %*
"@ | Set-Content "$BinDir\formdb-sync.bat" -Encoding ASCII

    # formdb-migrate.bat
    @"
@echo off
REM Re-run full migration from Zotero SQLite
set FORMDB_HOME=%USERPROFILE%\.formdb
set ZOTERO_DB=

REM Find Zotero database
if exist "%USERPROFILE%\Zotero\zotero.sqlite" set ZOTERO_DB=%USERPROFILE%\Zotero\zotero.sqlite

if "%ZOTERO_DB%"=="" (
    echo Error: Zotero database not found
    exit /b 1
)

cd /d "%FORMDB_HOME%\repo\migration"
julia --project=. bin/migrate.jl --from "%ZOTERO_DB%" --to "%FORMDB_HOME%\zotero" %*
"@ | Set-Content "$BinDir\formdb-migrate.bat" -Encoding ASCII

    # formdb-score.bat
    @"
@echo off
REM PROMPT evidence quality scoring
set FORMDB_HOME=%USERPROFILE%\.formdb
cd /d "%FORMDB_HOME%\repo\migration"
julia --project=. bin/score.jl %*
"@ | Set-Content "$BinDir\formdb-score.bat" -Encoding ASCII

    # formdb-doi.bat (v0.3.0)
    @"
@echo off
REM DOI immutability management
set FORMDB_HOME=%USERPROFILE%\.formdb
cd /d "%FORMDB_HOME%\repo\migration"
julia --project=. bin/doi.jl %*
"@ | Set-Content "$BinDir\formdb-doi.bat" -Encoding ASCII

    # formdb-publisher.bat (v0.4.0)
    @"
@echo off
REM Publisher registry management
set FORMDB_HOME=%USERPROFILE%\.formdb
cd /d "%FORMDB_HOME%\repo\migration"
julia --project=. bin/publisher.jl %*
"@ | Set-Content "$BinDir\formdb-publisher.bat" -Encoding ASCII

    # formdb-blindspot.bat (v0.4.0)
    @"
@echo off
REM Library blindspot analysis
set FORMDB_HOME=%USERPROFILE%\.formdb
cd /d "%FORMDB_HOME%\repo\migration"
julia --project=. bin/blindspot.jl %*
"@ | Set-Content "$BinDir\formdb-blindspot.bat" -Encoding ASCII

    Write-Success "Commands installed to $BinDir\"

    # Add to PATH if not already there
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$BinDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$BinDir", "User")
        Write-Warn "Added $BinDir to your PATH"
        Write-Host "  Restart your terminal for the change to take effect"
    }
}

# Create uninstall script
function New-UninstallScript {
    if (-not $Apply) { return }

    @"
# Uninstall FormDB for Zotero
Write-Host "This will remove FormDB installation."
Write-Host "Your Zotero library will NOT be affected."
Write-Host ""
`$confirm = Read-Host "Continue? [y/N]"
if (`$confirm -match '^[Yy]') {
    Remove-Item -Recurse -Force "$FormDBHome"
    `$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    `$newPath = (`$userPath -split ';' | Where-Object { `$_ -ne "$BinDir" }) -join ';'
    [Environment]::SetEnvironmentVariable("PATH", `$newPath, "User")
    Write-Host "FormDB uninstalled."
}
"@ | Set-Content "$FormDBHome\uninstall.ps1" -Encoding UTF8
}

# Show completion message
function Show-Complete {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "              Installation Complete!                            " -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""

    Write-Host "Your FormDB installation:" -ForegroundColor White
    Write-Host "  Data:    $FormDBZotero\"
    Write-Host "  Repo:    $FormDBRepo\"
    Write-Host ""

    Write-Host "Available commands:" -ForegroundColor White
    Write-Host "  formdb-server         # Start API server (port 8080)"
    Write-Host "  formdb-sync           # Sync from running Zotero"
    Write-Host "  formdb-migrate -Apply # Re-run full migration"
    Write-Host "  formdb-score          # PROMPT evidence scoring (v0.2.0)"
    Write-Host "  formdb-doi            # DOI management (v0.3.0)"
    Write-Host "  formdb-publisher      # Publisher registry (v0.4.0)"
    Write-Host "  formdb-blindspot      # Blindspot analysis (v0.4.0)"
    Write-Host ""

    Write-Host "Quick start:" -ForegroundColor White
    Write-Host "  # Start the server"
    Write-Host "  formdb-server"
    Write-Host ""
    Write-Host "  # Query your library"
    Write-Host "  Invoke-RestMethod http://localhost:8080/users/local/items"
    Write-Host ""

    Write-Host "To uninstall:" -ForegroundColor White
    Write-Host "  $FormDBHome\uninstall.ps1"
    Write-Host "  # or: .\install.ps1 -Uninstall"
    Write-Host ""
}

# Main
function Main {
    Write-Host ""
    Write-Host "FormDB for Zotero - Windows Installer" -ForegroundColor White
    Write-Host "=====================================" -ForegroundColor White
    Write-Host ""

    if (-not $Apply) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
        Write-Host ""
    }

    if (-not (Test-Prerequisites)) {
        Write-Err "Prerequisites not met. Please install missing dependencies."
        exit 1
    }

    Show-Plan

    if ($Apply -and -not $Force) {
        $confirm = Read-Host "Proceed with installation? [y/N]"
        if ($confirm -notmatch '^[Yy]') {
            Write-Host "Installation cancelled."
            exit 0
        }
        Write-Host ""
    }

    Install-Repo
    Write-Host ""

    Install-JuliaDeps
    Write-Host ""

    Invoke-Migration
    Write-Host ""

    Install-Commands
    Write-Host ""

    New-UninstallScript

    if ($Apply) {
        Show-Complete
    } else {
        Write-Host ""
        Write-Host "DRY RUN complete. Run with -Apply to install." -ForegroundColor Yellow
        Write-Host ""
    }
}

Main
