#tag Class
Protected Class Connection
Inherits TCPSocket
	#tag Event
		Sub Connected()
		  RaiseEvent Control_Connected()
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable()
		  RaiseEvent Control_DataAvailable()
		End Sub
	#tag EndEvent

	#tag Event
		Sub Error()
		  RaiseEvent Control_Error()
		End Sub
	#tag EndEvent

	#tag Event
		Sub SendComplete(userAborted as Boolean)
		  RaiseEvent Control_SendComplete(userAborted)
		End Sub
	#tag EndEvent

	#tag Event
		Function SendProgress(bytesSent as Integer, bytesLeft as Integer) As Boolean
		  Return RaiseEvent Control_SendProgress(bytesSent, bytesLeft)
		End Function
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Connect()
		  If Me.NetworkInterface = Nil Then Me.NetworkInterface = System.GetNetworkInterface(0)
		  Super.Connect()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DataAvailableHandler(Sender As TCPSocket)
		  'Handles DataSocket.DataAvailable
		  RaiseEvent Data_DataAvailable(Sender)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ErrorHandler(Sender As TCPSocket)
		  RaiseEvent Data_Error(Sender)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Listen()
		  If Me.NetworkInterface = Nil Then Me.NetworkInterface = System.GetNetworkInterface(0)
		  Super.Listen()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SendCompleteHandler(Sender As TCPSocket, UserAborted As Boolean)
		  'Handles DataSocket.SendComplete
		  RaiseEvent Data_SendComplete(Sender, userAborted)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SendProgressHandler(Sender As TCPSocket, BytesSent As Integer, BytesLeft As Integer) As Boolean
		  'Handles DataSocket.SendProgress
		  Return RaiseEvent Data_SendProgress(Sender, BytesSent, BytesLeft)
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Control_Connected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Control_DataAvailable()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Control_Error()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Control_SendComplete(UserAborted As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Control_SendProgress(BytesSent As Integer, BytesLeft As Integer) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Data_Connected(DataSocket As TCPSocket)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Data_DataAvailable(DataSocket As TCPSocket)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Data_Error(DataSocket As TCPSocket)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Data_SendComplete(DataSocket As TCPSocket, UserAborted As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Data_SendProgress(DataSocket As TCPSocket, BytesSent As Integer, BytesLeft As Integer) As Boolean
	#tag EndHook


	#tag Property, Flags = &h21
		Private DataSocket As TCPSocket
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected TransferMode As Integer = 1
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
		#tag ViewProperty
			Name="Username"
			Visible=true
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
