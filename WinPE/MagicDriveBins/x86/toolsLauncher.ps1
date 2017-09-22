Param (
    [String]$indexFile
)

$ErrorActionPreference = "SilentlyContinue"
$host.ui.RawUI.WindowTitle = 'MagicDrive Tools Launcher for Windows 32bit'

$currentPath = $(Get-Location).Path
$indexFilePath = $currentPath + '\' + $indexFile

$refresh = $false
do {
    Clear-Host
    try {
        $csvData = Import-Csv -Path $indexFile -ErrorAction Stop
    } catch {
        $msg = @"

    Failed to parser index file ${indexFilePath}: $_

    Press any key to exit...
"@
        Write-Host -NoNewline $msg
        $null = $Host.UI.RawUI.ReadKey(“NoEcho,IncludeKeyDown”)
        exit
    }

    $menuItems = @()
    $i = 1
    foreach ($appRecord in $csvData) {
        if ($appRecord.AppPath -match '^\s*$') {
            # If AppPath is not avaliable, skip the record
            continue
        }

        $toolName = $appRecord.AppName.Trim()
        if ($toolName -match '^\s*$') {
            $toolName = $appRecord.AppPath.Trim()
        }

        $menuObj = New-Object System.Object
        $menuObj |Add-Member -MemberType NoteProperty -Name 'ID' -Value $i
        $menuObj |Add-Member -MemberType NoteProperty -Name 'Tool' -Value $toolName
        $menuObj |Add-Member -MemberType NoteProperty -Name 'Description' -Value $appRecord.AppDescription.Trim()
        $menuObj |Add-Member -MemberType NoteProperty -Name 'Command' -Value $appRecord.AppPath.Trim()
        $menuItems += $menuObj
        $i += 1
    }

    $menuObj = New-Object System.Object
    $menuObj |Add-Member -MemberType NoteProperty -Name 'ID' -Value 'r'
    $menuObj |Add-Member -MemberType NoteProperty -Name 'Tool' -Value 'Refresh'
    $menuObj |Add-Member -MemberType NoteProperty -Name 'Description' -Value 'Reload the tools list'
    $menuItems += $menuObj

    $menuObj = New-Object System.Object
    $menuObj |Add-Member -MemberType NoteProperty -Name 'ID' -Value 'q'
    $menuObj |Add-Member -MemberType NoteProperty -Name 'Tool' -Value 'Quit'
    $menuObj |Add-Member -MemberType NoteProperty -Name 'Description' -Value 'Quit the Tools Launch Pad'
    $menuItems += $menuObj

    $menuItems |Format-Table -Property ID,Tool,Description -AutoSize

    $toolsCount = $menuItems.Count - 2
    if ($toolsCount -eq 0) {
        $ScopeString = 'r, q'
        $ScopeList = @('r', 'q')
    } elseif ($toolsCount -eq 1) {
        $ScopeString = '1, r, q'
        $ScopeList = @(1, 'r', 'q')
    } else {
        $ScopeString = "1-$toolsCount, r, q"
        $ScopeList = @(1..$toolsCount) + @('r', 'q')
    }

    while ($true) {
        $choice = $null
        do {
            if ($choice -ne $null) {
                Write-Host "  ERROR: [$choice] is not valid! Please try it again!`n"
            }
            $choice = $(Read-Host "Select an item by ID from above [$ScopeString]").Trim()
            if ($input -match '^[0-9]+$') {
                [Int]$choice = $choice
            } else {
                $choice = $choice.ToLower()
            }
        } until ($choice -in $ScopeList)

        if ($choice -eq 'q') {
            exit
        } elseif ($choice -eq 'r') {
            $refresh = $true
            break
        } else {
            $toolFullPath = $currentPath + '\' + $menuItems[$($choice - 1)].Command
            Write-Host "Launching [$toolFullPath]..."
            try {
                Start-Process $toolFullPath -ErrorAction Stop
            } catch {
                Write-Host "  ERROR: $_"
            }
            Write-Host
        }
    }
} until (-not $refresh)
