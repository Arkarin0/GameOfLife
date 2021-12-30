@echo off
echo Testing: master
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0..\eng\Test-BeforeCheckIn.ps1""" -publish "


echo Testing: Dev
powershell -ExecutionPolicy ByPass -NoProfile -command "& """%~dp0..\eng\Test-BeforeCheckIn.ps1""" -publish -branchname """Dev""" "