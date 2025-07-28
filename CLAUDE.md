# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WinKit is a Windows setup automation toolkit designed to streamline the process of setting up a new Windows computer. The main script `winkit.ps1` handles:

1. **Bloatware Removal**: Uninstalls non-essential Microsoft and Dell applications
2. **Essential Software Installation**: Installs development and productivity tools via winget
3. **Logging**: Comprehensive logging with timestamped entries

## Commands

### Running the Script
```powershell
# Run full setup (requires administrator)
.\winkit.ps1

# Run with verbose output
.\winkit.ps1 -Verbose

# Skip bloatware removal
.\winkit.ps1 -SkipBloatwareRemoval

# Skip software installation
.\winkit.ps1 -SkipSoftwareInstall

# Combine flags
.\winkit.ps1 -SkipBloatwareRemoval -Verbose
```

### Testing Individual Functions
```powershell
# Source the script first
. .\winkit.ps1

# Test individual functions
Test-Administrator
Install-Winget
Remove-Bloatware
Install-Software
Copy-Configs
```

## Architecture

### Script Structure
- **Parameter Handling**: Accepts switches for skipping sections and enabling verbose output
- **Logging System**: All operations logged to timestamped file `setup_YYYY-MM-DD_HH-mm-ss.log`
- **Administrator Check**: Enforces admin privileges with `#Requires -RunAsAdministrator`
- **Package Manager**: Uses winget as primary installation method, with automatic installation if missing

### Key Functions
- `Write-Log`: Centralized logging with timestamp and level (INFO/WARNING/ERROR)
- `Test-Administrator`: Verifies script is running with admin privileges
- `Install-Winget`: Ensures winget is available before software installation
- `Remove-Bloatware`: Removes Microsoft and Dell pre-installed apps via AppxPackage cmdlets
- `Install-Software`: Installs software using winget with error handling
- `Install-DirectDownloads`: Downloads and installs software not available in winget (Koofr, Drime)
- `Copy-Configs`: Copies configuration files from the `configs/` directory to appropriate locations (Neovim, WezTerm, PowerShell profile, and Clink)

### Software Installation List
The script installs these applications via winget IDs:
- OpenJS.NodeJS (Node.js)
- ProtonTechnologies.ProtonMail
- ProtonTechnologies.ProtonDrive
- ProtonTechnologies.ProtonVPN
- Git.Git
- Microsoft.PowerShell
- VSCodium.VSCodium
- Anthropic.Claude (Claude Desktop)
- StandardNotes.StandardNotes
- Docker.DockerDesktop
- Espanso.Espanso
- Google.Chrome
- AgileBits.1Password
- jqlang.jq
- Fork.Fork
- Neovim.Neovim
- wez.wezterm
- chrisant996.Clink

Note: Claude Code is installed via npm (`npm install -g @anthropic/claude-code`) after Node.js installation.

### Direct Download Applications
The script also installs these applications via direct download:
- **Koofr** - Cloud storage desktop sync client
- **Drime** - Cloud storage desktop client

These applications are downloaded from their official websites and installed automatically.

### Configuration Files
The script includes a `configs/` directory containing:
- `configs/nvim/init.lua` - Neovim configuration (copied to `%LOCALAPPDATA%\nvim\`)
- `configs/wezterm/wezterm.lua` - WezTerm configuration (copied to `%USERPROFILE%\.config\wezterm\`)
- `configs/powershell/Microsoft.PowerShell_profile.ps1` - PowerShell profile with aliases (copied to `$PROFILE`)
- `configs/clink/` - Clink configuration files for cmd.exe (copied to `%LOCALAPPDATA%\clink\`)

These configurations are automatically copied to their appropriate locations after software installation.

### Aliases
The setup script configures useful aliases for both PowerShell and cmd.exe (via Clink):

#### Common Aliases (available in both PowerShell and cmd.exe)
- `cc` - Claude Code
- `vi`, `vim` - Neovim
- `g` - Git
- `d` - Docker
- `py` - Python
- `n` - Node.js

#### Git Shortcuts
- `gs` - git status
- `gp` - git pull
- `gd` - git diff
- `ga` - git add
- `gco` - git checkout
- `gcm` - git commit -m
- `glog` - git log (pretty format)

#### Navigation
- `..` - Go up one directory
- `...` - Go up two directories
- `home` - Go to home directory
- `repos` - Go to ~/repos

#### Quick Config Editing
- `vimrc` - Edit Neovim config
- `wezconfig` - Edit WezTerm config
- `profile` - Edit PowerShell profile (PowerShell only)

#### Utilities
- `ll` - List all files (detailed)
- `which` - Find command location
- `touch` - Create empty file
- `mkcd` - Make directory and cd into it (PowerShell only)
- `aliases` - Show all available aliases

### Error Handling
- Non-terminating errors for individual package removals/installations
- Comprehensive try-catch blocks with logging
- Exit code 1 on critical failures
- Warnings for already installed software or missing packages