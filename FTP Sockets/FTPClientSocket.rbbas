#tag Class
Protected Class FTPClientSocket
Inherits FTPSocket
	#tag Event
		Sub Connected()
		  FTPLog("Connected to " + Me.RemoteAddress + ":" + Str(Me.Port))
		  VerbDispatchTimer = New Timer
		  VerbDispatchTimer.Period = 100
		  AddHandler VerbDispatchTimer.Action, AddressOf VerbDispatchHandler
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable()
		  Dim s As String = Me.Read
		  ParseResponse(s)
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub Disconnected()
		  Me.Close()
		End Sub
	#tag EndEvent

	#tag Event
		Sub TransferComplete(UserAborted As Boolean)
		  #pragma Unused UserAborted
		  DataStream.Close
		  DataSocket.Close
		  VerbDispatchTimer.Mode = Timer.ModeMultiple
		  If UploadDispatchTimer <> Nil Then UploadDispatchTimer.Mode = Timer.ModeOff
		End Sub
	#tag EndEvent

	#tag Event
		Function TransferProgress(BytesSent As Int64, BytesLeft As Int64) As Boolean
		  Return RaiseEvent TransferProgress(BytesSent, BytesLeft)
		End Function
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub ABOR()
		  If TransferInProgress Then
		    Me.Write("ABOR" + CRLF)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub APPE(RemoteFileName As String, LocalFile As FolderItem, Mode As Integer = 1)
		  CreateDataStream(LocalFile)
		  TYPE = Mode
		  If Me.Passive Then
		    PASV()
		  Else
		    PORT(Me.Port + 1)
		  End If
		  DoVerb("APPE", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CDUP()
		  DoVerb("CDUP")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Close()
		  mWorkingDirectory = ""
		  LastVerb.Verb = ""
		  LastVerb.Arguments = ""
		  Super.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Connect()
		  Super.Connect()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CWD(NewDirectory As String)
		  'Change the WorkingDirectory
		  DoVerb("CWD", NewDirectory)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DELE(RemoteFileName As String)
		  'Delete the file named RemoteFileName on the FTP server
		  DoVerb("DELE", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub DoVerb(Verb As String, Params As String = "")
		  Dim nextverb As FTPVerb
		  nextverb.Verb = Uppercase(Verb)
		  nextverb.Arguments = Trim(Params)
		  PendingVerbs.Append(nextverb)
		  If VerbDispatchTimer <> Nil Then VerbDispatchTimer.Mode = Timer.ModeMultiple
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub FEAT()
		  DoVerb("FEAT")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub List(TargetDirectory As String = "")
		  'Retrieves a directory listing
		  TargetDirectory = PathEncode(TargetDirectory)
		  CreateDataSocket()
		  If Me.Passive Then
		    PASV()
		  Else
		    PORT(Me.Port + 1)
		  End If
		  ListBuffer = New MemoryBlock(64 * 1024)
		  CreateDataStream(ListBuffer)
		  DoVerb("LIST", TargetDirectory)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MDTM(RemoteFileName As String)
		  DoVerb("MDTM", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MKD(NewDirectoryName As String)
		  DoVerb("MKD", NewDirectoryName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub NLST(TargetDirectory As String = "")
		  'Retrieves a directory listing
		  TargetDirectory = PathEncode(TargetDirectory)
		  If Me.Passive Then
		    PASV()
		  Else
		    PORT(Me.Port + 1)
		  End If
		  DoVerb("NLST", TargetDirectory)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub NOOP()
		  DoVerb("NOOP")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseResponse(Data As String)
		  Dim Code As Integer = Val(Left(Data, 3))
		  Dim msg As String = data.Replace(Format(Code, "000"), "")
		  
		  If msg.Trim <> "" Then
		    FTPLog(Str(Code) + " " + msg.Trim)
		  Else
		    FTPLog(Str(Code) + " " + FTPCodeToMessage(Code).Trim)
		  End If
		  
		  Select Case LastVerb.Verb
		  Case "USER"
		    Select Case Code
		    Case 230  'Logged in W/O pass
		      LoginOK = True
		      RaiseEvent Connected()
		    Case 331, 332  'Need PASS/ACCT
		      DoVerb("PASS", Me.Password)
		    End Select
		    
		  Case "PASS"
		    Select Case Code
		    Case 230 'Logged in with pass
		      LoginOK = True
		      FTPLog("Ready")
		      RaiseEvent Connected()
		    Case 530  'USER not set!
		      DoVerb("USER", Me.Username)
		    End Select
		  Case "RETR"
		    Select Case Code
		    Case 150 'About to start data transfer
		      Dim size As String = NthField(msg, "(", 2)
		      size = NthField(size, ")", 1)
		      DataLength = Val(size)
		    Case 425, 426 'Data connection not ready
		    Case 451, 551 'Disk read error
		    Case 226 'Done
		      TransferComplete()
		    End Select
		    
		  Case "STOR", "APPE"
		    Select Case Code
		    Case 150  'Ready
		      UploadDispatchTimer = New Timer
		      AddHandler UploadDispatchTimer.Action, AddressOf UploadDispatchHandler
		      UploadDispatchTimer.Period = 100
		      UploadDispatchTimer.Mode = Timer.ModeMultiple
		      TransferInProgress = True
		    Case 226  'Success
		      TransferComplete()
		      DataSocket.Close
		    Case 425  'No data connection!
		      Dim lv, la As String
		      lv = LastVerb.Verb
		      la = LastVerb.Arguments
		      If Passive Then
		        PASV()
		      Else
		        PORT(Me.Port + 1)
		      End If
		      DoVerb(lv, la)
		    Case 426  'Data connection lost
		    End Select
		  Case "STAT"
		    If Code = 200 Then
		      Dim Stats() As String = Split(msg, EndOfLine.Windows)
		      Stats.Remove(Stats.Ubound)
		      Stats.Remove(0)
		      For Each Stat As String In Stats
		        Stat = Stat.Trim
		        FTPLog("   " + Stat)
		      Next
		    End If
		    
		  Case "FEAT"
		    ServerFeatures = Split(msg, EndOfLine.Windows)
		    ServerFeatures.Remove(ServerFeatures.Ubound)
		    ServerFeatures.Remove(0)
		    For Each Feature As String In ServerFeatures
		      Feature = Feature.Trim
		      FTPLog("   " + Feature)
		    Next
		  Case "SYST"
		    ServerType = msg
		  Case "CWD"
		    Select Case Code
		    Case 250, 200 'OK
		      mWorkingDirectory = LastVerb.Arguments.Trim
		    End Select
		    
		  Case "PWD"
		    If Code = 257 Then 'OK
		      mWorkingDirectory = LastVerb.Arguments
		    End If
		  Case "LIST", "NLST"
		    Select Case Code
		    Case 226 'Here comes the directory list
		      ListResponse(ListBuffer)
		      ListBuffer = Nil
		    Case 425, 426  'no connection or connection lost
		    Case 451  'Disk error
		    End Select
		    
		  Case "CDUP"
		    If Code = 200 Or Code = 250 Then
		      DoVerb("PWD")
		    End If
		    
		  Case "PASV"
		    If Code = 227 Then 'Entering Passive Mode <h1,h2,h3,h4,p1,p2>.
		      CreateDataSocket(PASV_to_IPv4(msg))
		      DataSocket.Connect
		    End If
		    
		  Case "REST"
		    If Code = 350 Then
		      DataStream.Position = Val(LastVerb.Arguments)
		    End If
		    
		  Case "PORT"
		    If Code = 200 Then
		      'Active mode OK. Connect to the following port
		      CreateDataSocket(PASV_to_IPv4(msg))
		    End If
		    
		  Case "SIZE"
		  Case "TYPE"
		    If Code = 200 Then
		      Select Case LastVerb.Arguments
		      Case "A"
		        Me.TransferMode = ASCIIMode
		      Case "L8"
		        Me.TransferMode = LocalMode
		      Case "I"
		        Me.TransferMode = BinaryMode
		      Case "P"
		        Me.TransferMode = PortalMode
		      Case "E"
		        Me.TransferMode = EBCDICMode
		      End Select
		    End If
		    
		  Case "MKD"
		  Case "RMD"
		  Case "DELE"
		  Case "RNFR"
		    If Code = 350 Then
		      DoVerb("RNTO", RNT)
		    End If
		    
		  Case "RNTO"
		    If Code = 250 Then
		      FTPLog(RNF + " renamed to " + RNT + " successfully.")
		    End If
		    RNT = ""
		    RNF = ""
		    
		  Case "QUIT"
		    Me.Close
		    
		  Else
		    If Code = 220 Then  'Server now ready
		      'The server is now ready to begin the login handshake
		      If Me.Anonymous Then
		        Me.Username = "anonymous"
		        Me.Password = "bsftp@boredomsoft.org"
		      End If
		      DoVerb("USER", Me.Username)
		      
		    ElseIf Code = 421 Then  'Timeout
		      Me.Close
		      
		    End If
		  End Select
		  VerbDispatchTimer.Mode = Timer.ModeMultiple
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PASV()
		  'You must call either PASV or PORT before transferring anything over the DataSocket
		  DoVerb("PASV")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PORT(PortNumber As Integer)
		  'You must call either PASV or PORT before transferring anything over the DataSocket
		  'Data port.
		  Dim portparams As String = IPv4_to_PASV(Me.NetworkInterface.IPAddress, PortNumber)
		  CreateDataSocket(portparams)
		  DataSocket.Listen()
		  DoVerb("PORT", portparams)
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
		Sub Rename(OriginalName As String, NewName As String)
		  RNF = OriginalName
		  RNT = NewName
		  DoVerb("RNFR", RNF)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub REST(StartPosition As Int64 = 0)
		  DoVerb("REST", Str(StartPosition))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RETR(RemoteFileName As String, SaveTo As FolderItem, Mode As Integer = 1)
		  DataFile = SaveTo
		  TYPE = Mode
		  If Me.Passive Then
		    PASV()
		  Else
		    PORT(Me.Port + 1)
		  End If
		  DoVerb("RETR", PathEncode(RemoteFileName, WorkingDirectory))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RMD(RemovedDirectoryName As String)
		  DoVerb("RMD", RemovedDirectoryName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SIZE(RemoteFileName As String)
		  DoVerb("SIZE", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub STAT(RemoteFileName As String = "")
		  DoVerb("STAT", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub STOR(RemoteFileName As String, LocalFile As FolderItem, Mode As Integer = 1)
		  CreateDataStream(LocalFile)
		  TYPE = Mode
		  If Me.Passive Then
		    PASV()
		  Else
		    PORT(Me.Port + 1)
		  End If
		  DoVerb("STOR", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SYST()
		  DoVerb("SYST")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub TYPE(Assigns TransferType As Integer)
		  Select Case TransferType
		  Case ASCIIMode
		    DoVerb("TYPE", "A")
		  Case LocalMode
		    DoVerb("TYPE", "L8")
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
		Private Sub UploadDispatchHandler(Sender As Timer)
		  //Handles the FTPClientSocket.UploadDispatchTimer.Action event
		  If DataStream <> Nil Then
		    If Not DataStream.EOF Then
		      WriteData(DataStream.Read(32 * 1024))
		      App.YieldToNextThread()
		      If DataStream <> Nil Then
		        If RaiseEvent TransferProgress(DataStream.Position, DataStream.Length - DataStream.Position) Then
		          DoVerb("ABOR")
		        Else
		          DataSocket.Flush
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
		Private Sub VerbDispatchHandler(Sender As Timer)
		  //Handles the FTPClientSocket.VerbDispatchTimer.Action event
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
		Event ListResponse(ListData As MemoryBlock)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferComplete()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferProgress(BytesSent As Int64, BytesLeft As Int64) As Boolean
	#tag EndHook


	#tag Note, Name = FTPClientSocket Notes
		This class subclasses FTPSocket and provides a client socket.
		
		When an FTP control connnection is established, the client waits for the server to
		initiate the FTP handshake. Once the handshake is completed, the Connected event is
		raised and commands may be sent to the server.
		
		Commands
	#tag EndNote


	#tag Property, Flags = &h1
		Protected LastVerb As FTPVerb
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected ListBuffer As MemoryBlock
	#tag EndProperty

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
		Private UploadDispatchTimer As Timer
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
