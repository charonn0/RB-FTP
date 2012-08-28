#tag Class
Protected Class FTPClientSocket
Inherits FTPSocket
	#tag Event
		Sub ControlConnected()
		  FTPLog("Connected to " + Me.RemoteAddress + ":" + Str(Me.Port))
		  CommandDelayTimer.Mode = Timer.ModeMultiple
		  RaiseEvent Connected()
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub ControlError()
		  RaiseEvent Error(Me.LastErrorCode)
		End Sub
	#tag EndEvent

	#tag Event
		Function ControlReadProgress(BytesRead As Integer, BytesLeft As Integer) As Boolean
		  #pragma Unused BytesRead
		  #pragma Unused BytesLeft
		  Return False
		End Function
	#tag EndEvent

	#tag Event
		Sub ControlResponse(Response As FTPResponse)
		  Select Case LastVerb
		  Case "USER"
		    Select Case Response.Code
		    Case 230  //Logged in W/O pass
		      LoginOK = True
		      FTPLog("Ready")
		    Case 331, 332  //Need PASS/ACCT
		      DoVerb("PASS", Me.Password)
		    End Select
		    
		  Case "PASS"
		    Select Case Response.Code
		    Case 230 //Logged in with pass
		      LoginOK = True
		      FTPLog("Ready")
		    Case 530  //USER not set!
		      DoVerb("USER", Me.User)
		    End Select
		  Case "RETR"
		    Select Case Response.Code
		    Case 150 //About to start data transfer
		      
		    Case 425, 426 //Data connection not ready
		      Error(Response.Code)
		    Case 451, 551 //Disk read error
		      Error(Response.Code)
		    Case 226 //Done
		      DataSocket.Close
		      DownloadComplete(OutputFile)
		    End Select
		  Case "STOR", "APPE"
		    Select Case Response.Code
		    Case 150  //Ready
		      While Not OutputStream.EOF
		        WriteData(OutputStream.Read(512))
		      Wend
		      OutputStream.Position = 0
		      OutputStream.Close
		    Case 226  //Success
		      UploadComplete(OutputFile)
		    Case 425  //No data connection!
		      If Passive Then
		        DataSocket.Connect
		        DoVerb(LastVerb, LastParams)
		      Else
		        Error(Response.Code)
		      End If
		    Case 426  //Data connection lost
		      Error(Response.Code)
		    Else
		      Error(Response.Code)
		    End Select
		    
		  Case "FEAT"
		    
		  Case "SYST"
		    
		  Case "CWD"
		    Select Case Response.Code
		    Case 250, 200 //OK
		      WorkingDirectory = LastParams
		    Else
		      Error(Response.Code)
		    End Select
		    
		  Case "PWD"
		    If Response.Code = 257 Then //OK
		      WorkingDirectory = LastParams
		    Else
		      Error(Response.Code)
		    End If
		  Case "LIST"
		    
		  Case "CDUP"
		    If Response.Code = 200 Or Response.Code = 250 Then
		      DoVerb("PWD")
		    Else
		      Error(Response.Code)
		    End If
		  Case "PASV"
		    If Response.Code = 227 Then 'Entering Passive Mode <h1,h2,h3,h4,p1,p2>.
		      Dim p1, p2 As Integer
		      Dim h1, h2, h3, h4 As String
		      h1 = NthField(NthField(Response.Reply_Args, ",", 1), "(", 2)
		      h2 = NthField(Response.Reply_Args, ",", 2)
		      h3 = NthField(Response.Reply_Args, ",", 3)
		      h4 = NthField(Response.Reply_Args, ",", 4)
		      p1 = Val(NthField(Response.Reply_Args, ",", 5))
		      p2 = Val(NthField(Response.Reply_Args, ",", 6))
		      DataSocket.Port = p1 * 256 + p2
		      DataSocket.Address = h1 + "." + h2 + "." + h3 + "." + h4
		      FTPLog("Entering Passive Mode (" + h1 + "," + h2 + "," + h3 + "," + h4 + "," + Str(p1) + "," + Str(p2))
		      DataSocket.Connect
		    Else
		      Error(Response.Code)
		    End If
		  Case "REST"
		    If Response.Code = 350 Then
		      OutputStream.Position = Val(LastParams)
		    Else
		      Error(Response.Code)
		    End If
		  Case "PORT"
		    If Response.Code = 200 Then
		      //Active mode OK. Connect to the following port
		      DataSocket.Listen()
		    Else
		      Error(Response.Code)
		    End If
		  Case "TYPE"
		    If Response.Code = 200 Then
		      Select Case LastParams
		      Case "A", "A N"
		        Me.TransferMode = ASCIIMode
		      Case "I", "L"
		        Me.TransferMode = BinaryMode
		      End Select
		    Else
		      Error(Response.Code)
		    End If
		    
		  Case "MKD"
		    If Response.Code = 257 Then //OK
		      DoVerb("LIST")
		    Else
		      Error(Response.Code)
		    End If
		    
		  Case "RMD"
		    If Response.Code = 250 Then
		      DoVerb("LIST")
		    Else
		      Error(Response.Code)
		    End If
		    
		  Case "DELE"
		    If Response.Code = 250 Then
		      DoVerb("LIST")
		    Else
		      Error(Response.Code)
		    End If
		  Case "RNFR", "RNTO"  //TODO
		    
		  Else
		    If Response.Code = 220 Then
		      FTPLog(Response.Reply_Args)
		      DoVerb("USER", Me.User)
		    Else
		      //Sync error!
		    End If
		  End Select
		  
		  LastVerb = ""
		  LastParams = ""
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub ControlVerb(Verb As FTPVerb)
		  #pragma Unused Verb
		  //Clients do not accept Verbs
		  Return
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataConnected()
		  If OutputFile = Nil Then
		    OutputTempFile = GetTemporaryFolderItem
		  ElseIf OutputFile.Exists Then
		    OutputTempFile = OutputFile
		  Else
		    OutputTempFile = GetTemporaryFolderItem
		  End If
		  OutputStream = BinaryStream.Open(OutputTempFile, True)
		  
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataError()
		  RaiseEvent Error(Me.DataLastErrorCode)
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataReadComplete(UserAborted As Boolean)
		  If Not UserAborted Then
		    RaiseEvent DownloadComplete(OutputFile)
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataWriteComplete(UserAborted As Boolean)
		  If Not UserAborted Then
		    RaiseEvent UploadComplete(OutputFile)
		  End If
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub CommandDelayHandler(Sender As Timer)
		  #pragma Unused Sender
		  If IsConnected And UBound(PendingCommands) > -1 And LastVerb.Trim = "" Then
		    Dim s As String = PendingCommands(0)
		    PendingCommands.Remove(0)
		    LastVerb = NthField(s, " ", 1).Trim
		    LastParams = NthField(s, " ", 2).Trim
		    Write(s + CRLF)
		  End If
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub DoVerb(Verb As String, Params As String = "")
		  Select Case Verb
		  Case "ABOR"
		    'Abort
		    WriteCommand("ABOR " + Params)
		  Case "ACCT"
		    'Account.
		    QueueCommand("ACCT " + Params)
		  Case "ADAT"
		    'Authentication/Security Data.
		    QueueCommand("ADAT " + Params)
		  Case "ALLO"
		    'Allocate.
		    QueueCommand("ALLO " + Params)
		  Case "APPE"
		    'Append.
		    QueueCommand("APPE " + Params)
		  Case "AUTH"
		    'Authentication/Security Mechanism.
		    QueueCommand("AUTH " + Params)
		  Case "CCC"
		    'Clear Command Channel.
		    QueueCommand("CCC " + Params)
		  Case "CDUP"
		    'Change to parent directory.
		    QueueCommand("CDUP " + Params)
		  Case "CONF"
		    'Confidentiality Protected Command.
		    QueueCommand("CONF " + Params)
		  Case "CWD"
		    'Change working directory.
		    QueueCommand("CWD " + Params)
		  Case "DELE"
		    'Delete.
		    QueueCommand("DELE " + Params)
		  Case "ENC"
		    'Privacy Protected Command.
		    QueueCommand("ENC " + Params)
		  Case "EPRT"
		    'Extended Data port.
		    QueueCommand("EPRT " + Params)
		  Case "EPSV"
		    'Extended Passive.
		    QueueCommand("EPSV " + Params)
		  Case "FEAT"
		    'Feature.
		    QueueCommand("FEAT " + Params)
		  Case "HELP"
		    'Help.
		    QueueCommand("HELP " + Params)
		  Case "LANG"
		    'Language negotiation.
		    QueueCommand("LANG " + Params)
		  Case "LIST"
		    'List.
		    QueueCommand("LIST " + Params)
		  Case "LPRT"
		    'Long data port.
		    QueueCommand("LPRT " + Params)
		  Case "LPSV"
		    'Long passive.
		    QueueCommand("LPSV " + Params)
		  Case "MDTM"
		    'File modification time.
		    QueueCommand("MDTM " + Params)
		  Case "MIC"
		    'Integrity Protected Command.
		    QueueCommand("MIC " + Params)
		  Case "MKD"
		    'Make directory.
		    QueueCommand("MKD " + Params)
		  Case "MLSD"
		    QueueCommand("MLSD " + Params)
		    
		  Case "MLST"
		    QueueCommand("MLST " + Params)
		    
		  Case "MODE"
		    'Transfer mode.
		    QueueCommand("MODE " + Params)
		  Case "NLST"
		    'Name list.
		    QueueCommand("NLST " + Params)
		  Case "NOOP"
		    'No operation.
		    QueueCommand("NOOP " + Params)
		  Case "OPTS"
		    'Options.
		    QueueCommand("OPTS " + Params)
		  Case "PASS"
		    'Password.
		    WriteCommand("PASS " + Params)
		  Case "PASV"
		    'Passive mode.
		    QueueCommand("PASV " + Params)
		  Case "PBSZ"
		    'Protection Buffer Size.
		    QueueCommand("PBSZ " + Params)
		  Case "PORT"
		    'Data port.
		    Dim p1, p2 As Integer
		    Dim h1, h2, h3, h4 As String
		    h1 = NthField(NthField(Params, ",", 1), "(", 2)
		    h2 = NthField(Params, ",", 2)
		    h3 = NthField(Params, ",", 3)
		    h4 = NthField(Params, ",", 4)
		    p1 = Val(NthField(Params, ",", 5))
		    p2 = Val(NthField(Params, ",", 6))
		    DataSocket.Port = p1 * 256 + p2
		    DataSocket.Address = h1 + "." + h2 + "." + h3 + "." + h4
		    params = h1 + "," + h2 + "," + h3 + "," + h4 + "," + Str(p1) + "," + Str(p2)
		    QueueCommand("PORT " + Params)
		  Case "PROT"
		    'Data Channel Protection Level.
		    QueueCommand("PROT " + Params)
		  Case "PWD"
		    'Print working directory.
		    QueueCommand("PWD " + Params)
		  Case "QUIT"
		    'Logout.
		    QueueCommand("QUIT " + Params)
		  Case "REIN"
		    'Reinitialize.
		    QueueCommand("REIN " + Params)
		  Case "REST"
		    'Restart of interrupted transfer.
		    QueueCommand("REST " + Params)
		  Case "RETR"
		    'Retrieve.
		    QueueCommand("RETR " + Params)
		  Case "RMD"
		    'Remove directory.
		    QueueCommand("RMD " + Params)
		  Case "RNFR"
		    'Rename from.
		    QueueCommand("RNFR " + Params)
		  Case "RNTO"
		    'Rename to.
		    QueueCommand("RNTO " + Params)
		  Case "SITE"
		    'Site parameters.
		    QueueCommand("SITE " + Params)
		  Case "SIZE"
		    'File size.
		    QueueCommand("SIZE " + Params)
		  Case "SMNT"
		    'Structure mount.
		    QueueCommand("SMNT " + Params)
		  Case "STAT"
		    'Status.
		    QueueCommand("STAT " + Params)
		  Case "STOR"
		    'Store.
		    QueueCommand("STOR " + Params)
		  Case "STOU"
		    'Store unique.
		    QueueCommand("STOU " + Params)
		  Case "STRU"
		    'File structure.
		    QueueCommand("STRU " + Params)
		  Case "SYST"
		    'System.
		    QueueCommand("SYST " + Params)
		  Case "TYPE"
		    'Representation type.
		    QueueCommand("TYPE " + Params)
		  Case "USER"
		    'User name.
		    WriteCommand("USER " + Params)
		    HandShakeStep = 1
		  Case "XCUP"
		    'Change to the parent of the current working directory.
		    QueueCommand("XCUP " + Params)
		  Case "XMKD"
		    'Make a directory.
		    QueueCommand("XMKD " + Params)
		  Case "XPWD"
		    'Print the current working directory.
		    QueueCommand("XPWD " + Params)
		  Case "XRCP"
		    QueueCommand("XRCP " + Params)
		    
		  Case "XRMD"
		    'Remove the directory.
		    QueueCommand("XRMD " + Params)
		  Case "XRSQ"
		    QueueCommand("XRSQ " + Params)
		    
		  Case "XSEM"
		    'Send, Mail if cannot.
		    QueueCommand("XSEM " + Params)
		  Case "XSEN"
		    'Send to terminal.
		    QueueCommand("XSEN " + Params)
		  Else
		    'Unknown Verb
		    LastVerb = ""
		    LastParams = ""
		    RaiseEvent Error(500)
		  End Select
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Get(RemoteFileName As String, SaveTo As FolderItem)
		  OutputTempFile = GetTemporaryFolderItem()
		  OutputFile = SaveTo
		  If Me.Passive Then
		    DoVerb("PASV")
		  End If
		  If TransferMode = BinaryMode Then
		    DoVerb("TYPE", "I")
		  End If
		  
		  DoVerb("RETR", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub HandShake()
		  If HandShakeStep = 1 Then
		    If Password.Trim <> "" Then
		      DoVerb("PASS", Me.Password)
		    End If
		    HandShakeStep = 2
		    Return
		  ElseIf HandShakeStep = 2 Then
		    DoVerb("SYST")
		    HandShakeStep = 3
		    Return
		  ElseIf HandShakeStep = 3 Then
		    DoVerb("FEAT")
		    HandShakeStep = 4
		    Return
		  ElseIf HandShakeStep = 4 Then
		    If ServerHasFeature("UTF8") Then
		      DoVerb("OPTS", "UTF8 ON")
		    End If
		    HandShakeStep = 5
		    Return
		  ElseIf HandShakeStep = 5 Then
		    DoVerb("PWD")
		    HandShakeStep = 6
		    Return
		  ElseIf HandShakeStep = 6 Then
		    RaiseEvent Connected()
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Put(RemoteFileName As String, LocalFile As FolderItem)
		  If ServerHasFeature("PASV") And Me.Passive Then
		    DoVerb("PASV")
		  End If
		  If TransferMode = BinaryMode Then
		    DoVerb("TYPE", "I")
		  End If
		  OutputFile = LocalFile
		  DoVerb("STOR", WorkingDirectory + "/" + RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub QueueCommand(Command As String)
		  PendingCommands.Append(Command.Trim)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ReceiveReply(ReplyNumber As Integer, ReplyMessage As String)
		  Select Case ReplyNumber
		  Case 110
		    //Restart marker reply
		  Case 120
		    'Service ready in nnn minutes.
		    
		  Case 125
		    'Data connection already open; transfer starting.
		    
		  Case 150
		    'File status okay; about to open data connection.
		    DataSocket.Connect
		  Case 200
		    'Command okay.
		  Case 202
		    'Command not implemented, superfluous at this site.
		  Case 211
		    'System status, or system help reply.
		    'Break
		  Case 212
		    'Directory status.
		    
		  Case 213
		    'File status.
		    
		  Case 214
		    'Help message.
		    
		  Case 215
		    'NAME system type.
		    Me.ServerType = ReplyMessage
		  Case 220
		    'Service ready for new user.
		    
		  Case 221
		    'Service closing control connection.
		    
		  Case 225
		    'Data connection open; no transfer in progress.
		    
		  Case 226
		    'Closing data connection.
		    DataSocket.Close
		  Case 227
		    'Entering Passive Mode <h1,h2,h3,h4,p1,p2>.
		    Dim p1, p2 As Integer
		    Dim h1, h2, h3, h4 As String
		    h1 = NthField(NthField(ReplyMessage, ",", 1), "(", 2)
		    h2 = NthField(ReplyMessage, ",", 2)
		    h3 = NthField(ReplyMessage, ",", 3)
		    h4 = NthField(ReplyMessage, ",", 4)
		    p1 = Val(NthField(ReplyMessage, ",", 5))
		    p2 = Val(NthField(ReplyMessage, ",", 6))
		    DataSocket.Port = p1 * 256 + p2
		    DataSocket.Address = h1 + "." + h2 + "." + h3 + "." + h4
		    ReplyMessage = ("Entering Passive Mode (" + h1 + "," + h2 + "," + h3 + "," + h4 + "," + Str(p1) + "," + Str(p2))
		  Case 228
		    'Entering Long Passive Mode.
		    
		  Case 229
		    'Extended Passive Mode Entered.
		    
		  Case 230
		    'User logged in, proceed.
		    loginOK = True
		  Case 250
		    'Requested file action okay, completed.
		    
		  Case 257
		    '"PATHNAME" created.
		    FTPLog("Current directory is " + ReplyMessage)
		    WorkingDirectory = ReplyMessage
		  Case 331
		    'User name okay, need password.
		    DoVerb("PASS", Me.Password)
		  Case 332
		    'Need account for login.
		    DoVerb("PASS", Me.Password)
		  Case 350
		    'Requested file action pending further information.
		    
		  Case 421
		    'Service not available, closing control connection.
		    
		  Case 425
		    'Can't open data connection.
		    
		  Case 426
		    'Connection closed; transfer aborted.
		    
		  Case 450
		    'Requested file action not taken.
		    
		  Case 451
		    'Requested action aborted. Local error in processing.
		    
		  Case 452
		    'Requested action not taken.
		    
		  Case 500
		    'Syntax error, command unrecognized.
		    
		  Case 501
		    'Syntax error in parameters or arguments.
		    
		  Case 502
		    'Command not implemented.
		    
		  Case 503
		    'Bad sequence of commands.
		    
		  Case 504
		    'Command not implemented for that parameter.
		    
		  Case 521
		    'Supported address families are <af1, .., afn>
		    
		  Case 522
		    'Protocol not supported.
		    
		  Case 530
		    'Not logged in.
		    
		  Case 532
		    'Need account for storing files.
		    
		  Case 550
		    'Requested action not taken.
		    
		  Case 551
		    'Requested action aborted. Page type unknown.
		    
		  Case 552
		    'Requested file action aborted.
		    
		  Case 553
		    'Requested action not taken.
		    
		  Case 554
		    'Requested action not taken: invalid REST parameter.
		    
		  Case 555
		    'Requested action not taken: type or stru mismatch.
		    
		  Else
		    'Unknown
		  End Select
		  FTPLog(ReplyMessage)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ServerHasFeature(FeatureName As String) As Boolean
		  For Each feature As String In ServerFeatures
		    If feature = FeatureName Then
		      Return True
		    End If
		  Next
		  '
		  '
		  '
		  '
		  '
		  'Return ServerFeatures.IndexOf(FeatureName) <> -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteCommand(Command As String)
		  PendingCommands.Insert(0, Command.Trim)
		  
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Connected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DownloadComplete(File As FolderItem)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Error(Code As Integer)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event FTPLog(LogLine As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event UploadComplete(File As FolderItem)
	#tag EndHook


	#tag ComputedProperty, Flags = &h21
		#tag Getter
			Get
			  If mCommandDelayTimer = Nil Then
			    mCommandDelayTimer = New Timer
			    mCommandDelayTimer.Period = 250
			    AddHandler mCommandDelayTimer.Action, AddressOf CommandDelayHandler
			  End If
			  return mCommandDelayTimer
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  mCommandDelayTimer = value
			End Set
		#tag EndSetter
		Private CommandDelayTimer As Timer
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private HandShakeStep As Integer
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected LoginOK As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCommandDelayTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h0
		Password As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected PendingCommands() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		User As String
	#tag EndProperty


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
			InheritedFrom="FTPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataAddress"
			Group="Behavior"
			Type="String"
			InheritedFrom="FTPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataIsConnected"
			Group="Behavior"
			Type="Boolean"
			InheritedFrom="FTPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataLastErrorCode"
			Group="Behavior"
			Type="Integer"
			InheritedFrom="FTPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataPort"
			Group="Behavior"
			Type="Integer"
			InheritedFrom="FTPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
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
			InheritedFrom="FTPSocket"
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
			InheritedFrom="FTPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ServerType"
			Group="Behavior"
			Type="String"
			InheritedFrom="FTPSocket"
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
			Name="User"
			Visible=true
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
