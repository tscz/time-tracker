; Compilation Directives
#pragma compile(Compatibility, win10)
#pragma compile(UPX, False)
#pragma compile(FileDescription, time-tracker)
#pragma compile(ProductName, time-tracker)
#pragma compile(ProductVersion, 0.2)
#pragma compile(FileVersion, 0.2.0.0)

; Enforce DPI Awareness for High-Res Displays, see https://docs.microsoft.com/en-gb/windows/win32/hidpi/dpi-awareness-context
If @OSVersion = 'WIN_10' Then DllCall("User32.dll", "bool", "SetProcessDpiAwarenessContext", "HWND", "DPI_AWARENESS_CONTEXT" - 2)
If @OSVersion = 'WIN_81' Then DllCall("User32.dll", "bool", "SetProcessDPIAware")

; Do no show autoit tray icon during startup
#NoTrayIcon

; Exit hook
OnAutoItExitRegister("ExitScript")

; Libraries
#include <Array.au3>
#include <File.au3>
#include <GuiListView.au3>
#include <time-tracker-db.au3>
#include <time-tracker-gui.au3>

; Constants
#include <FileConstants.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <TrayConstants.au3>

#include <WinAPIProc.au3>
#include <WinAPI.au3>
#include <WinAPISys.au3>
#include <GUIConstants.au3>
#include <APISysConstants.au3>

; Options
Opt("TrayMenuMode", 3) ;0=append, 1=no default menu, 2=no automatic check, 4=menuitemID  not return
Opt("TrayOnEventMode", 1) ;0=disable, 1=enable

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

; Constants
Global Const $DLL = @LocalAppDataDir & "\time-tracker\sqlite_x64.dll"
Global Const $TASK_PATTERN = "(.*):\t(.*) (\(CTRL\+SHIFT\+[0-9]\))"

; Variables
Global $iAllTasksTrayItems = [] ; Array of all available Task Tray Items
Global $db = 0 ; Database object
Global $activeTask = 0 ; Current active task

; Main script
Main()

Func Main()
	Global $g_hForm = GUICreate('')

	InitDlls()
	$db = InitDatabase()
	InitTray()
	InitTrayTasks()

	While 1
		Sleep(100) ; An idle loop.
	WEnd
EndFunc

; Initialize external DLLs
Func InitDlls()
	Local $sDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
	Local $dllPath = _PathSplit($DLL, $sDrive, $sDir, $sFileName, $sExtension)

	DirCreate($dllPath[$PATH_DRIVE] & $dllPath[$PATH_DIRECTORY])
	FileInstall("../lib/sqlite3_29_0_x64.dll", $DLL, $FC_OVERWRITE)
EndFunc

Func InitDatabase()
	Local $db = _DB_Startup($DLL)
	_DB_InitSchema()

	Return $db
EndFunc

; Initialize Tray Menu and add items for all Tasks
Func InitTray()
	TrayCreateItem("") ; Create a separator line.
	Global $timeboxMenu = TrayCreateMenu("Timebox")
	Global $timeboxItemStart = TrayCreateItem("Start",$timeboxMenu)
	Global $timeboxItemStop = TrayCreateItem("Stop",$timeboxMenu)
	Global $timeboxItemPause = TrayCreateItem("Pause",$timeboxMenu)

	TrayItemSetOnEvent($timeboxItemStart, "OpenTimeboxGui")
	TrayItemSetOnEvent($timeboxItemStop, "StopTimebox")
	TrayItemSetOnEvent($timeboxItemPause, "PauseTimebox")

	TrayItemSetState($timeboxItemStop,$TRAY_DISABLE)
	TrayItemSetState($timeboxItemPause,$TRAY_DISABLE)

	TrayCreateItem("") ; Create a separator line.
	Global $taskItem = TrayCreateItem("Manage Tasks")
	TrayItemSetOnEvent($taskItem, "OpenConfigGui")

	TrayCreateItem("") ; Create a separator line.
	Global $exitItem = TrayCreateItem("Exit")
	TrayItemSetOnEvent($exitItem, "ExitScript")

	TraySetState($TRAY_ICONSTATE_SHOW) ; Show the tray menu.
EndFunc

Func InitTrayTasks()

	Local $iAllTasks = _DB_GetTasks()
	ReDim $iAllTasksTrayItems[UBound($iAllTasks)]

	; Create tray items
	For $i = UBound($iAllTasks) - 1 To 0 Step -1
		$iAllTasksTrayItems[$i] = TrayCreateItem($iAllTasks[$i][0] & ":" & @TAB & $iAllTasks[$i][1]  & " (CTRL+SHIFT+" & $i + 1 & ")", -1, 0, $TRAY_ITEM_RADIO)
		TrayItemSetOnEvent(-1, "setCurrentTaskViaMouse")

		; Enable active task, if present
		If $activeTask <> 0 Then
			If $iAllTasks[$i][0] = $activeTask[1] Then	TrayItemSetState($iAllTasksTrayItems[$i],$TRAY_CHECKED)
		EndIf
	Next

	; If no task is active, deactivate timebox
	If $activeTask = 0 Then
		TrayItemSetState($timeboxMenu,$TRAY_DISABLE)
	EndIf
EndFunc

Func ResetTray()
	For $task In $iAllTasksTrayItems
		TrayItemDelete($task)
	Next
EndFunc

Func DeactivateTray()
	For $task In $iAllTasksTrayItems
		TrayItemSetState($task,$TRAY_DISABLE)
	Next
	TrayItemSetState($taskItem,$TRAY_DISABLE)
EndFunc

Func ActivateTray()
	For $task In $iAllTasksTrayItems
		TrayItemSetState($task,$TRAY_ENABLE)
	Next
	TrayItemSetState($taskItem,$TRAY_ENABLE)
EndFunc

Func OpenConfigGui()
	Global $CLOSE_EVENT = _WinAPI_RegisterWindowMessage('CLOSE_EVENT')
	GUIRegisterMsg($CLOSE_EVENT, 'WM_SHELLHOOK')
	_WinAPI_RegisterShellHookWindow($g_hForm)

	TraySetState($TRAY_ICONSTATE_HIDE)

	Local $theTasks = _DB_GetTasks()
	Global $hGUI = MainGui($theTasks,$g_hForm)




EndFunc

Func WM_SHELLHOOK($hWnd, $iMsg, $wParam, $lParam)
    #forceref $iMsg

	Switch $iMsg
		Case $CLOSE_EVENT
			ResetTray()
			InitTrayTasks()
			TraySetState($TRAY_ICONSTATE_SHOW)
	EndSwitch
EndFunc

Func OpenTimeboxGui()
	TraySetState($TRAY_ICONSTATE_HIDE)
	Local $totalMinutes = InputBox("Timebox for Task '" & $activeTask[1] &"'", "Please enter timebox duration in minutes.")
	TraySetState($TRAY_ICONSTATE_SHOW)

	If $totalMinutes = "" Or StringIsInt($totalMinutes) = 0  Then Return

	DeactivateTray()

	TimeboxGui($totalMinutes)

	TrayItemSetState($timeboxItemStart,$TRAY_DISABLE)
	TrayItemSetState($timeboxItemStop,$TRAY_ENABLE)
	TrayItemSetState($timeboxItemPause,$TRAY_ENABLE)
EndFunc

Func StopTimebox()
	TimeboxGuiClose()
	ActivateTray()
	TrayItemSetState($timeboxItemStart,$TRAY_ENABLE)
	TrayItemSetState($timeboxItemStop,$TRAY_DISABLE)
	TrayItemSetState($timeboxItemPause,$TRAY_DISABLE)
EndFunc

Func PauseTimebox()
	Switch TrayItemGetText($timeboxItemPause)
		Case "Pause"
			TrayItemSetText($timeboxItemPause,"Resume")
			TimeboxGuiPause()
		Case "Resume"
			TrayItemSetText($timeboxItemPause,"Pause")
			TimeboxGuiResume()
	EndSwitch
EndFunc

Func SetCurrentTask($text)
	Local $task = StringRegExp($text,$TASK_PATTERN,$STR_REGEXPARRAYMATCH)

	TrayTip("Now working on '" & $task[0] & "'", $task[1], 0, $TIP_ICONASTERISK)
	endActiveTask()

	$activeTask = _DB_BeginWork($task[0])
	TrayItemSetState($timeboxMenu,$TRAY_ENABLE)
EndFunc

Func SetCurrentTaskViaHotkey()
	Local $hotkeyId = StringRight(@HotKeyPressed,1)

	If $hotkeyId > UBound($iAllTasksTrayItems) Then Return

	Local $newCurrentTask = $iAllTasksTrayItems[$hotkeyId-1]

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
	endActiveTask()
	_DB_Shutdown($db)
	_WinAPI_DeregisterShellHookWindow($g_hForm)
	Exit
EndFunc

Func endActiveTask()
	If $activeTask <> 0 Then _DB_EndWork($activeTask[0])
EndFunc
