VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "InputHandler"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public Enum ParseType
    pAscii = 0
    pHex = 1
    pBinary = 2
    pDecimal = 3
    pOctal = 4
    pNoColor = 99
End Enum

Private Type TypeStats
    allowedChars() As Byte
    maxLength As Long
    color As OLE_COLOR
    prefix() As Byte
    suffix() As Byte
End Type

Private totalTypes As Long
Private types() As TypeStats


Private Sub Class_Initialize()
    totalTypes = 5
    ReDim types(0 To totalTypes - 1)
    
    With types(ParseType.pAscii)
        .allowedChars = StrConv("", vbFromUnicode)
        .color = &HCF9600
        .maxLength = -1
        .prefix = StrConv(Chr(34), vbFromUnicode)
        .suffix = StrConv(Chr(34), vbFromUnicode)
    End With

    With types(ParseType.pBinary)
        .allowedChars = StrConv("01", vbFromUnicode)
        .color = &H1AA6FA
        .maxLength = 8
        .prefix = StrConv("0b", vbFromUnicode)
        .suffix = StrConv("", vbFromUnicode)
    End With
    
    With types(ParseType.pDecimal)
        .allowedChars = StrConv("0123456789", vbFromUnicode)
        .color = &H81B543
        .maxLength = 3
        .prefix = StrConv("", vbFromUnicode)
        .suffix = StrConv("", vbFromUnicode)
    End With
    
    
    With types(ParseType.pHex)
        .allowedChars = StrConv("0123456789abcdefABCDEF", vbFromUnicode)
        .color = &H4747F0
        .maxLength = 2
        .prefix = StrConv("0x", vbFromUnicode)
        .suffix = StrConv("", vbFromUnicode)
    End With
    
    With types(ParseType.pOctal)
        .allowedChars = StrConv("01234567", vbFromUnicode)
        .color = &HDA8972
        .maxLength = 3
        .prefix = StrConv("0o", vbFromUnicode)
        .suffix = StrConv("", vbFromUnicode)
    End With
End Sub


Function parseString(ByRef str As String, forceMode As Long) As Byte()
    Dim tmpType As ParseType
    Dim outputBytes() As Byte
    
    tmpType = getTypeByString(str, forceMode)
    
    If tmpType <> pNoColor Then
        
        If forceMode <> -1 Then
            Select Case forceMode
                Case pAscii
                    outputBytes = StrConv(str, vbFromUnicode)
                    
                Case pHex
                    ReDim outputBytes(0)
                    outputBytes(0) = Val("&H" & str)
                    
                Case pBinary
                    ReDim outputBytes(0)
                    outputBytes(0) = Bin2Dec(str)
                    
                Case pDecimal
                    ReDim outputBytes(0)
                    outputBytes(0) = Val(str)
                    
                Case pOctal
                    ReDim outputBytes(0)
                    outputBytes(0) = Val("&O" & str)
                
            End Select
            
        Else
            outputBytes = StrConv("", vbFromUnicode)
        End If
        
    Else
        outputBytes = StrConv("", vbFromUnicode)
    End If
    
    parseString = outputBytes
End Function

Function Bin2Dec(Num As String) As Byte
    Dim n As Integer, a As Integer, X As Integer
    n = Len(Num) - 1
    a = n
    
    Do While n > -1
        X = Mid(Num, ((a + 1) - n), 1)
        Bin2Dec = IIf((X = "1"), Bin2Dec + (2 ^ (n)), Bin2Dec)
        n = n - 1
    Loop
End Function

Function getColorByType(whatType As ParseType) As OLE_COLOR
    getColorByType = types(whatType).color
End Function

Function getTypeByString(ByRef str As String, forceMode As Long) As ParseType
    Dim firstChar As Integer
    Dim secondChar As Integer
    
    Dim totalLength As Long
    
    Dim bytes() As Byte
    
    Dim i As Long, j As Long
    
    bytes = StrConv(str, vbFromUnicode)
    
    totalLength = UBound(bytes)
    
    getTypeByString = pNoColor
    
    If forceMode <> -1 Then
        getTypeByString = IIf(onlyContainsAllowedChars(-1, bytes, types(forceMode).allowedChars, types(forceMode).maxLength), forceMode, pNoColor)
            
        Select Case forceMode
            Case ParseType.pDecimal
                If getTypeByString <> pNoColor Then
                    If Val(str) > 255 Or Val(str) < 0 Then
                        getTypeByString = pNoColor
                    End If
                End If
                
            Case ParseType.pOctal
                If getTypeByString <> pNoColor Then
                    If Val("&O" & str) > 255 Or Val("&O" & str) < 0 Then
                        getTypeByString = pNoColor
                    End If
                End If
        End Select
        
        Exit Function
    End If
    
    
    Dim prefixLength As Long
    Dim suffixLength As Long
    Dim foundAll As Boolean
        
    For i = 0 To totalTypes - 1
        prefixLength = UBound(types(i).prefix)
        suffixLength = UBound(types(i).suffix)
        
        If totalLength >= prefixLength And prefixLength > -1 Then
            foundAll = True
            For j = 0 To prefixLength
                If types(i).prefix(j) <> bytes(j) Then
                    foundAll = False
                    Exit For
                End If
            Next j
            
            If suffixLength > -1 Then
                For j = 0 To suffixLength
                    If types(i).suffix(j) <> bytes(totalLength - j) Then
                        foundAll = False
                        Exit For
                    End If
                Next j
                
                If foundAll = True Then
                    If totalLength + 1 < suffixLength + prefixLength + 2 Then
                        foundAll = False
                    End If
                End If
            End If
            
            If foundAll Then
                getTypeByString = IIf(onlyContainsAllowedChars(prefixLength, bytes, types(i).allowedChars, types(i).maxLength), i, pNoColor)
                
                Select Case i
                    Case ParseType.pDecimal
                        If getTypeByString <> pNoColor Then
                            If Val(str) > 255 Or Val(str) < 0 Then
                                getTypeByString = pNoColor
                            End If
                        End If
                
                    Case ParseType.pOctal
                        If getTypeByString <> pNoColor Then
                            If Val("&O" & str) > 255 Or Val("&O" & str) < 0 Then
                                getTypeByString = pNoColor
                            End If
                        End If
                    
'
                End Select
            End If
        End If
        
    Next i
    
    If getTypeByString <> pNoColor Then Exit Function
    
    
    For i = 0 To totalTypes - 1
        prefixLength = UBound(types(i).prefix)
        
        If prefixLength = -1 Then
            Select Case i
                Case ParseType.pDecimal
                    getTypeByString = IIf(onlyContainsAllowedChars(prefixLength, bytes, types(i).allowedChars, types(i).maxLength), i, pNoColor)
                    
                    If getTypeByString <> pNoColor Then
                        If Val(str) > 255 Or Val(str) < 0 Then
                            getTypeByString = pNoColor
                        End If
                    End If
            
            End Select
            
        End If
        
    Next i
    
    
'    If totalLength > 0 Then
'        firstChar = bytes(0)
'        secondChar = bytes(1)
'
'        Select Case firstChar
'            Case 48 '0'
'                Select Case secondChar
'                    Case 120 'x'
'                        getTypeByString = IIf(onlyContainsAllowedChars(2, bytes, allowedHex, maxLengthHex), colorHex, pNoColor)
'
'                    Case 98 'b'
'                        getTypeByString = IIf(onlyContainsAllowedChars(2, bytes, allowedBinary, maxLengthBinary), colorBinary, pNoColor)
'
'                    Case 111 'o'
'                        getTypeByString = IIf(onlyContainsAllowedChars(2, bytes, allowedOctal, maxLengthOctal), colorOctal, pNoColor)
'                        If getTypeByString <> pNoColor Then
'                            If Val("&O" & Right(str, Len(str) - 2)) > 255 Or Val("&O" & Right(str, Len(str) - 2)) < 0 Then
'                                getTypeByString = pNoColor
'                            End If
'                        End If
'
'                    Case Else
'                        getTypeByString = pNoColor
'                        GoTo checkForDecimal
'
'                End Select
'
'            Case 34 '"'
'                getTypeByString = IIf(bytes(UBound(bytes)) = 34, colorAscii, pNoColor)
'
'            Case Else
'                GoTo checkForDecimal
'        End Select
'
'    ElseIf totalLength = 0 Then
'        GoTo checkForDecimal
'    Else
'        getTypeByString = pNoColor
'        Exit Function
'    End If
'
'    Exit Function
'
'
'checkForDecimal:
'    getTypeByString = IIf(onlyContainsAllowedChars(0, bytes, allowedDec, maxLengthDec), colorDec, -1)
'    If getTypeByString <> pNoColor Then
'        If Val(str) > 255 Or Val(str) < 0 Then
'            getTypeByString = pNoColor
'        End If
'    End If
    
End Function

Function onlyContainsAllowedChars(startByte As Long, ByRef bytesIn() As Byte, ByRef allowedIn() As Byte, maxLength As Long) As Boolean
    Dim i As Long
    Dim j As Long
    Dim found As Boolean
    Dim allowedInLength As Long
    
    If maxLength <> -1 And UBound(bytesIn) - startByte - 1 >= maxLength Then
        onlyContainsAllowedChars = False
        Exit Function
    End If
    
    allowedInLength = UBound(allowedIn)
    
    If allowedInLength > -1 Then
        
        For i = startByte + 1 To UBound(bytesIn)
            found = False
            
            For j = 0 To allowedInLength
                If bytesIn(i) = allowedIn(j) Then
                    found = True
                    Exit For
                End If
            Next j
            
            If found = False Then
                onlyContainsAllowedChars = False
                Exit Function
            End If
        Next i
    End If
    
    onlyContainsAllowedChars = True
End Function