#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WinKit - Windows Developer Environment Setup Toolkit
.DESCRIPTION
    WinKit automates the setup of a new Windows computer by:
    1. Removing bloatware (Microsoft and Dell apps)
    2. Installing essential development and productivity software
    3. Configuring developer tools with custom aliases and settings
.NOTES
    This script requires administrator privileges
#>

param(
    [switch]$SkipBloatwareRemoval,
    [switch]$SkipSoftwareInstall,
    [switch]$ScanOnly,
    [switch]$Verbose,
    [switch]$Update
)

# Enable verbose output if requested
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# Script configuration
$LogFile = "setup_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    Write-Output $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage
}

# Check if running as administrator
function Test-Administrator {
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Get all installed programs
function Get-InstalledPrograms {
    Write-Log "Scanning installed programs..."
    
    # Explicitly create as hashtable
    $InstalledPrograms = @{}
    
    # Check if winget is available
    $WingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $WingetCmd) {
        Write-Log "Winget not found, skipping winget scan" -Level "WARNING"
    } else {
        # Get programs from winget
        try {
            Write-Log "Running winget list..."
            $WingetOutput = winget list --disable-interactivity 2>$null
            
            # Find the header line
            $HeaderFound = $false
            $DataStarted = $false
            
            foreach ($Line in $WingetOutput) {
                # Look for the dashed line separator
                if ($Line -match '^[\-]{3,}') {
                    $DataStarted = $true
                    continue
                }
                
                # Process data lines
                if ($DataStarted -and $Line.Trim() -ne '') {
                    # Split by multiple spaces
                    $Parts = $Line -split '\s{2,}'
                    
                    # The ID is typically in the second column
                    if ($Parts.Count -ge 2) {
                        $Id = $Parts[1].Trim()
                        
                        # Skip if it's the header row or looks like a version number
                        if ($Id -and $Id -ne 'Id' -and $Id -ne '' -and 
                            $Id -notmatch '^\d+\.\d+' -and 
                            $Id -notmatch '^MSIX\\' -and
                            $Id -notmatch 'ΓÇª') {
                            
                            # Special handling for ARP entries
                            if ($Id -eq 'ARP\User\X64\Fork') {
                                $InstalledPrograms['Fork.Fork'] = $true
                                Write-Verbose "Found Fork (ARP): $Id"
                            } else {
                                $InstalledPrograms[$Id] = $true
                                Write-Verbose "Found: $Id"
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Log "Failed to get winget list: $($_.Exception.Message)" -Level "WARNING"
        }
    }
    
    # Check for specific programs that might not show in winget
    # Check for Node.js
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $InstalledPrograms['OpenJS.NodeJS'] = $true
    }
    
    # Check for Go
    if (Get-Command go -ErrorAction SilentlyContinue) {
        $InstalledPrograms['GoLang.Go'] = $true
    }
    
    # Check for Git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $InstalledPrograms['Git.Git'] = $true
    }
    
    # Check for Docker
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        $InstalledPrograms['Docker.DockerDesktop'] = $true
    }
    
    # Check for Claude Code
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        $InstalledPrograms['ClaudeCode'] = $true
    }
    
    # Check for Neovim
    if (Get-Command nvim -ErrorAction SilentlyContinue) {
        $InstalledPrograms['Neovim.Neovim'] = $true
    }
    
    # Check for WezTerm
    if (Get-Command wezterm -ErrorAction SilentlyContinue) {
        $InstalledPrograms['wez.wezterm'] = $true
    }
    
    # Check for Fork (may be listed differently in winget)
    if (Test-Path "$env:LOCALAPPDATA\Fork\Fork.exe") {
        $InstalledPrograms['Fork.Fork'] = $true
    }
    
    # Also check for Wispr Flow
    if ($InstalledPrograms.ContainsKey('ARP\User\X64\WisprFlow')) {
        $InstalledPrograms.Remove('ARP\User\X64\WisprFlow')
    }
    
    Write-Log "Found $($InstalledPrograms.Count) installed programs"
    
    # Debug: Show what was found
    if ($VerbosePreference -eq 'Continue') {
        Write-Verbose "Installed programs hashtable contents:"
        foreach ($key in $InstalledPrograms.Keys) {
            Write-Verbose "  - $key"
        }
    }
    
    # Return hashtable
    return $InstalledPrograms
}

# Install winget if not present
function Install-Winget {
    Write-Log "Checking for Windows Package Manager (winget)..."
    
    try {
        $null = Get-Command winget -ErrorAction Stop
        Write-Log "winget is already installed"
        return $true
    }
    catch {
        Write-Log "winget not found, attempting to install..."
        
        try {
            # Install App Installer from Microsoft Store
            $AppInstaller = Get-AppxPackage -Name Microsoft.DesktopAppInstaller
            if (-not $AppInstaller) {
                Write-Log "Installing Microsoft.DesktopAppInstaller..."
                Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
            }
            
            # Verify installation
            Start-Sleep -Seconds 5
            $null = Get-Command winget -ErrorAction Stop
            Write-Log "winget installed successfully"
            return $true
        }
        catch {
            Write-Log "Failed to install winget: $($_.Exception.Message)" -Level "ERROR"
            return $false
        }
    }
}

# Remove bloatware applications
function Remove-Bloatware {
    Write-Log "Starting bloatware removal..."
    
    # Microsoft bloatware to remove
    $MicrosoftBloatware = @(
        "Microsoft.3DBuilder",
        "Microsoft.BingWeather",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.Messaging",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MixedReality.Portal",
        "Microsoft.Office.OneNote",
        "Microsoft.People",
        "Microsoft.Print3D",
        "Microsoft.SkypeApp",
        "Microsoft.Wallet",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCamera",
        "microsoft.windowscommunicationsapps",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.YourPhone",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo"
    )
    
    # Dell bloatware patterns
    $DellBloatware = @(
        "*Dell*",
        "*MyDell*",
        "*DellInc*"
    )
    
    # Remove Microsoft bloatware
    foreach ($App in $MicrosoftBloatware) {
        try {
            $Package = Get-AppxPackage -Name $App -AllUsers -ErrorAction SilentlyContinue
            if ($Package) {
                Write-Log "Removing $App..."
                Remove-AppxPackage -Package $Package.PackageFullName -AllUsers -ErrorAction Stop
                Write-Log "Successfully removed $App"
            } else {
                Write-Log "$App not found, skipping..."
            }
        }
        catch {
            Write-Log "Failed to remove $App : $($_.Exception.Message)" -Level "WARNING"
        }
    }
    
    # Remove Dell bloatware
    foreach ($Pattern in $DellBloatware) {
        try {
            $Packages = Get-AppxPackage -Name $Pattern -AllUsers -ErrorAction SilentlyContinue
            foreach ($Package in $Packages) {
                Write-Log "Removing Dell app: $($Package.Name)..."
                Remove-AppxPackage -Package $Package.PackageFullName -AllUsers -ErrorAction Stop
                Write-Log "Successfully removed $($Package.Name)"
            }
        }
        catch {
            Write-Log "Failed to remove Dell package $Pattern : $($_.Exception.Message)" -Level "WARNING"
        }
    }
    
    Write-Log "Bloatware removal completed"
}

# Show installation plan
function Show-InstallationPlan {
    param(
        [hashtable]$InstalledPrograms = @{}
    )
    
    Write-Log "=== WinKit Installation Plan ==="
    
    # Debug check
    if ($null -eq $InstalledPrograms) {
        Write-Log "InstalledPrograms is null!" -Level "ERROR"
        $InstalledPrograms = @{}
    }
    
    Write-Verbose "Show-InstallationPlan received type: $($InstalledPrograms.GetType().FullName)"
    Write-Verbose "Keys count: $($InstalledPrograms.Keys.Count)"
    
    # Software to install with their winget IDs
    $SoftwareList = @(
        @{ Name = "Node.js"; Id = "OpenJS.NodeJS" },
        @{ Name = "Go"; Id = "GoLang.Go" },
        @{ Name = "Proton Mail"; Id = "Proton.ProtonMail" },
        @{ Name = "Proton Drive"; Id = "Proton.ProtonDrive" },
        @{ Name = "Proton VPN"; Id = "Proton.ProtonVPN" },
        @{ Name = "Git for Windows"; Id = "Git.Git" },
        @{ Name = "PowerShell 7"; Id = "Microsoft.PowerShell" },
        @{ Name = "VSCodium"; Id = "VSCodium.VSCodium" },
        @{ Name = "Claude Desktop"; Id = "Anthropic.Claude" },
        @{ Name = "Standard Notes"; Id = "StandardNotes.StandardNotes" },
        @{ Name = "Docker Desktop"; Id = "Docker.DockerDesktop" },
        @{ Name = "Espanso"; Id = "Espanso.Espanso" },
        @{ Name = "Google Chrome"; Id = "Google.Chrome" },
        @{ Name = "1Password"; Id = "AgileBits.1Password" },
        @{ Name = "jq"; Id = "jqlang.jq" },
        @{ Name = "Fork"; Id = "Fork.Fork" },
        @{ Name = "Neovim"; Id = "Neovim.Neovim" },
        @{ Name = "WezTerm"; Id = "wez.wezterm" },
        @{ Name = "Clink"; Id = "chrisant996.Clink" }
    )
    
    $ToInstall = @()
    $AlreadyInstalled = @()
    
    foreach ($Software in $SoftwareList) {
        try {
            if ($InstalledPrograms.ContainsKey($Software.Id)) {
                $AlreadyInstalled += $Software.Name
                Write-Verbose "MATCH: $($Software.Name) - ID: $($Software.Id)"
            } else {
                $ToInstall += $Software.Name
                Write-Verbose "NO MATCH: $($Software.Name) - ID: $($Software.Id)"
            }
        }
        catch {
            Write-Log "Error checking $($Software.Name): $_" -Level "ERROR"
            $ToInstall += $Software.Name
        }
    }
    
    # Check Claude Code separately
    if ($InstalledPrograms -is [hashtable] -and $InstalledPrograms.ContainsKey('ClaudeCode')) {
        $AlreadyInstalled += "Claude Code (npm)"
    } else {
        $ToInstall += "Claude Code (npm)"
    }
    
    # Direct downloads
    $ToInstall += "Koofr (direct download)"
    $ToInstall += "Drime (direct download)"
    
    Write-Host "`nAlready Installed ($($AlreadyInstalled.Count)):" -ForegroundColor Green
    foreach ($App in $AlreadyInstalled | Sort-Object) {
        Write-Host "  [OK] $App" -ForegroundColor DarkGray
    }
    
    Write-Host "`nTo Be Installed ($($ToInstall.Count)):" -ForegroundColor Yellow
    foreach ($App in $ToInstall | Sort-Object) {
        Write-Host "  * $App" -ForegroundColor White
    }
    
    Write-Host "`nBloatware to Remove:" -ForegroundColor Red
    Write-Host "  * Microsoft Store apps (Weather, Skype, Xbox, etc.)" -ForegroundColor White
    Write-Host "  * Dell pre-installed software" -ForegroundColor White
    
    Write-Host "`nConfiguration Files to Copy:" -ForegroundColor Cyan
    Write-Host "  * Neovim config" -ForegroundColor White
    Write-Host "  * WezTerm config" -ForegroundColor White
    Write-Host "  * PowerShell profile with aliases" -ForegroundColor White
    Write-Host "  * Clink configuration" -ForegroundColor White
    
    Write-Host ""
}

# Install software using winget
function Install-Software {
    param(
        [hashtable]$InstalledPrograms = @{}
    )
    
    Write-Log "Starting software installation..."
    
    # Software to install with their winget IDs
    $SoftwareList = @(
        @{ Name = "Node.js"; Id = "OpenJS.NodeJS" },
        @{ Name = "Go"; Id = "GoLang.Go" },
        @{ Name = "Proton Mail"; Id = "Proton.ProtonMail" },
        @{ Name = "Proton Drive"; Id = "Proton.ProtonDrive" },
        @{ Name = "Proton VPN"; Id = "Proton.ProtonVPN" },
        @{ Name = "Git for Windows"; Id = "Git.Git" },
        @{ Name = "PowerShell 7"; Id = "Microsoft.PowerShell" },
        @{ Name = "VSCodium"; Id = "VSCodium.VSCodium" },
        @{ Name = "Claude Desktop"; Id = "Anthropic.Claude" },
        @{ Name = "Standard Notes"; Id = "StandardNotes.StandardNotes" },
        @{ Name = "Docker Desktop"; Id = "Docker.DockerDesktop" },
        @{ Name = "Espanso"; Id = "Espanso.Espanso" },
        @{ Name = "Google Chrome"; Id = "Google.Chrome" },
        @{ Name = "1Password"; Id = "AgileBits.1Password" },
        @{ Name = "jq"; Id = "jqlang.jq" },
        @{ Name = "Fork"; Id = "Fork.Fork" },
        @{ Name = "Neovim"; Id = "Neovim.Neovim" },
        @{ Name = "WezTerm"; Id = "wez.wezterm" },
        @{ Name = "Clink"; Id = "chrisant996.Clink" }
    )
    
    foreach ($Software in $SoftwareList) {
        try {
            # Check if already installed using our scan (unless updating)
            if (-not $Update -and $InstalledPrograms.ContainsKey($Software.Id)) {
                Write-Log "$($Software.Name) is already installed, skipping..."
                continue
            }
            
            Write-Log "Installing $($Software.Name)..."
            
            # Use upgrade for update mode, install for new installations
            if ($Update) {
                # Check if update is available first
                $UpdateCheck = winget list --id $Software.Id --exact
                if ($UpdateCheck -match "Available") {
                    Write-Log "Update available for $($Software.Name), installing..."
                    $Result = winget upgrade --id $Software.Id --accept-package-agreements --accept-source-agreements --silent
                } else {
                    Write-Log "$($Software.Name) is already up to date"
                    continue
                }
            } else {
                $Result = winget install --id $Software.Id --accept-package-agreements --accept-source-agreements --silent
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Successfully installed/updated $($Software.Name)"
            } elseif ($LASTEXITCODE -eq -1978335189) {
                Write-Log "$($Software.Name) is already up to date"
            } else {
                Write-Log "Installation/update of $($Software.Name) failed with exit code: $LASTEXITCODE" -Level "ERROR"
            }
        }
        catch {
            Write-Log "Failed to process $($Software.Name): $($_.Exception.Message)" -Level "ERROR"
        }
    }
    
    # Install Claude Code via npm
    try {
        # Check if already installed (unless updating)
        if (-not $Update -and $InstalledPrograms.ContainsKey('ClaudeCode')) {
            Write-Log "Claude Code is already installed, skipping..."
        } else {
            if ($Update -and $InstalledPrograms.ContainsKey('ClaudeCode')) {
                Write-Log "Checking for Claude Code updates via npm..."
                # Check if update available
                $OutdatedCheck = npm outdated -g @anthropic-ai/claude-code 2>&1
                if ($OutdatedCheck -match "@anthropic-ai/claude-code") {
                    Write-Log "Update available for Claude Code"
                } else {
                    Write-Log "Claude Code is already up to date"
                    continue
                }
            }
            
            Write-Log "Installing Claude Code via npm..."
            # Install Claude Code globally via npm
            $NpmResult = npm install -g @anthropic-ai/claude-code 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Successfully installed Claude Code via npm"
                Write-Log "You can now use 'claude' or 'cc' commands in your terminal"
            } else {
                Write-Log "Failed to install Claude Code via npm: $NpmResult" -Level "ERROR"
                Write-Log "You may need to install it manually or check npm connectivity" -Level "WARNING"
            }
        }
    }
    catch {
        Write-Log "Could not install Claude Code: $($_.Exception.Message)" -Level "WARNING"
    }
    
    Write-Log "Software installation completed"
}

# Get latest GitHub release info
function Get-LatestGitHubRelease {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$AssetPattern
    )
    
    try {
        $ReleasesUrl = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
        $Release = Invoke-RestMethod -Uri $ReleasesUrl -UseBasicParsing
        $Asset = $Release.assets | Where-Object { $_.name -like $AssetPattern } | Select-Object -First 1
        
        if ($Asset) {
            return @{
                Url = $Asset.browser_download_url
                Version = $Release.tag_name
                FileName = $Asset.name
            }
        }
    }
    catch {
        Write-Log "Failed to get latest release from GitHub: $($_.Exception.Message)" -Level "WARNING"
    }
    
    return $null
}

# Get installed app version
function Get-InstalledAppVersion {
    param(
        [string]$AppName,
        [string]$InstallPath
    )
    
    try {
        if (Test-Path $InstallPath) {
            $FileInfo = Get-Item $InstallPath
            if ($FileInfo.VersionInfo.FileVersion) {
                return $FileInfo.VersionInfo.FileVersion
            }
        }
    }
    catch {
        Write-Verbose "Could not get version for $AppName"
    }
    
    return $null
}

# Install software that requires direct download
function Install-DirectDownloads {
    param(
        [hashtable]$InstalledPrograms = @{}
    )
    
    Write-Log "Starting direct download installations..."
    
    # Create temp directory for downloads
    $TempDir = Join-Path $env:TEMP "WinKit_Downloads"
    if (-not (Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    }
    
    # Install Koofr
    try {
        $KoofrExePath = "$env:LOCALAPPDATA\Koofr\Koofr.exe"
        $KoofrInstalled = Test-Path $KoofrExePath
        
        if ($KoofrInstalled -and -not $Update) {
            Write-Log "Koofr is already installed, skipping..."
        } else {
            $ShouldInstall = $true
            
            if ($Update -and $KoofrInstalled) {
                # For Koofr, we can't easily check version, so prompt user
                Write-Log "Koofr is installed but version check not available"
                Write-Log "To update Koofr, please check manually at https://app.koofr.net"
                $ShouldInstall = $false
            }
            
            if ($ShouldInstall) {
                Write-Log "Downloading Koofr desktop client..."
                # Koofr direct download link
                $KoofrUrl = "https://app.koofr.net/dl/apps/win"
                $KoofrInstaller = Join-Path $TempDir "KoofrSetup.exe"
                
                # Download with proper headers
                $Headers = @{
                    'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                }
                
                Invoke-WebRequest -Uri $KoofrUrl -OutFile $KoofrInstaller -UseBasicParsing -Headers $Headers
                
                if (Test-Path $KoofrInstaller) {
                    Write-Log "Installing Koofr..."
                    Start-Process -FilePath $KoofrInstaller -ArgumentList "/S" -Wait
                    Write-Log "Koofr installation completed"
                } else {
                    Write-Log "Failed to download Koofr installer" -Level "ERROR"
                }
            }
        }
    }
    catch {
        Write-Log "Failed to install Koofr: $($_.Exception.Message)" -Level "ERROR"
        Write-Log "You may need to install Koofr manually from https://app.koofr.net" -Level "WARNING"
    }
    
    # Install Drime
    try {
        $DrimeExePath = "$env:ProgramFiles\Drime\Drime.exe"
        $DrimeInstalled = Test-Path $DrimeExePath
        
        if ($DrimeInstalled -and -not $Update) {
            Write-Log "Drime is already installed, skipping..."
        } else {
            Write-Log "Getting latest Drime release from GitHub..."
            
            # Get latest release info from GitHub
            $DrimeRelease = Get-LatestGitHubRelease -Owner "drimecloud" -Repo "Drimeclientpublic" -AssetPattern "*Setup*.exe"
            
            if (-not $DrimeRelease) {
                # Fallback to known release
                Write-Log "Using fallback URL for Drime..."
                $DrimeRelease = @{
                    Url = "https://github.com/drimecloud/Drimeclientpublic/releases/download/v2.1.0/Drime-Setup-2.1.0.exe"
                    Version = "v2.1.0"
                }
            }
            
            $ShouldInstall = $true
            
            if ($Update -and $DrimeInstalled) {
                # Check if update needed
                $InstalledVersion = Get-InstalledAppVersion -AppName "Drime" -InstallPath $DrimeExePath
                $LatestVersion = $DrimeRelease.Version -replace '^v', ''
                
                if ($InstalledVersion -and $LatestVersion) {
                    if ([version]$InstalledVersion -ge [version]$LatestVersion) {
                        Write-Log "Drime is already up to date (version $InstalledVersion)"
                        $ShouldInstall = $false
                    } else {
                        Write-Log "Drime update available: $InstalledVersion -> $LatestVersion"
                    }
                } else {
                    Write-Log "Could not determine Drime version, proceeding with update"
                }
            }
            
            if ($ShouldInstall) {
                Write-Log "Downloading Drime from: $($DrimeRelease.Url)"
                $DrimeInstaller = Join-Path $TempDir "DrimeSetup.exe"
                
                # Download the installer
                Invoke-WebRequest -Uri $DrimeRelease.Url -OutFile $DrimeInstaller -UseBasicParsing
                
                if (Test-Path $DrimeInstaller) {
                    Write-Log "Installing Drime..."
                    Start-Process -FilePath $DrimeInstaller -ArgumentList "/S" -Wait
                    Write-Log "Drime installation completed"
                } else {
                    Write-Log "Failed to download Drime installer" -Level "ERROR"
                }
            }
        }
    }
    catch {
        Write-Log "Failed to install Drime: $($_.Exception.Message)" -Level "ERROR"
        Write-Log "You may need to install Drime manually from https://github.com/drimecloud/Drimeclientpublic/releases" -Level "WARNING"
    }
    
    # Cleanup temp directory
    try {
        Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Log "Failed to cleanup temp directory: $($_.Exception.Message)" -Level "WARNING"
    }
    
    Write-Log "Direct download installations completed"
}

# Copy configuration files
function Copy-Configs {
    Write-Log "Starting configuration file copying..."
    
    # Get script directory
    $ScriptDir = Split-Path -Parent $MyInvocation.PSCommandPath
    $ConfigsDir = Join-Path $ScriptDir "configs"
    
    if (-not (Test-Path $ConfigsDir)) {
        Write-Log "Configs directory not found at $ConfigsDir" -Level "WARNING"
        return
    }
    
    # Copy Neovim config
    try {
        $NvimSource = Join-Path $ConfigsDir "nvim\init.lua"
        $NvimDest = "$env:LOCALAPPDATA\nvim"
        
        if (Test-Path $NvimSource) {
            Write-Log "Copying Neovim configuration..."
            
            # Create destination directory if it doesn't exist
            if (-not (Test-Path $NvimDest)) {
                New-Item -ItemType Directory -Path $NvimDest -Force | Out-Null
                Write-Log "Created Neovim config directory: $NvimDest"
            }
            
            Copy-Item -Path $NvimSource -Destination "$NvimDest\init.lua" -Force
            Write-Log "Successfully copied Neovim configuration"
        } else {
            Write-Log "Neovim config not found at $NvimSource" -Level "WARNING"
        }
    }
    catch {
        Write-Log "Failed to copy Neovim config: $($_.Exception.Message)" -Level "ERROR"
    }
    
    # Copy WezTerm config
    try {
        $WezTermSource = Join-Path $ConfigsDir "wezterm\wezterm.lua"
        $WezTermDest = "$env:USERPROFILE\.config\wezterm"
        
        if (Test-Path $WezTermSource) {
            Write-Log "Copying WezTerm configuration..."
            
            # Create destination directory if it doesn't exist
            if (-not (Test-Path $WezTermDest)) {
                New-Item -ItemType Directory -Path $WezTermDest -Force | Out-Null
                Write-Log "Created WezTerm config directory: $WezTermDest"
            }
            
            Copy-Item -Path $WezTermSource -Destination "$WezTermDest\wezterm.lua" -Force
            Write-Log "Successfully copied WezTerm configuration"
        } else {
            Write-Log "WezTerm config not found at $WezTermSource" -Level "WARNING"
        }
    }
    catch {
        Write-Log "Failed to copy WezTerm config: $($_.Exception.Message)" -Level "ERROR"
    }
    
    # Copy PowerShell profile
    try {
        $PSProfileSource = Join-Path $ConfigsDir "powershell\Microsoft.PowerShell_profile.ps1"
        $PSProfileDest = Split-Path $PROFILE -Parent
        
        if (Test-Path $PSProfileSource) {
            Write-Log "Copying PowerShell profile with aliases..."
            
            # Create destination directory if it doesn't exist
            if (-not (Test-Path $PSProfileDest)) {
                New-Item -ItemType Directory -Path $PSProfileDest -Force | Out-Null
                Write-Log "Created PowerShell profile directory: $PSProfileDest"
            }
            
            Copy-Item -Path $PSProfileSource -Destination $PROFILE -Force
            Write-Log "Successfully copied PowerShell profile to $PROFILE"
        } else {
            Write-Log "PowerShell profile not found at $PSProfileSource" -Level "WARNING"
        }
    }
    catch {
        Write-Log "Failed to copy PowerShell profile: $($_.Exception.Message)" -Level "ERROR"
    }
    
    # Copy Clink configuration
    try {
        $ClinkSource = Join-Path $ConfigsDir "clink"
        $ClinkDest = "$env:LOCALAPPDATA\clink"
        
        if (Test-Path $ClinkSource) {
            Write-Log "Copying Clink configuration..."
            
            # Create destination directory if it doesn't exist
            if (-not (Test-Path $ClinkDest)) {
                New-Item -ItemType Directory -Path $ClinkDest -Force | Out-Null
                Write-Log "Created Clink config directory: $ClinkDest"
            }
            
            # Copy all Clink files
            Copy-Item -Path "$ClinkSource\*" -Destination $ClinkDest -Force -Recurse
            Write-Log "Successfully copied Clink configuration"
        } else {
            Write-Log "Clink config not found at $ClinkSource" -Level "WARNING"
        }
    }
    catch {
        Write-Log "Failed to copy Clink config: $($_.Exception.Message)" -Level "ERROR"
    }
    
    Write-Log "Configuration file copying completed"
}

# Update all installed software
function Update-AllSoftware {
    param(
        [hashtable]$InstalledPrograms = @{}
    )
    
    Write-Log "Starting update process for all installed software..."
    
    # Check for winget updates first
    try {
        Write-Log "Checking for available winget updates..."
        $AvailableUpdates = winget upgrade --include-unknown
        if ($AvailableUpdates -match "No installed package found") {
            Write-Log "All winget packages are up to date"
        } else {
            Write-Log "Updating winget packages..."
            $UpdateResult = winget upgrade --all --accept-package-agreements --accept-source-agreements
            Write-Log "Winget update completed"
        }
    }
    catch {
        Write-Log "Failed to update winget packages: $($_.Exception.Message)" -Level "ERROR"
    }
    
    # Update npm packages
    try {
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            Write-Log "Checking for npm updates..."
            $OutdatedPackages = npm outdated -g --depth=0 2>&1
            if ($OutdatedPackages -match "Package" -or $OutdatedPackages -match "MISSING") {
                Write-Log "Updating global npm packages..."
                npm update -g
                Write-Log "npm update completed"
            } else {
                Write-Log "All npm packages are up to date"
            }
        }
    }
    catch {
        Write-Log "Failed to update npm packages: $($_.Exception.Message)" -Level "WARNING"
    }
    
    Write-Log "Note: Direct download apps (Koofr, Drime) will be checked for updates..."
}

# Main execution
function Main {
    if ($Update) {
        Write-Log "=== WinKit Update Mode Started ==="
    } else {
        Write-Log "=== WinKit Setup Started ==="
    }
    Write-Log "Log file: $LogFile"
    
    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-Log "This script must be run as Administrator!" -Level "ERROR"
        throw "Administrator privileges required"
    }
    
    # Install winget if needed (before scanning)
    if (-not (Install-Winget)) {
        Write-Log "Failed to install winget. Some installations may fail." -Level "WARNING"
    }
    
    # Scan installed programs
    $InstalledPrograms = Get-InstalledPrograms
    
    # Ensure it's a hashtable
    if ($InstalledPrograms -is [array]) {
        Write-Log "Converting array to hashtable..."
        $temp = @{}
        foreach ($item in $InstalledPrograms) {
            if ($item -is [hashtable]) {
                foreach ($key in $item.Keys) {
                    $temp[$key] = $item[$key]
                }
            }
        }
        $InstalledPrograms = $temp
    }
    
    # If scan only mode, show plan and exit
    if ($ScanOnly) {
        Show-InstallationPlan -InstalledPrograms $InstalledPrograms
        Write-Log "Scan-only mode completed. No changes were made."
        return
    }
    
    # Remove bloatware
    if (-not $SkipBloatwareRemoval) {
        Remove-Bloatware
    } else {
        Write-Log "Skipping bloatware removal (SkipBloatwareRemoval flag set)"
    }
    
    # Install/Update software
    if (-not $SkipSoftwareInstall) {
        if ($Update) {
            Update-AllSoftware -InstalledPrograms $InstalledPrograms
        }
        Install-Software -InstalledPrograms $InstalledPrograms
        Install-DirectDownloads -InstalledPrograms $InstalledPrograms
    } else {
        Write-Log "Skipping software installation (SkipSoftwareInstall flag set)"
    }
    
    # Copy configuration files
    Copy-Configs
    
    if ($Update) {
        Write-Log "=== WinKit Update Completed ==="
    } else {
        Write-Log "=== WinKit Setup Completed ==="
    }
    Write-Log "Please review the log file for any errors or warnings: $LogFile"
    Write-Log "Some applications may require a system restart to function properly."
}

# Execute main function
try {
    Main
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    exit 1
}