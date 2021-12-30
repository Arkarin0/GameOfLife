@echo off
echo Testing Nuget packing
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0..\eng\Test-BeforeCheckIn.ps1""" -pack -branchname """Dev""" "