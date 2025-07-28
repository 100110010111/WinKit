@echo off
REM Clink startup script with aliases for cmd.exe
REM This file should be run when cmd.exe starts with Clink

REM Claude Code
doskey cc=claude $*

REM Editor aliases
doskey vi=nvim $*
doskey vim=nvim $*

REM Git shortcuts
doskey g=git $*
doskey gs=git status
doskey gp=git pull
doskey gd=git diff
doskey ga=git add $*
doskey gco=git checkout $*
doskey gcm=git commit -m "$*"
doskey glog=git log --oneline --graph --decorate

REM Directory navigation
doskey ..=cd ..
doskey ...=cd ..\..
doskey home=cd /d %USERPROFILE%
doskey repos=cd /d %USERPROFILE%\repos

REM Enhanced listing
doskey ll=dir /a
doskey la=dir /a /h
doskey ls=dir /b

REM Docker shortcuts
doskey d=docker $*
doskey dps=docker ps
doskey dpsa=docker ps -a
doskey di=docker images

REM Python/Node shortcuts
doskey py=python $*
doskey n=node $*

REM Quick edit configs
doskey vimrc=nvim "%LOCALAPPDATA%\nvim\init.lua"
doskey wezconfig=nvim "%USERPROFILE%\.config\wezterm\wezterm.lua"

REM Utilities
doskey which=where $*
doskey touch=type nul ^> $*
doskey clear=cls

REM Show aliases
doskey aliases=doskey /macros

echo Clink aliases loaded. Type 'aliases' to see all shortcuts.