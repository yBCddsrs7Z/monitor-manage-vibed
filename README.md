# monitor-manage

Simple AHK script to toggle between monitor sets. E.g two desktop monitors and one TV

| Shortcut | Action |
| -------- | ------ |
| alt+1    | Switch to desktop monitors  |
| alt+2    | Switch to TV                |
| alt+3    | Toggle between the two sets |

## prereqs
Requires [DisplayConfig@5.0.0](https://www.powershellgallery.com/packages/DisplayConfig/5.0.0)

Can be configured to be triggered with SteamInput!

Also should be set up as a script on startup:
- Create shortcut of monitor-toggle.ahk
- Ensure AHK is used to automatically open the shortcut
- Open startup folder with Win+R `shell:startup`
- Move the shortcut into the folder