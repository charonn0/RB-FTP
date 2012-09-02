#tag Class
Protected Class FTPServerSocket
Inherits FTPSocket
	#tag Event
		Sub Connected()
		  FTPLog("Remote host connected from " + Me.RemoteAddress + " on port " + Str(Me.Port))
		  InactivityTimer.Mode = Timer.ModeMultiple
		  DoResponse(221, Banner)
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable()
		  Dim s As String = Me.Read
		  ParseVerb(s)
		End Sub
	#tag EndEvent

	#tag Event
		Sub Disconnected()
		  FTPLog("Remote host closed the connection.")
		  Me.Close
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h1001
		Protected Sub Constructor()
		  Super.Constructor
		  InactivityTimer = New Timer
		  InactivityTimer.Period = TimeOutPeriod
		  AddHandler InactivityTimer.Action, AddressOf InactivityHandler
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub DoResponse(Code As Integer, Params As String = "")
		  If Params.Trim = "" Then Params = FTPCodeToMessage(Code)
		  params = Trim(Str(Code) + " " + Params)
		  Me.Write(params + CRLF)
		  FTPLog(params)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FindFile(Name As String) As FolderItem
		  If RootDirectory.Child(Name).Exists Then Return RootDirectory.Child(Name)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub InactivityHandler(Sender As Timer)
		  Sender.Mode = Timer.ModeOff
		  DoResponse(421, "Inactivity timeout.")
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseVerb(Data As String)
		  Dim Verb As FTPVerb
		  If InStr(Data, " ") > 0 Then
		    Verb.Verb = NthField(Data, " ", 1)
		    Verb.Arguments = Data.Replace(Verb.Verb + " ", "")
		  Else
		    Verb.Verb = Data
		  End If
		  
		  
		  'This event is raised by FTPSocket.DataAvailable
		  'Verb is a FTPSocket.FTPVerb stucture
		  
		  FTPLog(Verb.Verb + " " + Verb.Arguments)
		  InactivityTimer.Reset()
		  Select Case Verb.Verb.Trim
		  Case "USER"
		    Username = Verb.Arguments.Trim
		    If Me.Anonymous And Username = "anonymous" Then
		      DoResponse(331, "Anonymous login OK, send e-mail address as password.")
		    Else
		      DoResponse(331) 'Need PASS
		    End If
		    
		  Case "PASS"
		    Password = Verb.Arguments.Trim
		    If Username.Trim = "" Then
		      DoResponse(530)  'USER not set!
		    ElseIf Me.Anonymous And Username = "anonymous" Then
		      Call UserLogon(Username, Password)  'anon users passwords don't matter
		      DoResponse(230) 'Logged in with pass
		      LoginOK = True
		    Else
		      If UserLogon(Username, Password) Then
		        DoResponse(230) 'Logged in with pass
		        LoginOK = True
		      Else
		        DoResponse(530) 'Bad password!
		      End If
		    End If
		  Case "RETR"
		    If LoginOK Then
		      OutputFile = GetFolderItem(RootDirectory.AbsolutePath + WorkingDirectory + Verb.Arguments)
		      If OutputFile <> Nil Then
		        If OutputFile.Exists And Not OutputFile.Directory Then
		          OutputStream = BinaryStream.Open(OutputFile)
		          DoResponse(150)
		          While Not OutputStream.EOF
		            WriteData(OutputStream.Read(1024 * 64))
		            App.YieldToNextThread
		          Wend
		          DoResponse(226)
		          DataSocket.Close
		        Else
		          DoResponse(451) 'bad file
		        End If
		      Else
		        DoResponse(451) 'bad file
		      End If
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "STOR"
		    If LoginOK Then
		      If RootDirectory.Child(Verb.Arguments).Exists And Not AllowWrite Then
		        DoResponse(450, "Filename taken.")
		      Else
		        OutputFile = SpecialFolder.Temporary.Child(Verb.Arguments)
		        OutputStream = OutputStream.Create(OutputFile, True)
		      End If
		      DoResponse(150) 'Ready
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "FEAT"
		    If LoginOK Then
		      Me.Write("211-Features:" + CRLF + " PASV" + CRLF)
		      DoResponse(211, "End")
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "SYST"
		    If LoginOK Then
		      DoResponse(215, "BS FTPd " + Format(FTPVersion, "#0.0#"))
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "CWD"
		    If LoginOK Then
		      Dim g As FolderItem = FindFile(Verb.Arguments)
		      If g <> Nil Then
		        If ChildOfParent(g, RootDirectory) Then
		          WorkingDirectory = Replace(g.AbsolutePath, RootDirectory.AbsolutePath, "")
		          DoResponse(250)  'OK
		        Else
		          DoResponse(550)  'bad file
		        End If
		      Else
		        DoResponse(550)  'bad file
		      End If
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "PWD"
		    If LoginOK Then
		      DoResponse(257, """" + WorkingDirectory + """")
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "LIST"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		      ' 226 'Here comes the directory list
		      ' 425, 426  'no connection or connection lost
		      ' 451  'Disk error
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "CDUP"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		      ' 200  'OK
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "PASV"
		    If LoginOK Then
		      CreateDataSocket()
		      DataSocket.Listen
		      Dim p1, p2 As Integer
		      Dim h1, h2, h3, h4 As String
		      h1 = NthField(NthField(DataSocket.Address, ".", 1), "(", 2)
		      h2 = NthField(DataSocket.Address, ".", 2)
		      h3 = NthField(DataSocket.Address, ".", 3)
		      h4 = NthField(DataSocket.Address, ".", 4)
		      p1 = DataSocket.port Mod 256
		      p2 = DataSocket.port - p1
		      DoResponse(227, "Entering Passive Mode (" + h1 + "," + h2 + "," + h3 + "," + h4 + "," + Str(p1) + "," + Str(p2))
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "REST"
		    If LoginOK Then
		      OutputStream.Position = Val(Verb.Arguments)
		      DoResponse(350)
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "PORT"
		    If LoginOK Then
		      If DataSocket.IsConnected Then
		        DoResponse(125)
		      Else
		        Dim p1, p2 As Integer
		        Dim h1, h2, h3, h4 As String
		        h1 = NthField(NthField(Verb.Arguments, ",", 1), "(", 2)
		        h2 = NthField(Verb.Arguments, ",", 2)
		        h3 = NthField(Verb.Arguments, ",", 3)
		        h4 = NthField(Verb.Arguments, ",", 4)
		        p1 = Val(NthField(Verb.Arguments, ",", 5))
		        p2 = Val(NthField(Verb.Arguments, ",", 6))
		        CreateDataSocket()
		        DataSocket.Port = p1 * 256 + p2
		        DataSocket.Address = h1 + "." + h2 + "." + h3 + "." + h4
		        DoResponse(200, "Entering Active Mode (" + h1 + "," + h2 + "," + h3 + "," + h4 + "," + Str(p1) + "," + Str(p2))
		        DataSocket.Connect
		      End If
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "TYPE"
		    If LoginOK Then
		      Select Case Verb.Arguments
		      Case "A", "A N"
		        Me.TransferMode = ASCIIMode
		        DoResponse(200)
		      Case "I", "L"
		        Me.TransferMode = BinaryMode
		        DoResponse(200)
		      Else
		        DoResponse(504) 'Command not implemented for param
		      End Select
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "MKD"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		      ' 257
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "RMD"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		      
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "DELE"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "RNFR"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "RNTO"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "QUIT"
		    DoResponse(221, "Bye.")
		    Me.Close
		  Else
		    DoResponse(500)  'syntax error or unknown verb
		  End Select
		  
		  
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event UserLogon(UserName As String, Password As String) As Boolean
	#tag EndHook


	#tag Property, Flags = &h0
		AllowWrite As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		Banner As String = "Welcome to BSFTPd!"
	#tag EndProperty

	#tag Property, Flags = &h21
		Private InactivityTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h0
		RootDirectory As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h0
		#tag Note
			600000ms = 10 minutes
		#tag EndNote
		TimeOutPeriod As Integer = 600000
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected WorkingDirectory As String = "/"
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Address"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="TCPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowWrite"
			Visible=true
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
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
			Name="Banner"
			Visible=true
			Group="Behavior"
			InitialValue="Welcome to BSFTPd!"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataAddress"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
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
			InheritedFrom="TCPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TimeOutPeriod"
			Visible=true
			Group="Behavior"
			InitialValue="600000"
			Type="Integer"
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
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="FTPSocket"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
