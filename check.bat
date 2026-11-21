@echo off
rem Runs all checks in one go: Flutter analyze + tests, backend typecheck + tests.
cd /d "%~dp0mobile"
call flutter gen-l10n
call flutter analyze
call flutter test
cd /d "%~dp0backend"
call npm run typecheck
call npm test
echo.
echo ===== CHECKS FINISHED =====
