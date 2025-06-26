#Requires AutoHotkey v2.0

scriptsDir := A_MyDocuments "\monitor-manage\scripts"
desktop_active := scriptsDir "\desktop_active"
tv_active := scriptsDir "\tv_active"

!1:: { ; Alt+1 hotkey
    Run('powershell -ExecutionPolicy Bypass -File "' scriptsDir '\desktop.ps1"')
    FileAppend("", desktop_active)
    if FileExist(tv_active) {
        FileDelete(tv_active)
    }
}

!2:: { ; Alt+2 hotkey
    Run('powershell -ExecutionPolicy Bypass -File "' scriptsDir '\tv.ps1"')
    FileAppend("", tv_active)
    if FileExist(desktop_active) {
        FileDelete(desktop_active)
    }
}

!3:: { ; Alt+3 hotkey
    if FileExist(tv_active) {
        Run('powershell -ExecutionPolicy Bypass -File "' scriptsDir '\desktop.ps1"')
        FileAppend("", desktop_active)
        FileDelete(tv_active)
    } else if FileExist(desktop_active) {
        Run('powershell -ExecutionPolicy Bypass -File "' scriptsDir '\tv.ps1"')
        FileAppend("", tv_active)
        FileDelete(desktop_active)
    } else {
        Run('powershell -ExecutionPolicy Bypass -File "' scriptsDir '\desktop.ps1"')
        FileAppend("", desktop_active)
    }
}
