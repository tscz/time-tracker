; Enforce DPI Awareness for High-Res Displays, see https://docs.microsoft.com/en-gb/windows/win32/hidpi/dpi-awareness-context
If @OSVersion = 'WIN_10' Then DllCall("User32.dll", "bool", "SetProcessDpiAwarenessContext", "HWND", "DPI_AWARENESS_CONTEXT" - 2)
If @OSVersion = 'WIN_81' Then DllCall("User32.dll", "bool", "SetProcessDPIAware")

; Do no show autoit tray icon during startup
#NoTrayIcon

; Libraries
#include <Array.au3>
#include <File.au3>
#include <GuiListView.au3>
#include <time-tracker-db.au3>

; Constants
#include <FileConstants.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <TrayConstants.au3>

; Options
Opt("TrayMenuMode", 3) ;0=append, 1=no default menu, 2=no automatic check, 4=menuitemID  not return
Opt("TrayOnEventMode", 1) ;0=disable, 1=enable
Opt("GUICoordMode", 2) ;1=absolute, 0=relative, 2=cell


; Hotkeys (^=CTRL, +=SHIFT)
HotKeySet("^+1", "SetCurrentTaskViaHotkey")
HotKeySet("^+2", "SetCurrentTaskViaHotkey")
HotKeySet("^+3", "SetCurrentTaskViaHotkey")
HotKeySet("^+4", "SetCurrentTaskViaHotkey")
HotKeySet("^+5", "SetCurrentTaskViaHotkey")
HotKeySet("^+6", "SetCurrentTaskViaHotkey")
HotKeySet("^+7", "SetCurrentTaskViaHotkey")
HotKeySet("^+8", "SetCurrentTaskViaHotkey")
HotKeySet("^+9", "SetCurrentTaskViaHotkey")
HotKeySet("^+0", "SetCurrentTaskViaHotkey")

; Constants
Global Const $DLL = @LocalAppDataDir & "\time-tracker\sqlite_x64.dll"

; Variables
Global $iAllTasks = [] ; Array of all available Tasks
Global $iAllTasksTrayItems = [] ; Array of all available Task Tray Items
Global $db = 0 ; Database object

; Main script
Main()

Func Main()
	InitDlls()
	$db = InitDb()
	InitConfig()
	InitTray()

	While 1
		Sleep(100) ; An idle loop.
	WEnd
EndFunc

; Main GUI script
Func MainGui()

	Local $hGUI = GUICreate("Manage Tasks",500,400)
	Local $idListview = GUICtrlCreateListView("", 10, 10, 480, 300)
	_GUICtrlListView_AddColumn($idListview, "Task-ID", 100)
	_GUICtrlListView_AddColumn($idListview, "Task", 350)
	_GUICtrlListView_AddArray($idListview, $iAllTasks)
	Local $idOK = GUICtrlCreateButton("Close", -1, 20, 100, 30)


	; Display the GUI.
	GUISetState(@SW_SHOW, $hGUI)


	; Loop until the user exits.
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $idOK
				ExitLoop
		EndSwitch
	WEnd

	; Delete the previous GUI and all controls.
	GUIDelete($hGUI)
EndFunc

; Initialize external DLLs
Func InitDlls()
	Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
	Local $dllPath = _PathSplit($DLL, $sDrive, $sDir, $sFileName, $sExtension)

	DirCreate($dllPath[$PATH_DRIVE] & $dllPath[$PATH_DIRECTORY])
	FileInstall("../lib/sqlite3_29_0_x64.dll", $DLL, $FC_OVERWRITE)
EndFunc

Func InitDb()
	Local $hDskDb = _DB_Startup($DLL)
	_DB_InitSchema()

	Return $hDskDb
EndFunc


; Initialize and read configuration from db
Func InitConfig()

	$iAllTasks = _DB_GetTasks()

	If @error Then Exit
EndFunc

; Initialize Tray Menu and add items for all Tasks
Func InitTray()
	ReDim $iAllTasksTrayItems[UBound($iAllTasks)]

	For $i = 0 To UBound($iAllTasks) - 1
		$iAllTasksTrayItems[$i] = TrayCreateItem($iAllTasks[$i][0] & ":" & $iAllTasks[$i][1], -1, -1, $TRAY_ITEM_RADIO)
		TrayItemSetOnEvent(-1, "setCurrentTaskViaMouse")
	Next

	; Set task #1 as the default checked task
	If UBound($iAllTasksTrayItems) > 0 Then TrayItemSetState($iAllTasksTrayItems[0],$TRAY_CHECKED)

	TrayCreateItem("") ; Create a separator line.
	TrayCreateItem("Manage Tasks")
	TrayItemSetOnEvent(-1, "MainGui")

	TrayCreateItem("") ; Create a separator line.
	TrayCreateItem("Exit")
	TrayItemSetOnEvent(-1, "ExitScript")

	TraySetState($TRAY_ICONSTATE_SHOW) ; Show the tray menu.
EndFunc

Func SetCurrentTask($text)
	TrayTip("Currently working on new task", $text, 0, $TIP_ICONASTERISK)
EndFunc

Func SetCurrentTaskViaHotkey()
	Local $hotkeyId = StringRight(@HotKeyPressed,1)

	If $hotkeyId > UBound($iAllTasksTrayItems) Then Return

	Local $newCurrentTask = 0
	If $hotkeyId = 0 Then
		$newCurrentTask = $iAllTasksTrayItems[9]
	Else
		$newCurrentTask = $iAllTasksTrayItems[$hotkeyId-1]
	EndIf

	SetCurrentTask(TrayItemGetText($newCurrentTask))

	For $task In $iAllTasksTrayItems
		If $task == $newCurrentTask Then
			TrayItemSetState($task,$TRAY_CHECKED)
		Else
			TrayItemSetState($task,$TRAY_UNCHECKED)
		EndIf
	Next
EndFunc

Func SetCurrentTaskViaMouse()
	SetCurrentTask(TrayItemGetText(@TRAY_ID))
EndFunc

Func ExitScript()
	_DB_Shutdown($db)
	Exit
EndFunc