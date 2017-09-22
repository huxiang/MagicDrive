> Read this file with the latest **Google Chrome** or **Mozilla Firefox** for the best experience.

# Pre-requisites and Limitations

* Only support portable tools
* 32 bit tool can only be used in 32 bit Windows PE; 64 bit tool can only be used in 64 bit Windows PE

# Quick Start

1. (Optional) Navigate to the `PortableTools` folder on MagicDrive, create sub-folders for 32 bit and 64 bit tools, any folder name is OK
2. Copy the tools to seperate sub folders
3. Edit `PortableTools-x86.csv` to fill in information of 32 bit tools, edit `PortableTools-x64.csv` to fill in information of 64 bit tools
4. Reboot from the MagicDrive and select **Install Windows**, you'll be able to start the **Third-Party Tools Launcher** in Windows PE by using `t`

# How to Configure the PortableTools-*.csv Files

They are the index files of your third-party tools, you only need to fill 3 properties for each tool:

* **AppPath**: The executable file (\*.exe) path of the tool, it should be the relative path from the configuration file (PortableTools-\*.csv). This property is required.
* **AppName**: A friendly display name for the tool. This property is optional. AppPath will be used if it's not given.
* **AppDescription**: Brief description for the tool. This property is optional.

### Example

You have the configuration file: `F:\PortableTools\x86\PortableTools-x86.csv`. And You have two third-party tools: `F:\PortableTools\x86\Everything\Everything.exe` and `F:\PortableTools\x86\ghost32.exe`.

You can write the configure file `F:\PortableTools\x86\PortableTools-x86.csv` like this:

| AppPath                    | AppName    | AppDescription                      |
|----------------------------|------------|-------------------------------------|
| Everything\\Everything.exe | Everything | A rapid local file search tool      |
| ghost32.exe                | Ghost      | A famous system backup/restore tool |
