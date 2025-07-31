# PowerShell Profile with Aliases
# This file should be copied to $PROFILE location

# Claude Code alias
Set-Alias -Name cc -Value claude

# Editor aliases
Set-Alias -Name vi -Value nvim
Set-Alias -Name vim -Value nvim

# Git shortcuts
Set-Alias -Name g -Value git

# Common git command functions
function gs { git status }
function gp { git pull }
function gd { git diff }
function ga { git add }
function gco { param($branch) git checkout $branch }
function gcm { param($message) git commit -m $message }
function glog { git log --oneline --graph --decorate }

# Directory navigation
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function home { Set-Location ~ }
function repos { Set-Location ~/repos }

# Enhanced listing
function ll { Get-ChildItem -Force }
function la { Get-ChildItem -Force -Hidden }

# Docker shortcuts
Set-Alias -Name d -Value docker
function dps { docker ps }
function dpsa { docker ps -a }
function di { docker images }

# Python/Node shortcuts
Set-Alias -Name py -Value python
Set-Alias -Name n -Value node

# Quick edit configs
function vimrc { nvim "$env:LOCALAPPDATA\nvim\init.lua" }
function wezconfig { nvim "$env:USERPROFILE\.config\wezterm\wezterm.lua" }
function profile { nvim $PROFILE }

# Useful utilities
function which { param($command) Get-Command $command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source }
function touch { param($file) New-Item -ItemType File -Name $file -Force }
function mkcd { param($dir) New-Item -ItemType Directory -Name $dir -Force; Set-Location $dir }

# Show this profile's aliases
function aliases {
    Write-Host "`nPowerShell Aliases:" -ForegroundColor Green
    Write-Host "  cc       - Claude Code" -ForegroundColor Yellow
    Write-Host "  vi, vim  - Neovim" -ForegroundColor Yellow
    Write-Host "  g        - Git" -ForegroundColor Yellow
    Write-Host "  d        - Docker" -ForegroundColor Yellow
    Write-Host "  py       - Python" -ForegroundColor Yellow
    Write-Host "  n        - Node.js" -ForegroundColor Yellow
    Write-Host "`nGit Functions:" -ForegroundColor Green
    Write-Host "  gs       - git status" -ForegroundColor Yellow
    Write-Host "  gp       - git pull" -ForegroundColor Yellow
    Write-Host "  gd       - git diff" -ForegroundColor Yellow
    Write-Host "  ga       - git add" -ForegroundColor Yellow
    Write-Host "  gco      - git checkout" -ForegroundColor Yellow
    Write-Host "  gcm      - git commit -m" -ForegroundColor Yellow
    Write-Host "  glog     - git log (pretty)" -ForegroundColor Yellow
    Write-Host "`nNavigation:" -ForegroundColor Green
    Write-Host "  ..       - Go up one directory" -ForegroundColor Yellow
    Write-Host "  ...      - Go up two directories" -ForegroundColor Yellow
    Write-Host "  home     - Go to home directory" -ForegroundColor Yellow
    Write-Host "  repos    - Go to ~/repos" -ForegroundColor Yellow
    Write-Host "`nConfig Editing:" -ForegroundColor Green
    Write-Host "  vimrc    - Edit Neovim config" -ForegroundColor Yellow
    Write-Host "  wezconfig- Edit WezTerm config" -ForegroundColor Yellow
    Write-Host "  profile  - Edit PowerShell profile" -ForegroundColor Yellow
    Write-Host "`nUtilities:" -ForegroundColor Green
    Write-Host "  ll       - List all files (detailed)" -ForegroundColor Yellow
    Write-Host "  which    - Find command location" -ForegroundColor Yellow
    Write-Host "  touch    - Create empty file" -ForegroundColor Yellow
    Write-Host "  mkcd     - Make directory and cd into it" -ForegroundColor Yellow
}

# Fix PowerShell colors for better visibility
# This fixes the issue where parameters are hard to see
Set-PSReadLineOption -Colors @{
    Command = 'Yellow'
    Parameter = 'Green'
    Operator = 'Magenta'
    Variable = 'Cyan'
    String = 'Blue'
    Number = 'White'
    Type = 'Gray'
    Comment = 'DarkGray'
}

# Welcome message
Write-Host "PowerShell profile loaded. Type 'aliases' to see available shortcuts." -ForegroundColor Cyan