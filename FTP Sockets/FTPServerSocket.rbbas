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


	#tag Method, Flags = &h1
		Protected Sub DoResponse(Code As Integer, Params As String = "")
		  If Params.Trim = "" Then Params = FTPCodeToMessage(Code)
		  params = Trim(Str(Code) + " " + Params)
		  Me.Write(params + CRLF)
		  FTPLog(params)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FileListing(Directory As FolderItem) As String
		  If Directory = Nil Then
		    DoResponse(451, "That directory does not exist.")
		    Return ""
		  End If
		  Dim thelist As String = "." + CRLF + ".." + CRLF
		  For i As Integer = 0 To Directory.Count - 1
		    Dim fsize, fname, fperms, fowner, fgroup, fmoddate As String
		    fperms = "FOROWOXGRGWGXWRWWWX"
		    fsize = Str(Directory.TrueItem(i).Length)
		    fname =  Directory.TrueItem(i).Name
		    
		    If Directory.TrueItem(i).IsReadable Then
		      fperms = Replace(fperms, "OR", "r")
		      fperms = Replace(fperms, "GR", "r")
		      fperms = Replace(fperms, "WR", "r")
		    Else
		      fperms = Replace(fperms, "OR", "-")
		      fperms = Replace(fperms, "GR", "-")
		      fperms = Replace(fperms, "WR", "-")
		    End If
		    
		    If Directory.TrueItem(i).IsWriteable Then
		      fperms = Replace(fperms, "OW", "w")
		      fperms = Replace(fperms, "GW", "w")
		      fperms = Replace(fperms, "WW", "w")
		    Else
		      fperms = Replace(fperms, "OW", "-")
		      fperms = Replace(fperms, "GW", "-")
		      fperms = Replace(fperms, "WW", "-")
		    End If
		    
		    If Directory.TrueItem(i).Directory Then
		      fperms = Replace(fperms, "F", "D")
		    Else
		      fperms = Replace(fperms, "F", "-")
		    End If
		    
		    If Directory.TrueItem(i).IsWriteable And Directory.TrueItem(i).IsReadable Then
		      fperms = Replace(fperms, "OX", "x")
		      fperms = Replace(fperms, "GX", "x")
		      fperms = Replace(fperms, "WX", "x")
		    Else
		      fperms = Replace(fperms, "OX", "-")
		      fperms = Replace(fperms, "GX", "-")
		      fperms = Replace(fperms, "WX", "-")
		    End If
		    
		    fmoddate = Directory.TrueItem(i).ModificationDate.ShortDate
		    
		    thelist = thelist + fperms + " 1 " + fowner + " " + fgroup + " " + fsize + " " + fmoddate + " " + fname + CRLF
		  Next
		  
		  Return thelist
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FindFile(Name As String) As FolderItem
		  Dim g As FolderItem
		  If mWorkingDirectory = Nil Then mWorkingDirectory = App.ExecutableFile.Parent
		  If Left(Name, 1) = "/" Then //relative to RootDirectory
		    g = RootDirectory
		    Name = Replace(Name, "/", "")
		  Else //relative to WorkingDirectory
		    g = mWorkingDirectory
		  End If
		  
		  Dim parts() As String = Split(Name, "/")
		  For i As Integer = 0 To UBound(parts)
		    If g.Child(parts(i)).Exists Then
		      g = g.Child(parts(i))
		    Else
		      Return Nil
		    End If
		  Next
		  
		  If ChildOfParent(g, RootDirectory) Then
		    Return g
		  Else
		    Return Nil
		  End If
		  
		Exception NilObjectException
		  Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub InactivityHandler(Sender As Timer)
		  //Handles the FTPServerSocket.InactivityTimer.Action event
		  Sender.Mode = Timer.ModeOff
		  DoResponse(421, "Inactivity timeout.")
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Listen()
		  Super.Listen
		  FTPLog("Now listening on port " + Str(Me.Port))
		  InactivityTimer = New Timer
		  InactivityTimer.Period = TimeOutPeriod
		  AddHandler InactivityTimer.Action, AddressOf InactivityHandler
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
		      DataFile = GetFolderItem(RootDirectory.AbsolutePath + WorkingDirectory + Verb.Arguments)
		      If DataFile <> Nil Then
		        If DataFile.Exists And Not DataFile.Directory Then
		          CreateDataStream(DataFile)
		          DoResponse(150)
		          While Not DataStream.EOF
		            WriteData(DataStream.Read(1024 * 64))
		            App.YieldToNextThread
		          Wend
		          DataSocket.Flush
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
		        DataFile = SpecialFolder.Temporary.Child(Verb.Arguments)
		        CreateDataStream(DataFile)
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
		      'We'll claim to be UNIX even if we aren't
		      DoResponse(215, "UNIX Type: L8")
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "CWD", "XCWD"
		    If LoginOK Then
		      Dim g As FolderItem = FindFile(Verb.Arguments)
		      If g <> Nil Then
		        If ChildOfParent(g, RootDirectory) Then
		          mWorkingDirectory = g
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
		      If DataSocket <> Nil Then
		        Dim s As String = FileListing(FindFile(Verb.Arguments))
		        If s.Trim <> "" Then
		          DoResponse(226)
		          WriteData(s)
		          DataSocket.Flush
		          DataSocket.Close
		        Else
		          DoResponse(451, "No list.")
		        End If
		      Else
		        DoResponse(425) //no connection
		      End If
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
		      If DataSocket = Nil Then
		        Me.PASVAddress = IPv4_to_PASV(Me.NetworkInterface.IPAddress, Me.Port + 1)
		        DataSocket.Listen
		        DoResponse(227, "Entering Passive Mode (" + Me.PASVAddress + ").")
		      ElseIf Not DataSocket.IsConnected Then
		        DataSocket.Listen
		        DoResponse(227, "Entering Passive Mode (" + Me.PASVAddress + ").")
		      Else
		        DoResponse(125)  //already open
		      End If
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "REST"
		    If LoginOK Then
		      DataStream.Position = Val(Verb.Arguments)
		      DoResponse(350)
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "PORT"
		    If LoginOK Then
		      Me.PASVAddress = Verb.Arguments
		      DoResponse(200, Verb.Arguments)
		      DataSocket.Connect
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "TYPE"
		    If LoginOK Then
		      Select Case Verb.Arguments.Trim
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

	#tag Property, Flags = &h21
		Private mRootDirectory As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mWorkingDirectory As FolderItem
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mRootDirectory
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  mRootDirectory = value
			  mWorkingDirectory = value
			End Set
		#tag EndSetter
		RootDirectory As FolderItem
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		#tag Note
			600000ms = 10 minutes
		#tag EndNote
		TimeOutPeriod As Integer = 600000
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mWorkingDirectory <> Nil And RootDirectory <> Nil Then
			    return Replace(mWorkingDirectory.AbsolutePath, RootDirectory.AbsolutePath, "/")
			  Else
			    Return "/"
			  End If
			End Get
		#tag EndGetter
		WorkingDirectory As String
	#tag EndComputedProperty


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
		#tag ViewProperty
			Name="WorkingDirectory"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
