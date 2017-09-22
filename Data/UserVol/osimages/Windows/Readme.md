> Read this file with the latest **Google Chrome** or **Mozilla Firefox** for the best experience.

# Pre-requisites and Limitations

- Only support Windows Vista and later versions
- Only support Windows 64bit images for EFI boot
- Image files must be put on file systems supported by Windows

# Quick Start

1. Copy the Windows installation image file (*.iso) to `<MagicDrive>:\osimages\Windows\`
2. Reboot your machine from the USB drive
3. Select **Install Windows** to start Windows PE
4. (BIOS boot only)Select **Windows 64bit** or **Windows 32bit** of the Windows platform you want to install
5. Select the image file you want to use
6. Continue Windows installation as well as you are using a physical DVD

# For Advanced Users

### Using image files on hard disk of the physical machine

1. You can put the Windows installation image file on any windows file system of your hard disk
2. Reboot your machine from the USB drive
3. Select **Install Windows** to start Windows PE
4. (BIOS boot only)Select **Windows 64bit** or **Windows 32bit** of the Windows platform you want to install
5. Select `s` to list all storage drives
6. Select the drive where you put your image file in
7. Select the image file you want to use
8. Continue Windows installation as well as you are using a physical DVD

### Using image files on network share

Save access info of network share(s) to the comma delimited CSV file `<MagicDrive>:\osimages\Windows\OSImageFileServers.csv`, then you should be able to see network drives in Windows PE if the access info is correct. You can simply select image file from network drive to start Windows installation.

##### How to configure the OSImageFileServers.csv file
For example, you have Windows installation image files on below network shares:
```
UNC path: \\smbserver.example.com\share\users\Win10rs\ and \\smbserver.example.com\share\OS\Windows\
Username: smbuser
Password: password
```
Then you should write the OSImageFileServers.csv file like this:
| ShareFolder                     | Username | Password | ImagePath                  |
|---------------------------------|----------|----------|----------------------------|
| \\\\smbserver.example.com\share | smbuser  | password | \users\Win10rs;\OS\Windows |

You can add more rows if you have more servers on network.

##### Security considerations

You may lend the removable device to others very often. It's not a good idea to store your personal credentials on such a device.

To resolve this problem, you don't have to put the OSImageFileServers.csv file under `<MagicDrive>:\osimages\Windows\`, you can put it on any Windows file system of your machine's hard disk. But remember to put it in the root directory of he file system, for example: `D:\`, `E:\`, etc.

If you just don't want to store any OSImageFileServers.csv file, it's fine. You can connect to file server in the WinPE by providing the access information. The access information will not be written in any file.