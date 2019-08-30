; For values available to Windows 10 users - https://docs.microsoft.com/en-gb/windows/win32/hidpi/dpi-awareness-context

If @OSVersion = 'WIN_10' Then DllCall("User32.dll", "bool", "SetProcessDpiAwarenessContext" , "HWND", "DPI_AWARENESS_CONTEXT" -2)
If @OSVersion = 'WIN_81' Then DllCall("User32.dll", "bool", "SetProcessDPIAware")

#NoTrayIcon
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <TrayConstants.au3>

Opt("TrayMenuMode", 3) ; The default tray menu items will not be shown and items are not checked when selected. These are options 1 and 2 for TrayMenuMode.
Opt("TrayOnEventMode", 1) ; Enable TrayOnEventMode.

Global $iCurrentTask
Global $aArray = 0

#include <Array.au3>
#include <File.au3>
#include <MsgBoxConstants.au3>


Func initFile($sFilePath)
	Local $hFileOpen = FileOpen($sFilePath, BitOR($FO_APPEND , $FO_CREATEPATH))
	If $hFileOpen = -1 Then Return SetError(1, 0, 0)

	FileClose($hFileOpen)
EndFunc


Func CreateOrReadConfig()

Local $sFilePath = @LocalAppDataDir & "\time-tracker\tasks.csv"

initFile($sFilePath)

Local $emptyTaskList[2] = [1, "No Task definied"]


If FileGetSize($sFilePath) = 0 Then
	$aArray = $emptyTaskList
Else
    ; Read the current script file into an array using the variable defined previously.
    ; $iFlag is specified as 0 in which the array count will not be defined. Use UBound() to find the size of the array.
    If Not _FileReadToArray($sFilePath, $aArray) Then
        MsgBox($MB_SYSTEMMODAL, "", "There was an error reading the file. @error: " & @error) ; An error occurred reading the current script file.
    EndIf
EndIf



EndFunc

CreateOrReadConfig()
Example()



Func Example()
	$iCurrentTask = TrayCreateItem("No Current Task");
    Local $iSettings = TrayCreateMenu("Swich Current task") ; Create a tray menu sub menu with two sub items.


	For $i = 1 To $aArray[0]
		$aArray[$i] = TrayCreateItem($aArray[$i], $iSettings,-1,$TRAY_ITEM_RADIO)
		TrayItemSetOnEvent(-1, "setCurrentTask")
	Next

TrayCreateItem("") ; Create a separator line.

    Local $idAbout = TrayCreateItem("Manage Tasks")
	TrayItemSetOnEvent(-1, "About")
    TrayCreateItem("") ; Create a separator line.

    Local $idExit = TrayCreateItem("Exit")
    TrayItemSetOnEvent(-1, "ExitScript")


    TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, "About") ; Display the About MsgBox when the tray icon is double clicked on with the primary mouse button.

    TraySetState($TRAY_ICONSTATE_SHOW) ; Show the tray menu.

    While 1
        Sleep(100) ; An idle loop.
    WEnd
EndFunc   ;==>Example

Func setCurrentTask()
	TrayItemSetText($iCurrentTask,TrayItemGetText(@TRAY_ID))
	TrayTip ( "New Task set", TrayItemGetText(@TRAY_ID) , 0 ,$TIP_ICONASTERISK )

EndFunc

Func About()
    ; Display a message box about the AutoIt version and installation path of the AutoIt executable.
    MsgBox($MB_SYSTEMMODAL, "", "AutoIt tray menu example." & @CRLF & @CRLF & _
            "Version: " & @AutoItVersion & @CRLF & _
            "Install Path: " & StringLeft(@AutoItExe, StringInStr(@AutoItExe, "\", $STR_NOCASESENSEBASIC, -1) - 1)) ; Find the folder of a full path.
EndFunc   ;==>About

Func ExitScript()
	Exit
EndFunc   ;==>ExitScript

