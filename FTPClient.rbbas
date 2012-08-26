#tag Class
Protected Class FTPClient
Inherits FTPClientSocket
	#tag Event
		Sub Connected()
		  RaiseEvent Connected
		End Sub
	#tag EndEvent

	#tag Event
		Sub Error(Code As Integer)
		  RaiseEvent Error(Code)
		End Sub
	#tag EndEvent

	#tag Event
		Sub FTPLog(LogLine As String)
		  RaiseEvent FTPLog(LogLine)
		End Sub
	#tag EndEvent

	#tag Event
		Sub ReceiveReply(ReplyNumber As Integer, ReplyMessage As String)
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
		    HandShake()
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
		    
		  Case 250
		    'Requested file action okay, completed.
		    
		  Case 257
		    '"PATHNAME" created.
		    
		  Case 331
		    'User name okay, need password.
		    
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
		  
		  FTPLog(Str(ReplyNumber) + " " + ReplyMessage)
		End Sub
	#tag EndEvent

	#tag Event
		Sub SendComplete(UserAborted As Boolean)
		  RaiseEvent SendComplete(UserAborted)
		End Sub
	#tag EndEvent

	#tag Event
		Function SendProgress(BytesSent As Integer, BytesLeft As Integer) As Boolean
		  Return RaiseEvent SendProgress(BytesSent, BytesLeft)
		End Function
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Get(RemoteFileName As String, SaveTo As FolderItem, OverWrite As Boolean = True)
		  If ServerHasFeature("PASV") And Me.Passive Then
		    DoVerb("PASV")
		  End If
		  If TransferMode = BinaryMode Then
		    DoVerb("TYPE", "I")
		  End If
		  OutputFile = SaveTo
		  OutputStream = BinaryStream.Create(OutputFile, OverWrite)
		  DoVerb("RETR", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandShake()
		  If Me.Anonymous Then
		    FTPLog("Logging in as anonymous")
		    Me.User = "anonymous"
		  End If
		  Write("USER " + Me.User)
		  DoVerb("SYST")
		  DoVerb("FEAT")
		  DoVerb("OPTS", "UTF8 ON")
		  DoVerb("PWD")
		  
		  RaiseEvent Connected
		  
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
		  OutputStream = BinaryStream.Open(OutputFile, False)
		  
		  DoVerb("STOR", LocalFile.AbsolutePath)
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Connected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Error(Code As Integer)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event FileReceived(DownloadedFile As FolderItem)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event FTPLog(LogLine As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SendComplete(UserAborted As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SendProgress(BytesSent As Integer, BytesLeft As Integer) As Boolean
	#tag EndHook


	#tag ViewBehavior
		#tag ViewProperty
			Name="Anonymous"
			Visible=true
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			InheritedFrom="FTPClientSocket"
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
			InheritedFrom="FTPClientSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Password"
			Visible=true
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="FTPClientSocket"
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
			InheritedFrom="FTPClientSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ServerAddress"
			Visible=true
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="FTPClientSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ServerType"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="FTPClientSocket"
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
			InheritedFrom="FTPClientSocket"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
