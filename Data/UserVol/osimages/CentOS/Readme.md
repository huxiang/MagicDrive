> Read this file with the latest **Google Chrome** or **Mozilla Firefox** for the best experience.

# Pre-requisites and Limitations

- Only CentOS 7.x is supported (If you need to install CentOS 6.x, check out the **iPXE** method)
- Image file must be put on Linux file system, `ext4` has been tested
- When using image file from local hard disk, LVM logic volume is not supported
- When using image file from local hard disk, `<mount_point>/osimages/xxxx.devuuid` file must exist

# Quick Start

If your MagicDrive is using Linux file system, e.g. `ext4`

1. Copy the CentOS installation image file (*.iso) to `<MagicDrive>/osimages/CentOS/`
2. Reboot your machine from the USB drive
3. Select **Install CentOS** to list all valid CentOS installation image files
4. Select the image file you want to use
5. Continue CentOS installation as well as you are using a physical DVD

or else, see **Using image files on hard disk of the physical machine**

# For Advanced Users

### Using image files on hard disk of the physical machine

1. Make the same directory structure as that in MagicDrive: `mkdir -p <mount_point>/osimages/CentOS`, and create `<mount_point>/osimages/xxxx.devuuid` file, for example:

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
root@ubuntu:~# mkdir -p ${mount_point}/osimages/CentOS
root@ubuntu:~# grub-probe --targe=fs_uuid --device /dev/sdc1
0d0935cd-574a-4108-8082-cba7899295fe
root@ubuntu:~# touch ${mount_point}/osimages/0d0935cd-574a-4108-8082-cba7899295fe.devuuid
root@ubuntu:~# ls -l ${mount_point}/osimages/0d0935cd-574a-4108-8082-cba7899295fe.devuuid
-rw-r--r-- 1 root root 0 Jun 29 23:11 /data/osimages/0d0935cd-574a-4108-8082-cba7899295fe.devuuid
root@ubuntu:~# 
```

2. Copy CentOS installation image file (*.iso) to the `<mount_point>/osimages/CentOS` you created
3. Reboot your machine from the USB drive
4. Select **Install CentOS** to list all valid CentOS installation image files
5. Select the image file you want to use
6. Continue CentOS installation as well as you are using a physical DVD
