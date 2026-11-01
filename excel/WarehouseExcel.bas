Attribute VB_Name = "WarehouseExcel"
Option Explicit

' Offline helpers for the IT consumables warehouse.
' Desktop Excel on Windows. ACE OLEDB must match Excel's bitness.
' These match sql/ba.sql: extended value, then a markup pass floored at 0.
'
' QueryStockValue
'   Sheet "Stock" headers: SKU, Name, UnitCost, Quantity.
'   Writes SKU, Name, UnitCost, Quantity, Total onto sheet "Valuation"
'   for rows with UnitCost > 50, highest total first.
'   Queries a temp copy so ACE can read the open workbook, including unsaved edits.
'
' CleanCostsOffline
'   Sheet "Raw" from row 2: SKU, Cost, Markup%.
'   Markup 20 means 20 percent. Writes the marked-up cost onto sheet "Cleaned".
'   Blank rows stay blank. Text such as $1,250.00 is accepted. Prices floor at 0.

Public Sub QueryStockValue()
    Dim cn As Object
    Dim rs As Object
    Dim sql As String
    Dim tmp As String
    Dim props As String
    Dim ext As String
    Dim f As Long
    Dim dot As Long
    Dim out As Worksheet
    Dim errNum As Long
    Dim errSrc As String
    Dim errDesc As String

    dot = InStrRev(ThisWorkbook.Name, ".")
    If dot = 0 Then Err.Raise 5, , "Save the workbook as xlsx, xlsm, xlsb, or xls first."
    ext = LCase$(Mid$(ThisWorkbook.Name, dot))
    Select Case ext
        Case ".xlsx": props = "Excel 12.0 Xml"
        Case ".xlsm": props = "Excel 12.0 Macro"
        Case ".xlsb": props = "Excel 12.0"
        Case ".xls": props = "Excel 8.0"
        Case Else: Err.Raise 5, , "Save the workbook as xlsx, xlsm, xlsb, or xls first."
    End Select

    tmp = Environ$("TEMP") & "\whq_" & Format$(Now, "yyyymmddhhnnss") & ext

    On Error GoTo CleanFail
    ThisWorkbook.SaveCopyAs tmp

    Set cn = CreateObject("ADODB.Connection")
    cn.Open "Provider=Microsoft.ACE.OLEDB.12.0;" & _
            "Data Source=" & tmp & ";" & _
            "Extended Properties=""" & props & ";HDR=Yes;IMEX=0"";"

    ' ACE does not see the Total alias in ORDER BY. Repeat the expression.
    sql = "SELECT SKU, Name, UnitCost, Quantity, (UnitCost * Quantity) AS Total " & _
          "FROM [Stock$] WHERE UnitCost > 50 ORDER BY (UnitCost * Quantity) DESC"

    Set rs = CreateObject("ADODB.Recordset")
    rs.Open sql, cn, 0, 1

    Set out = ThisWorkbook.Worksheets("Valuation")
    out.UsedRange.ClearContents
    For f = 0 To rs.Fields.Count - 1
        out.Cells(1, f + 1).Value = rs.Fields(f).Name
    Next f
    If Not rs.EOF Then out.Range("A2").CopyFromRecordset rs

    rs.Close
    cn.Close
    Set rs = Nothing
    Set cn = Nothing
    Kill tmp
    Exit Sub

CleanFail:
    errNum = Err.Number
    errSrc = Err.Source
    errDesc = Err.Description
    On Error Resume Next
    If Not rs Is Nothing Then
        If rs.State = 1 Then rs.Close
    End If
    If Not cn Is Nothing Then
        If cn.State = 1 Then cn.Close
    End If
    If Len(tmp) > 0 Then Kill tmp
    On Error GoTo 0
    Err.Raise errNum, errSrc, errDesc
End Sub

Public Sub CleanCostsOffline()
    Dim data As Variant
    Dim i As Long
    Dim lastRow As Long
    Dim ws As Worksheet
    Dim out As Worksheet
    Dim cost As Variant
    Dim markup As Variant
    Dim price As Currency

    Set ws = ThisWorkbook.Worksheets("Raw")
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    If lastRow < 2 Then Exit Sub
    data = ws.Range("A2:C" & lastRow).Value

    For i = 1 To UBound(data, 1)
        cost = MoneyValue(data(i, 2))
        markup = MoneyValue(data(i, 3))
        If Not IsEmpty(cost) And Not IsEmpty(markup) Then
            price = CCur(cost) * (1 + CCur(markup) / 100)
            If price < 0 Then price = 0
            data(i, 2) = price
        End If
    Next i

    Set out = ThisWorkbook.Worksheets("Cleaned")
    lastRow = out.Cells(out.Rows.Count, 1).End(xlUp).Row
    If lastRow >= 2 Then out.Range("A2:C" & lastRow).ClearContents
    out.Range("A2").Resize(UBound(data, 1), 3).Value = data
End Sub

' Empty in, Empty out. Numbers and currency text such as $1,250.00 become Currency.
Private Function MoneyValue(ByVal v As Variant) As Variant
    Dim s As String

    If IsEmpty(v) Then Exit Function
    If IsNumeric(v) Then
        MoneyValue = CCur(v)
        Exit Function
    End If

    s = CStr(v)
    s = Replace$(s, "$", "")
    s = Replace$(s, ",", "")
    s = Replace$(s, " ", "")
    s = Trim$(s)
    If Len(s) = 0 Then Exit Function
    If IsNumeric(s) Then MoneyValue = CCur(s)
End Function
