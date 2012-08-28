#tag Window
Begin Window Window1
   BackColor       =   16777215
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
   MenuBar         =   1231673343
   MenuBarVisible  =   True
   MinHeight       =   64
   MinimizeButton  =   True
   MinWidth        =   64
   Placement       =   0
   Resizeable      =   True
   Title           =   "Untitled"
   Visible         =   True
   Width           =   600
   Begin FTPClientSocket Client
      Address         =   "mc.boredomsoft.org"
      DataIsConnected =   ""
      DataLastErrorCode=   ""
      DataPort        =   ""
      Height          =   32
      Index           =   -2147483648
      Left            =   625
      LockedInPosition=   False
      Passive         =   True
      Password        =   "n9tgXMv9Xu"
      Port            =   21
      Scope           =   0
      TabPanelIndex   =   0
      Top             =   0
      User            =   "ftpstore"
      Width           =   32
   End
   Begin Listbox Listbox1
      AutoDeactivate  =   True
      AutoHideScrollbars=   True
      Bold            =   ""
      Border          =   True
      ColumnCount     =   1
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
      HasHeading      =   ""
      HeadingIndex    =   -1
      Height          =   352
      HelpTag         =   ""
      Hierarchical    =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      InitialValue    =   ""
      Italic          =   ""
      Left            =   0
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
      TabIndex        =   0
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   0
      Underline       =   ""
      UseFocusRing    =   True
      Visible         =   True
      Width           =   600
      _ScrollWidth    =   -1
   End
   Begin PushButton PushButton1
      AutoDeactivate  =   True
      Bold            =   ""
      ButtonStyle     =   0
      Cancel          =   ""
      Caption         =   "Untitled"
      Default         =   ""
      Enabled         =   True
      Height          =   22
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Italic          =   ""
      Left            =   260
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Scope           =   0
      TabIndex        =   1
      TabPanelIndex   =   0
      TabStop         =   True
      TextFont        =   "System"
      TextSize        =   0
      TextUnit        =   0
      Top             =   364
      Underline       =   ""
      Visible         =   True
      Width           =   80
   End
   Begin ProgressBar ProgressBar1
      AutoDeactivate  =   True
      Enabled         =   True
      Height          =   20
      HelpTag         =   ""
      Index           =   -2147483648
      InitialParent   =   ""
      Left            =   10
      LockBottom      =   ""
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   ""
      LockTop         =   True
      Maximum         =   100
      Scope           =   0
      TabPanelIndex   =   0
      Top             =   360
      Value           =   0
      Visible         =   True
      Width           =   238
   End
End
#tag EndWindow

#tag WindowCode
#tag EndWindowCode

#tag Events Client
	#tag Event
		Sub FTPLog(LogLine As String)
		  Listbox1.AddRow(LogLine)
		End Sub
	#tag EndEvent
	#tag Event
		Sub Error(Code As Integer)
		  Listbox1.AddRow(Str(Code))
		End Sub
	#tag EndEvent
	#tag Event
		Function DataReadProgress(BytesRead As Integer, BytesLeft As Integer) As Boolean
		  ProgressBar1.Value = (BytesRead * 100 / (BytesRead + BytesLeft))
		End Function
	#tag EndEvent
	#tag Event
		Sub Connected()
		  Dim f As FolderItem = SpecialFolder.Desktop.Child("Prolexic_Threat_Advisory_Dirt_Jumper_v3.pdf")
		  Me.Get("Prolexic_Threat_Advisory_Dirt_Jumper_v3.pdf", f)
		End Sub
	#tag EndEvent
	#tag Event
		Sub DownloadComplete(File As FolderItem)
		  Listbox1.AddRow("Get Complete")
		  File.Parent.Launch
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events PushButton1
	#tag Event
		Sub Action()
		  Client.Connect
		  
		End Sub
	#tag EndEvent
#tag EndEvents
