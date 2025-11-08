@echo off
echo [104mEE GSC Timer compilation[0m

gsc-tool.exe --mode comp --game t6 --system pc ".\timer.gsc"
COPY ".\compiled\t6\timer.gsc" "%LocalAppData%\Plutonium\storage\t6\scripts\zm\"
