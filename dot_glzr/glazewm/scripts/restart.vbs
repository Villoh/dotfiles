' Restarts GlazeWM by killing the process and relaunching it.
Dim sh
Set sh = CreateObject("WScript.Shell")

Dim glazewmExe
glazewmExe = sh.ExpandEnvironmentStrings("%USERPROFILE%\scoop\apps\glazewm\current\glazewm.exe")

sh.Run "taskkill /IM glazewm.exe /F", 0, True
sh.Run """" & glazewmExe & """", 0, False
