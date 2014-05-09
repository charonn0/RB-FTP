#tag Class
Protected Class Client
Inherits FTP.Connection
	#tag Event
		Sub Control_Connected()
		  VerbDispatchTimer = New Timer
		  VerbDispatchTimer.Period = 100
		  AddHandler VerbDispatchTimer.Action, WeakAddressOf VerbDispatchHandler
		End Sub
	#tag EndEvent

	#tag Event
		Sub Control_DataAvailable()
		  Dim i As Integer = InStrB(Me.Lookahead, CRLF)
		  Do Until i <= 0
		    Dim data As String = Me.Read(i + 1)
		    ParseResponse(data)
		    i = InStrB(Me.Lookahead, CRLF)
		  Loop
		  
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Close()
		  VerbDispatchTimer = Nil
		  LastVerb = Nil
		  Super.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Connect(ClearPending As Boolean = True)
		  VerbDispatchTimer = Nil
		  If ClearPending Then ReDim PendingVerbs(-1)
		  Super.Connect()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub DoVerb(Verb As String, Params As String = "", HighPriority As Boolean = False)
		  'Use this method to queue up verbs to be executed
		  Dim nextverb As FTPVerb
		  nextverb.Verb = Uppercase(Verb)
		  nextverb.Arguments = Trim(Params)
		  If Not HighPriority Then
		    PendingVerbs.Insert(0, nextverb)
		  Else
		    'Some verbs can't wait in line
		    PendingVerbs.Append(nextverb)
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseResponse(Data As String)
		  Dim Code As Integer = Val(Left(Data, 3))
		  Dim msg As String = data.Replace(Format(Code, "000"), "")
		  
		  If Not RaiseEvent Response(Code, msg, LastVerb.Left, LastVerb.Right) Then
		    
		    Select Case LastVerb.Verb
		    Case "USER"
		      Select Case Code
		      Case 230  'Logged in W/O pass
		        LoginOK = True
		        RaiseEvent Connected()
		      Case 331, 332  'Need PASS/ACCT
		        DoVerb("PASS", Me.Password, True)
		      End Select
		      
		    Case "PASS"
		      Select Case Code
		      Case 230 'Logged in with pass
		        LoginOK = True
		        RaiseEvent Connected()
		      Case 530  'USER not set!
		        DoVerb("USER", Me.Username, True) 'Warning: some FTP servers (Microsoft IIS) send this code for ALL errors, resulting in an infinite loop.
		      End Select
		    Case "RETR"
		      Select Case Code
		      Case 150 'About to start data transfer
		        Dim size As String = NthField(msg, "(", 2)
		        size = NthField(size, ")", 1)
		      Case 425, 426 'Data connection not ready
		        Dim lv, la As String
		        lv = LastVerb.Verb
		        la = LastVerb.Arguments
		        If Passive Then
		          PASV()
		        Else
		          PORT(Me.Port + 1)
		        End If
		        DoVerb(lv, la)
		      Case 451, 551 'Disk read error
		        DataBuffer.Close
		        Call GetData()
		        TransferComplete()
		      Case 226 'Done
		        Dim s As String = Me.GetData
		        DataBuffer.Write(s)
		        DataBuffer.Close
		        TransferComplete()
		      End Select
		      
		    Case "STOR", "APPE"
		      Select Case Code
		      Case 150  'Ready
		        Me.TransmitData(DataBuffer.Read(DataBuffer.Length - DataBuffer.Position))
		        TransferInProgress = True
		      Case 226  'Success
		        TransferComplete()
		        Me.CloseData
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
		        DataBuffer.Close
		        Call GetData()
		        TransferComplete()
		      End Select
		    Case "STAT"
		      If Code = 211 Or Code = 212 Or Code = 213 Then
		        Dim Stats() As String = Split(msg, EndOfLine.Windows)
		        Stats.Remove(Stats.Ubound)
		        Stats.Remove(0)
		        For Each Stat As String In Stats
		          Stat = Stat.Trim
		          FTPLog("   " + Stat)
		        Next
		      End If
		      
		    Case "FEAT"
		      Select Case Left(msg, 1)
		      Case "-"
		        Return
		      Case " "
		        ServerFeatures.Append(msg.Trim)
		      Else
		        Return
		      End Select
		      
		    Case "SYST"
		      ServerType = msg
		    Case "CWD"
		      Select Case Code
		      Case 250, 200 'OK
		        mWorkingDirectory = LastVerb.Arguments.Trim
		      End Select
		      
		    Case "PWD"
		      If Code = 257 Then 'OK
		        mWorkingDirectory = NthField(msg, " ", 2)
		        mWorkingDirectory = ReplaceAll(msg, """", "")
		      End If
		    Case "LIST", "NLST"
		      Select Case Code
		      Case 226, 150 'Here comes the directory list
		        Dim s() As String = Split(Me.GetData(), CRLF)
		        For i As Integer = UBound(s) DownTo 0
		          If s(i).Trim = "" Or s(i).Trim = "." Or s(i).Trim = ".." Then s.Remove(i)
		          
		        Next
		        ListResponse(s)
		      Case 425, 426  'no connection or connection lost
		      Case 451  'Disk error
		      End Select
		      DataBuffer = Nil
		    Case "CDUP"
		      If Code = 200 Or Code = 250 Then
		        DoVerb("PWD")
		      End If
		      
		    Case "PASV"
		      If Code = 227 Then 'Entering Passive Mode <h1,h2,h3,h4,p1,p2>.
		        Me.ConnectData(msg)
		      End If
		      
		    Case "REST"
		      If Code = 350 Then
		        DataBuffer.Position = Val(LastVerb.Arguments)
		      End If
		      
		    Case "PORT"
		      If Code = 200 Then
		        'Active mode OK. Connect to the following port
		        'Me.PASVAddress = msg
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
		      Else
		        RNT = ""
		        RNF = ""
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
		        DoVerb("USER", Me.Username, True)
		      ElseIf Code = 421 Then  'Timeout
		        Me.Close
		      End If
		    End Select
		  End If
		  If VerbDispatchTimer <> Nil Then VerbDispatchTimer.Mode = Timer.ModeMultiple
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub VerbDispatchHandler(Sender As Timer)
		  //Handles the FTPClientSocket.VerbDispatchTimer.Action event
		  If Not TransferInProgress And UBound(PendingVerbs) > -1 Then
		    Dim nextverb As FTPVerb = PendingVerbs.Pop
		    If nextverb.Verb = "STOR" Or nextverb.Verb = "APPE" Then
		      DataBuffer = BinaryStream.Open(PendingTransfers.Value(nextverb.Arguments))
		      PendingTransfers.Remove(nextverb.Arguments)
		    ElseIf nextverb.Verb = "RETR" Then
		      DataBuffer = BinaryStream.Create(PendingTransfers.Value(nextverb.Arguments), True)
		      PendingTransfers.Remove(nextverb.Arguments)
		    End If
		    FTPLog(nextverb.Verb + " " + nextverb.Arguments)
		    Me.Write(nextverb.Verb + " " + nextverb.Arguments + CRLF)
		    LastVerb = nextverb
		    Sender.Mode = Timer.ModeOff
		  End If
		  
		Exception Err As KeyNotFoundException
		  FTPLog("Local file could not be found!")
		  If DataBuffer <> Nil Then DataBuffer.Close
		  
		  
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Connected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Response(Code As Integer, Message As String, Verb As String, Params As String) As Boolean
	#tag EndHook


	#tag Property, Flags = &h1
		Protected LastVerb As Pair
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected LoginOK As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		Password As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected PendingVerbs() As Pair
	#tag EndProperty

	#tag Property, Flags = &h0
		Username As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private VerbDispatchTimer As Timer
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
			Visible=true
			Group="Behavior"
			InitialValue="/"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
