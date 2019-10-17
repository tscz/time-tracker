; Enforce DPI Awareness for High-Res Displays, see https://docs.microsoft.com/en-gb/windows/win32/hidpi/dpi-awareness-context
If @OSVersion = 'WIN_10' Then DllCall("User32.dll", "bool", "SetProcessDpiAwarenessContext", "HWND", "DPI_AWARENESS_CONTEXT" - 2)
If @OSVersion = 'WIN_81' Then DllCall("User32.dll", "bool", "SetProcessDPIAware")

#include <GuiListView.au3>
#include <GUIConstantsEx.au3>
#include <StringConstants.au3>
#include <WindowsConstants.au3>
#include <Date.au3>
#include <WinAPISysWin.au3>


#include <time-tracker-db.au3>
#include <time-tracker-excel.au3>

Opt("GUICoordMode", 2) ;1=absolute, 0=relative, 2=cell
Opt("GUIOnEventMode", 1) ; Change to OnEvent mode

Global $TASKS = []
Global $idListview = 0
Global $parent = 0

;GUI_Example()


Func GUI_Example()
	Local $hDskDb = _DB_Startup(@ScriptDir & "\..\lib\sqlite3_29_0.dll")
	Local $iAllTasks = _DB_GetTasks()
	;MainGui($iAllTasks,0)
	_DB_Shutdown($hDskDb)
EndFunc

Func Refresh()
	 $TASKS = _DB_GetTasks()
	_GUICtrlListView_DeleteAllItems ( $idListview )
	_GUICtrlListView_AddArray($idListview, $TASKS)
EndFunc


; Main GUI script
Func MainGui(ByRef $iAllTasks, ByRef $guiParent)

	$parent = $guiParent

	Global $hGUI = GUICreate("Manage Tasks",500,400)
	$idListview = GUICtrlCreateListView("", 10, 10, 480, 300)
	_GUICtrlListView_AddColumn($idListview, "Task-ID", 100)
	_GUICtrlListView_AddColumn($idListview, "Task", 350)
	_GUICtrlListView_AddArray($idListview, $iAllTasks)
	Local $idAdd = GUICtrlCreateButton("Add", -1, 20, 100, 30)
	Local $idDelete = GUICtrlCreateButton("Delete", 20, -1, 100, 30)
	Local $idExport = GUICtrlCreateButton("Export", 20, -1, 100, 30)

	; Add Event Handler
	GUISetOnEvent($GUI_EVENT_CLOSE, "MainGuiClose",$hGUI)
	GUICtrlSetOnEvent($idAdd, "AddTask")
	GUICtrlSetOnEvent($idDelete, "DeleteTask")
	GUICtrlSetOnEvent($idExport, "ExportTasks")

	; Display the GUI.
	GUISetState(@SW_SHOW, $hGUI)

	Return $hGUI
EndFunc

Func MainGuiClose()
	GUIDelete($hGUI)
	_WinAPI_SendMessageTimeout($parent,_WinAPI_RegisterWindowMessage('CLOSE_EVENT'))
EndFunc

Func DeleteTask()
	Local $selectedTask = _GUICtrlListView_GetItemTextarray ( $idListview)[1]
	_DB_RemoveTask($selectedTask)
	Refresh()
EndFunc

Func AddTask()
	Local $id = InputBox("Task-ID", "Please enter a task id.")
	Local $description = InputBox("Task-Descriptio ", "Please enter a task description.")
	_DB_AddTask($id,$description)
	Refresh()
EndFunc

Func ExportTasks()
	Export()
EndFunc


Func Export()
	Excel_Export(_DB_GetTasks(),_DB_GetTimeTrackings())
EndFunc

Func TimeboxGui($totalMinutes)
	Global $popup = GUICreate('TimeboxCounter', 170, 50, @DesktopWidth + (-180), @DesktopHeight + (-120), $WS_POPUPWINDOW,Default, WinGetHandle(AutoItWinGetTitle()))

	GUISetBkColor(0x000000)
	Global $clockLabel = GUICtrlCreateLabel('', 10, 0, 500, 100)
	GUICtrlSetFont($clockLabel, 20, 0, 0, 'Segoe UI')
	GUICtrlSetColor($clockLabel, 0x32cd32)
	WinSetTrans($popup, "", 190)
	WinSetOnTop($popup, "", 1)

	GUISetState(@SW_SHOW ,$popup)

	Global $end = _DateAdd('n', $totalMinutes, _NowCalc())
		Timer()

	AdlibRegister("Timer", 50)

EndFunc

Func TimeboxGuiClose()
	GUIDelete($popup)
	AdlibUnRegister("Timer")
EndFunc

Func TimeboxGuiPause()
	AdlibUnRegister("Timer")
	Global $delay = _DateDiff ( "s", _NowCalc(), $end )
EndFunc

Func TimeboxGuiResume()
	$end = _DateAdd('s', $delay, _NowCalc())
	AdlibRegister("Timer")
EndFunc

Func Timer()
	Local $now = _NowCalc()
	Local $difference =  _DateDiff ( "s", $now, $end )

	If $difference <= 0 Then
		GUICtrlSetData($clockLabel, StringFormat("%02i:%02i:%02i", 0, 0, 0))
		GUICtrlSetColor($clockLabel,  0xFF0000)
		AdlibUnRegister("Timer")
		Return
	EndIf

	Local $hours = Mod($difference / 60 / 60, 60)
	Local $minutes = Mod($difference / 60, 60)
	Local $seconds = Mod($difference,60)

	Local $g_sTime = StringFormat("%02i:%02i:%02i", $hours, $minutes, $seconds)
	If GUICtrlRead($clockLabel) <> $g_sTime Then GUICtrlSetData($clockLabel, $g_sTime)

EndFunc