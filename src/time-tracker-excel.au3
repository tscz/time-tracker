#include <Excel.au3>
#include <MsgBoxConstants.au3>


Func Excel_Export($tasks, $timetracking)
	; Create application object and open an example workbook
	Local $oExcel = _Excel_Open()
	If @error Then Exit MsgBox($MB_SYSTEMMODAL, "Excel UDF: _Excel_SheetAdd Example", "Error creating the Excel application object." & @CRLF & "@error = " & @error & ", @extended = " & @extended)
	Local $oWorkbook = _Excel_BookNew($oExcel, 1)
	If @error Then
		MsgBox($MB_SYSTEMMODAL, "Excel UDF: _Excel_SheetAdd Example", "Error opening workbook '" & @ScriptDir & "\Extras\_Excel1.xls'." & @CRLF & "@error = " & @error & ", @extended = " & @extended)
		_Excel_Close($oExcel)
		Exit
	EndIf

	; Insert an index sheet with links to all other sheets.
	; Handles Sheet names with spaces correctly.
	Local $timetrackingSheet = _Excel_SheetAdd($oWorkbook, 1, False, 1, "Timetracking")
	If @error Then Exit MsgBox($MB_SYSTEMMODAL, "Excel UDF: _Excel_SheetAdd Example 3", "Error adding sheet." & @CRLF & "@error = " & @error & ", @extended = " & @extended)

	Local $taskSheet = _Excel_SheetAdd($oWorkbook, 1, False, 1, "Tasks")
	If @error Then Exit MsgBox($MB_SYSTEMMODAL, "Excel UDF: _Excel_SheetAdd Example 3", "Error adding sheet." & @CRLF & "@error = " & @error & ", @extended = " & @extended)

	_Excel_SheetDelete($oWorkbook,1)

	For $row = 0 to UBound($tasks) - 1
		$taskSheet.Cells($row + 1,1).Value = $tasks[$row][0]
		$taskSheet.Cells($row + 1,2).Value = $tasks[$row][1]
	Next

	For $row = 0 to UBound($timetracking) - 1
		$timetrackingSheet.Cells($row + 1,1).Value = $timetracking[$row][0]
		$timetrackingSheet.Cells($row + 1,2).Value = $timetracking[$row][1]
		$timetrackingSheet.Cells($row + 1,3).Value = $timetracking[$row][2]
		$timetrackingSheet.Cells($row + 1,4).Value = $timetracking[$row][3]
	Next

	$taskSheet.Columns(1).AutoFit
	$taskSheet.Columns(2).AutoFit

	$timetrackingSheet.Columns(1).AutoFit
	$timetrackingSheet.Columns(2).AutoFit
	$timetrackingSheet.Columns(3).AutoFit
	$timetrackingSheet.Columns(4).AutoFit


EndFunc