> This document is obsoleted. The MagicDrive WinPE Creation process has been automated by [buildPE.bat](WinPE/buildPE.bat).

# Prepare Environment

Install Win10x64 and then ADK for win10: [Download the Windows ADK](https://developer.microsoft.com/en-us/windows/hardware/windows-assessment-deployment-kit)

Start **Deployment and Imaging Tools Environment** cmd as Administrator.

## Create WinPE 64bit

### Create 64bit Windows PE boot image

Run below command in **Deployment and Imaging Tools Environment** cmd:

```dos
copype amd64 C:\WinPE_amd64
```

### Mount the Windows PE boot image

Run below command in **Deployment and Imaging Tools Environment** cmd:

```dos
Dism /Mount-Image /ImageFile:"C:\WinPE_amd64\media\sources\boot.wim" /index:1 /MountDir:"C:\WinPE_amd64\mount"
```

### Increase temporary storage (scratch space)

Run below command in **Deployment and Imaging Tools Environment** cmd to increase the temporary storage to 512 MB:

```dos
Dism /Set-ScratchSpace:512 /Image:"C:\WinPE_amd64\mount"
```

### Added features needed by MagicDrive

Run below commands in **Deployment and Imaging Tools Environment** cmd:

```dos
Dism /Add-Package /Image:"C:\WinPE_amd64\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-FontSupport-ZH-CN.cab"

Dism /Add-Package /Image:"C:\WinPE_amd64\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-FMAPI.cab"

Dism /Add-Package /Image:"C:\WinPE_amd64\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"

Dism /Add-Package /Image:"C:\WinPE_amd64\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-NetFX.cab"

Dism /Add-Package /Image:"C:\WinPE_amd64\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WDS-Tools.cab"

Dism /Add-Package /Image:"C:\WinPE_amd64\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-Scripting.cab"

Dism /Add-Package /Image:"C:\WinPE_amd64\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-PowerShell.cab"

Dism /Add-Package /Image:"C:\WinPE_amd64\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-DismCmdlets.cab"

Dism /Add-Package /Image:"C:\WinPE_amd64\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-StorageWMI.cab"

Dism /Add-Package /Image:"C:\WinPE_amd64\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-EnhancedStorage.cab"
```

### Replace the startup script

Replace `C:\WinPE_amd64\mount\Windows\System32\startnet.cmd` by customized [startnet.cmd](WinPE/MagicDriveBins/amd64/startnet.cmd).

Copy [setup.ps1](WinPE/MagicDriveBins/amd64/setup.ps1) and [setupFunctions.ps1](WinPE/MagicDriveBins/amd64/setupFunctions.ps1) files to `C:\WinPE_amd64\mount\Windows\System32\`.

### (Optional) Change WinPE background image

1. In Windows Explorer, navigate to `C:\WinPE_amd64\mount\windows\system32`.

2. Right-click the `C:\WinPE_amd64\mount\windows\system32\winpe.jpg` file, and select **Properties** > **Security tab** > **Advanced**.

3. Next to Owner, select **Change**. Change the owner to **Administrators**.

4. Apply the changes, and exit the Properties window to save changes.

5. Right-click the `C:\WinPE_amd64\mount\windows\system32\winpe.jpg` file, and select **Properties** > **Security tab** > **Advanced**.

6. Modify the permissions for **Administrators** to allow full access.

7. Apply the changes, and exit the Properties window to save changes

8. Replace the `C:\WinPE_amd64\mount\windows\system32\winpe.jpg` file with [winpe.jpg](WinPE/MagicDriveBins/amd64/winpe.jpg)

### Save boot images for UEFI

Copy **bootmgfw.efi** and **bootmgr.efi** files from `C:\WinPE_amd64\mount\Windows\Boot\EFI\` to other place, like `C:\win10x64_efi\`.

### Commit changes and umount boot image

Run below command in **Deployment and Imaging Tools Environment** cmd:

```dos
Dism /Unmount-Image /MountDir:"C:\WinPE_amd64\mount" /commit
```

### Create ISO image

Run below command in **Deployment and Imaging Tools Environment** cmd:

```dos
MakeWinPEMedia /ISO C:\WinPE_amd64 C:\WinPE_amd64\WinPE_amd64.iso
```

### Add UEFI boot image files to ISO image

Open the ISO image file in ISO editing tool, add `C:\win10x64_efi\bootmgfw.efi` and `C:\win10x64_efi\bootmgr.efi` files to `<WinPEx64 ISO>:\EFI\Microsoft\Boot`

## Create WinPE 32bit

### Create 32bit Windows PE boot image

Run below command in **Deployment and Imaging Tools Environment** cmd:

```dos
copype x86 C:\WinPE_x86
```

### Mount the Windows PE boot image

Run below command in **Deployment and Imaging Tools Environment** cmd:

```dos
Dism /Mount-Image /ImageFile:"C:\WinPE_x86\media\sources\boot.wim" /index:1 /MountDir:"C:\WinPE_x86\mount"
```

### Increase temporary storage (scratch space)

Run below command in **Deployment and Imaging Tools Environment** cmd to increase the temporary storage to 512 MB:

```dos
Dism /Set-ScratchSpace:512 /Image:"C:\WinPE_x86\mount"
```

### Added features needed by MagicDrive

Run below commands in **Deployment and Imaging Tools Environment** cmd:

```dos
Dism /Add-Package /Image:"C:\WinPE_x86\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs\WinPE-FontSupport-ZH-CN.cab"

Dism /Add-Package /Image:"C:\WinPE_x86\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs\WinPE-FMAPI.cab"

Dism /Add-Package /Image:"C:\WinPE_x86\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs\WinPE-WMI.cab"

Dism /Add-Package /Image:"C:\WinPE_x86\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs\WinPE-NetFX.cab"

Dism /Add-Package /Image:"C:\WinPE_x86\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs\WinPE-WDS-Tools.cab"

Dism /Add-Package /Image:"C:\WinPE_x86\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs\WinPE-Scripting.cab"

Dism /Add-Package /Image:"C:\WinPE_x86\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs\WinPE-PowerShell.cab"

Dism /Add-Package /Image:"C:\WinPE_x86\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs\WinPE-DismCmdlets.cab"

Dism /Add-Package /Image:"C:\WinPE_x86\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs\WinPE-StorageWMI.cab"

Dism /Add-Package /Image:"C:\WinPE_x86\mount" /PackagePath:"C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\x86\WinPE_OCs\WinPE-EnhancedStorage.cab"
```

### Replace the startup script

Replace `C:\WinPE_x86\mount\Windows\System32\startnet.cmd` by customized [startnet.cmd](WinPE/MagicDriveBins/x86/startnet.cmd).

Copy [setup.ps1](WinPE/MagicDriveBins/x86/setup.ps1) and [setupFunctions.ps1](WinPE/MagicDriveBins/x86/setupFunctions.ps1) files to `C:\WinPE_x86\mount\Windows\System32\`.

### (Optional) Change WinPE background image

1. In Windows Explorer, navigate to `C:\WinPE_x86\mount\windows\system32`.

2. Right-click the `C:\WinPE_x86\mount\windows\system32\winpe.jpg` file, and select **Properties** > **Security tab** > **Advanced**.

3. Next to Owner, select **Change**. Change the owner to **Administrators**.

4. Apply the changes, and exit the Properties window to save changes.

5. Right-click the `C:\WinPE_x86\mount\windows\system32\winpe.jpg` file, and select **Properties** > **Security tab** > **Advanced**.

6. Modify the permissions for **Administrators** to allow full access.

7. Apply the changes, and exit the Properties window to save changes

8. Replace the `C:\WinPE_x86\mount\windows\system32\winpe.jpg` file with [winpe.jpg](WinPE/MagicDriveBins/x86/winpe.jpg)

### Save boot images for UEFI

Copy **bootmgfw.efi** and **bootmgr.efi** files from `C:\WinPE_x86\mount\Windows\Boot\EFI\` to other place, like `C:\win10x86_efi\`.

### Commit changes and umount boot image

Run below command in **Deployment and Imaging Tools Environment** cmd:

```dos
Dism /Unmount-Image /MountDir:"C:\WinPE_x86\mount" /commit
```

### Create ISO image

Run below command in **Deployment and Imaging Tools Environment** cmd:

```dos
MakeWinPEMedia /ISO C:\WinPE_x86 C:\WinPE_x86\WinPE_x86.iso
```

### Add UEFI boot image files to ISO image

Open the ISO image file in ISO editing tool, add `C:\win10x86_efi\bootmgfw.efi` and `C:\win10x86_efi\bootmgr.efi` files to `<WinPEx86 ISO>:\EFI\Microsoft\Boot`

## Merge WinPE 64bit and WinPE 32bit

This will be done based on WinPE 64bit image.

1. Extract **WinPE_amd64.iso** to `C:\iso_amd64`

2. Extract **WinPE_x86.iso** to `C:\iso_x86`

3. Open **WinPE_amd64.iso** in ISO editing tool

4. Rename `<WinPE_amd64.iso>\EFI\Microsoft` to `<WinPE_amd64.iso>\EFI\Microsoft-x64`

5. Add `C:\iso_x86\EFI\Microsoft` to `<WinPE_amd64.iso>\EFI\`, and rename it to `<WinPE_amd64.iso>\EFI\Microsoft-x86`

6. Rename `<WinPE_amd64.iso>\source\boot.wim` to `<WinPE_amd64.iso>\source\boot-x64.wim`

7. Add `C:\iso_x86\source\boot.wim` to `<WinPE_amd64.iso>\source\`, and rename it to `<WinPE_amd64.iso>\source\boot-x86.wim`

8. Add `C:\iso_x86\EFI\Boot\bootia32.efi` to `<WinPE_amd64.iso>\EFI\Boot`

9. Download and install [Visual BCD editor](https://www.boyans.net/DownloadVisualBCD.html)

10. Open `C:\iso_amd64\Boot\BCD` and `C:\iso_x86\Boot\BCD` files in Visual BCD editor

11. For `C:\iso_amd64\Boot\BCD`, change the **BcdStore\Loaders\Windows Setup** entry as below:

    a. **Description** value to **Windows 64bit**

    b. Change `\sources\boot.wim` in **ApplicationDevice** value to `\sources\boot-x64.wim`

    c. Change `\sources\boot.wim` in **OSDevice** value to `\sources\boot-x64.wim`

    d. Delete the **loader_custom:0x250000c2** element

12. For `C:\iso_amd64\Boot\BCD`, right click on **BcdStore\Loaders** entry, select **New Vista/7/VHD Loader**

13. Change all elements (add and delete elements if needed) of the new added **New Vista/7/VHD Loader**, ensure it becomes the same with **BcdStore\Loaders\Windows Setup** of `C:\iso_x86\Boot\BCD`

14. For `C:\iso_amd64\Boot\BCD`, change the new added loader node as below:

    a. Change **Description** value to **Windows 32bit**

    b. Change `\sources\boot.wim` in **ApplicationDevice** value to `\sources\boot-x86.wim`

    c. Change `\sources\boot.wim` in **OSDevice** value to `\sources\boot-x86.wim`

    d. Delete the **loader_custom:0x250000c2** element

15. Open `C:\iso_amd64\EFI\Microsoft\Boot\BCD` file in Visual BCD editor, make below changes to the **BcdStore\Loaders\Windows Setup** entry:

    a. Change `\sources\boot.wim` in **ApplicationDevice** value to `\sources\boot-x64.wim`

    b. Change `\sources\boot.wim` in **OSDevice** value to `\sources\boot-x64.wim`
    
    c. Delete the **loader_custom:0x250000c2** element

16. Open `C:\iso_x86\EFI\Microsoft\Boot\BCD` file in Visual BCD editor, make below changes to the **BcdStore\Loaders\Windows Setup** entry:

    a. Change `\sources\boot.wim` in **ApplicationDevice** value to `\sources\boot-x86.wim`

    b. Change `\sources\boot.wim` in **OSDevice** value to `\sources\boot-x86.wim`
    
    c. Delete the **loader_custom:0x250000c2** element

17. Close all Visual BCD editor windows

18. Replace `<WinPE_amd64.iso>\EFI\Microsoft-x64\Boot\BCD` by `C:\iso_amd64\EFI\Microsoft\Boot\BCD`

19. Replace `<WinPE_amd64.iso>\EFI\Microsoft-x86\Boot\BCD` by `C:\iso_x86\EFI\Microsoft\Boot\BCD`

20. Replace `<WinPE_amd64.iso>\Boot\BCD` by `C:\iso_amd64\Boot\BCD`

21. Change label of **WinPE_amd64.iso** to **WinPE**

22. Save the ISO file as **WinPE.iso**