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
		Sub SendComplete(UserAborted As Boolean)
		  
		  
		  RaiseEvent SendComplete(UserAborted)
		End Sub
	#tag EndEvent

	#tag Event
		Function SendProgress(BytesSent As Integer, BytesLeft As Integer) As Boolean
		  Return RaiseEvent SendProgress(BytesSent, BytesLeft)
		End Function
	#tag EndEvent


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
