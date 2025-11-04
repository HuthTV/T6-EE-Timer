@echo off
echo [104mEE GSC Timer compilation[0m

gsc-tool.exe -m comp -g t6 -s pc ".\timer.gsc"
COPY ".\compiled\t6\timer.gsc" "%LocalAppData%\Plutonium\storage\t6\scripts\zm\"
