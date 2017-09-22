> Read this file with the latest **Google Chrome** or **Mozilla Firefox** for the best experience.

# Pre-requisites and Limitations

- Image file must be put on Linux file system, `ext4` has been tested
- _**(For Fedora workstation only)**_ The image file must be renamed to `<ISO_label>.iso` to work
- When using image file from local hard disk, LVM logic volume is not supported
- _**(For Fedora server only)**_ When using image file from local hard disk, `<mount_point>/osimages/xxxx.devuuid` file must exist

# Quick Start

If your MagicDrive is using Linux file system, e.g. `ext4`

1. Copy the Fedora installation image file (*.iso) to `<MagicDrive>/osimages/Fedora/`
2. _**(For Fedora workstation only)**_ Rename image file to `<ISO_label>.iso`, for example:

```
shawnh@ubuntu:/media/shawnh/MagicDrive$ ls osimages/Fedora/
Fedora-Live-Workstation-x86_64-23-10.iso  Fedora-Server-DVD-x86_64-23.iso
Fedora-Live-WS-i686-23-10.iso
shawnh@ubuntu:/media/shawnh/MagicDrive$ isoinfo -d -i osimages/Fedora/Fedora-Live-Workstation-x86_64-23-10.iso
CD-ROM is in ISO 9660 format
System id: LINUX
Volume id: Fedora-Live-WS-x86_64-23-10        <<----
Volume set id: 
Publisher id: 
Data preparer id: 
Application id: GENISOIMAGE ISO 9660/HFS FILESYSTEM CREATOR (C) 1993 E.YOUNGDALE (C) 1997-2006 J.PEARSON/J.SCHILLING (C) 2006-2007 CDRKIT TEAM
Copyright File id: 
Abstract File id: 
Bibliographic File id: 
Volume set size is: 1
Volume set sequence number is: 1
Logical block size is: 2048
Volume size is: 717215
El Torito VD version 1 found, boot catalog is in sector 42
Joliet with UCS level 3 found
Rock Ridge signatures version 1 found
Eltorito validation header:
    Hid 1
    Arch 0 (x86)
    ID ''
    Key 55 AA
    Eltorito defaultboot header:
        Bootid 88 (bootable)
        Boot media 0 (No Emulation Boot)
        Load segment 0
        Sys type 0
        Nsect 4
        Bootoff 842 2114
shawnh@ubuntu:/media/shawnh/MagicDrive$ mv osimages/Fedora/Fedora-Live-Workstation-x86_64-23-10.iso osimages/Fedora/Fedora-Live-WS-x86_64-23-10.iso
shawnh@ubuntu:/media/shawnh/MagicDrive$ 
```

3. Reboot your machine from the USB drive
4. Select **Install Fedora** to list all valid Fedora installation image files
4. Select the image file you want to use
5. Continue Fedora installation as well as you are using a physical DVD

or else, see **Using image files on hard disk of the physical machine**

# For Advanced Users

### Using image files on hard disk of the physical machine

1. Make the same directory structure as that in MagicDrive: `mkdir -p <mount_point>/osimages/Fedora`
2. _**(For Fedora server only)**_ Create `<mount_point>/osimages/xxxx.devuuid` file, for example:

```
root@ubuntu:~# df -lh
Filesystem      Size  Used Avail Use% Mounted on
udev            973M     0  973M   0% /dev
tmpfs           199M   17M  182M   9% /run
/dev/sda1        98G   19G   74G  20% /
tmpfs           992M  212K  992M   1% /dev/shm
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
tmpfs           992M     0  992M   0% /sys/fs/cgroup
tmpfs           199M   68K  199M   1% /run/user/1000
/dev/sdc1        59G   52M   56G   1% /data
root@ubuntu:~# export mount_point=/data
root@ubuntu:~# mkdir -p ${mount_point}/osimages/Fedora
root@ubuntu:~# grub-probe --targe=fs_uuid --device /dev/sdc1
0d0935cd-574a-4108-8082-cba7899295fe
root@ubuntu:~# touch ${mount_point}/osimages/0d0935cd-574a-4108-8082-cba7899295fe.devuuid
root@ubuntu:~# ls -l ${mount_point}/osimages/0d0935cd-574a-4108-8082-cba7899295fe.devuuid
-rw-r--r-- 1 root root 0 Jun 29 23:11 /data/osimages/0d0935cd-574a-4108-8082-cba7899295fe.devuuid
root@ubuntu:~# 
```

3. Copy Fedora installation image file (*.iso) to the `<mount_point>/osimages/Fedora` you created
4. _**(For Fedora workstation only)**_ Rename image file to `<ISO_label>.iso`
5. Reboot your machine from the USB drive
6. Select **Install Fedora** to list all valid Fedora installation image files
7. Select the image file you want to use
8. Continue Fedora installation as well as you are using a physical DVD
