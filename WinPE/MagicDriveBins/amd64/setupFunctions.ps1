$windowTitle = 'MagicDrive Windows 64bit Installer'
$usbImageDeviceLabel = 'MagicDrive'
$usbImageFolder = '\osimages\Windows\'
$usbVirtualDrive = 'USB-Repo'
$osimageServerConfigFile = 'OSImageFileServers.csv'
$toolFolder = '\PortableTools\'
$toolIndexFile = 'PortableTools-x64.csv'
$toolsLauncher = $env:SystemRoot + '\system32\toolsLauncher.ps1'

$toolsIndexPath = $null
$networkSupport = $true
$fileServers = @{}
$fsDrives = @{}
$peMemDrive = $null

$menuHistory = @{}
$menuIndex = 0
$stgDriveMenuIndex = $null


function Get-UserSelection {
    Param (
        [String]$ScopeString,
        [Array]$ScopeList
    )

    $choice = $null
    do {
        if ($choice -ne $null) {
            Write-Host "  ERROR: [$choice] is not valid! Please try it again!`n"
        }
        $choice = $(Read-Host "Select an item from above [$ScopeString]").Trim()
        if ($choice -match '^[0-9]+$') {
            [Int]$choice = $choice
        } else {
            $choice = $choice.ToLower()
        }
    } until ($choice -in $ScopeList)

    return $choice
}  # Function Get-UserSelection end


function Get-CDDrives {
    # http://powershell.com/cs/blogs/tips/archive/2009/05/07/finding-cd-rom-drives.aspx
    # https://msdn.microsoft.com/en-us/library/aa394173(v=vs.85).aspx, see "DriveType" section
    $cdDrives = (Get-WmiObject win32_logicaldisk -filter 'DriveType=5').DeviceID  -creplace ':$',''
    
    if ($cdDrives -eq $null) {
        $cdDrives = @()
    }

    return $cdDrives
}  # Function Get-CDDrives end


function Get-USBDrives {
    # https://msdn.microsoft.com/en-us/library/aa394173(v=vs.85).aspx, see "DriveType" section
    $removableDrives = (Get-WmiObject win32_logicaldisk -filter 'DriveType=2').DeviceID -creplace ':$',''
    $usbDrives = @()

    if ($removableDrives -ne $null) {
        foreach ($removableDrive in $removableDrives) {
            if ($removableDrive -notin @('A', 'B')) {
                # Exclude floppy drives
                $usbDrives += $removableDrive
            }
        }
    }

    return $usbDrives
}  # Function Get-USBDrives end


function Get-NetDrives {
    # https://msdn.microsoft.com/en-us/library/aa394173(v=vs.85).aspx, see "DriveType" section
    $netDrives = (Get-WmiObject win32_logicaldisk -filter 'DriveType=4').DeviceID  -creplace ':$',''

    if ($netDrives -eq $null) {
        $netDrives = @()
    }

    return $netDrives
}  # Function Get-NetDrives end


function Get-LocalDrives {
    $localDrives = @()

    foreach ($vol in (Get-Volume)) {
        if ($vol.DriveType -eq 'Fixed') {
            $localDrives += $vol.DriveLetter
        }
    }

    return $localDrives
}  # Function Get-LocalDrives end


function Get-FSDrives {
    $fsDrives = @{
        'VirtualDrive' = @();
        'LocalDrive' = @();
        'NetDrive' = @();
        'USBDrive' = @()
    }

    $localDrives = Get-LocalDrives
    $cdDrives = Get-CDDrives
    $netDrives = Get-NetDrives
    $usbDrives = Get-USBDrives

    if ($peMemDrive -eq $null) {
        # The PE Memory disk drive should only be acquired once before calling any Set-Location
        $peMemDrive = (Get-Location).Drive.Name
    }

    if ($usbImageDeviceLabel -in (Get-Volume).FileSystemLabel) {
        # Bear kids may plug two or more USB devices on one machine
        $usbImageDrives = (Get-Volume -FileSystemLabel $usbImageDeviceLabel).DriveLetter

        foreach ($usbImageDrive in $usbImageDrives) {
            $usbImagePath = $usbImageDrive + ':' + $usbImageFolder
            if (Test-Path $usbImagePath) {
                if ($usbVirtualDrive -notin (Get-PSDrive -PSProvider FileSystem).Name) {
                    New-PSDrive -Name $usbVirtualDrive -PSProvider FileSystem -Root $usbImagePath -Scope 'script' > $null
                }
                break
            }
        }
    }

    $nonUSBVirtualDrives = @()
    foreach ($fsDrive in (Get-PSDrive -PSProvider FileSystem)) {
        $tmpItem = New-Object System.Object
        $tmpItem |Add-Member -MemberType NoteProperty -Name 'Name' -Value $($fsDrive.Name + ':\')
        $tmpItem |Add-Member -MemberType NoteProperty -Name 'Drive' -Value $fsDrive.Name

        if ($fsDrive.Name -in (Get-Volume).DriveLetter) {
            $tmpItem |Add-Member -MemberType NoteProperty -Name 'Label' -Value (Get-Volume $fsDrive.Name).FileSystemLabel
        } else {
            $tmpItem |Add-Member -MemberType NoteProperty -Name 'Label' -Value ''
        }

        if ($fsDrive.DisplayRoot.Length -gt 0) {
            $tmpItem |Add-Member -MemberType NoteProperty -Name 'Root' -Value $fsDrive.DisplayRoot
        } else {
            $tmpItem |Add-Member -MemberType NoteProperty -Name 'Root' -Value $fsDrive.Root
        }

        if ($fsDrive.Name -in $virtualDrives) {
            $fsDrives['VirtualDrive'] += $tmpItem
        } elseif ($fsDrive.Name -in $localDrives) {
            $fsDrives['LocalDrive'] += $tmpItem
        } elseif ($fsDrive.Name -in $netDrives) {
            $fsDrives['NetDrive'] += $tmpItem
        } elseif ($fsDrive.Name -in $usbDrives) {
            $fsDrives['USBDrive'] += $tmpItem
        } elseif ($fsDrive.Name -in $cdDrives -or $fsDrive.Name -in @('A', 'B', $peMemDrive)) {
            # Skip CD/DVD, floppy drives and WinPE memory disk
            continue
        } elseif ($fsDrive.Name -eq $usbVirtualDrive) {
            $fsDrives['VirtualDrive'] += $tmpItem
        } else {
            $nonUSBVirtualDrives += $tmpItem
        }
    }
    # To ensure USB virtual drive comes first in the virtual drives list
    $fsDrives['VirtualDrive'] += $nonUSBVirtualDrives

    return $fsDrives
}  # Function Get-FSDrives end


function Import-OSImageServers {
    Param (
        [String]$ConfigFilePath
    )

    if (Test-Path $ConfigFilePath) {
        try {
            $csvData = Import-Csv -Path $ConfigFilePath -ErrorAction Stop
        } catch {
            # If the CSV file format is not correct, just skip it silently
            return
        }

        foreach ($serverInfo in $csvData) {
            if ($serverInfo.ShareFolder -notmatch '^\\\\[A-Za-z0-9\.\-]+\\[^\\]+') {
                # Skip if the ShareFolder is not valid
                continue
            }
            $shareFolder = $serverInfo.ShareFolder

            if ($fileServers.$shareFolder -eq $null) {
                $fileServerHt = @{
                    'Username' = 'anonymous';
                    'Password' = '';
                    'ImagePath' = @()
                }
                $fileServers.Add($shareFolder, $fileServerHt)
            }
            $fileServerHt = $fileServers.$shareFolder

            if ($serverInfo.Username -match '^\s*$') {
                $fileServerHt.Username = 'anonymous'
            } else {
                $fileServerHt.Username = $serverInfo.Username
            }

            $fileServerHt.Password = $serverInfo.Password

            foreach ($newPath in $($serverInfo.ImagePath -split ';')) {
                if ($newPath -notin $fileServerHt.ImagePath) {
                    $fileServerHt.ImagePath += $newPath
                }
            }

            $fileServers.$shareFolder = $fileServerHt
        }
    }
}  # Function Import-OSImageServers end


function Input-NewOSImageServer {
    Param (
        [HashTable]$PreviousInput
    )

    if ($PreviousInput.Count -ne 0) {
        [String]$preShareFolder = $PreviousInput.Keys[0]
        $preUsername = $PreviousInput.$preShareFolder.Username
    }

    Write-Host 'Please provide information about the share folder below'

    $shareFolder = $null
    do {
        if ($shareFolder -ne $null) {
            Write-Host "  ERROR: Invalid UNC path [$shareFolder], it should be something like \\<IP_or_FQDN>\<Share_Name>.`n"
        }

        $promptMsg = 'Share Folder UNC'
        if ($preShareFolder -ne $null) {
            $promptMsg += " ($preShareFolder)"
        }

        $shareFolder = $(Read-Host $promptMsg).Trim()

        if ($preShareFolder -ne $null -and $shareFolder -match '^\s*$') {
            $shareFolder = $preShareFolder
        }
    } until ($shareFolder -match '^\\\\[A-Za-z0-9\.\-]+\\.+')

    $promptMsg = 'Username'
    if ($preUsername -ne $null) {
        $promptMsg += " ($preUsername)"
    }

    $username = $(Read-Host $promptMsg).Trim()
    if ($username -match '^\s*$') {
        if ($preUsername -ne $null) {
            $username = $preUsername
        } else {
            $username = 'anonymous'
        }
    }

    $password = Read-Host 'Password' -AsSecureString
    $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

    $fileServer = @{
        $shareFolder = @{
            'Username' = $username;
            'Password' = $password;
            'ImagePath' = @()
        }
    }

    return $fileServer
}  # Function Input-NewOSImageServer end


function Find-UnusedDrives {
    Param (
        [Bool]$ReveseAlphabetical = $true
    )

    $driverLetters = 67..90 |foreach-object { [char]$_ }
    if ($ReveseAlphabetical) {
        [Array]::Reverse($driverLetters)
    }

    $unusedDrives = @()
    $usedDrivers = (Get-PSDrive -PSProvider FileSystem).Name
    foreach ($driverLetter in $driverLetters) {
        if ($driverLetter -notin $usedDrivers) {
            $unusedDrives += $driverLetter
        }
    }
    
    return $unusedDrives
}  # Function Find-UnusedDrives end


function Mount-SharedFolders {
    Param (
        [HashTable]$FileServers
    )

    $unusedDrives = Find-UnusedDrives

    $result = $true
    $driveIndex = -1
    foreach ($shareFolder in $FileServers.keys) {
        if ($shareFolder -in $(Get-PSDrive -PSProvider FileSystem).DisplayRoot) {
            # If the shared folder has already been mounted, skip it
            continue
        }

        $driveIndex ++
        if ($unusedDrives[$driveIndex] -eq $null) {
            # No available driver letter to be used
            return
        }

        $drive = $unusedDrives[$driveIndex]
        $username = $FileServers.$shareFolder.Username
        $password = ConvertTo-SecureString –String $FileServers.$shareFolder.Password –AsPlainText -Force

        $credential = New-Object -TypeName System.Management.Automation.PSCredential –ArgumentList $username, $password
        
        $msg = '  * Mounting [{0}]...' -f $shareFolder
        Write-Host -NoNewline $msg
        try {
            New-PSDrive -Name $drive -PSProvider FileSystem -Root $shareFolder -Credential $credential -Persist -Scope 'script' -ErrorAction Stop > $null
        } catch {
            Write-Host 'Failed!' -ForegroundColor Red

            Write-Host "    ERROR: $_"
            $result = $false
            continue
        }
        Write-Host 'Succeed!' -ForegroundColor Green

        if ($FileServers.$shareFolder.ImagePath.Count -eq 0) {
            # If no ImagePath specified, skip the virtual drive mapping phase
            continue
        }

        $shareHost = [String][Regex]::match($shareFolder, '^\\\\([A-Za-z0-9\.\-]+)\\.+').Groups[1].Value
        if ($shareHost -notmatch '^\d') {
            # For non-IP address, using short hostname as prefix
            $virtualDrivePrefix = [String][Regex]::match($shareHost, '^([^\.]+)')
        } else {
            # For IP address, directly using it as prefix
            $virtualDrivePrefix = $shareHost
        }

        $virtualDrivePrefix += '-Repo'
        for ($imagePathIndex = 0; $imagePathIndex -lt $FileServers.$shareFolder.ImagePath.Count; $imagePathIndex ++) {
            $virtualDriveName = $virtualDrivePrefix + $($imagePathIndex.ToString())
            $rootPath = $drive + ':' + $FileServers.$shareFolder.ImagePath[$imagePathIndex]

            New-PSDrive -Name $virtualDriveName -PSProvider FileSystem -Root $rootPath -Scope 'script' > $null
        }
    }

    return $result
}  # Function Mount-SharedFolders end


function Get-FriendlySize {
    Param (
        [Decimal]$SizeInByte
    )

    if ($($SizeInByte / 1PB) -gt 1) {
        $friendlySize = "{0:N2} PB" -f $($SizeInByte / 1PB)
    } elseif ($($SizeInByte / 1TB) -gt 1) {
        $friendlySize = "{0:N2} TB" -f $($SizeInByte / 1TB)
    } elseif ($($SizeInByte / 1GB) -gt 1) {
        $friendlySize = "{0:N2} GB" -f $($SizeInByte / 1GB)
    } elseif ($($SizeInByte / 1MB) -gt 1) {
        $friendlySize = "{0:N2} MB" -f $($SizeInByte / 1MB)
    } elseif ($($SizeInByte / 1KB) -gt 1) {
        $friendlySize = "{0:N2} KB" -f $($SizeInByte / 1KB)
    } else {
        $friendlySize = $SizeInByte.ToString() + ' Bytes'
    }

    return $friendlySize
}  # Function Get-FriendlySize end


function Get-ISOSubMenu {
    Param (
        [String]$ISOPath
    )

    $menuDesc = @"
Directories and ISO Files
-------------------------
You can select a directory to enter it, or an ISO file to install Windows from it.

Note: Windows Vista and later versions are supported, only Windows 64bit images are supported.

Items under [$ISOPath]:
"@

    $dirItems = Get-ChildItem $ISOPath
    $menuItems = @()
    foreach ($item in $dirItems) {
        $itemObj = New-Object System.Object

        if ($item.Mode -match '^d') {
            $itemDesc = @('<DIR>', '', $item.Name)
            $itemAction = 'LISTISO'
        } elseif ($item.Name -imatch '\.iso$') {
            $fileSize = Get-FriendlySize -SizeInByte $item.Length
            $itemDesc = @('<ISO>', $fileSize, $item.Name)
            $itemAction = 'MOUNTISO'
        } else {
            # All other files besides directory and *.iso are ignored
            continue
        }

        $itemObj |Add-Member -MemberType NoteProperty -Name 'Name' -Value $item.Name
        $itemObj |Add-Member -MemberType NoteProperty -Name 'Action' -Value $itemAction
        $itemObj |Add-Member -MemberType NoteProperty -Name 'Description' -Value $itemDesc
        $menuItems += $itemObj
    }

    return ($menuDesc, $menuItems)
}  # Function Get-ISOSubMenu end


function Get-FSDriveSubMenu {
    Param (
        [HashTable]$FSDrives
    )

    $menuDesc = @"
Storage Drives
--------------
Please select the location of the ISO file you want to use.

Available storage drives:
"@

    $menuItems = @()
    $fsDriveTypes = @('VirtualDrive', 'LocalDrive', 'NetDrive', 'USBDrive')
    foreach ($fsDriveType in $fsDriveTypes) {
        if ($FSDrives[$fsDriveType].Count -gt 0) {
            foreach ($fsDrive in $($FSDrives[$fsDriveType])) {
                $driveName = $fsDrive.Drive
                if ($driveName.Length -eq 1) {
                    $driveName = 'Drive ' + $driveName
                }
                $itemDesc = @($driveName, $fsDriveType, $fsDrive.Label, $fsDrive.Root)

                $itemObj = New-Object System.Object
                $itemObj |Add-Member -MemberType NoteProperty -Name 'Name' -Value $($fsDrive.Name)
                $itemObj |Add-Member -MemberType NoteProperty -Name 'Action' -Value 'LISTISO'
                $itemObj |Add-Member -MemberType NoteProperty -Name 'Description' -Value $itemDesc
                $menuItems += $itemObj
            }
        }
    }

    if ($networkSupport) {
        $addNetDriveMenuText = '<Add a Shared Folder as NetDrive>'
        $addNetDriveObj = New-Object System.Object
        $addNetDriveObj |Add-Member -MemberType NoteProperty -Name 'Action' -Value 'ADDNETDRIVE'
        $addNetDriveObj |Add-Member -MemberType NoteProperty -Name 'Description' -Value $addNetDriveMenuText
        $menuItems += $addNetDriveObj
    }

    return ($menuDesc, $menuItems)
}  # Function Get-FSDriveSubMenu end


function Show-Menu {
    Param (
        [String]$FSPath,
        [String]$MenuType,
        [String]$MenuDesc,
        [Array]$MenuItems
    )

    $menuObj = New-Object System.Object
    $menuObj |Add-Member -MemberType NoteProperty -Name 'FSPath' -Value $FSPath
    $menuObj |Add-Member -MemberType NoteProperty -Name 'MenuDesc' -Value $MenuDesc
    $menuObj |Add-Member -MemberType NoteProperty -Name 'MenuItems' -Value $MenuItems
    
    if ($menuHistory[$menuIndex] -eq $null) {
        $menuHistory[$menuIndex] += $menuObj
    } else {
        $menuHistory[$menuIndex] = $menuObj
    }

    if (($MenuType -eq 'Storage-Drives') -and ($stgDriveMenuIndex -eq $null)) {
        # When call the 'Storage-Drives' menu for the 1st time, remember its index
        $stgDriveMenuIndex = $menuIndex
    }

    $menuActionHt = @{
        'm' = 'MAINMENU';
        'b' = 'PREMENU';
        's' = 'LISTFSDRIVE';
        't' = 'TOOLS';
        'c' = 'SYSCMD';
        'r' = 'REBOOT'
    }
    $choiceScopeString = $null
    $choiceScopeList = @()

    Clear-Host
    Write-Host $MenuDesc
    $widthTable = @()
    if ($MenuItems.Count -gt 0) {
        $widthTable += $($MenuItems.Count.ToString()).Length + 1    # Add 1 for ')'
    
        for ($i = 0; $i -lt $MenuItems.Count; $i++) {
            if (($MenuItems[$i].Description.Count -eq 1) -and ($MenuItems[$i].Description[0] -match '^<.+>$')) {
                continue
            }

            for ($j = 0; $j -lt $MenuItems[$i].Description.Count; $j++) {
                if ($widthTable[$j + 1] -eq $null) {
                    $widthTable += $MenuItems[$i].Description[$j].Length
                } elseif ($widthTable[$j + 1] -lt $MenuItems[$i].Description[$j].Length) {
                    $widthTable[$j + 1] += $MenuItems[$i].Description[$j].Length
                }
            }
        }

        for ($i = 0; $i -lt $MenuItems.Count; $i++) {
            $id = $i + 1
            $menuActionHt[$id] = $MenuItems[$i].Action

            $indexStr = $id.ToString() + ')'
            $item = "  {0, $($widthTable[0])} " -f $indexStr

            if (($MenuItems[$i].Description.Count -eq 1) -and ($MenuItems[$i].Description -match '^<.+>$')) {
                $item += $MenuItems[$i].Description
            } else {
                for ($j = 0; $j -lt $MenuItems[$i].Description.Count; $j++) {
                    $tmpDesc = $MenuItems[$i].Description[$j]
                    $item = "{0}{1, -$($widthTable[$j + 1])}  " -f $item,$tmpDesc
                }
            }
            Write-Host $item
        }
        Write-Host

        if ($MenuItems.Count -eq 1) {
            $choiceScopeString = '1'
            $choiceScopeList = @(1)
        } else {
            $choiceScopeString = "1-$($MenuItems.Count)"
            $choiceScopeList = @(1..$($MenuItems.Count))
        }
    } else {
        $widthTable += 2      # The index colume should be 'X)' at least
        Write-Host '  <No available item found!>'
        Write-Host
    }

    Write-Host 'Other Tasks:'
    # 't' option is not available when tools index file is not found
    if ($toolsIndexPath -ne $null) {
        Write-Host '  t) Third-party tools'
        if ($choiceScopeString -eq $null) {
            $choiceScopeString = 't'
        } else {
            $choiceScopeString += ', t'
        }
        $choiceScopeList += 't'
    }

    Write-Host '  c) Start WinPE system CMD here'
    Write-Host '  r) Reboot machine'
    if ($choiceScopeString -eq $null) {
        $choiceScopeString = 'c, r'
    } else {
        $choiceScopeString += ', c, r'
    }
    $choiceScopeList += 'c'
    $choiceScopeList += 'r'

    # 's' option is not available on the storage drives selection page
    if ($MenuType -ne 'Storage-Drives') {
        Write-Host
        Write-Host '  s) Show all storage drives'
        $choiceScopeString += ', s'
        $choiceScopeList += 's'
    }

    # 'm' and 'b' options are olny available on non-main menu
    if ($menuIndex -ne 0) {
        if ($MenuType -eq 'Storage-Drives') {
            Write-Host
        }
        Write-Host '  m) Main menu'
        Write-Host '  b) Back to the previous menu'
        $choiceScopeString += ', m, b'
        $choiceScopeList += 'm'
        $choiceScopeList += 'b'
    }
    Write-Host

    do {
        $choice = Get-UserSelection -ScopeString $choiceScopeString -ScopeList $choiceScopeList
        $changeMenu = $true
        
        switch ($($menuActionHt[$choice])) {

            MAINMENU {
                $menuIndex = 0
                Show-Menu -FSPath $($menuHistory[$menuIndex].FSPath) -MenuDesc $($menuHistory[$menuIndex].MenuDesc) -MenuItems $($menuHistory[$menuIndex].MenuItems)
            }

            PREMENU {
                $menuIndex --
                Show-Menu -FSPath $($menuHistory[$menuIndex].FSPath) -MenuDesc $($menuHistory[$menuIndex].MenuDesc) -MenuItems $($menuHistory[$menuIndex].MenuItems)
            }

            TOOLS {
                Set-Location $toolsIndexPath
                # Start PowerShell instance in cmd to get the same style with the main Window
                Start-Process cmd.exe -ArgumentList "/c Powershell.exe -executionpolicy remotesigned -File $toolsLauncher -indexFile $toolIndexFile"
                Write-Host 'Third-party Tools Launcher started.'
                Write-Host
                $changeMenu = $false
            }

            SYSCMD {
                Set-Location $FSPath
                Start-Process cmd.exe
                Write-Host 'WinPE system Command Prompt started.'
                Write-Host
                $changeMenu = $false
            }

            REBOOT {
                Write-Host 'Rebooting...'
                wpeutil reboot
            }

            LISTFSDRIVE {
                if ($stgDriveMenuIndex -eq $null) {
                    # When call the 'Storage-Drives' menu for the 1st time from other menu, increase menuIndex first
                    $menuIndex ++
                } else {
                    # Then call the 'Storage-Drives' menu at other places, use the menu in the 1st call
                    $menuIndex = $stgDriveMenuIndex
                }

                ($newMenuDesc, $newMenuItems) = Get-FSDriveSubMenu -FSDrives $fsDrives
                Show-Menu -FSPath $FSPath -MenuType 'Storage-Drives' -MenuDesc $newMenuDesc -MenuItems $newMenuItems
            }

            LISTISO {
                $menuIndex ++

                $object = $MenuItems[$choice - 1].Name
                if ($object -match ':') {
                    $newFSPath = $object
                } else {
                    $newFSPath = $FSPath + $object + '\'
                }

                ($newMenuDesc, $newMenuItems) = Get-ISOSubMenu -ISOPath $newFSPath
                Show-Menu -FSPath $newFSPath -MenuType 'List-ISO' -MenuDesc $newMenuDesc -MenuItems $newMenuItems
            }

            MOUNTISO {
                $isoVirtualPath = $FSPath + $($MenuItems[$choice - 1].Name)
                
                try {
                    # Virtual drive is not supported by Mount-DiskImage command...
                    Set-Location $FSPath -ErrorAction Stop

                    $driveRoot = $pwd.Drive.Root
                    if ($driveRoot -notmatch '\\$') {
                        $driveRoot += '\'
                    }

                    $currentLocation = $pwd.Drive.CurrentLocation
                    if ($currentLocation -ne '' -and $currentLocation -notmatch '\\$') {
                        $currentLocation += '\'
                    }

                    $isoFilePath = $driveRoot + $currentLocation + $($MenuItems[$choice - 1].Name)

                    Write-Host "Mounting [$isoVirtualPath]..."
                    $drivesBeforeMount = (Get-PSDrive).Name
                    Mount-DiskImage -ImagePath $isoFilePath -Access ReadOnly -ErrorAction Stop

                    $drivesAfterMount = (Get-PSDrive).Name
                    $mountDrive = (compare $drivesBeforeMount $drivesAfterMount).InputObject
                    $setupCmd = $mountDrive + ':\setup.exe'

                    Write-Host "Executing [$setupCmd]..."
                    Start-Process $setupCmd -ErrorAction Stop
                } catch {
                    Write-Host "  ERROR: $_"
                }
                
                Write-Host
                $changeMenu = $false
            }

            ADDNETDRIVE {
                $newFileServer = @{}
                do {
                    Write-Host
                    $newFileServer = Input-NewOSImageServer -PreviousInput $newFileServer
                    Write-Host
                    $shareMounted = Mount-SharedFolders -FileServers $newFileServer

                    $userCancelled = $false
                    if (-not $shareMounted) {
                        Write-Host
                        $input = $null
                        do {
                            if ($input -ne $null) {
                                Write-Host "[$input] is not valid! Please enter it again!`n"
                            }
                            $input = $(Read-Host 'Would you like to retry? [y/n]').Trim()
                        } until ($input -imatch '^[yn]$')

                        if ($input -imatch '^n$') {
                            $userCancelled = $true
                        } 
                    }
                } until ($shareMounted -or $userCancelled)

                Write-Host
                if ($shareMounted) {
                    Write-Host -NoNewline 'Press any key to refresh the page...'
                    $null = $Host.UI.RawUI.ReadKey(“NoEcho,IncludeKeyDown”)
                    Write-Host

                    Write-Host
                    Write-Host 'Rescanning file system drives...'
                    $fsDrives = Get-FSDrives
                    ($newMenuDesc, $newMenuItems) = Get-FSDriveSubMenu -FSDrives $fsDrives
                    Show-Menu -FSPath $FSPath -MenuType 'Storage-Drives' -MenuDesc $newMenuDesc -MenuItems $newMenuItems
                } else {
                    $changeMenu = $false
                }
            }
        }
    } until ($changeMenu)
}  # Function Show-Menu end
