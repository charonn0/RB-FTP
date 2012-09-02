#tag Class
Protected Class FTPSocket
Inherits TCPSocket
	#tag Event
		Sub Error()
		  If Me.LastErrorCode = 102 Then
		    RaiseEvent Disconnected()
		  Else
		    RaiseEvent Error()
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub SendComplete(userAborted as Boolean)
		  //We're not interested in the control connection's progress
		  #pragma Unused userAborted
		  Return
		End Sub
	#tag EndEvent

	#tag Event
		Function SendProgress(bytesSent as Integer, bytesLeft as Integer) As Boolean
		  //We're not interested in the control connection's progress
		  #pragma Unused bytesSent
		  #pragma Unused bytesLeft
		  Return False
		End Function
	#tag EndEvent


	#tag Method, Flags = &h1
		Protected Shared Function ChildOfParent(Child As FolderItem, Parent As FolderItem) As Boolean
		  'A method to determine whether the Child FolderItem is contained within the Parent
		  'FolderItem or one of its sub-directories.
		  
		  If Not Parent.Directory Then Return False
		  While Child.Parent <> Nil
		    If Child.Parent.AbsolutePath = Parent.AbsolutePath Then
		      Return True
		    End If
		    Child = Child.Parent
		  Wend
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Close()
		  LoginOK = False
		  ReDim ServerFeatures(-1)
		  ServerType = ""
		  TransferInProgress = False
		  TransferMode = 0
		  
		  If DataSocket <> Nil Then
		    DataSocket.Close
		    DataSocket = Nil
		  End If
		  
		  If OutputStream <> Nil Then
		    OutputStream.Close
		  End If
		  
		  Super.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Connect()
		  CreateDataSocket()
		  DataSocket.Address = Me.Address
		  DataSocket.Port = Me.Port + 1
		  Super.Connect
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConnectedHandler(Sender As TCPSocket)
		  #pragma Unused Sender
		  'RaiseEvent ReadyToTransfer()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub CreateDataSocket()
		  DataSocket = New TCPSocket
		  AddHandler DataSocket.Connected, AddressOf ConnectedHandler
		  AddHandler DataSocket.DataAvailable, AddressOf DataAvailableHandler
		  AddHandler DataSocket.Error, AddressOf ErrorHandler
		  AddHandler DataSocket.SendComplete, AddressOf SendCompleteHandler
		  AddHandler DataSocket.SendProgress, AddressOf SendProgressHandler
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub CreateOutputStream(BackingFile As FolderItem = Nil)
		  If BackingFile <> Nil Then
		    OutputFile = BackingFile
		    If Not OutputFile.Exists Then
		      OutputStream = BinaryStream.Create(BackingFile, True)
		    Else
		      OutputStream = BinaryStream.Open(BackingFile, False)
		    End If
		    OutputMB = Nil
		  Else
		    OutputMB = New MemoryBlock(1024 * 64)
		    OutputStream = New BinaryStream(OutputMB)
		    OutputFile = Nil
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function CRLF() As String
		  Return Encodings.ASCII.Chr(13) + Encodings.ASCII.Chr(10)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DataAvailableHandler(Sender As TCPSocket)
		  Dim s As String = Sender.ReadAll
		  OutputStream.Write(s)
		  TransferInProgress = True
		  If RaiseEvent TransferProgress(OutputStream.Position, OutputLength - OutputStream.Position) Then
		    Write("ABOR" + CRLF)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ErrorHandler(Sender As TCPSocket)
		  If Sender.LastErrorCode = 102 Then
		    Sender.Close
		    'If OutputStream <> Nil Then OutputStream.Close
		    TransferInProgress = False
		    RaiseEvent TransferComplete(False)
		  Else
		    RaiseEvent Error()
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function FTPCodeToMessage(Code As Integer) As String
		  Select Case Code
		  Case 110
		    Return "Restart marker reply"
		  Case 120
		    Return "Service ready in nnn minutes."
		    
		  Case 125
		    Return "Data connection already open; transfer starting."
		    
		  Case 150
		    Return "File status okay; about to open data connection."
		    
		  Case 200
		    Return "Command okay."
		    
		  Case 202
		    Return "Command not implemented, superfluous at this site."
		    
		  Case 211
		    Return "System status, or system help reply."
		    
		  Case 212
		    Return "Directory status."
		    
		  Case 213
		    Return "File status."
		    
		  Case 214
		    Return "Help message."
		    
		  Case 215
		    Return "NAME system type."
		    
		  Case 220
		    Return "Service ready for new user."
		    
		  Case 221
		    Return "Service closing control connection."
		    
		  Case 225
		    Return "Data connection open; no transfer in progress."
		    
		  Case 226
		    Return "Closing data connection."
		    
		  Case 227
		    Return "Entering Passive Mode <h1,h2,h3,h4,p1,p2>."
		    
		  Case 228
		    Return "Entering Long Passive Mode."
		    
		  Case 229
		    Return "Extended Passive Mode Entered."
		    
		  Case 230
		    Return "User logged in, proceed."
		    
		  Case 250
		    Return "Requested file action okay, completed."
		    
		  Case 257
		    Return ""
		    
		  Case 331
		    Return "User name okay, need password."
		    
		  Case 332
		    Return "Need account for login."
		    
		  Case 350
		    Return "Requested file action pending further information."
		    
		  Case 421
		    Return "Service not available, closing control connection."
		    
		  Case 425
		    Return "Can't open data connection."
		    
		  Case 426
		    Return "Connection closed; transfer aborted."
		    
		  Case 450
		    Return "Requested file action not taken."
		    
		  Case 451
		    Return "Requested action aborted. Local error in processing."
		    
		  Case 452
		    Return "Requested action not taken."
		    
		  Case 500
		    Return "Syntax error, command unrecognized."
		    
		  Case 501
		    Return "Syntax error in parameters or arguments."
		    
		  Case 502
		    Return "Command not implemented."
		    
		  Case 503
		    Return "Bad sequence of commands."
		    
		  Case 504
		    Return "Command not implemented for that parameter."
		    
		  Case 521
		    Return "Supported address families are <af1, .., afn>"
		    
		  Case 522
		    Return "Protocol not supported."
		    
		  Case 530
		    Return "Not logged in."
		    
		  Case 532
		    Return "Need account for storing files."
		    
		  Case 550
		    Return "Requested action not taken."
		    
		  Case 551
		    Return "Requested action aborted. Page type unknown."
		    
		  Case 552
		    Return "Requested file action aborted."
		    
		  Case 553
		    Return "Requested action not taken."
		    
		  Case 554
		    Return "Requested action not taken: invalid REST parameter."
		    
		  Case 555
		    Return "Requested action not taken: type or stru mismatch."
		    
		  Else
		    Return "Unknown."
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub FTPLog(LogLine As String)
		  'This method allows any subclass of the FTPSocket to raise its own FTPLog event.
		  RaiseEvent FTPLog(LogLine)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function ParseList(ListData As String) As FTPListEntry()
		  Const ReadPerm = 4
		  Const WritePerm = 2
		  Const ExPerm = 1
		  
		  Const TypeFile = 0
		  Const TypeDir = 1
		  Const TypeLink = 2
		  
		  Dim list() As FTPListEntry
		  Dim lines() As String = Split(ListData, CRLF)
		  
		  
		  For Each Line As String In lines
		    Dim mode, linkcount, owner, group, filesize, modDate, filename As String
		    mode = NthField(line, " ", 1)
		    Line = Replace(Line, mode, "").Trim
		    
		    linkcount = NthField(line, " ", 1)
		    Line = Replace(line, linkcount, "").Trim
		    
		    owner = NthField(line, " ", 1)
		    Line = Replace(Line, owner, "").Trim
		    
		    group = NthField(line, " ", 1)
		    Line = Replace(Line, group, "").Trim
		    
		    filesize = NthField(line, " ", 1)
		    Line = Replace(Line, filesize, "").Trim
		    
		    modDate = NthField(line, " ", 1) + " " + modDate + NthField(line, " ", 2) + " " + modDate + NthField(line, " ", 3)
		    Line = Replace(Line, modDate, "").Trim
		    
		    filename = line.Trim
		    
		    Dim ListEntry As FTPListEntry
		    Select Case Mid(mode, 1, 1)
		    Case "-"
		      ListEntry.EntryType = TypeFile
		    Case "D"
		      ListEntry.EntryType = TypeDir
		    Case "L"
		      ListEntry.EntryType = TypeLink
		    End Select
		    
		    Dim tmp As Integer = 0
		    If Mid(mode, 2, 1) = "r" Then
		      tmp = tmp + 4
		    End If
		    
		    If Mid(mode, 3, 1) = "w" Then
		      tmp = tmp + 2
		    End If
		    
		    If Mid(mode, 4, 1) = "x" Then
		      tmp = tmp + 1
		    End If
		    
		    ListEntry.OwnerPerms = tmp
		    tmp = 0
		    
		    If Mid(mode, 5, 1) = "r" Then
		      tmp = tmp + 4
		    End If
		    
		    If Mid(mode, 6, 1) = "w" Then
		      tmp = tmp + 2
		    End If
		    
		    If Mid(mode, 7, 1) = "x" Then
		      tmp = tmp + 1
		    End If
		    
		    ListEntry.GroupPerms = tmp
		    tmp = 0
		    
		    If Mid(mode, 8, 1) = "r" Then
		      tmp = tmp + 4
		    End If
		    
		    If Mid(mode, 9, 1) = "w" Then
		      tmp = tmp + 2
		    End If
		    
		    If Mid(mode, 10, 1) = "x" Then
		      tmp = tmp + 1
		    End If
		    
		    ListEntry.WorldPerms = tmp
		    
		    ListEntry.FileName = filename
		    ListEntry.FileSize = Val(filesize)
		    ListEntry.Owner = owner
		    ListEntry.Group = group
		    ListEntry.Timestamp = modDate
		    list.Append(ListEntry)
		  Next
		  
		  Return list
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function PathDecode(Path As String, NamePrefix As String = "") As String
		  Path = ReplaceAll(Path, Chr(&o0), Chr(&o12))
		  Return ReplaceAll(NamePrefix + Path, "//", "/")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function PathEncode(Path As String, NamePrefix As String = "") As String
		  Path = ReplaceAll(Path, Chr(&o12), Chr(&o0))
		  Return NamePrefix + Path
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Read() As String
		  Dim la As String
		  
		  While Me.Lookahead.LenB > 0
		    la = la + Me.ReadAll
		    App.YieldToNextThread
		  Wend
		  
		  Return la
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadData() As String
		  Return DataSocket.ReadAll
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SendCompleteHandler(Sender As TCPSocket, UserAborted As Boolean)
		  #pragma Unused Sender
		  'If OutputStream <> Nil Then OutputStream.Close
		  If OutputStream.Position < OutputStream.Length Then Return
		  TransferInProgress = False
		  RaiseEvent TransferComplete(UserAborted)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SendProgressHandler(Sender As TCPSocket, BytesSent As Integer, BytesLeft As Integer) As Boolean
		  #pragma Unused Sender
		  Return RaiseEvent TransferProgress(BytesSent, BytesLeft)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Write(Command As String)
		  Super.Write(Command)
		  Me.Flush
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub WriteData(Data As String)
		  DataSocket.Write(Data)
		  DataSocket.Flush
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Disconnected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Error()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event FTPLog(LogLine As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferComplete(UserAborted As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferProgress(BytesSent As UInt64, BytesLeft As UInt64) As Boolean
	#tag EndHook


	#tag Note, Name = FTPSocket Notes
		This class provides both the control and data connections for a given FTP session.
		FTPClientSocket and FTPServerSocket are subclassed from FTPSocket. FTPSocket should 
		only know about the connections themselves without needing to know whether it's a 
		client or server flavor. Other non-socket data which is used in both clients and 
		servers are also dealt with in FTPSocket.
		
		This class is not intended to be used except as the superclass of another TCPSocket 
		that handles protocol layer stuff via the ControlVerb event (for servers) or the 
		ControlRespose event (for clients) and Write and WriteData for both clients and servers.
	#tag EndNote


	#tag Property, Flags = &h0
		Anonymous As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected DataSocket As TCPSocket
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected LoginOK As Boolean
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected OutputFile As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected OutputLength As UInt64
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected OutputMB As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected OutputStream As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h0
		Passive As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h0
		Password As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected ServerFeatures() As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected ServerType As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected TransferInProgress As Boolean
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected TransferMode As Integer = 1
	#tag EndProperty

	#tag Property, Flags = &h0
		Username As String
	#tag EndProperty


	#tag Constant, Name = ASCIIMode, Type = Double, Dynamic = False, Default = \"2", Scope = Public
	#tag EndConstant

	#tag Constant, Name = BinaryMode, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant

	#tag Constant, Name = EBCDICMode, Type = Double, Dynamic = False, Default = \"4", Scope = Public
	#tag EndConstant

	#tag Constant, Name = FTPVersion, Type = Double, Dynamic = False, Default = \"0.1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LocalMode, Type = Double, Dynamic = False, Default = \"3", Scope = Public
	#tag EndConstant

	#tag Constant, Name = PortalMode, Type = Double, Dynamic = False, Default = \"-1", Scope = Public
	#tag EndConstant


	#tag Structure, Name = FTPListEntry, Flags = &h0
		FileName As String*256
		  Owner As String*64
		  Group As String*64
		  EntryType As Integer
		  OwnerPerms As Integer
		  GroupPerms As Integer
		  WorldPerms As Integer
		  FileSize As UInt64
		Timestamp As String*64
	#tag EndStructure

	#tag Structure, Name = FTPVerb, Flags = &h1
		Verb As String*64
		Arguments As String*448
	#tag EndStructure


	#tag ViewBehavior
		#tag ViewProperty
			Name="Address"
			Visible=true
			Group="Behavior"
			Type="String"
			InheritedFrom="TCPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Anonymous"
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataAddress"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataIsConnected"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataLastErrorCode"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataPort"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Passive"
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Password"
			Visible=true
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Port"
			Visible=true
			Group="Behavior"
			InitialValue="21"
			Type="Integer"
			InheritedFrom="TCPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Username"
			Visible=true
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
