@echo off
echo Testing Nuget packing
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0..\eng\build.ps1""" -pack -c Release -officialSourceBranchName Components-Dev -officialBuildId ManualTest"