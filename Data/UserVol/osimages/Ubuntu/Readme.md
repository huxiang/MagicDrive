> Read this file with the latest **Google Chrome** or **Mozilla Firefox** for the best experience.

# Pre-requisites and Limitations

- Image file should not be put on `exFAT` file system
- Image file can be put on `ext4` and `NTFS` file systems, other file systems have not been tested
- For using image file from local hard disk, LVM logic volume is not supported

# Quick Start

1. Copy the Ubuntu installation image file (*.iso) to `<MagicDrive>:\osimages\Ubuntu\`
2. Reboot your machine from the USB drive
3. Select **Install Ubuntu** to list all valid Ubuntu installation image files
4. Select the image file you want to use
5. Continue Ubuntu installation as well as you are using a physical DVD

# For Advanced Users

### Using image files on hard disk of the physical machine

1. Make the same directory structure as that in MagicDrive: `mkdir <local_fs_root>:\osimages\Ubuntu`(on Windows) or `mkdir -p <local_fs_root/mount_point>/osimages/Ubuntu` (on Linux)
2. Copy Ubuntu installation image file (*.iso) to the `osimages\Ubuntu` you created
3. Reboot your machine from the USB drive
4. Select **Install Ubuntu** to list all valid Ubuntu installation image files
5. Select the image file you want to use
6. Continue Ubuntu installation as well as you are using a physical DVD
