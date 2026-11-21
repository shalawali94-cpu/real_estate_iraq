@echo off
rem Usage: step.bat "commit message"  -> runs all checks, then commits + pushes.
cd /d C:\dev\real_estate_iraq
call check.bat
cd /d C:\dev\real_estate_iraq
echo === commit + push ===
call save.bat %*
echo === ALL DONE ===
