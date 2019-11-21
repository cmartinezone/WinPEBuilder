# WinPEBuilder 1.1
WinPEBuilder creates your Windows Environment easily and faster in a few clicks. You will be able to Generate a custom WinPE Images with the essential packages included.
## WinPE Packages preset:
- ***HTA, WMI, StorageWMI, Scripting, NetFx, PowerShell, DismCmdlets, FMAPI, SecureBootCmdlets, EnhancedStorage, SecureStartup (BitLocker Support).***
- More information about [WinPE packages](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-add-packages--optional-components-reference#winpe-optional-components-- "WinPE packages")
## How Does it Work?
- First, you must install the [Windows Assessment and Deployment Kit (Windows ADK)](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install "Windows Assessment and Deployment Kit (Windows ADK)").
- Do not Forget to Install New [Windows Preinstallation Environment (PE)](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install#other-adk-downloads "Windows Preinstallation Environment (PE)") is available separately from the Assessment and Deployment Kit (ADK).
- Download the Latest Release zip file and, unzip it.
Now we are almost ready to create our WinPE:
### WinPEBuilder directory layout:
    ├── Add-Drivers   # Add all the drivers in this location, they will added to the WinPE Image.
    ├── Add-Scripts   # any script or file will copy to the WinPE %SYSTEM32% root 
    ├── WinPE-ISO     # The WinPE ISO will be generated on this directory and will named: WinPE_X64.iso 
    └── WinPE-Root    # This Directory is used to mount the WinPE image.
##### Optional:
- Changing the Background: Replace the the image located **"\Add-Scripts\winpe.jpg"** 800x600 px. 
- If you want the default WinPE background remove **"\Add-Scripts\winpe.jpg"**.
- Calling Custom Scripts. You need to edit **["\Add-Scripts\startnet.cmd"](Add-Scripts/startnet.cmd)**
- Add your **Scripts** and **drivers** to the corresponding directories.
------------
#### Run as Administrator: WinPEBuilder.bat
Your WinPE ISO will be ready in 2 to 5 minutes.


## Donate:
If this project helps, you can give me a cup of coffee ;).

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=5NWDHDEXV9582&source=url)
