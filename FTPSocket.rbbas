#tag Class
Protected Class FTPSocket
	#tag Method, Flags = &h0
		Sub Connect()
		  ControlSocket = New TCPSocket
		  ControlSocket.Port = Me.Port
		  DataSocket = New TCPSocket
		  DataSocket.Port = Me.Port + 1
		  AddHandler ControlSocket.Connected, AddressOf ConnectedHandler
		  AddHandler ControlSocket.DataAvailable, AddressOf DataAvailableHandler
		  AddHandler ControlSocket.Error, AddressOf ErrorHandler
		  AddHandler ControlSocket.SendComplete, AddressOf SendCompleteHandler
		  AddHandler ControlSocket.SendProgress, AddressOf SendProgressHandler
		  
		  AddHandler DataSocket.Connected, AddressOf ConnectedHandler
		  AddHandler DataSocket.DataAvailable, AddressOf DataAvailableHandler
		  AddHandler DataSocket.Error, AddressOf ErrorHandler
		  AddHandler DataSocket.SendComplete, AddressOf SendCompleteHandler
		  AddHandler DataSocket.SendProgress, AddressOf SendProgressHandler
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ConnectedHandler(Sender As TCPSocket)
		  RaiseEvent Connected(Sender Is ControlSocket)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function CRLF() As String
		  Return Encodings.ASCII.Chr(13) + Encodings.ASCII.Chr(10)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DataAvailableHandler(Sender As TCPSocket)
		  RaiseEvent DataAvailable(Sender Is ControlSocket)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ErrorHandler(Sender As TCPSocket)
		  RaiseEvent Error(Sender Is ControlSocket)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadCommand() As String
		  Dim la As String
		  
		  While ControlSocket.Lookahead.LenB > 0
		    la = la + ControlSocket.ReadAll
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
		  RaiseEvent SendComplete(UserAborted, Sender Is ControlSocket)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SendProgressHandler(Sender As TCPSocket, BytesSent As Integer, BytesLeft As Integer) As Boolean
		  Return RaiseEvent SendProgress(BytesSent, BytesLeft, Sender Is ControlSocket)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WriteCommand(Command As String)
		  ControlSocket.Write(Command)
		  ControlSocket.Flush
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
		Event SendComplete(UserAborted As Boolean, IsControlSocket As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SendProgress(BytesSent As Integer, BytesLeft As Integer, IsControlSocket As Boolean) As Boolean
	#tag EndHook


	#tag Property, Flags = &h1
		Protected ControlSocket As TCPSocket
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected DataSocket As TCPSocket
	#tag EndProperty

	#tag Property, Flags = &h0
		Port As Integer = 21
	#tag EndProperty


	#tag Constant, Name = ASCIIMode, Type = Double, Dynamic = False, Default = \"2", Scope = Public
	#tag EndConstant

	#tag Constant, Name = BinaryMode, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant


	#tag ViewBehavior
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
