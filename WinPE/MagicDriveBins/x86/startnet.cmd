@echo off & setLocal enabledelayedexpansion
cls
goto GETNETWORKOPT

:ERRNETWORKOPT
echo Invalid option, try again.

:GETNETWORKOPT
echo.
set enableNetwork=y
set /p "enableNetwork=Start with Network Support? [y/n] (y): "

if %enableNetwork%==y goto WITHNET
if %enableNetwork%==Y goto WITHNET
if %enableNetwork%==n goto WITHOUTNET
if %enableNetwork%==N goto WITHOUTNET
goto ERRNETWORKOPT

:WITHNET
echo.
echo Initializing WinPE Network...
wpeinit >NUL 2>&1
echo.
echo Starting PowerShell...
Powershell.exe -executionpolicy remotesigned -File setup.ps1 -NetworkEnabled true
goto END

:WITHOUTNET
echo.
echo Starting PowerShell...
Powershell.exe -executionpolicy remotesigned -File setup.ps1 -NetworkEnabled false
goto END

:END
exit
