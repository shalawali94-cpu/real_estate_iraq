@echo off
rem Usage: save.bat "commit message"   (commits everything and pushes to GitHub)
cd /d "%~dp0"
if "%~1"=="" (
  echo Please give a message: save.bat "what I did"
  goto :eof
)
git add -A
git commit -m "%~1"
git push
