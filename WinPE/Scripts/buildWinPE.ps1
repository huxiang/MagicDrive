# Read Environment Variables
[String]$winPeArch = $Env:WINPE_ARCH

# Debug switch, uncomment to show debug messages
# $DebugPreference = "Continue"

$scriptDir = $(Split-Path -Path $MyInvocation.InvocationName)
$functionScript = $scriptDir + '\buildWinPEFunctions.ps1'
. ("$functionScript")

Clear-Host

$winPeArch = $winPeArch.ToLower()
if ($winPeArch -notin @('x86', 'amd64', 'mix')) {
    Write-Host
    Write-Host "ERROR: WINPE_ARCH can be only 'x86', 'amd64' or 'mix'." -ForegroundColor Red
    Write-Host
    exit
}

Build-WinPE -type $winPeArch
