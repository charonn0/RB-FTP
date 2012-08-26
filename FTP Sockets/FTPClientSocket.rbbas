#tag Class
Protected Class FTPClientSocket
Inherits FTPSocket
	#tag Event
		Sub Connected(IsControlSocket As Boolean)
		  If IsControlSocket Then
		    FTPLog("Connected to " + Me.RemoteAddress + ":" + Str(Me.Port))
		    CommandDelayTimer.Mode = Timer.ModeMultiple
		  End If
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable(IsControlSocket As Boolean)
		  If IsControlSocket Then
		    Dim s As String = Me.Read
		    ParseResponse(s)
		  Else
		    Dim s As String = Me.ReadData
		    OutputStream.Write(s)
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub Error(IsControlSocket As Boolean)
		  If IsControlSocket Then
		    RaiseEvent Error(Me.LastErrorCode)
		  Else
		    RaiseEvent Error(DataSocket.LastErrorCode)
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub FTPLog(LogLine As String)
		  RaiseEvent FTPLog(LogLine)
		End Sub
	#tag EndEvent

	#tag Event
		Sub SendComplete(UserAborted As Boolean, IsControlSocket As Boolean)
		  If Not IsControlSocket Then
		    OutputStream.Close
		    RaiseEvent SendComplete(UserAborted)
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Function SendProgress(BytesSent As Integer, BytesLeft As Integer, IsControlSocket As Boolean) As Boolean
		  If Not IsControlSocket Then
		    Return RaiseEvent SendProgress(BytesSent, BytesLeft)
		    
		  End If
		End Function
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub CommandDelayHandler(Sender As Timer)
		  #pragma Unused Sender
		  If IsConnected And UBound(PendingCommands) > -1 Then
		    Dim s As String = PendingCommands(0)
		    PendingCommands.Remove(0)
		    WriteCommand(s + CRLF)
		  End If
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub DoVerb(Verb As String, Params As String = "")
		  Select Case Verb
		  Case "ABOR"
		    'Abort
		    WriteCommand("ABOR " + Params + CRLF)
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
		    WriteCommand("PASS " + Params + CRLF)
		  Case "PASV"
		    'Passive mode.
		    QueueCommand("PASV " + Params)
		  Case "PBSZ"
		    'Protection Buffer Size.
		    QueueCommand("PBSZ " + Params)
		  Case "PORT"
		    'Data port.
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
		    WriteCommand("USER " + Params + CRLF)
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
		    RaiseEvent Error(500)
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HandleResponse(code As Integer, args As String, raw As String) As Boolean
		  Select Case Code
		  Case 215
		    'NAME system type.
		    Me.ServerType = args
		    HandShake()
		    Return True
		  Case 220, 230, 331, 332
		    'loginOK = True
		    HandShake()
		    If code = 230 Then
		      LoginOK = True
		    End If
		    Return True
		  Case 530
		    HandShakeStep = 0
		    HandShake()
		    Return True
		    
		  Case 211
		    If raw.Trim = "211 End" Then Return False
		    ServerFeatures = Split(DefineEncoding(raw, Encodings.ASCII), CRLF)
		    ServerFeatures.Remove(0)
		    For Each feature As String In ServerFeatures
		      feature = feature.Trim
		    Next
		    HandShake()
		    Return False
		  Else
		    Return False
		  End Select
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub HandShake()
		  If LoginOK Or HandShakeStep <= 2 Then
		    If HandShakeStep = 0 Then
		      If Me.Anonymous Then
		        FTPLog("Logging in as anonymous")
		        Me.User = "anonymous"
		      End If
		      DoVerb("USER", Me.User)
		      HandShakeStep = 1
		    ElseIf HandShakeStep = 1 Then
		      DoVerb("PASS", Me.Password)
		      HandShakeStep = 2
		    ElseIf HandShakeStep = 2 Then
		      DoVerb("SYST")
		      HandShakeStep = 3
		    ElseIf HandShakeStep = 3 Then
		      DoVerb("FEAT")
		      HandShakeStep = 4
		    ElseIf HandShakeStep = 4 Then
		      If ServerHasFeature("UTF8") Then
		        DoVerb("OPTS", "UTF8 ON")
		      End If
		      HandShakeStep = 5
		    ElseIf HandShakeStep = 5 Then
		      DoVerb("PWD")
		      HandShakeStep = 6
		    End If
		    
		    If HandShakeStep = 6 Then RaiseEvent Connected()
		    
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseResponse(Response As String)
		  If HandShakeStep < 6 Then
		    HandShake()
		  End If
		  
		  Dim num As Integer
		  Dim msg As String
		  
		  num = Val(Left(Response, 3))
		  msg = msg.Replace(Format(num, "000"), "")
		  'If msg.Trim = "" Then msg = FTPCodeToMessage(num)
		  'FTPLog(Format(num, "000") + ": " + msg)
		  
		  If Not HandleResponse(num, msg, Response) Then
		    RaiseEvent ReceiveReply(num, msg)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub QueueCommand(Command As String)
		  PendingCommands.Append(Command.Trim)
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
		  If UTFMode Then
		    Command = DefineEncoding(Command, Encodings.UTF8)
		  End If
		  FTPLog(Command)
		  Super.Write(Command + CRLF)
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Connected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Error(Code As Integer)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event FTPLog(LogLine As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ReceiveReply(ReplyNumber As Integer, ReplyMessage As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SendComplete(UserAborted As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SendProgress(BytesSent As Integer, BytesLeft As Integer) As Boolean
	#tag EndHook


	#tag Property, Flags = &h0
		Anonymous As Boolean = False
	#tag EndProperty

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

	#tag Property, Flags = &h1
		Protected OutputFile As FolderItem
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
		Protected PendingCommands() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		RemoteDirectory As String = "/"
	#tag EndProperty

	#tag Property, Flags = &h21
		Private ServerFeatures() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		ServerType As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected TransferMode As Integer = 1
	#tag EndProperty

	#tag Property, Flags = &h0
		User As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private UTFMode As Boolean
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
			Visible=true
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
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
			Visible=true
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
			InheritedFrom="FTPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="RemoteDirectory"
			Visible=true
			Group="Behavior"
			InitialValue="/"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ServerType"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
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
