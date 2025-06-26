#Requires AutoHotkey v2.0

!1:: { ; Alt+1 hotkey
    Run('powershell -ExecutionPolicy Bypass -File "C:\Users\Matt\development\monitor-manage\scripts\desktop.ps1"')
}

!2:: { ; Alt+2 hotkey
    Run('powershell -ExecutionPolicy Bypass -File "C:\Users\Matt\development\monitor-manage\scripts\tv.ps1"')
}

!3:: { ; Alt+3 hotkey
    if FileExist("C:\Users\Matt\development\monitor-manage\scripts\1") {
        Run('powershell -ExecutionPolicy Bypass -File "C:\Users\Matt\development\monitor-manage\scripts\desktop.ps1"')
        FileAppend("", "C:\Users\Matt\development\monitor-manage\scripts\2")
        FileDelete("C:\Users\Matt\development\monitor-manage\scripts\1")
    } else if FileExist("C:\Users\Matt\development\monitor-manage\scripts\2") { 
        Run('powershell -ExecutionPolicy Bypass -File "C:\Users\Matt\development\monitor-manage\scripts\tv.ps1"')
        FileAppend("", "C:\Users\Matt\development\monitor-manage\scripts\1")
        FileDelete("C:\Users\Matt\development\monitor-manage\scripts\2")
    } else {
        FileAppend("", "C:\Users\Matt\development\monitor-manage\scripts\1")
    }
}