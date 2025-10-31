@echo off
setlocal enabledelayedexpansion

rem ===== ARGUMENT CHECK =====
if "%~1"=="" (
    echo Usage: build_timer.bat ^<versiontag^>
    echo Example: build_timer.bat V22
    exit /b 1
)

set VERSIONTAG=%~1
set INFILE=timer.gsc
set OUTFILE=T6EE_%VERSIONTAG%.gsc
set OUTPUT_DIR=%LocalAppData%\Plutonium\storage\t6\scripts\zm

rem ===== HEADER =====
echo [44;97mEE GSC Timer compilation [43;30m[%VERSIONTAG%][0m

rem ===== PREPROCESS =====
if not exist "%INFILE%" (
    echo Error: Input file not found: %INFILE%
    exit /b
)

dotnet preprocessor\bin\Release\net9.0\preprocessor.dll "%INFILE%" "%OUTFILE%" --version=%VERSIONTAG%
if errorlevel 1 (
    echo Preprocessor failed!
    exit /b
)

rem ===== COMPILE =====
if not exist ".\compiled\t6" mkdir ".\compiled\t6"
gsc-tool.exe -m comp -g t6 -s pc "%OUTFILE%"
if errorlevel 1 (
    echo GSC compilation failed!
    echo.
    exit /b
)

rem ===== DEPLOY =====
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if exist ".\compiled\t6\%OUTFILE%" (
    move /Y ".\compiled\t6\%OUTFILE%" "%OUTPUT_DIR%\%OUTFILE%" >nul
    echo %OUTFILE% copied to: %OUTPUT_DIR%
)
