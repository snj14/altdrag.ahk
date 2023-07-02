#Requires AutoHotkey v2.0

; 左Alt + 左ドラッグ：ウィンドウ移動
; 左Alt + 右ドラッグ：ウィンドウサイズ変更

GetMonitorIndexFromWindow(windowHandle) {
    max_area := 0
    max_index := 0
    WinGetPos &win_left, &win_top, &w, &h, windowHandle
    win_right  := win_left + w
    win_bottom := win_top + h
    Loop MonitorGetCount() {
        MonitorGet A_Index, &mon_left, &mon_top, &mon_right, &mon_bottom
        area := (min(win_right, mon_right) - max(win_left,mon_left)) * (min(win_bottom,mon_bottom) - max(win_top,mon_top))
        if(max_area < area) {
            max_area := area
            max_index := A_Index
        }
    }
    return max_index
}
GetMonitorIndexFromMouse(){
    monitorIndex := 0
    CoordMode("Mouse", "Screen")
    MouseGetPos(&xpos, &ypos)
    Loop MonitorGetCount() {
        MonitorGet A_Index, &mon_left, &mon_top, &mon_right, &mon_bottom
        if (mon_Left < xpos and mon_Top < ypos and mon_Right > xpos and mon_Bottom > ypos) {
            monitorIndex := A_Index
            break
        }
    }
    return monitorIndex
}

; left   : 0 1/2
; top    : 0 1/2
; width  : 1 1/2
; height : 1 1/2
SnapActiveWindow(left_, top_, width_,height_, mouse_or_window) {
    offset := WinACtive("ahk_group GroupSnapNoOffset") ? 0 : 8
    WinGetMinMax("A") && WinRestore("A") ; restore if maximized 
    activeMon := (mouse_or_window == "mouse") ? GetMonitorIndexFromMouse() : GetMonitorIndexFromWindow("A")
    MonitorGetWorkArea(activeMon, &MN_Left, &MN_Top, &MN_Right, &MN_Bottom)
    width  := (MN_Right - MN_Left) * width_  + (offset * 2)
    height := (MN_BOTTOM - MN_TOP) * height_ + (offset)
    top    := MN_TOP  + ((MN_BOTTOM - MN_TOP))*top_
    left   := MN_LEFT + ((MN_RIGHT - MN_LEFT))*left_ - (offset)
    WinMove(left,top,width,height,"A")
}


; window move
; LWin & LButton::
LAlt & LButton::
{
    mouse_button := GetKeyState("MButton","P") ? "MButton" : GetKeyState("LButton","P") ? "LButton" : GetKeyState("RButton","P") ? "RButton" : ""

    ; maximize when double click
    If (A_ThisHotkey = A_PriorHotkey and A_TimeSincePriorHotkey < 500){
        WinMaximize "A"
        return
    }
    CoordMode("Mouse","Screen")
    MouseGetPos(&sx,&sy,&mh)
    ; except desktop
    class := WinGetClass("ahk_id " mh)
    if (class == "WorkerW") {
        return
    }
    ; detect offset
    offset := WinACtive("ahk_group GroupSnapNoOffset") ? 0 : 8
    ; restore if maximized
    if (WinGetMinMax("ahk_id " mh) == 1) {
        WinRestore "ahk_id " mh
        WinGetPos &wx,&wy,&ww,&wh,"ahk_id " mh
        WinMove(wx,wh,sx-(ww/2),sy-(wh/2),"ahk_id " mh)
    }
    ; prepare to snap
    monitors := []
    Loop MonitorGetCount()
    {
        MonitorGetWorkArea(A_Index, &MN_Left, &MN_Top, &MN_Right, &MN_Bottom)
        monitors.push([MN_Left,MN_Right,MN_Top,MN_Bottom])
    }

    WinGetPos(&wx,&wy,&ww,&wh,"ahk_id " mh)
    WinActivate("ahk_id " mh)

    while(GetKeyState(mouse_button,"P")){
        MouseGetPos(&mx,&my)
        snap_direction := ""
        ; detect snap position
        For index, element in monitors {
            if (!(element[1] < mx && mx < element[2] && element[3] < my && my < element[4])){
                continue
            }
            if (element[1] -1 < mx && mx < element[1] +50){
                snap_direction := "left"
            }else if (element[2] -50 < mx && mx < element[2] +1){
                snap_direction := "right"
            }else if (element[3] -1 < my && my < element[3] +50){
                snap_direction := "top"
            }
        }
        if (snap_direction == "top"){
            WinMaximize "A"
        }else if (snap_direction == "left"){
            SnapActiveWindow(0,0,1/2,1,"mouse")
        }else if (snap_direction == "right"){
            SnapActiveWindow(1/2,0,1/2,1,"mouse")
        }else{
            WinGetMinMax("A") && WinRestore("A") ; restore if maximized
            WinMove(wx-(sx-mx),wy-(sy-my),ww,wh,"A")
        }
    }
    return
}

; window resize
; LWin & RButton::
LAlt & RButton::
{
    CoordMode("Mouse","Screen")
    MouseGetPos(&sx,&sy,&mh)
    ; except desktop
    if (WinGetClass("ahk_id " mh) == "WorkerW") {
        return
    }
    WinGetPos(&wx,&wy,&ww,&wh,"ahk_id " mh)
    WinActivate("ahk_id " mh)
    ; restore if maximized
    if (WinGetMinMax("ahk_id " mh) == 1) {
        WinRestore "ahk_id " mh
    }
    WinMove(wx,wy,sx-wx+5,sy-wy+5,"ahk_id " mh)
    while(GetKeyState("RButton","P")){
        MouseGetPos(&mx,&my)
        WinMove(wx,wy,mx-wx+5,my-wy+5,"ahk_id " mh)
    }
}
