Param (
    [String]$NetworkEnabled = 'true'
)

. .\setupFunctions.ps1
$ErrorActionPreference = "SilentlyContinue"
$host.ui.RawUI.WindowTitle = $windowTitle

if ($NetworkEnabled -imatch 'false') {
    $networkSupport = $false
} else {
    $networkSupport = $true
}

Write-Host
Write-Host 'Scanning file system drives...'
$fsDrives = Get-FSDrives
$fsPath = (Get-Location).Path

if ($networkSupport) {
    # Read config from <uInstaller>:\osimages\Win64\OSImageFileServers.csv first
    Import-OSImageServers -ConfigFilePath $($usbVirtualDrive + ':\' + $osimageServerConfigFile)

    # Then if any config files found in drive root, read them to overwrite the initial config
    foreach ($fsName in (Get-PSDrive -PSProvider FileSystem).Name) {
        if ($fsName -eq $usbVirtualDrive) {
            # Skip the initial config now
            continue
        }

        Import-OSImageServers -ConfigFilePath $($fsName + ':\' + $osimageServerConfigFile)
    }

    if ($fileServers.Count -gt 0) {
        Write-Host
        Write-Host 'Mount shared folders on network:'
        $succeed = Mount-SharedFolders -FileServers $fileServers

        if (-not $succeed) {
            Write-Host
            Write-Host -NoNewline 'Press any key to continue...'
            $null = $Host.UI.RawUI.ReadKey(“NoEcho,IncludeKeyDown”)
            Write-Host
        }

        Write-Host
        Write-Host 'Rescanning file system drives...'
        $fsDrives = Get-FSDrives
    }
}

$searchDrivers = @()
$searchDrivers += $fsDrives.USBDrive.Name
$searchDrivers += $fsDrives.LocalDrive.Name
$searchDrivers += $fsDrives.NetDrive.Name
foreach ($driveName in $searchDrivers) {
    $searchPath = $driveName + $toolFolder
    if (Test-Path $searchPath) {
        $searchResult = Get-ChildItem -Path $searchPath -Filter $toolIndexFile -Recurse
        if ($searchResult -ne $null) {
            $toolsIndexPath = $searchResult[0].DirectoryName
            break
        }
    }
}

$useUSBfirst = $false
if ($usbVirtualDrive -in $fsDrives['VirtualDrive'].Drive) {
    $newFSPath = $usbVirtualDrive + ':\'
    ($menuDesc, $menuItems) = Get-ISOSubMenu -ISOPath $newFSPath

    if ($menuItems.Count -gt 0) {
        $useUSBfirst = $true
        Show-Menu -FSPath $newFSPath -MenuType 'List-ISO' -MenuDesc $menuDesc -MenuItems $menuItems
    }

    $msg = @"

    There's no valid OS image file or folder under <DriveLabel:$usbImageDeviceLabel>:$usbImageFolder

    Press any key to the storage drives selection page...
"@

} else {
    $msg = @"

    Unable to determine <DriveLabel:$usbImageDeviceLabel>:$usbImageFolder

    Press any key to the storage drives selection page...
"@

}

if (-not $useUSBfirst) {
    Clear-Host
    Write-Host -NoNewline $msg
    $null = $Host.UI.RawUI.ReadKey(“NoEcho,IncludeKeyDown”)

    ($menuDesc, $menuItem) = Get-FSDriveSubMenu -FSDrives $fsDrives
    Show-Menu -FSPath $fsPath -MenuType 'Storage-Drives' -MenuDesc $menuDesc -MenuItems $menuItem
}
