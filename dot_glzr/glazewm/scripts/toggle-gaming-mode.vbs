' Toggles GlazeWM focused_window border, corner_style and transparency on/off,
' then reloads the config.
Dim sh, configPath, content, focused, rest, splitPos, fromVal, toVal, re, bData

Set sh = CreateObject("WScript.Shell")
configPath = sh.ExpandEnvironmentStrings("%USERPROFILE%") & "\.glzr\glazewm\config.yaml"

' Read UTF-8 file
Dim streamIn : Set streamIn = CreateObject("ADODB.Stream")
streamIn.Type = 2
streamIn.Charset = "UTF-8"
streamIn.Open
streamIn.LoadFromFile configPath
content = streamIn.ReadText(-1)
streamIn.Close

' Split at other_windows so replacements only affect focused_window
splitPos = InStr(content, "  other_windows:")
If splitPos > 1 Then
    focused = Left(content, splitPos - 1)
    rest    = Mid(content, splitPos)
Else
    focused = content
    rest    = ""
End If

' Detect current state
Set re = New RegExp
re.Pattern = "border:\r?\n      enabled: false"
If re.Test(focused) Then
    fromVal = "false" : toVal = "true"
Else
    fromVal = "true"  : toVal = "false"
End If

' Toggle border, corner_style, transparency
re.Global = True
re.Pattern = "(border:\r?\n      enabled:) " & fromVal
focused = re.Replace(focused, "$1 " & toVal)
re.Pattern = "(corner_style:\r?\n      enabled:) " & fromVal
focused = re.Replace(focused, "$1 " & toVal)
re.Pattern = "(transparency:\r?\n      enabled:) " & fromVal
focused = re.Replace(focused, "$1 " & toVal)

content = focused & rest

' Write UTF-8 without BOM
Dim streamOut : Set streamOut = CreateObject("ADODB.Stream")
streamOut.Open
streamOut.Type = 2
streamOut.Charset = "UTF-8"
streamOut.WriteText content
streamOut.Position = 0
streamOut.Type = 1
streamOut.Position = 3 ' Skip 3-byte UTF-8 BOM
bData = streamOut.Read
streamOut.Close

Dim streamFinal : Set streamFinal = CreateObject("ADODB.Stream")
streamFinal.Open
streamFinal.Type = 1
streamFinal.Write bData
streamFinal.SaveToFile configPath, 2
streamFinal.Close

' Reload GlazeWM config
Dim glazewmExe : glazewmExe = sh.ExpandEnvironmentStrings("%ProgramFiles%\glzr.io\GlazeWM\cli\glazewm.exe")
sh.Run """" & glazewmExe & """ command wm-reload-config", 0, False
