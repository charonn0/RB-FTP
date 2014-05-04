#tag Window
Begin Window ServerDemo
   BackColor       =   &hFFFFFF
   Backdrop        =   ""
   CloseButton     =   True
   Composite       =   False
   Frame           =   0
   FullScreen      =   False
   HasBackColor    =   False
   Height          =   400
   ImplicitInstance=   True
   LiveResize      =   True
   MacProcID       =   0
   MaxHeight       =   32000
   MaximizeButton  =   False
   MaxWidth        =   32000
   MenuBar         =   ""
   MenuBarVisible  =   True
   MinHeight       =   64
   MinimizeButton  =   True
   MinWidth        =   64
   Placement       =   0
   Resizeable      =   True
   Title           =   "FTP Server"
   Visible         =   True
   Width           =   600
   Begin Listbox Listbox1
      AutoDeactivate  =   True
      AutoHideScrollbars=   True
      Bold            =   False
      Border          =   True
      ColumnCount     =   1
      ColumnsResizable=   False
      ColumnWidths    =   ""
      DataField       =   ""
      DataSource      =   ""
      DefaultRowHeight=   -1
      Enabled         =   True
      EnableDrag      =   False
      EnableDragReorder=   False
      GridLinesHorizontal=   0
      GridLinesVertical=   0
      HasHeading      =   False
      HeadingIndex    =   -1
      Height          =   299
      HelpTag         =   ""
      Hierarchical    =   False
      Index           =   -2147483648
      InitialParent   =   ""
      InitialValue    =   ""
      Italic          =   False
      Left            =   0
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      RequiresSelection=   False
      Scope           =   0
      ScrollbarHorizontal=   False
      ScrollBarVertical=   True
      SelectionType   =   0
      TabIndex        =   0
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   0
      Underline       =   False
      UseFocusRing    =   True
      Visible         =   True
      Width           =   600
      _ScrollWidth    =   -1
   End
   Begin TextField Port
      AcceptTabs      =   False
      Alignment       =   0
      AutoDeactivate  =   True
      AutomaticallyCheckSpelling=   False
      BackColor       =   "&cFFFFFF00"
      Bold            =   False
      Border          =   True
      CueText         =   ""
      DataField       =   ""
      DataSource      =   ""
      Enabled         =   True
      Format          =   ""
      Height          =   22
      HelpTag         =   ""
      Index           =   -2147483648
      Italic          =   False
      Left            =   204
      LimitText       =   0
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   True
      Mask            =   ""
      Password        =   False
      ReadOnly        =   False
      Scope           =   0
      TabIndex        =   4
      TabPanelIndex   =   0
      TabStop         =   True
      Text            =   21
      TextColor       =   "&c00000000"
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   330
      Underline       =   False
      UseFocusRing    =   True
      Visible         =   True
      Width           =   20
   End
   Begin CheckBox AllowAnon
      AutoDeactivate  =   True
      Bold            =   False
      Caption         =   "Allow Anonymous"
      DataField       =   ""
      DataSource      =   ""
      Enabled         =   True
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   False
      Left            =   19
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   True
      Scope           =   0
      State           =   0
      TabIndex        =   5
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   361
      Underline       =   False
      Value           =   False
      Visible         =   True
      Width           =   131
   End
   Begin Label Label1
      AutoDeactivate  =   True
      Bold            =   ""
      DataField       =   ""
      DataSource      =   ""
      Enabled         =   True
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   5
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Multiline       =   ""
      Scope           =   0
      Selectable      =   False
      TabIndex        =   6
      TabPanelIndex   =   0
      TabStop         =   True
      Text            =   "Listen On:"
      TextAlign       =   2
      TextColor       =   &h000000
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   332
      Transparent     =   False
      Underline       =   ""
      Visible         =   True
      Width           =   71
   End
   Begin Listbox Users
      AutoDeactivate  =   True
      AutoHideScrollbars=   True
      Bold            =   ""
      Border          =   True
      ColumnCount     =   3
      ColumnsResizable=   ""
      ColumnWidths    =   ""
      DataField       =   ""
      DataSource      =   ""
      DefaultRowHeight=   -1
      Enabled         =   True
      EnableDrag      =   ""
      EnableDragReorder=   ""
      GridLinesHorizontal=   0
      GridLinesVertical=   0
      HasHeading      =   True
      HeadingIndex    =   -1
      Height          =   76
      HelpTag         =   ""
      Hierarchical    =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      InitialValue    =   "Username	Password	Root"
      Italic          =   ""
      Left            =   237
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      RequiresSelection=   ""
      Scope           =   0
      ScrollbarHorizontal=   ""
      ScrollBarVertical=   True
      SelectionType   =   0
      TabIndex        =   7
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   324
      Underline       =   ""
      UseFocusRing    =   True
      Visible         =   True
      Width           =   363
      _ScrollWidth    =   -1
   End
   Begin PushButton PushButton1
      AutoDeactivate  =   True
      Bold            =   ""
      ButtonStyle     =   0
      Cancel          =   ""
      Caption         =   "Add User"
      Default         =   ""
      Enabled         =   True
      Height          =   22
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   431
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Scope           =   0
      TabIndex        =   8
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   302
      Underline       =   ""
      Visible         =   True
      Width           =   80
   End
   Begin PushButton PushButton2
      AutoDeactivate  =   True
      Bold            =   ""
      ButtonStyle     =   0
      Cancel          =   ""
      Caption         =   "Remove User"
      Default         =   ""
      Enabled         =   True
      Height          =   22
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   513
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Scope           =   0
      TabIndex        =   9
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   302
      Underline       =   ""
      Visible         =   True
      Width           =   80
   End
   Begin ServerSocket FTPServer
      Enabled         =   True
      Height          =   32
      Index           =   -2147483648
      Left            =   612
      LockedInPosition=   False
      MaximumSocketsConnected=   25
      MinimumSocketsAvailable=   10
      Port            =   21
      Scope           =   0
      TabIndex        =   7
      TabPanelIndex   =   0
      TabStop         =   True
      Top             =   0
      Visible         =   True
      Width           =   32
   End
   Begin PushButton PushButton3
      AutoDeactivate  =   True
      Bold            =   False
      ButtonStyle     =   0
      Cancel          =   False
      Caption         =   "Listen"
      Default         =   False
      Enabled         =   True
      Height          =   22
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   False
      Left            =   5
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   False
      Scope           =   0
      TabIndex        =   10
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   302
      Underline       =   False
      Visible         =   True
      Width           =   80
   End
   Begin ComboBox nic
      AutoComplete    =   False
      AutoDeactivate  =   True
      Bold            =   False
      DataField       =   ""
      DataSource      =   ""
      Enabled         =   True
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialValue    =   ""
      Italic          =   False
      Left            =   79
      ListIndex       =   0
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
      LockTop         =   False
      Scope           =   0
      TabIndex        =   11
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0.0
      TextUnit        =   0
      Top             =   330
      Underline       =   False
      UseFocusRing    =   True
      Visible         =   True
      Width           =   121
   End
End
#tag EndWindow

#tag WindowCode
	#tag Event
		Sub Close()
		  If FTPServer.IsListening Then FTPServer.StopListening
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Loggit(line As String)
		  #pragma BreakOnExceptions Off
		  Try
		    Listbox1.AddRow(line)
		    Listbox1.RowTag(Listbox1.LastIndex) = Left(Line, 3)
		    Listbox1.ScrollPosition = Listbox1.LastIndex * Listbox1.RowHeight
		  Catch
		    Return
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LogHandler(Sender As FTPServerSocket, LogLine As String)
		  #pragma Unused Sender
		  If LogLine.Trim <> "" Then loggit(LogLine)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function UserLogonHandler(Sender As FTPServerSocket, UserName As String, Password As String) As Boolean
		  #pragma Unused Sender
		  For i As Integer = 0 To Users.ListCount - 1
		    Dim u, p As String
		    Dim f As FolderItem = GetFolderItem(Users.Cell(i, 2))
		    u = Users.Cell(i, 0)
		    p = Users.Cell(i, 1)
		    If UserName = u And Password = p Then
		      Sender.RootDirectory = f
		      Return True
		    End If
		  Next
		  
		  Return AllowAnon.Value And UserName = "anonymous"
		End Function
	#tag EndMethod


#tag EndWindowCode

#tag Events Listbox1
	#tag Event
		Function ConstructContextualMenu(base as MenuItem, x as Integer, y as Integer) As Boolean
		  #pragma Unused X
		  #pragma Unused Y
		  base.Append(New MenuItem("Copy"))
		End Function
	#tag EndEvent
	#tag Event
		Function ContextualMenuAction(hitItem as MenuItem) As Boolean
		  Select Case hitItem.Text
		  Case "Copy"
		    Dim cp As New Clipboard
		    cp.Text = Me.Cell(Me.ListIndex, 0)
		    cp.Close
		  End Select
		End Function
	#tag EndEvent
	#tag Event
		Function CellBackgroundPaint(g As Graphics, row As Integer, column As Integer) As Boolean
		  #pragma Unused column
		  If row <= Me.LastIndex Then
		    Dim tmp As String = Me.RowTag(Row)
		    If IsNumeric(tmp.Trim) Then
		      g.foreColor= &c0080FF99
		    else
		      g.foreColor= &c00FF4099
		    end if
		    g.FillRect 0,0,g.width,g.height
		  End If
		End Function
	#tag EndEvent
#tag EndEvents
#tag Events Users
	#tag Event
		Function CellClick(row as Integer, column as Integer, x as Integer, y as Integer) As Boolean
		  #pragma Unused X
		  #pragma Unused Y
		  If column = 2 And row > -1 And row <= Me.ListIndex Then
		    Dim f As FolderItem = SelectFolder()
		    If f <> Nil Then
		      Me.Cell(row, column) = f.AbsolutePath
		    End If
		    Return True
		  End If
		End Function
	#tag EndEvent
#tag EndEvents
#tag Events PushButton1
	#tag Event
		Sub Action()
		  Users.AddRow("Set User Name", "Set Password", "Set Root")
		  Users.CellType(Users.LastIndex, 0) = Listbox.TypeEditable
		  Users.CellType(Users.LastIndex, 1) = Listbox.TypeEditable
		  Users.CellType(Users.LastIndex, 2) = Listbox.TypeEditable
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events PushButton2
	#tag Event
		Sub Action()
		  If Users.ListIndex > -1 Then
		    Users.RemoveRow(Users.ListIndex)
		  End If
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events FTPServer
	#tag Event
		Function AddSocket() As TCPSocket
		  Dim client As New FTPServerSocket
		  client.Banner = "Welcome to BSFTPd!"
		  client.AllowWrite = True
		  client.TimeOutPeriod = 60000
		  client.NetworkInterface = Me.NetworkInterface
		  AddHandler client.FTPLog, AddressOf LogHandler
		  AddHandler client.UserLogon, AddressOf UserLogonHandler
		  Return client
		End Function
	#tag EndEvent
	#tag Event
		Sub Error(ErrorCode as Integer)
		  Loggit("ServerSocket error: " + Str(ErrorCode))
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events PushButton3
	#tag Event
		Sub Action()
		  If FTPServer.IsListening Then
		    FTPServer.StopListening
		    Me.Caption = "Listen"
		  Else
		    FTPServer.NetworkInterface = nic.RowTag(nic.ListIndex)
		    FTPServer.Port = Val(port.Text)
		    FTPServer.Listen()
		    Me.Caption = "Listening..."
		  End If
		  
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events nic
	#tag Event
		Sub Open()
		  Dim i As Integer
		  For i = 0 To System.NetworkInterfaceCount - 1
		    Me.AddRow(System.GetNetworkInterface(i).IPAddress)
		    If System.GetNetworkInterface(i).IPAddress <> "0.0.0.0" Then
		      Me.RowTag(i) = System.GetNetworkInterface(i)
		    End If
		  Next
		  For i = Me.ListCount - 1 DownTo 0
		    If Me.RowTag(i) = Nil Then
		      Me.RemoveRow(i)
		    Else
		      Me.ListIndex = i
		    End If
		  Next
		End Sub
	#tag EndEvent
#tag EndEvents
