@ECHO off

SETLOCAL

REM ***********************************************************
REM   MagicDrive WinPE creation script
REM   -  Before running this script, set the below parameters
REM   -  Note: There must not be any whitespace characters
REM            after the '=' on each set variable line
REM ***********************************************************

REM Directory path in which the WinPE images are saved
REM Only local paths are supported
SET OUTPUT_PATH=D:\

REM Supported machine architect by MagicDrive WinPE
REM Valid values can be:
REM     - "x86": for 32bit machines
REM     - "amd64": for 64bit machines
REM     - "mix": for both 32bit and 64bit machines
SET WINPE_ARCH=mix


REM --------------------------
REM DO NOT modify the script below
REM --------------------------
"%~dp0Scripts\BuildMagicDrivePE.cmd"
