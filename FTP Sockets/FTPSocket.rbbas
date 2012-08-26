#tag Class
Protected Class FTPSocket
Inherits TCPSocket
	#tag Event
		Sub Connected()
		  RaiseEvent Connected(True)
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable()
		  RaiseEvent DataAvailable(True)
		End Sub
	#tag EndEvent

	#tag Event
		Sub Error()
		  RaiseEvent Error(True)
		End Sub
	#tag EndEvent

	#tag Event
		Sub SendComplete(userAborted as Boolean)
		  RaiseEvent SendComplete(UserAborted, True)
		End Sub
	#tag EndEvent

	#tag Event
		Function SendProgress(bytesSent as Integer, bytesLeft as Integer) As Boolean
		  Return RaiseEvent SendProgress(BytesSent, BytesLeft, True)
		End Function
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Connect()
		  DataSocket = New TCPSocket
		  DataSocket.Port = Me.Port + 1
		  
		  AddHandler DataSocket.Connected, AddressOf ConnectedHandler
		  AddHandler DataSocket.DataAvailable, AddressOf DataAvailableHandler
		  AddHandler DataSocket.Error, AddressOf ErrorHandler
		  AddHandler DataSocket.SendComplete, AddressOf SendCompleteHandler
		  AddHandler DataSocket.SendProgress, AddressOf SendProgressHandler
		  
		  Super.Connect
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConnectedHandler(Sender As TCPSocket)
		  RaiseEvent Connected(False)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function CRLF() As String
		  Return Encodings.ASCII.Chr(13) + Encodings.ASCII.Chr(10)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DataAvailableHandler(Sender As TCPSocket)
		  RaiseEvent DataAvailable(False)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ErrorHandler(Sender As TCPSocket)
		  RaiseEvent Error(False)
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
		    Return """PATHNAME"" created."
		    
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

	#tag Method, Flags = &h0
		Function Read() As String
		  Dim la As String
		  
		  While Me.Lookahead.LenB > 0
		    la = la + Me.ReadAll
		    App.YieldToNextThread
		  Wend
		  
		  Return la
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadData() As String
		  Return DataSocket.ReadAll
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SendCompleteHandler(Sender As TCPSocket, UserAborted As Boolean)
		  RaiseEvent SendComplete(UserAborted, False)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SendProgressHandler(Sender As TCPSocket, BytesSent As Integer, BytesLeft As Integer) As Boolean
		  Return RaiseEvent SendProgress(BytesSent, BytesLeft, False)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Write(Command As String)
		  Super.Write(Command)
		  Me.Flush
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WriteData(Data As String)
		  DataSocket.Write(Data)
		  DataSocket.Flush
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Connected(IsControlSocket As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DataAvailable(IsControlSocket As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Error(IsControlSocket As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event FTPLog(LogLine As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SendComplete(UserAborted As Boolean, IsControlSocket As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SendProgress(BytesSent As Integer, BytesLeft As Integer, IsControlSocket As Boolean) As Boolean
	#tag EndHook


	#tag Property, Flags = &h1
		Protected DataSocket As TCPSocket
	#tag EndProperty


	#tag Constant, Name = ASCIIMode, Type = Double, Dynamic = False, Default = \"2", Scope = Public
	#tag EndConstant

	#tag Constant, Name = BinaryMode, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Address"
			Visible=true
			Group="Behavior"
			Type="String"
			InheritedFrom="TCPSocket"
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
	#tag EndViewBehavior
End Class
#tag EndClass
