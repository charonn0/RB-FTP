#tag Class
Protected Class FTPClientSocket
Inherits FTPSocket
	#tag Event
		Sub Connected(IsControlSocket As Boolean)
		  If IsControlSocket Then
		    FTPLog("Connected to " + ControlSocket.RemoteAddress + ":" + Str(ControlSocket.Port))
		    CommandDelayTimer.Mode = Timer.ModeMultiple
		  End If
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable(IsControlSocket As Boolean)
		  If IsControlSocket Then
		    Dim s As String = Me.ReadCommand
		    ParseResponse(s)
		  Else
		    Dim s As String = Me.ReadData
		    OutputFile.Write(s)
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub Error(IsControlSocket As Boolean)
		  If IsControlSocket Then
		    RaiseEvent Error(ControlSocket.LastErrorCode)
		  Else
		    RaiseEvent Error(DataSocket.LastErrorCode)
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub SendComplete(UserAborted As Boolean, IsControlSocket As Boolean)
		  If Not IsControlSocket Then
		    OutputFile.Close
		    RaiseEvent SendComplete(UserAborted)
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Function SendProgress(BytesSent As Integer, BytesLeft As Integer, IsControlSocket As Boolean) As Boolean
		  If Not IsControlSocket Then
		    RaiseEvent SendProgress(BytesSent, BytesLeft)
		    
		  End If
		End Function
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub CommandDelayHandler(Sender As Timer)
		  #pragma Unused Sender
		  If LoginOK And UBound(PendingCommands) > -1 Then
		    Dim s As String = PendingCommands(0)
		    PendingCommands.Remove(0)
		    WriteCommand(s + CRLF)
		  End If
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Connect()
		  Super.Connect()
		  ControlSocket.Address = Me.ServerAddress
		  ControlSocket.Connect
		  DataSocket.Listen
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Get(RemoteFileName As String, SaveTo As FolderItem, OverWrite As Boolean = True)
		  'If ServerHasFeature("PASV") And Me.Passive Then
		  PendingCommands.Append("PASV")
		  'End If
		  If TransferMode = BinaryMode Then
		    WriteCommand("TYPE I" + CRLF)
		  End If
		  
		  OutputFile = BinaryStream.Create(SaveTo, OverWrite)
		  PendingCommands.Append("RETR " + RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandShake()
		  If Me.Anonymous Then
		    FTPLog("Logging in as anonymous")
		    Me.User = "anonymous"
		  End If
		  WriteCommand("USER " + Me.User + CRLF)
		  
		  PendingCommands.Append("SYST")
		  PendingCommands.Append("FEAT")
		  PendingCommands.Append("PWD")
		  
		  RaiseEvent Connected
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub List()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseResponse(Response As String)
		  If InStr(Response, "211-Features:") > 0 Then
		    ServerFeatures = Split(DefineEncoding(Response, Encodings.ASCII), CRLF)
		    ServerFeatures.Remove(0)
		    For Each feature As String In ServerFeatures
		      feature = feature.Trim
		    Next
		    
		    'If ServerHasFeature("UTF8") Then
		    PendingCommands.Append("OPTS UTF8 ON")
		    'End If
		    
		    
		  Else
		    Dim cmdNumber As Integer
		    Dim cmdMsg As String
		    cmdNumber = Val(NthField(Response, " ", 1).Trim)
		    cmdMsg = Mid(Response, Len(NthField(Response, " ", 1).Trim + " "), Response.Len)
		    
		    FTPLog(Str(cmdNumber) + ": " + cmdMsg)
		    Select Case cmdNumber
		    Case 220 //Hello
		      HandShake()
		    Case 331  //Password
		      WriteCommand("PASS " + Me.Password + CRLF)
		    Case 230 //Login successful
		      LoginOK = True
		    Case 215  //SYST response
		      ServerType = cmdMsg
		    Case 200
		      UTFMode = True
		    Case 257 //PWD reply
		      RemoteDirectory = cmdMsg
		    Case 227  //PASV reply
		      Dim p1, p2 As Integer
		      Dim h1, h2, h3, h4 As String
		      h1 = NthField(NthField(cmdMsg, ",", 1), "(", 2)
		      h2 = NthField(cmdMsg, ",", 2)
		      h3 = NthField(cmdMsg, ",", 3)
		      h4 = NthField(cmdMsg, ",", 4)
		      p1 = Val(NthField(cmdMsg, ",", 5))
		      p2 = Val(NthField(cmdMsg, ",", 6))
		      DataSocket.Port = p1 * 256 + p2
		      DataSocket.Address = h1 + "." + h2 + "." + h3 + "." + h4
		      DataSocket.Connect
		    Case 500
		      RaiseEvent Error(500)
		      
		    End Select
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ServerHasFeature(FeatureName As String) As Boolean
		  Return ServerFeatures.IndexOf(FeatureName) <> -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteCommand(Command As String)
		  FTPLog(Command)
		  Super.WriteCommand(Command)
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
		Event SendComplete(UserAborted As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SendProgress(BytesSent As Integer, BytesLeft As Integer)
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
		Private LoginOK As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCommandDelayTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private OutputFile As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h0
		Passive As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h0
		Password As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private PendingCommands() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		RemoteDirectory As String = "/"
	#tag EndProperty

	#tag Property, Flags = &h0
		ServerAddress As String
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
			Name="ServerAddress"
			Visible=true
			Group="Behavior"
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
