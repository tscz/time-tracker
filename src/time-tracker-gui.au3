; Enforce DPI Awareness for High-Res Displays, see https://docs.microsoft.com/en-gb/windows/win32/hidpi/dpi-awareness-context
If @OSVersion = 'WIN_10' Then DllCall("User32.dll", "bool", "SetProcessDpiAwarenessContext", "HWND", "DPI_AWARENESS_CONTEXT" - 2)
If @OSVersion = 'WIN_81' Then DllCall("User32.dll", "bool", "SetProcessDPIAware")

#include <GuiListView.au3>
#include <GUIConstantsEx.au3>
#include <StringConstants.au3>

#include <time-tracker-db.au3>
#include <time-tracker-excel.au3>

Opt("GUICoordMode", 2) ;1=absolute, 0=relative, 2=cell


Global $TASKS = []
Global $idListview = 0

;GUI_Example()


Func GUI_Example()
	Local $hDskDb = _DB_Startup(@ScriptDir & "\..\lib\sqlite3_29_0.dll")
	Local $iAllTasks = _DB_GetTasks()
	MainGui($iAllTasks)
	_DB_Shutdown($hDskDb)
EndFunc

Func Refresh()
	 $TASKS = _DB_GetTasks()
	_GUICtrlListView_DeleteAllItems ( $idListview )
	_GUICtrlListView_AddArray($idListview, $TASKS)
EndFunc


; Main GUI script
Func MainGui(ByRef $iAllTasks)

	Local $hGUI = GUICreate("Manage Tasks",500,400)
	$idListview = GUICtrlCreateListView("", 10, 10, 480, 300)
	_GUICtrlListView_AddColumn($idListview, "Task-ID", 100)
	_GUICtrlListView_AddColumn($idListview, "Task", 350)
	_GUICtrlListView_AddArray($idListview, $iAllTasks)
	Local $idAdd = GUICtrlCreateButton("Add", -1, 20, 100, 30)
	Local $idDelete = GUICtrlCreateButton("Delete", 20, -1, 100, 30)
	Local $idExport = GUICtrlCreateButton("Export", 20, -1, 100, 30)

	; Display the GUI.
	GUISetState(@SW_SHOW, $hGUI)


	; Loop until the user exits.
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $idDelete
				Local $selectedTask = _GUICtrlListView_GetItemTextarray ( $idListview)[1]
				_DB_RemoveTask($selectedTask)
				Refresh()
			Case $idAdd
				Local $id = InputBox("Task-ID", "Please enter a task id.")
				Local $description = InputBox("Task-Descriptio ", "Please enter a task description.")
				_DB_AddTask($id,$description)
				Refresh()
			case $idExport
				Export()
		EndSwitch
	WEnd

	; Delete the previous GUI and all controls.
	GUIDelete($hGUI)
EndFunc

Func Export()
	Excel_Export(_DB_GetTasks(),_DB_GetTimeTrackings())
EndFunc