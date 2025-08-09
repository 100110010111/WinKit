# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WinKit is a Windows developer environment setup toolkit that automates the configuration of new Windows computers. The main script `winkit.ps1` provides:

1. **Smart Installation**: Scans existing programs and only installs what's missing
2. **Bloatware Removal**: Uninstalls non-essential Microsoft and Dell applications
3. **Essential Software Installation**: Installs development and productivity tools via winget, npm, and direct downloads
4. **Configuration Management**: Copies custom configs for Neovim, WezTerm, PowerShell, and Clink
5. **Comprehensive Logging**: Timestamped logging of all operations

## Commands

### Running the Script
```powershell
# Preview what would be installed (scan only mode)
.\winkit.ps1 -ScanOnly

# Run full setup (requires administrator)
.\winkit.ps1

# Update all installed software
.\winkit.ps1 -Update

# Run with verbose output
.\winkit.ps1 -Verbose

# Skip bloatware removal
.\winkit.ps1 -SkipBloatwareRemoval

# Skip software installation
.\winkit.ps1 -SkipSoftwareInstall

# Combine flags
.\winkit.ps1 -SkipBloatwareRemoval -Verbose
.\winkit.ps1 -Update -Verbose
```

### Quick Color Fix
```powershell
# Fix PowerShell parameter visibility issue
.\fix-ps-colors.ps1
```

### Testing Individual Functions
```powershell
# Source the script first
. .\winkit.ps1

# Test individual functions
Test-Administrator
Install-Winget
Get-InstalledPrograms
Show-InstallationPlan
Remove-Bloatware
Install-Software
Install-DirectDownloads
Copy-Configs
```

## Architecture

### Script Structure
- **Parameter Handling**: Accepts switches for scan-only mode, update mode, skipping sections, and verbose output
- **Smart Scanning**: Detects installed programs via winget list and command availability checks
- **Logging System**: All operations logged to timestamped file `setup_YYYY-MM-DD_HH-mm-ss.log`
- **Administrator Check**: Enforces admin privileges with `#Requires -RunAsAdministrator`
- **Package Manager**: Uses winget as primary method, npm for Claude Code, and direct downloads for Koofr/Drime
- **Update Mode**: Updates all installed software with `-Update` flag

### Key Functions
- `Write-Log`: Centralized logging with timestamp and level (INFO/WARNING/ERROR)
- `Test-Administrator`: Verifies script is running with admin privileges
- `Get-InstalledPrograms`: Scans system for installed software using winget and command checks
- `Show-InstallationPlan`: Displays what will be installed/removed before making changes
- `Install-Winget`: Ensures winget is available before software installation
- `Remove-Bloatware`: Removes Microsoft and Dell pre-installed apps via AppxPackage cmdlets
- `Install-Software`: Installs software using winget with skip logic for existing programs
- `Get-LatestGitHubRelease`: Fetches latest release info (URL, version) from GitHub repositories
- `Get-InstalledAppVersion`: Retrieves version info from installed executables
- `Install-DirectDownloads`: Downloads and installs Koofr and Drime desktop clients
- `Update-AllSoftware`: Updates all installed packages via winget and npm
- `Copy-Configs`: Copies configuration files from the `configs/` directory to appropriate locations

### Software Installation List

#### Winget Packages
- OpenJS.NodeJS (Node.js)
- GoLang.Go (Go Programming Language)
- Proton.ProtonMail (Proton Mail)
- Proton.ProtonDrive (Proton Drive)  
- Proton.ProtonVPN (Proton VPN)
- Git.Git (Git for Windows)
- Microsoft.PowerShell (PowerShell 7)
- VSCodium.VSCodium (VSCodium)
- Anthropic.Claude (Claude Desktop)
- StandardNotes.StandardNotes (Standard Notes)
- Docker.DockerDesktop (Docker Desktop)
- Espanso.Espanso (Espanso)
- Google.Chrome (Google Chrome)
- AgileBits.1Password (1Password)
- jqlang.jq (jq)
- Fork.Fork (Fork Git Client)
- Neovim.Neovim (Neovim)
- wez.wezterm (WezTerm)
- chrisant996.Clink (Clink)

#### NPM Package
- @anthropic-ai/claude-code (Claude Code) - Installed globally after Node.js

#### Direct Downloads
- Koofr Desktop Client - Downloaded from app.koofr.net/dl/apps/win
- Drime Desktop Client - Downloaded from GitHub releases (latest version)

Note: The script handles special cases like Fork which may appear as `ARP\User\X64\Fork` in winget listings.

### Configuration Files
The script includes a `configs/` directory containing:
- `configs/nvim/init.lua` - Neovim configuration (copied to `%LOCALAPPDATA%\nvim\`)
- `configs/wezterm/wezterm.lua` - WezTerm configuration (copied to `%USERPROFILE%\.config\wezterm\`)
- `configs/powershell/Microsoft.PowerShell_profile.ps1` - PowerShell profile with aliases (copied to `$PROFILE`)
- `configs/clink/` - Clink configuration files (copied to `%LOCALAPPDATA%\clink\`)

These configurations are automatically copied to their appropriate locations after software installation.

### PowerShell Aliases
The PowerShell profile includes these useful aliases:
- `cc` → claude (Claude Code)
- `vi`, `vim` → nvim (Neovim)
- `g` → git
- `d` → docker
- `py` → python
- `n` → node

And Git helper functions:
- `gs` → git status
- `gp` → git pull
- `gd` → git diff
- `ga` → git add
- `gco` → git checkout
- `gcm` → git commit -m
- `glog` → git log (pretty format)

### Error Handling
- Non-terminating errors for individual package removals/installations
- Comprehensive try-catch blocks with logging
- Exit code 1 on critical failures
- Warnings for already installed software or missing packages
- Special handling for winget output parsing edge cases
- Graceful fallback for direct downloads that fail

## Troubleshooting

### Common Issues

1. **PowerShell parameter colors not visible**
   - Run `./fix-ps-colors.ps1` for immediate fix
   - Colors are permanently fixed when PowerShell profile is copied

2. **winget IDs don't match**
   - Proton apps changed from `ProtonTechnologies.*` to `Proton.*`
   - Fork may appear as `ARP\User\X64\Fork` instead of `Fork.Fork`
   - Script handles these cases automatically

3. **Direct downloads fail**
   - Koofr downloaded from app.koofr.net/dl/apps/win with proper headers
   - Drime fetched from GitHub releases API for latest version
   - Version checking for Drime to avoid unnecessary updates
   - Installers downloaded to temp directory only when needed
   - Silent installation attempted with `/S` flag
   - Fallback URLs used if API calls fail
   - Manual installation URLs provided in log if download fails

4. **Scan shows incorrect results**
   - Script checks both winget list and command availability
   - Some programs may be detected via multiple methods
   - Use `-Verbose` flag to see detailed detection logic

## Implementation Details

### Smart Scanning Algorithm
The `Get-InstalledPrograms` function uses multiple detection methods:
1. Parses `winget list` output, handling special characters and format variations
2. Checks for command availability (e.g., `Get-Command node`)
3. Looks for specific executables in known locations
4. Returns a hashtable for O(1) lookup performance

### Installation Plan Display
The `Show-InstallationPlan` function:
- Groups software by installation status (installed vs to-be-installed)
- Shows counts for each category
- Includes all software types (winget, npm, direct downloads)
- Used by `-ScanOnly` parameter for preview mode

### Special ID Handling
The script handles these ID variations:
- Fork: `Fork.Fork` vs `ARP\User\X64\Fork`
- Proton apps: `ProtonTechnologies.*` vs `Proton.*`
- Wispr Flow: Store app ID `9N1B9JWB3M35`

### Update Mode
The `-Update` flag enables smart software updates:
- Checks for and updates only outdated winget packages
- Checks for and updates only outdated npm packages
- For Drime: Compares installed version with latest GitHub release
- For Koofr: Notifies user to check manually (no version API available)
- Only downloads and installs when updates are actually needed
- Shows "up to date" messages when no updates required