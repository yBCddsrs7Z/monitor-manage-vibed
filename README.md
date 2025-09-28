# monitor-manage

AHK script to configure profiles of enabled / disabled displays and the default audio device. 

- Create configs with names "1" through "9".
- First display in each config will be set to primary.
- Switch to the config by pressing alt+n on your keyboard.
- Cycle through all profiles in order with alt+0

<details>
  <summary>Example configuration:</summary>
  
```json
{
  "1": {
    "audio": "Speakers (5- ODAC-revB USB DAC)",
    "activeDisplays": [
      "AW2725DF"
    ],
    "disableDisplays": [
      "LG TV SSCR2"
    ]
  },
  "2": {
    "audio": "Speakers (5- ODAC-revB USB DAC)",
    "activeDisplays": [
      "AW2725DF",
      "LG TV SSCR2"
    ],
    "disableDisplays": []
  },
  "3": {
    "audio": "LG TV SSCR2 (NVIDIA High Definition Audio)",
    "activeDisplays": [
      "AW2725DF",
      "LG TV SSCR2"
    ],
    "disableDisplays": []
  },
  "4": {
    "audio": "LG TV SSCR2 (NVIDIA High Definition Audio)",
    "activeDisplays": [
      "LG TV SSCR2"
    ],
    "disableDisplays": [
      "AW2725DF"
    ]
  }
}
```
</details>
   
## Prerequisites
Requires:
- [AutoHotkey](https://www.autohotkey.com/download/)
- Powershell modules
  - Requires DisplayConfig - `Install-Module -Name DisplayConfig -RequiredVersion 5.0.0`
  - Requires AudioDeviceCmdlets - `Install-Module -Name AudioDeviceCmdlets -Repository PSGallery -Force`

Usage guide:
- Install prerequisites
- Clone repository / download files to Documents folder
- Create profiles in `config.json`
  - Find display names through `Get-DisplayInfo`
  - Find audio device names through `Get-AudioDevice -List`
- Create shortcut of `monitor-toggle.ahk`
- Choose AHK as the default program for `.ahk` files
- Open startup folder with Win+R `shell:startup`
- Move the shortcut into the folder
- Note: Updates to the config file will only take effect if you re-open `monitor-toggle.ahk`
