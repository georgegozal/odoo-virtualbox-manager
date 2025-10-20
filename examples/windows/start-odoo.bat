@echo off
REM ===============================================================
REM Odoo VirtualBox Manager - Quick Start (Windows)
REM ===============================================================

title Odoo VirtualBox Manager

echo.
echo ================================================
echo Odoo VirtualBox Manager - Quick Start
echo ================================================
echo.

REM Change to script directory
cd /d "%~dp0"

REM Go to repository root
cd ..\..

REM Check if Python is installed
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found!
    echo.
    echo Please install Python 3.7+ from https://www.python.org/
    echo.
    pause
    exit /b 1
)

echo [OK] Python found
echo.

REM Check if odoo-restart-windows.py exists
if not exist "scripts\odoo-restart-windows.py" (
    echo [ERROR] Script not found: scripts\odoo-restart-windows.py
    echo.
    echo Make sure you're running this from the correct directory.
    echo.
    pause
    exit /b 1
)

echo [OK] Script found
echo.

REM Default parameters
set DATABASE=swisscapital
set DEV_MODE=xml

REM Show menu
echo Select an option:
echo.
echo 1. Start Odoo (default: %DATABASE%, dev=%DEV_MODE%)
echo 2. Start with custom database
echo 3. Start with module update
echo 4. Exit
echo.

set /p CHOICE="Enter choice (1-4): "

if "%CHOICE%"=="1" goto :START_DEFAULT
if "%CHOICE%"=="2" goto :START_CUSTOM_DB
if "%CHOICE%"=="3" goto :START_WITH_UPDATE
if "%CHOICE%"=="4" goto :EXIT

echo Invalid choice!
pause
exit /b 1

:START_DEFAULT
echo.
echo Starting Odoo with default settings...
echo Database: %DATABASE%
echo Dev mode: %DEV_MODE%
echo.
python scripts\odoo-restart-windows.py -d %DATABASE% --dev %DEV_MODE%
goto :END

:START_CUSTOM_DB
echo.
set /p CUSTOM_DB="Enter database name: "
if "%CUSTOM_DB%"=="" (
    echo Database name cannot be empty!
    pause
    exit /b 1
)
echo.
echo Starting Odoo with database: %CUSTOM_DB%
echo.
python scripts\odoo-restart-windows.py -d %CUSTOM_DB% --dev %DEV_MODE%
goto :END

:START_WITH_UPDATE
echo.
set /p MODULES="Enter modules to update (comma-separated, e.g., sale,stock): "
if "%MODULES%"=="" (
    echo Modules cannot be empty!
    pause
    exit /b 1
)
echo.
echo Starting Odoo with module update: %MODULES%
echo.
python scripts\odoo-restart-windows.py -d %DATABASE% -u %MODULES% --dev %DEV_MODE%
goto :END

:EXIT
echo.
echo Exiting...
exit /b 0

:END
echo.
echo ================================================
echo Odoo stopped
echo ================================================
echo.
pause