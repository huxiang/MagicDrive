# Pre-requisites

- A Windows 10 VM with [Windows ADK](https://developer.microsoft.com/en-us/windows/hardware/windows-assessment-deployment-kit) installed

- A Ubuntu VM

# Build MirageDrive WinPE

1. Download the project as zip on the Windows 10 VM.

2. Uncompress the zip package.

3. Modify `WinPE\buildPE.bat` file based on your environment and requirements.

4. Right click on the `WinPE\buildPE.bat` file, run it as Administrator.

5. Just wait for the WinPE image creation completes.

# Create MagicDrive With A USB Storage Device

This part has only been tested on Ubuntu 16.04 x64 VM.

## Install Required Packages

Install these packages on the Ubuntu VM:

```
# apt install scsitools
# apt install git
# apt install grub-efi
```

## Connect WinPE ISO to Ubuntu VM

Connect the `MagicDrive_WinPE.iso` created on Windows 10 VM to the Ubuntu VM via virtual CD/DVD.

## Git Clone MagicDrive Project

Git clone the project to `/github` directory of the Ubuntu VM

```
# mkdir /github
# cd /github
# git clone https://github.com/huxiang/MagicDrive.git
```

## Transform Your USB Storage Device to MagicDrive

Plug your USB storage device into the Ubuntu VM, then run the `make_magicdrive` tool. Here's an example:

```
root@ubuntu:/github# cd /github/MagicDrive/Install/
root@ubuntu:/github/MagicDrive/Install# ./make_magicdrive 
Usage:
   make_magicdrive DISKDEV [FSTYPE]

where,
   DISKDEV     Device file of the WHOLE disk which your want to transform
               it to MagicDrive
   FSTYPE      File system type of the MagicDrive, it can be nfts or ext4,
               it is ntfs by default

Example:
   make_magicdrive /dev/sdb
   make_magicdrive /dev/sdb ntfs
   make_magicdrive /dev/sdb ext4

Avaliable Disks:
   /dev/sdb	16 GB
   /dev/sda	100 GB

root@ubuntu:/github/MagicDrive/Install# ./make_magicdrive /dev/sdb
Warning: [/dev/sdb] has existing partition(s)!

To transform this device to MagicDrive, its partition table must be re-built.

*** All your data on this device now will be lost!!! ***

Please type "DELETE" and then press [Enter] key to ensure that you have
understood the risk of this operation.
Type anything else and press [Enter] key to exit:
DELETE

Clearing partition table on [/dev/sdb]...Done!
Creating partitions on [/dev/sdb]...Done!
Creating file system on [/dev/sdb1]...Done!
Creating file system on [/dev/sdb2]...Done!
Creating file system on [/dev/sdb3]...Done!
Getting file system UUIDs for [/dev/sdb1]...Done!
Getting file system UUIDs for [/dev/sdb2]...Done!
Getting file system UUIDs for [/dev/sdb3]...Done!
Mounting [/dev/sdb1] to [/mnt/usb1]...Done!
Mounting [/dev/sdb2] to [/mnt/usb2]...Done!
Mounting [/dev/sdb3] to [/mnt/usb3]...Done!
Installing grub2 to [/dev/sdb2]...Done!
Writing grub2 config files to [/dev/sdb2]...Done!
Writing WinPE files to [/dev/sdb3]...Done!
Writing user files to [/dev/sdb1]...Done!
Umount [/dev/sdb1]...Done!
Umount [/dev/sdb2]...Done!
Umount [/dev/sdb3]...Done!

Congratulations! You MagicDrive is ready to use!

root@ubuntu:/github/MagicDrive/Install# 
```
