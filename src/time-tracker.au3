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
#include <time-tracker-gui.au3>

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
Global $iAllTasksTrayItems = [] ; Array of all available Task Tray Items
Global $db = 0 ; Database object
Global $activeTask = 0 ; Current active task

; Main script
Main()

Func Main()
	InitDlls()
	$db = InitDb()
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

Func InitDb()
	Local $hDskDb = _DB_Startup($DLL)
	_DB_InitSchema()

	Return $hDskDb
EndFunc

; Initialize Tray Menu and add items for all Tasks
Func InitTray()
	TrayCreateItem("") ; Create a separator line.
	TrayCreateItem("Manage Tasks")
	TrayItemSetOnEvent(-1, "OpenConfigGui")

	TrayCreateItem("") ; Create a separator line.
	TrayCreateItem("Exit")
	TrayItemSetOnEvent(-1, "ExitScript")

	TraySetState($TRAY_ICONSTATE_SHOW) ; Show the tray menu.
EndFunc

Func InitTrayTasks()

	Local $iAllTasks = _DB_GetTasks()
	ReDim $iAllTasksTrayItems[UBound($iAllTasks)]

	For $i = UBound($iAllTasks) - 1 To 0 Step -1
		$iAllTasksTrayItems[$i] = TrayCreateItem($iAllTasks[$i][0] & ":" & @TAB & $iAllTasks[$i][1], -1, 0, $TRAY_ITEM_RADIO)
		TrayItemSetOnEvent(-1, "setCurrentTaskViaMouse")
	Next

	; Set task #1 as the default checked task
	If UBound($iAllTasksTrayItems) > 0 Then TrayItemSetState($iAllTasksTrayItems[0],$TRAY_CHECKED)
EndFunc


Func ResetTray()
	For $task In $iAllTasksTrayItems
		TrayItemDelete($task)
	Next
EndFunc

Func OpenConfigGui()
	Local $theTasks = _DB_GetTasks()
	MainGui($theTasks)
	ResetTray()
	InitTrayTasks()
EndFunc

Func SetCurrentTask($text)
	TrayTip("Currently working on new task", $text, 0, $TIP_ICONASTERISK)

	If $activeTask <> 0 Then _DB_EndWork($activeTask)

	Local $task = StringSplit($text,":")[1]
	_DB_BeginWork($task)
	$activeTask = $task
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