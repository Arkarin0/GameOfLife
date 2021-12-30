@echo off
echo Testing: Main
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0..\eng\publish-assets.ps1""" -configuration Release -releaseName master -test"


echo Testing: Dev
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0..\eng\publish-assets.ps1""" -configuration Release -branchName Dev -test"