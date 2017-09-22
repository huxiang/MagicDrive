@ECHO off

REM Echo Note! Make sure you have run this batch file "as administrator" before continuing.
net session >nul 2>&1
IF ERRORLEVEL 1 (
    ECHO You must right-click and select
    ECHO.
    ECHO "RUN AS ADMINISTRATOR"  to run this batch file.
    ECHO.
    ECHO Exiting...
    ECHO.
    PAUSE
    EXIT /D
)

IF /I %PROCESSOR_ARCHITECTURE%==amd64 (
    SET ADKROOT=C:\Program Files ^(x86^)\Windows Kits\10\Assessment and Deployment Kit
) ELSE (
    SET ADKROOT=C:\Program Files\Windows Kits\10\Assessment and Deployment Kit
)

CALL "%ADKROOT%\Deployment Tools\DandISetEnv.bat"
PowerShell.exe -executionpolicy remotesigned -File "%~dp0\buildWinPE.ps1"

PAUSE
