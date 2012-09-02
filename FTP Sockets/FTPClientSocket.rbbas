#tag Class
Protected Class FTPClientSocket
Inherits FTPSocket
	#tag Event
		Sub Connected()
		  FTPLog("Connected to " + Me.RemoteAddress + ":" + Str(Me.Port))
		  VerbDispatchTimer = New Timer
		  VerbDispatchTimer.Period = 100
		  AddHandler VerbDispatchTimer.Action, AddressOf VerbDispatcher
		End Sub
	#tag EndEvent

	#tag Event
		Sub ControlResponse(Response As FTPResponse)
		  //This event is raised by FTPSocket.DataAvailable
		  //Response is a FTPSocket.FTPResponse stucture
		  
		  If Response.Reply_Args.Trim <> "" Then
		    FTPLog(Str(Response.Code) + " " + Response.Reply_Args.Trim)
		  Else
		    FTPLog(Str(Response.Code) + " " + FTPCodeToMessage(Response.Code).Trim)
		  End If
		  
		  
		  Select Case LastVerb.Verb
		  Case "USER"
		    Select Case Response.Code
		    Case 230  //Logged in W/O pass
		      LoginOK = True
		      RaiseEvent Connected()
		    Case 331, 332  //Need PASS/ACCT
		      DoVerb("PASS", Me.Password)
		    Else
		      Me.HandleFTPError(Response.Code)
		    End Select
		    
		  Case "PASS"
		    Select Case Response.Code
		    Case 230 //Logged in with pass
		      LoginOK = True
		      FTPLog("Ready")
		      RaiseEvent Connected()
		    Case 530  //USER not set!
		      DoVerb("USER", Me.Username)
		    Else
		      Me.HandleFTPError(Response.Code)
		    End Select
		  Case "RETR"
		    Select Case Response.Code
		    Case 150 //About to start data transfer
		      Dim size As String = NthField(Response.Reply_Args, "(", 2)
		      size = NthField(size, ")", 1)
		      OutputLength = Val(size)
		      If OutputFile = Nil Then
		        OutputFile = GetTemporaryFolderItem()
		      End If
		      If Not OutputFile.Exists Then
		        OutputFile = GetTemporaryFolderItem()
		      End If
		      If OutputStream = Nil Then
		        OutputStream = BinaryStream.Open(OutputFile)
		      End If
		    Case 425, 426 //Data connection not ready
		      HandleFTPError(Response.Code)
		    Case 451, 551 //Disk read error
		      HandleFTPError(Response.Code)
		    Case 226 //Done
		      'DataSocket.Close
		      TransferComplete(OutputFile)
		    Else
		      Me.HandleFTPError(Response.Code)
		    End Select
		  Case "STOR", "APPE"
		    Select Case Response.Code
		    Case 150  //Ready
		      UploadDispatcher = New Timer
		      AddHandler UploadDispatcher.Action, AddressOf UploadHandler
		      UploadDispatcher.Period = 1
		      UploadDispatcher.Mode = Timer.ModeMultiple
		      TransferInProgress = True
		    Case 226  //Success
		      TransferComplete(OutputFile)
		    Case 425  //No data connection!
		      If Passive Then
		        DataSocket.Connect
		        DoVerb(LastVerb.Verb, LastVerb.Arguments)
		      Else
		        HandleFTPError(Response.Code)
		      End If
		    Case 426  //Data connection lost
		      HandleFTPError(Response.Code)
		    Else
		      HandleFTPError(Response.Code)
		    End Select
		    
		  Case "FEAT"
		    ServerFeatures = Split(Response.Reply_Args, EndOfLine.Windows)
		  Case "SYST"
		    ServerType = Response.Reply_Args
		  Case "CWD"
		    Select Case Response.Code
		    Case 250, 200 //OK
		      mWorkingDirectory = LastVerb.Arguments
		    Else
		      HandleFTPError(Response.Code)
		    End Select
		    
		  Case "PWD"
		    If Response.Code = 257 Then //OK
		      mWorkingDirectory = LastVerb.Arguments
		      'FTPLog("CWD is " + WorkingDirectory)
		    Else
		      HandleFTPError(Response.Code)
		    End If
		  Case "LIST"
		    Select Case Response.Code
		    Case 226 //Here comes the directory list
		      'FTPLog("Directory list OK")
		    Case 425, 426  //no connection or connection lost
		      HandleFTPError(Response.Code)
		    Case 451  //Disk error
		      HandleFTPError(Response.Code)
		    Else
		      HandleFTPError(Response.Code)
		    End Select
		  Case "CDUP"
		    If Response.Code = 200 Or Response.Code = 250 Then
		      DoVerb("PWD")
		    Else
		      HandleFTPError(Response.Code)
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
		      'FTPLog("Entering Passive Mode (" + h1 + "," + h2 + "," + h3 + "," + h4 + "," + Str(p1) + "," + Str(p2))
		      DataSocket.Connect
		    Else
		      HandleFTPError(Response.Code)
		    End If
		  Case "REST"
		    If Response.Code = 350 Then
		      OutputStream.Position = Val(LastVerb.Arguments)
		    Else
		      HandleFTPError(Response.Code)
		    End If
		  Case "PORT"
		    If Response.Code = 200 Then
		      //Active mode OK. Connect to the following port
		      DataSocket.Listen()
		    Else
		      HandleFTPError(Response.Code)
		    End If
		  Case "TYPE"
		    If Response.Code = 200 Then
		      Select Case LastVerb.Arguments
		      Case "A", "A N"
		        Me.TransferMode = ASCIIMode
		      Case "I", "L"
		        Me.TransferMode = BinaryMode
		      End Select
		    Else
		      HandleFTPError(Response.Code)
		    End If
		    
		  Case "MKD"
		    If Response.Code = 257 Then //OK
		      LIST()
		    Else
		      HandleFTPError(Response.Code)
		    End If
		    
		  Case "RMD"
		    If Response.Code = 250 Then
		      LIST()
		    Else
		      HandleFTPError(Response.Code)
		    End If
		    
		  Case "DELE"
		    If Response.Code = 250 Then
		      LIST()
		    Else
		      HandleFTPError(Response.Code)
		    End If
		  Case "RNFR"
		    If Response.Code = 350 Then
		      DoVerb("RNTO", RNT)
		    Else
		      HandleFTPError(Response.Code)
		    End If
		  Case "RNTO"
		    If Response.Code = 250 Then
		      DoVerb("RNTO", RNT)
		      FTPLog(RNF + " renamed to " + RNT + " successfully.")
		      RNT = ""
		      RNF = ""
		    Else
		      HandleFTPError(Response.Code)
		    End If
		  Case "QUIT"
		    HandleFTPError(Response.Code)
		    Me.Close
		  Else
		    If Response.Code = 220 Then  //Server now ready
		      If Me.Anonymous Then
		        Me.Username = "anonymous"
		        Me.Password = "bsftp@boredomsoft.org"
		      End If
		      DoVerb("USER", Me.Username)
		    Else
		      //Sync error!
		    End If
		  End Select
		  VerbDispatchTimer.Mode = Timer.ModeMultiple
		End Sub
	#tag EndEvent

	#tag Event
		Sub ControlVerb(Verb As FTPVerb)
		  //FTP clients do not receive FTPVerb messages.
		  #pragma Unused Verb
		  FTPLog("Error: the remote server appears to be another client!")
		  Me.Disconnect()
		  Me.Close()
		End Sub
	#tag EndEvent

	#tag Event
		Sub TransferComplete(UserAborted As Boolean)
		  If Not UserAborted Then
		    If OutputFile <> Nil Then
		      RaiseEvent TransferComplete(OutputFile)
		    ElseIf OutputMB <> Nil Then
		      RaiseEvent TransferComplete(OutputMB)
		    End If
		  End If
		  
		  OutputMB = Nil
		  OutputStream = Nil
		  OutputFile = Nil
		  DataSocket.Disconnect
		  VerbDispatchTimer.Mode = Timer.ModeMultiple
		End Sub
	#tag EndEvent

	#tag Event
		Function TransferProgress(BytesSent As UInt64, BytesLeft As UInt64) As Boolean
		  Return RaiseEvent TransferProgress(BytesSent, BytesLeft)
		End Function
	#tag EndEvent

	#tag Event
		Sub TransferStarting()
		  'FTPLog("Data connection opened.")
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub CWD(NewDirectory As String)
		  //Change the WorkingDirectory
		  DoVerb("CWD", NewDirectory)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DELE(RemoteFileName As String)
		  //Delete the file named RemoteFileName on the FTP server
		  DoVerb("DELE", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub DoVerb(Verb As String, Params As String = "")
		  Dim nextverb As FTPVerb
		  Select Case Verb
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
		    nextverb.Verb = "PORT"
		    nextverb.Arguments = Params
		  Case "LIST"
		    'List.
		    OutputMB = New MemoryBlock(1024 * 64)
		    OutputStream = New BinaryStream(OutputMB)
		    OutputFile = Nil
		    nextverb.Verb = "LIST"
		    nextverb.Arguments = Params
		  Else
		    nextverb.Verb = Uppercase(Verb)
		    nextverb.Arguments = Trim(Params)
		  End Select
		  
		  PendingVerbs.Append(nextverb)
		  If VerbDispatchTimer <> Nil Then 
		    VerbDispatchTimer.Mode = Timer.ModeMultiple
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub List(TargetDirectory As String = "")
		  //Retrieves a directory listing
		  TargetDirectory = PathEncode(TargetDirectory)
		  DoVerb("LIST", TargetDirectory)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PASV()
		  //You must call either PASV or PORT before transferring anything over the DataSocket
		  DoVerb("PASV")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PORT(PortNumber As Integer)
		  //You must call either PASV or PORT before transferring anything over the DataSocket
		  DoVerb("PORT", Str(PortNumber))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PWD()
		  DoVerb("PWD")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Quit()
		  DoVerb("QUIT")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub REST(StartPosition As UInt64 = 0)
		  DoVerb("REST", Str(StartPosition))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RETR(RemoteFileName As String, SaveTo As FolderItem)
		  OutputFile = SaveTo
		  OutputStream = BinaryStream.Create(OutputFile, True)
		  DoVerb("RETR", PathEncode(RemoteFileName, WorkingDirectory))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub STOR(RemoteFileName As String, LocalFile As FolderItem)
		  OutputFile = LocalFile
		  OutputStream = BinaryStream.Open(OutputFile)
		  DoVerb("STOR", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub TYPE(Assigns TransferType As Integer)
		  Select Case TransferType
		  Case ASCIIMode
		    DoVerb("TYPE", "A")
		  Case LocalMode
		    DoVerb("TYPE", "L 8")
		  Case BinaryMode
		    DoVerb("TYPE", "I")
		  Case PortalMode
		    DoVerb("TYPE", "V")
		  Case EBCDICMode
		    DoVerb("TYPE", "E")
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub UploadHandler(Sender As Timer)
		  If OutputStream <> Nil Then
		    If Not OutputStream.EOF Then
		      WriteData(OutputStream.Read(1024 * 64))
		      If OutputStream <> Nil Then
		        If RaiseEvent TransferProgress(OutputStream.Position, OutputStream.Length - OutputStream.Position) Then
		          DoVerb("ABOR")
		        End If
		      End If
		    End If
		  Else
		    Sender.Mode = Timer.ModeOff
		  End If
		  
		Exception NilObjectException
		  Sender.Mode = Timer.ModeOff
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub VerbDispatcher(Sender As Timer)
		  If Not TransferInProgress And UBound(PendingVerbs) > -1 Then
		    Dim nextverb As FTPVerb = PendingVerbs(0)
		    PendingVerbs.Remove(0)
		    FTPLog(nextverb.Verb + " " + nextverb.Arguments)
		    Me.Write(nextverb.Verb + " " + nextverb.Arguments + CRLF)
		    LastVerb = nextverb
		    Sender.Mode = Timer.ModeOff
		  End If
		  
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Connected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferComplete(FolderItemOrMemoryBlock As Variant)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferProgress(BytesSent As UInt64, BytesLeft As UInt64) As Boolean
	#tag EndHook


	#tag Property, Flags = &h21
		Private mWorkingDirectory As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private PendingVerbs() As FTPVerb
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RNF As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RNT As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private UploadDispatcher As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private VerbDispatchTimer As Timer
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mWorkingDirectory
			End Get
		#tag EndGetter
		WorkingDirectory As String
	#tag EndComputedProperty


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
			Visible=true
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
			InheritedFrom="FTPSocket"
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
			InheritedFrom="FTPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="WorkingDirectory"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
