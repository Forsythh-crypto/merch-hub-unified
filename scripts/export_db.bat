@echo off
echo Exporting Merch Hub Database...
echo.

REM Check if XAMPP is running
echo Checking XAMPP MySQL service...
netstat -an | findstr :3306 >nul
if %errorlevel% neq 0 (
    echo ERROR: MySQL is not running. Please start XAMPP first.
    pause
    exit /b 1
)

REM Set database name (change this to match your database name)
set DB_NAME=merch_hub
set EXPORT_FILE=merch_hub_database.sql

echo Exporting database: %DB_NAME%
echo Output file: %EXPORT_FILE%
echo.

REM Export database using mysqldump
"C:\xampp\mysql\bin\mysqldump.exe" -u root -p %DB_NAME% > %EXPORT_FILE%

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS: Database exported to %EXPORT_FILE%
    echo.
    echo Next steps:
    echo 1. Copy %EXPORT_FILE% to the scripts/ folder
    echo 2. Commit and push to GitHub
    echo 3. Share with your groupmates
) else (
    echo.
    echo ERROR: Failed to export database
    echo Please check:
    echo - XAMPP MySQL is running
    echo - Database name is correct
    echo - MySQL credentials
)

echo.
pause
