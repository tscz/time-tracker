#include <MsgBoxConstants.au3>
#include <SQLite.au3>

; Constants
Global Const $DB_FILE = @LocalAppDataDir & "\time-tracker\tasks.db"

Global Const $QUERY_CREATE_TABLE_TASKS = "CREATE TABLE IF NOT EXISTS Tasks(id TEXT PRIMARY KEY, description TEXT);"
Global Const $QUERY_CREATE_TABLE_TIMETRACKINGS = "CREATE TABLE IF NOT EXISTS Timetrackings(id INTEGER PRIMARY KEY, task_id TEXT, begin TEXT, end TEXT);"
Global Const $QUERY_INSERT_TASK = "INSERT INTO Tasks(id,description) VALUES ('%s','%s');"
Global Const $QUERY_GET_TASKS = "SELECT * FROM tasks;"
Global Const $QUERY_GET_TIMETRACKINGS = "SELECT * FROM Timetrackings ORDER BY id;"
Global Const $QUERY_INSERT_TIMETRACKING = "INSERT INTO Timetrackings(task_id,begin,end) VALUES ('%s',datetime('now','localtime'),datetime('now','localtime'));"
Global Const $QUERY_UPDATE_TIMETRACKING = "UPDATE Timetrackings SET end=datetime('now','localtime') WHERE id='%s';"


;Example()

Func Example()
	Local $hDskDb = _DB_Startup(@ScriptDir & "\..\lib\sqlite3_29_0.dll")
	_DB_InitSchema()
	_DB_AddTask("New Task 2","This is a new task")
	$id = _DB_BeginWork("New Task 5")
	Sleep(1000)
	_DB_EndWork($id)
	_DB_GetTasks()
	_DB_GetTimeTrackings()
	_DB_Shutdown($hDskDb)
EndFunc

; DB Connection Handling

Func _DB_Startup($sqliteDll)
	Local $sSQliteDll = _SQLite_Startup($sqliteDll, False, 1)
	If @error Then
		MsgBox($MB_SYSTEMMODAL, "SQLite Error", "'" & $sqliteDll &"' Can't be Loaded!")
		Exit -1
	EndIf

	Local $hDskDb = _SQLite_Open($DB_FILE) ; Open a permanent disk database
	If @error Then
		MsgBox($MB_SYSTEMMODAL, "SQLite Error", "Can't open or create a permanent Database! " & @error & ":" & @extended)
		Exit -1
	EndIf

	Return $hDskDb
EndFunc

Func _DB_InitSchema()
	_SQLite_Exec(-1, $QUERY_CREATE_TABLE_TASKS)
	_SQLite_Exec(-1, $QUERY_CREATE_TABLE_TIMETRACKINGS)
EndFunc

Func _DB_Shutdown($hDskDb)
	_SQLite_Close($hDskDb)
	_SQLite_Shutdown()
EndFunc

; Task Management

Func _DB_AddTask($id,$description)
	_SQLite_Exec(-1, StringFormat($QUERY_INSERT_TASK, $id, $description))
EndFunc

Func _DB_RemoveTask()
EndFunc

Func _DB_GetTasks()
	Local $aResult, $iRows, $iColumns, $iRval
	$iRval = _SQLite_GetTable2d(-1, $QUERY_GET_TASKS, $aResult, $iRows, $iColumns)
	If $iRval = $SQLITE_OK Then
		_ArrayDelete($aResult,0)
		_SQLite_Display2DResult($aResult)
		Return $aResult
	Else
		MsgBox($MB_SYSTEMMODAL, "SQLite Error: " & $iRval, _SQLite_ErrMsg())
	EndIf
EndFunc

; Time Tracking Management

Func _DB_BeginWork($task)
	Local $id
	_SQLite_Exec(-1, StringFormat($QUERY_INSERT_TIMETRACKING,$task))
	_SQLite_QuerySingleRow(-1,"SELECT last_insert_rowid()",$id)
	Return $id[0]
EndFunc

Func _DB_EndWork($task)
	Local $id
	_SQLite_Exec(-1, StringFormat($QUERY_UPDATE_TIMETRACKING,$task))
	Return $task
EndFunc

Func _DB_GetTimeTrackings()
	Local $hQuery, $aNames, $aRow
	_SQLite_Query(-1, $QUERY_GET_TIMETRACKINGS, $hQuery)
	_SQLite_FetchNames($hQuery, $aNames)
	ConsoleWrite(StringFormat(" %-10s  %-10s  %-19s  %-20s", $aNames[0], $aNames[1], $aNames[2], $aNames[3]) & @CRLF)
	While _SQLite_FetchData($hQuery, $aRow, False, False) = $SQLITE_OK ; Read Out the next Row
		ConsoleWrite(StringFormat(" %-10s  %-10s  %-10s  %-10s  %-10s", $aRow[0], $aRow[1], $aRow[2], $aRow[3]) & @CRLF)
	WEnd
EndFunc








