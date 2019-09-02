; For values available to Windows 10 users - https://docs.microsoft.com/en-gb/windows/win32/hidpi/dpi-awareness-context
If @OSVersion = 'WIN_10' Then DllCall("User32.dll", "bool", "SetProcessDpiAwarenessContext", "HWND", "DPI_AWARENESS_CONTEXT" - 2)
If @OSVersion = 'WIN_81' Then DllCall("User32.dll", "bool", "SetProcessDPIAware")

#NoTrayIcon
#include <Array.au3>
#include <File.au3>
#include <GuiListView.au3>

#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <TrayConstants.au3>


Opt("TrayMenuMode", 3) ; The default tray menu items will not be shown and items are not checked when selected. These are options 1 and 2 for TrayMenuMode.
Opt("TrayOnEventMode", 1) ; Enable TrayOnEventMode.

HotKeySet("^+1", "setCurrentTaskViaHotkey")
HotKeySet("^+2", "setCurrentTaskViaHotkey")
HotKeySet("^+3", "setCurrentTaskViaHotkey")
HotKeySet("^+4", "setCurrentTaskViaHotkey")
HotKeySet("^+5", "setCurrentTaskViaHotkey")
HotKeySet("^+6", "setCurrentTaskViaHotkey")
HotKeySet("^+7", "setCurrentTaskViaHotkey")
HotKeySet("^+8", "setCurrentTaskViaHotkey")
HotKeySet("^+9", "setCurrentTaskViaHotkey")
HotKeySet("^+0", "setCurrentTaskViaHotkey")

Global $iAllTasks = []
Global $iAllTasksTrayItems = []

main()

Func main()

	Local $sFilePath = @LocalAppDataDir & "\time-tracker\tasks.csv"

	CreateOrReadConfig($sFilePath)

	TrayLoop()

EndFunc   ;==>main



Func CreateOrReadConfig($sFilePath)

	Local $hFileOpen = FileOpen($sFilePath, BitOR($FO_APPEND, $FO_CREATEPATH))
	If $hFileOpen = -1 Then Return SetError(1, 0, 0)
	FileClose($hFileOpen)

	If FileGetSize($sFilePath) = 0 Then
		$iAllTasks = 0
	Else
		If Not _FileReadToArray($sFilePath, $iAllTasks,$FRTA_NOCOUNT,",") Then
			MsgBox($MB_SYSTEMMODAL, "", "There was an error reading the file. @error: " & @error) ; An error occurred reading the current script file.
		EndIf
	EndIf

EndFunc   ;==>CreateOrReadConfig


Func TrayLoop()
	ReDim $iAllTasksTrayItems[UBound($iAllTasks)]

	For $i = 0 To UBound($iAllTasks) - 1
		$iAllTasksTrayItems[$i] = TrayCreateItem($iAllTasks[$i][0] & ":" & $iAllTasks[$i][1], -1, -1, $TRAY_ITEM_RADIO)
		TrayItemSetOnEvent(-1, "setCurrentTaskViaMouse")
	Next

	If UBound($iAllTasksTrayItems) > 0 Then TrayItemSetState($iAllTasksTrayItems[0],$TRAY_CHECKED)

	TrayCreateItem("") ; Create a separator line.

	Local $idAbout = TrayCreateItem("Manage Tasks")
	TrayItemSetOnEvent(-1, "ShowGui")
	TrayCreateItem("") ; Create a separator line.

	Local $idExit = TrayCreateItem("Exit")
	TrayItemSetOnEvent(-1, "ExitScript")

	TraySetState($TRAY_ICONSTATE_SHOW) ; Show the tray menu.

	While 1
		Sleep(100) ; An idle loop.
	WEnd
EndFunc   ;==>TrayLoop


Func setCurrentTaskViaHotkey()
	Local $hotkeyId = StringRight(@HotKeyPressed,1)

	If $hotkeyId > UBound($iAllTasksTrayItems) Then Return


	Local $newCurrentTask = 0
	If $hotkeyId = 0 Then
		$newCurrentTask = $iAllTasksTrayItems[9]
	Else
		$newCurrentTask = $iAllTasksTrayItems[$hotkeyId-1]
	EndIf

	setCurrentTask(TrayItemGetText($newCurrentTask))

	For $task In $iAllTasksTrayItems
		If $task == $newCurrentTask Then
			TrayItemSetState($task,$TRAY_CHECKED)
		Else
			TrayItemSetState($task,$TRAY_UNCHECKED)
		EndIf
	Next
EndFunc

Func setCurrentTaskViaMouse()
	setCurrentTask(TrayItemGetText(@TRAY_ID))
EndFunc   ;==>setCurrentTask

Func setCurrentTask($text)
	TrayTip("New Task set", $text, 0, $TIP_ICONASTERISK)
EndFunc   ;==>setCurrentTask

Func ShowGui()
	; Create a GUI with various controls.
	Local $hGUI = GUICreate("Manage Tasks")
	Local $idOK = GUICtrlCreateButton("Close", 310, 370, 85, 25)

	$idListview = GUICtrlCreateListView("", 2, 2, 394, 268)
	GUISetState(@SW_SHOW)

	; Add columns
	_GUICtrlListView_AddColumn($idListview, "Task-ID", 100)
	_GUICtrlListView_AddColumn($idListview, "Task", 100)

	; Display the GUI.
	GUISetState(@SW_SHOW, $hGUI)

	_GUICtrlListView_AddArray($idListview, $iAllTasks)

	; Loop until the user exits.
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $idOK
				ExitLoop

		EndSwitch
	WEnd

	; Delete the previous GUI and all controls.
	GUIDelete($hGUI)
EndFunc   ;==>About

Func ExitScript()
	Exit
EndFunc   ;==>ExitScript

