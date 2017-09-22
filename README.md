# MagicDrive

## Introduction

A MagicDrive is a special USB storage device, it's a unified OS installer. You only need to copy OS installation image (*.iso) files to the MagicDrive and then boot your computer from the MagicDrive, you'll be able to install different OSes from the MagicDrive.

## Advantages

- The MagicDrive uses original OS installation image (*.iso) files, not separated files from the OS installation images. So you can re-use the OS installation image files in MagicDrive for other purposes, like install OS for a virtual machine.

- You can only see 1~2 folders for MagicDrive in the USB storage root folder. It looks very clean (If you ever created bootable USB of Windows OS or WinPE, you must know what I mean). You are free to save your other files in the MagicDrive, like documents and photos.

- To add a new OS support, you only need to copy the OS installation image file to MagicDrive. You don't have to wipe and rewrite your USB device to install different OSes. Your personal files on MagicDrive are not impacted.

- One MagicDrive (with different OS installation images) can be used to install many different OSes without any modification.

- It supports all Windows (Windows Vista and later) and Ubuntu perfectly. It also has limited support for other Linux distributions, such as RHEL, CentOS, etc.

- For Windows installation, it can use Windows installation images on network share without PXE support.

## How To...

Please refer to [MagicDriveCreation.md](Docs/MagicDriveCreation.md) about how to create a MagicDrive with a general USB storage device.

Then find and read the **Readme.html** files under `osimages/<OS_name>/` of your MagicDrive for further instructions.
