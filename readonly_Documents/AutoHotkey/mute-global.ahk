#Requires AutoHotkey v2.0

; WIN + SHIFT + S → Toggle mute speakers
#+s::
{
    try
        SoundSetMute(-1)
    catch
        return
    status := SoundGetMute() ? "🔇 Audio OFF" : "🔊 Audio ON"
    OcultarTray()
    TrayTip(status, "Altavoces")
    SetTimer(OcultarTray, -1000)
}

; WIN + SHIFT + M → Toggle mute microphone
#+m::
{
    try
        SoundSetMute(-1,, "Microphone")
    catch
        return
    status := SoundGetMute(, "Microphone") ? "🔇 Mic OFF" : "🎤 Mic ON"
    OcultarTray()
    TrayTip(status, "Micrófono")
    SetTimer(OcultarTray, -1000)
}

OcultarTray() {
    TrayTip()
    A_IconHidden := true
    Sleep(200)
    A_IconHidden := false
}
