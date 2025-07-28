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
    [switch]$Verbose
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

# Install software using winget
function Install-Software {
    Write-Log "Starting software installation..."
    
    # Software to install with their winget IDs
    $SoftwareList = @(
        @{ Name = "Node.js"; Id = "OpenJS.NodeJS" },
        @{ Name = "Proton Mail"; Id = "ProtonTechnologies.ProtonMail" },
        @{ Name = "Proton Drive"; Id = "ProtonTechnologies.ProtonDrive" },
        @{ Name = "Proton VPN"; Id = "ProtonTechnologies.ProtonVPN" },
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
            Write-Log "Checking if $($Software.Name) is already installed..."
            
            # Check if already installed using winget list
            $InstalledCheck = winget list --id $Software.Id --exact 2>&1
            
            if ($InstalledCheck -match "No installed package found") {
                Write-Log "Installing $($Software.Name)..."
                $Result = winget install --id $Software.Id --accept-package-agreements --accept-source-agreements --silent
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Successfully installed $($Software.Name)"
                } else {
                    Write-Log "Installation of $($Software.Name) failed with exit code: $LASTEXITCODE" -Level "ERROR"
                }
            } else {
                Write-Log "$($Software.Name) is already installed, skipping..."
            }
        }
        catch {
            Write-Log "Failed to process $($Software.Name): $($_.Exception.Message)" -Level "ERROR"
        }
    }
    
    # Install Claude Code via npm
    try {
        Write-Log "Installing Claude Code via npm..."
        # Check if already installed
        $ClaudePath = Get-Command claude -ErrorAction SilentlyContinue
        if ($ClaudePath) {
            Write-Log "Claude Code is already installed"
        } else {
            # Install Claude Code globally via npm
            $NpmResult = npm install -g @anthropic/claude-code 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Successfully installed Claude Code via npm"
            } else {
                Write-Log "Failed to install Claude Code via npm: $NpmResult" -Level "ERROR"
                Write-Log "You may need to install it manually from https://claude.ai/code" -Level "WARNING"
            }
        }
    }
    catch {
        Write-Log "Could not install Claude Code: $($_.Exception.Message)" -Level "WARNING"
    }
    
    Write-Log "Software installation completed"
}

# Install software that requires direct download
function Install-DirectDownloads {
    Write-Log "Starting direct download installations..."
    
    # Create temp directory for downloads
    $TempDir = Join-Path $env:TEMP "WinKit_Downloads"
    if (-not (Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    }
    
    # Install Koofr
    try {
        Write-Log "Downloading Koofr desktop client..."
        $KoofrUrl = "https://app.koofr.net/desktop/download/windows"
        $KoofrInstaller = Join-Path $TempDir "KoofrSetup.exe"
        
        # Download the installer
        Invoke-WebRequest -Uri $KoofrUrl -OutFile $KoofrInstaller -UseBasicParsing
        
        if (Test-Path $KoofrInstaller) {
            Write-Log "Installing Koofr..."
            Start-Process -FilePath $KoofrInstaller -ArgumentList "/S" -Wait
            Write-Log "Koofr installation completed"
        } else {
            Write-Log "Failed to download Koofr installer" -Level "ERROR"
        }
    }
    catch {
        Write-Log "Failed to install Koofr: $($_.Exception.Message)" -Level "ERROR"
    }
    
    # Install Drime
    try {
        Write-Log "Downloading Drime desktop client..."
        # Note: The actual download URL might need to be updated based on Drime's website
        $DrimeUrl = "https://drime.cloud/desktop/download/windows"
        $DrimeInstaller = Join-Path $TempDir "DrimeSetup.exe"
        
        # Download the installer
        Invoke-WebRequest -Uri $DrimeUrl -OutFile $DrimeInstaller -UseBasicParsing
        
        if (Test-Path $DrimeInstaller) {
            Write-Log "Installing Drime..."
            Start-Process -FilePath $DrimeInstaller -ArgumentList "/S" -Wait
            Write-Log "Drime installation completed"
        } else {
            Write-Log "Failed to download Drime installer" -Level "ERROR"
        }
    }
    catch {
        Write-Log "Failed to install Drime: $($_.Exception.Message)" -Level "ERROR"
        Write-Log "You may need to install Drime manually from https://drime.cloud/desktop" -Level "WARNING"
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

# Main execution
function Main {
    Write-Log "=== WinKit Setup Started ==="
    Write-Log "Log file: $LogFile"
    
    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-Log "This script must be run as Administrator!" -Level "ERROR"
        throw "Administrator privileges required"
    }
    
    # Install winget if needed
    if (-not (Install-Winget)) {
        Write-Log "Failed to install winget. Some installations may fail." -Level "WARNING"
    }
    
    # Remove bloatware
    if (-not $SkipBloatwareRemoval) {
        Remove-Bloatware
    } else {
        Write-Log "Skipping bloatware removal (SkipBloatwareRemoval flag set)"
    }
    
    # Install software
    if (-not $SkipSoftwareInstall) {
        Install-Software
        Install-DirectDownloads
    } else {
        Write-Log "Skipping software installation (SkipSoftwareInstall flag set)"
    }
    
    # Copy configuration files
    Copy-Configs
    
    Write-Log "=== WinKit Setup Completed ==="
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