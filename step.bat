@echo off
rem One-shot helper: publish local test drafts, run all checks, then commit + push.
cd /d C:\dev\real_estate_iraq
echo === 1/3 publish local test drafts ===
docker exec -i supabase_db_real_estate_iraq psql -U postgres -d postgres -At < supabase\dev\publish_drafts.sql
echo === 2/3 checks ===
call check.bat
cd /d C:\dev\real_estate_iraq
echo === 3/3 commit + push ===
call save.bat "Phase 5: my properties screen, draft status labels, dev publish script"
echo === ALL DONE ===
