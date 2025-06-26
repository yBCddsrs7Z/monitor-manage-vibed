#Requires AutoHotkey v2.0

scriptsDir := A_MyDocuments "\monitor-manage\scripts"

!1:: { ; Alt+1 hotkey
    Run('powershell -ExecutionPolicy Bypass -File "' scriptsDir '\desktop.ps1"')
}

!2:: { ; Alt+2 hotkey
    Run('powershell -ExecutionPolicy Bypass -File "' scriptsDir '\tv.ps1"')
}

!3:: { ; Alt+3 hotkey
    desktop_active := scriptsDir "\1"
    tv_active := scriptsDir "\2"
    if FileExist(desktop_active) {
        Run('powershell -ExecutionPolicy Bypass -File "' scriptsDir '\desktop.ps1"')
        FileAppend("", tv_active)
        FileDelete(desktop_active)
    } else if FileExist(tv_active) {
        Run('powershell -ExecutionPolicy Bypass -File "' scriptsDir '\tv.ps1"')
        FileAppend("", desktop_active)
        FileDelete(tv_active)
    } else {
        FileAppend("", desktop_active)
    }
}
