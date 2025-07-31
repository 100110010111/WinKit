# Quick fix for PowerShell parameter visibility issue
# This script doesn't require admin privileges

Write-Host "Fixing PowerShell colors..." -ForegroundColor Cyan

# Set better colors for visibility
Set-PSReadLineOption -Colors @{
    Command = 'Yellow'
    Parameter = 'Green'
    Operator = 'Cyan'
    Variable = 'Magenta'
    String = 'White'
    Number = 'White'
    Type = 'Yellow'
    Comment = 'DarkGreen'
    Keyword = 'Green'
    ContinuationPrompt = 'Gray'
    Default = 'White'
}

Write-Host "Colors fixed for current session!" -ForegroundColor Green
Write-Host ""
Write-Host "To make this permanent, run:" -ForegroundColor Yellow
Write-Host "  Copy-Item configs\powershell\Microsoft.PowerShell_profile.ps1 `$PROFILE -Force" -ForegroundColor White
Write-Host ""
Write-Host "Then restart PowerShell or run:" -ForegroundColor Yellow
Write-Host "  . `$PROFILE" -ForegroundColor White