# Read Environment Variables
[String]$outputPath = $Env:OUTPUT_PATH
[String]$adkRoot = $Env:ADKROOT

if (-not $outputPath.EndsWith('\')) {
    $outputPath += '\'
}

$peFeatures = @(
    'WinPE-FMAPI',
    'WinPE-WMI',
    'WinPE-NetFX',
    'WinPE-WDS-Tools',
    'WinPE-Scripting',
    'WinPE-PowerShell',
    'WinPE-DismCmdlets',
    'WinPE-StorageWMI',
    'WinPE-EnhancedStorage',
    'WinPE-Dot3Svc'
)

$global:step = 1
$global:totalStep = 0
$tmpPath = $outputPath + 'MagicDrive-Pe-Temp'

function Run-Cmd {
    Param (
        [String]$cmd
    )

    Write-Debug "$cmd"
    Invoke-Expression "$cmd"
}

function Clone-Object {
    # Download from: https://stackoverflow.com/questions/7468707/deep-copy-a-dictionary-hashtable-in-powershell
    param($DeepCopyObject)
    $memStream = new-object IO.MemoryStream
    $formatter = new-object Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $formatter.Serialize($memStream, $DeepCopyObject)
    $memStream.Position=0
    $formatter.Deserialize($memStream)
}

function Read-BcdBootLoaderConfig {
    Param (
        [String]$bcdFile
    )

    $bcdData = @()
    $bootEntry = @{}
    $readStart = $false
    foreach ($line in $(Run-Cmd "bcdedit /store `"$bcdFile`"")) {
        $line = $line.Trim()
        if (-not $readStart) {
            if ($line -eq 'Windows Boot Loader') {
                $readStart = $true
            }
            continue
        }

        if ($line -imatch '^-+$') {
            if ($bootEntry.Count -gt 0) {
                $bcdData += Clone-Object $bootEntry
                $bootEntry.Clear()
                continue
            }
        }

        if ($line -imatch '^(?<key>\S+)\s+(?<value>\S[\s\S]+)$') {
            $bootEntry[$matches['key']] = $matches['value']
        }
    }
    $bcdData += $bootEntry
    return $bcdData
}

function Convert-BcdBootConfig {
    Param (
        [String]$arch,
        [HashTable]$bootConfig
    )

    if ($arch -eq 'x86') {
        $description = 'Windows 32bit'
    } else {
        $description = 'Windows 64bit'
    }

    $result = @{}
    foreach ($h in $bootConfig.GetEnumerator()) {
        if ($h.key -in @('identifier', 'bootmenupolicy')) {
            continue
        }

        if ($h.key -in @('device', 'osdevice')) {
            $h.Value = $h.value.Replace('boot.wim', "boot-$arch.wim")
        }

        if ($h.key -eq 'description') {
            $h.Value = $description
        }

        $result[$h.key] = $h.value
    }

    return $result
}

function Remove-BcdBootLoader {
    Param (
        [String]$bcdFile,
        [String]$bootLoaderId
    )

    Run-Cmd "bcdedit /store `"$bcdFile`" /delete '$bootLoaderId'" |Out-Null
}

function Add-BcdBootLoader {
    Param (
        [String]$bcdFile,
        [HashTable]$bootConfig,
        [Boolean]$setDefault = $false
    )

    $description = $bootConfig.description
    $out = Run-Cmd "bcdedit /store `"$bcdFile`" /create /d `"$description`" /application osloader"
    if ($out -match '^[^{]+(?<id>{\S+})[^}]+') {
        $id = $matches['id']
    } else {
        Write-Error "Failed to add boot loader `"$description`" to $bcdFile."
        return
    }

    Run-Cmd "bcdedit /store `"$bcdFile`" /displayorder '$id' /addlast" |Out-Null
    foreach ($key in $bootConfig.Keys) {
        $value = $bootConfig.$key
        Run-Cmd "bcdedit /store `"$bcdFile`" /set '$id' '$key' '$value'" |Out-Null
    }

    if ($setDefault) {
        Run-Cmd "bcdedit /store `"$bcdFile`" /default '$id'" |Out-Null
    }
}

function Prepare-WinPe {
    Param (
        [String]$arch
    )

    if (-not ($arch -imatch 'amd64|x86')) {
        Write-Host "ERROR: arch can be only 'x86' or 'amd64'."
        return -1
    }
    $arch = $arch.ToLower()

    $tmpRoot = $tmpPath + '\WinPE_{0}' -f $arch
    $tmpPeSystem32 = $tmpRoot + '\mount\Windows\system32'
    $tmpPeBgPicture = $tmpPeSystem32 + '\winpe.jpg'
    $tmpImageFile = $tmpRoot + '\media\sources\boot.wim'
    $tmpMountDir = $tmpRoot + '\mount'
    $adkPePackagePath = $adkRoot + '\Windows Preinstallation Environment\{0}\WinPE_OCs' -f $arch
    $magicDriverScriptsDir = '{0}\..\MagicDriveBins\{1}' -f $scriptDir, $arch

    Write-Host
    Write-Host "$global:step/$global:totalStep) Creating $arch Windows PE Boot Image..."
    Run-Cmd "copype $arch `"$tmpRoot`"" |Out-Null
    $global:step++

    Write-Host
    Write-Host "$global:step/$global:totalStep) Mouting $arch Windows PE Boot Image..."
    Run-Cmd "Dism /Mount-Image /ImageFile:`"$tmpImageFile`" /index:1 /MountDir:`"$tmpMountDir`""  |Out-Null
    Run-Cmd "Dism /Set-ScratchSpace:512 /Image:`"$tmpMountDir`""  |Out-Null
    $global:step++

    Write-Host
    Write-Host "$global:step/$global:totalStep) Adding Features to $arch Windows PE Boot Image..."
    $featureCount = 1
    $featureTotalCount = $peFeatures.Count
    foreach ($peFeature in $peFeatures) {
        Write-Host "  - Adding $peFeature [$featureCount/$featureTotalCount]..." -NoNewline
        Run-Cmd "Dism /Add-Package /Image:`"$tmpMountDir`" /PackagePath:`"$adkPePackagePath\$peFeature.cab`""  |Out-Null
        $featureCount++
        Write-Host "Done"
    }
    $global:step++

    Write-Host
    Write-Host "$global:step/$global:totalStep) Deploying MagicDrive startup scripts..."
    Write-Host "  - Replacing startnet.cmd..." -NoNewline
    Copy-Item "$magicDriverScriptsDir\startnet.cmd" $tmpPeSystem32
    Write-Host "Done"

    Write-Host "  - Deploying PowerShell scripts..." -NoNewline
    Copy-Item "$magicDriverScriptsDir\*.ps1" $tmpPeSystem32
    Write-Host "Done"

    Write-Host "  - Replacing Desktop Background winpe.jpg..." -NoNewline
    $bgPicAcl = Get-Acl -Path $tmpPeBgPicture
    $adminGroup = New-Object System.Security.Principal.NTAccount("Builtin", "Administrators")
    $adminFullAccessAr = New-Object  system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
    $bgPicAcl.SetOwner($adminGroup)
    $bgPicAcl.SetAccessRule($adminFullAccessAr)
    Set-Acl -Path $tmpPeBgPicture -AclObject $bgPicAcl
    Copy-Item "$magicDriverScriptsDir\*.jpg" $tmpPeSystem32
    Write-Host "Done"
    $global:step++

    Write-Host
    Write-Host "$global:step/$global:totalStep) Configuring EFI Boot Manager for $arch Windows PE Boot Image..."
    Copy-Item -Path "$tmpMountDir\Windows\Boot\EFI\bootmgfw.efi" -Destination "$tmpRoot\media\EFI\Microsoft\Boot"
    Copy-Item -Path "$tmpMountDir\Windows\Boot\EFI\bootmgr.efi" -Destination "$tmpRoot\media\EFI\Microsoft\Boot"
    $global:step++

    Write-Host
    Write-Host "$global:step/$global:totalStep) Umounting $arch Windows PE Boot Image..."
    Run-Cmd "Dism /Unmount-Image /MountDir:`"$tmpMountDir`" /commit"  |Out-Null
    $global:step++

    return $tmpRoot
}

function Merge-WinPe {
    Param (
        [String]$x86PeRoot,
        [String]$amd64PeRoot
    )

    $x86MediaRoot = $x86PeRoot + '\media'
    $amd64MediaRoot = $amd64PeRoot + '\media'

    $mixPeRoot = $tmpPath + '\WinPE_mix'
    $mixMediaRoot = $mixPeRoot + '\media'

    Write-Host
    Write-Host "$global:step/$global:totalStep) Creating mix Windows PE Boot Image..."
    Run-Cmd "mkdir `"$mixPeRoot`"" |Out-Null
    Copy-Item -Path "$amd64PeRoot\*" -Destination $mixPeRoot -Recurse

    Rename-Item -Path "$mixMediaRoot\EFI\Microsoft" -NewName "$mixMediaRoot\EFI\Microsoft-amd64"
    Copy-Item -Path "$x86MediaRoot\EFI\Microsoft" -Destination "$mixMediaRoot\EFI\Microsoft-x86" -Recurse

    Rename-Item -Path "$mixMediaRoot\sources\boot.wim" -NewName "$mixMediaRoot\sources\boot-amd64.wim"
    Copy-Item -Path "$x86MediaRoot\sources\boot.wim" -Destination "$mixMediaRoot\sources\boot-x86.wim"

    Copy-Item -Path "$x86MediaRoot\EFI\Boot\bootia32.efi" -Destination "$mixMediaRoot\EFI\Boot"
    $global:step++

    Write-Host
    Write-Host "$global:step/$global:totalStep) Configuring BIOS Boot Loader..."
    $x86BcdBootConfig = Read-BcdBootLoaderConfig -bcdFile "$x86MediaRoot\Boot\BCD"
    $amd64BcdBootConfig = Read-BcdBootLoaderConfig -bcdFile "$amd64MediaRoot\Boot\BCD"

    $x86BcdBootConfig = Convert-BcdBootConfig -arch 'x86' -bootConfig $x86BcdBootConfig
    $amd64BcdBootConfig = Convert-BcdBootConfig -arch 'amd64' -bootConfig $amd64BcdBootConfig

    Remove-BcdBootLoader -bcdFile "$mixMediaRoot\Boot\BCD" -bootLoaderId '{default}'
    Add-BcdBootLoader -bcdFile "$mixMediaRoot\Boot\BCD" -bootConfig $amd64BcdBootConfig -setDefault $true
    Add-BcdBootLoader -bcdFile "$mixMediaRoot\Boot\BCD" -bootConfig $x86BcdBootConfig
    $global:step++

    Write-Host
    Write-Host "$global:step/$global:totalStep) Configuring EFI Boot Loader..."
    $x86BcdBootConfig = Read-BcdBootLoaderConfig -bcdFile "$mixMediaRoot\EFI\Microsoft-x86\Boot\BCD"
    $x86BcdBootConfig = Convert-BcdBootConfig -arch 'x86' -bootConfig $x86BcdBootConfig
    Remove-BcdBootLoader -bcdFile "$mixMediaRoot\EFI\Microsoft-x86\Boot\BCD" -bootLoaderId '{default}'
    Add-BcdBootLoader -bcdFile "$mixMediaRoot\EFI\Microsoft-x86\Boot\BCD" -bootConfig $x86BcdBootConfig -setDefault $true

    $amd64BcdBootConfig = Read-BcdBootLoaderConfig -bcdFile "$mixMediaRoot\EFI\Microsoft-amd64\Boot\BCD"
    $amd64BcdBootConfig = Convert-BcdBootConfig -arch 'amd64' -bootConfig $amd64BcdBootConfig
    Remove-BcdBootLoader -bcdFile "$mixMediaRoot\EFI\Microsoft-amd64\Boot\BCD" -bootLoaderId '{default}'
    Add-BcdBootLoader -bcdFile "$mixMediaRoot\EFI\Microsoft-amd64\Boot\BCD" -bootConfig $amd64BcdBootConfig -setDefault $true

    Copy-Item -Path "$mixMediaRoot\EFI\Microsoft-amd64" -Destination "$mixMediaRoot\EFI\Microsoft" -Recurse
    $global:step++

    return $mixPeRoot
}

function Build-WinPe {
    Param (
        [string]$type
    )

    $type = $type.ToLower()
    if ($type -notin @('x86', 'amd64', 'mix')) {
        Write-Host "ERROR: type can be only 'x86', 'amd64' or 'mix'."
        return
    }

    Write-Host
    Write-Host "*******************************************************************************"
    Write-Host "                         MirageDrive WinPE Builder"
    Write-Host "*******************************************************************************"
    Write-Host
    Write-Host "Stand by, this process might take a few minutes..."

    if ($type -in @('x86', 'amd64')) {
        $global:totalStep = 8
        $peRoot = Prepare-WinPe -arch $type
    } else {
        $global:totalStep = 17
        $x86PeRoot = Prepare-WinPe -arch 'x86'
        $amd64PeRoot = Prepare-WinPe -arch 'amd64'
        $peRoot = Merge-WinPe -x86PeRoot $x86PeRoot -amd64PeRoot $amd64PeRoot
    }

    $peIsoFile = $outputPath + 'MagicDrive_WinPE.iso'

    Write-Host
    Write-Host "$global:step/$global:totalStep) Creating $type WinPE ISO image..."
    Run-Cmd "MakeWinPEMedia /ISO '$peRoot' '$peIsoFile'" |Out-Null
    $global:step++

    Write-Host
    Write-Host "$global:step/$global:totalStep) Clean up..."
    Remove-Item -Path $tmpPath -Recurse -Force
    $global:step++

    Write-Host
    Write-Host "Congratulations! MirageDrive WinPE has been successfully created, find the image file at:"
    Write-Host
    Write-Host "    $peIsoFile"
    Write-Host
}
