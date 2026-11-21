@echo off
rem Starts everything for local development in ONE Windows Terminal window (tabs):
rem   1) Supabase (starts if it is not running)   2) Backend API   3) Flutter app in Chrome
cd /d "%~dp0"

echo Checking local Supabase...
call supabase status >nul 2>nul
if errorlevel 1 (
  echo Starting local Supabase, please wait...
  call supabase start
)

set SUPA_URL=http://127.0.0.1:54321
set SUPA_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
set API_URL=http://localhost:3000
set FLUTTER_CMD=flutter run -d chrome --dart-define=SUPABASE_URL=%SUPA_URL% --dart-define=SUPABASE_ANON_KEY=%SUPA_KEY% --dart-define=API_BASE_URL=%API_URL%

where wt >nul 2>nul
if errorlevel 1 (
  echo Windows Terminal not found, opening separate windows...
  start "Backend" cmd /k "cd /d %~dp0backend && npm run dev"
  start "Flutter" cmd /k "cd /d %~dp0mobile && %FLUTTER_CMD%"
  goto :eof
)

wt -w 0 new-tab --title Backend -d "%~dp0backend" cmd /k "npm run dev" ; new-tab --title Flutter -d "%~dp0mobile" cmd /k "%FLUTTER_CMD%"
