#tag Class
Protected Class Connection
Inherits TCPSocket
	#tag Event
		Sub Error()
		  If Me.LastErrorCode = 102 Then
		    RaiseEvent Disconnected()
		  Else
		    Me.Close
		    RaiseEvent FTPLog(SocketErrorMessage(Me))
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub SendComplete(userAborted as Boolean)
		  //We're not interested in the control connection's progress
		  #pragma Unused userAborted
		  Return
		End Sub
	#tag EndEvent

	#tag Event
		Function SendProgress(bytesSent as Integer, bytesLeft as Integer) As Boolean
		  //We're not interested in the control connection's progress
		  #pragma Unused bytesSent
		  #pragma Unused bytesLeft
		  Return False
		End Function
	#tag EndEvent


	#tag Method, Flags = &h1
		Protected Sub Close()
		  LoginOK = False
		  ReDim ServerFeatures(-1)
		  ServerType = ""
		  TransferInProgress = False
		  TransferMode = 0
		  
		  If DataSocket <> Nil Then
		    Me.CloseData
		    DataSocket = Nil
		  End If
		  
		  Super.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub CloseData()
		  If DataSocket <> Nil Then
		    DataSocket.Flush()
		    Me.DataSocket.Close()
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Connect()
		  If Me.NetworkInterface = Nil Then Me.NetworkInterface = System.GetNetworkInterface(0)
		  Super.Connect()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub ConnectData(PASVparams As String, DataInterface As NetworkInterface = Nil)
		  Me.CreateDataSocket(PASVparams, DataInterface)
		  Me.DataSocket.Connect()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub CreateDataSocket(PASVParams As String, NetInterface As NetworkInterface = Nil)
		  Me.CloseData
		  DataSocket = New TCPSocket
		  If NetInterface <> Nil Then
		    DataSocket.NetworkInterface = NetInterface
		  Else
		    DataSocket.NetworkInterface = Self.NetworkInterface
		  End If
		  AddHandler DataSocket.DataAvailable, WeakAddressOf DataAvailableHandler
		  AddHandler DataSocket.Error, WeakAddressOf ErrorHandler
		  AddHandler DataSocket.SendComplete, WeakAddressOf SendCompleteHandler
		  AddHandler DataSocket.SendProgress, WeakAddressOf SendProgressHandler
		  
		  If PASVParams.Trim <> "" Then
		    PASVParams = PASV_to_IPv4(PASVParams)
		    Dim ipv4 As String
		    Dim dport As Integer
		    ipv4 = NthField(PASVParams, ":", 1)
		    dport = Val(NthField(PASVParams, ":", 2))
		    DataSocket.Address = ipv4
		    DataSocket.Port = dport
		  Else
		    Dim rand As New Random
		    DataSocket.Address = DataSocket.NetworkInterface.IPAddress
		    DataSocket.Port = Rand.InRange(1025, 65534)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DataAvailableHandler(Sender As TCPSocket)
		  'Handles DataSocket.DataAvailable
		  Dim s As String = Sender.ReadAll
		  DataReadBuffer = DataReadBuffer + s
		  TransferInProgress = True
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ErrorHandler(Sender As TCPSocket)
		  If Sender.LastErrorCode = 102 Then
		    Sender.Close
		    TransferInProgress = False
		    'TransferComplete(True)
		  Else
		    Sender.Close
		    RaiseEvent FTPLog(SocketErrorMessage(Sender))
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub FTPLog(LogLine As String)
		  'This method allows any subclass of the FTPSocket to raise its own FTPLog event.
		  RaiseEvent FTPLog(LogLine)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetData() As String
		  Dim s As String = DataReadBuffer
		  DataReadBuffer = ""
		  Return s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function IsDataConnected() As Boolean
		  If DataSocket <> Nil Then Return DataSocket.IsConnected
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Listen()
		  If Me.NetworkInterface = Nil Then Me.NetworkInterface = System.GetNetworkInterface(0)
		  Super.Listen()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub ListenData(Port As Integer)
		  Dim PASVparams As String = IPv4_to_PASV(Me.NetworkInterface.IPAddress, Port)
		  CreateDataSocket(PASVparams)
		  DataSocket.Listen()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Read() As String
		  If Me.IsConnected Then
		    Dim la As String = Me.ReadAll
		    Return la
		  Else
		    ErrorHandler(Me)
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SendCompleteHandler(Sender As TCPSocket, UserAborted As Boolean)
		  'Handles DataSocket.SendComplete
		  #pragma Unused Sender
		  TransferInProgress = False
		  RaiseEvent TransferComplete(UserAborted)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SendProgressHandler(Sender As TCPSocket, BytesSent As Integer, BytesLeft As Integer) As Boolean
		  'Handles DataSocket.SendProgress
		  #pragma Unused Sender
		  Return RaiseEvent TransferProgress(BytesSent, BytesLeft)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub TransmitData(Data As String)
		  ' If the current TransferMode is ASCII or EBCDIC and the passed Data string has encoding data associated with it
		  ' then the Data are CONVERTED prior to being written; otherwise, the data are written verbatim.
		  
		  Select Case TransferMode
		  Case BinaryMode, LocalMode
		    Me.DataSocket.Write(Data)
		    
		  Case EBCDICMode, ASCIIMode
		    Dim out As String
		    If Data.Encoding <> Nil Then
		      Dim outen As TextEncoding
		      If TransferMode = ASCIIMode Then
		        outen = Encodings.ASCII
		      Else
		        outen = GetTextEncoding(&h0C01) 'EBCDIC
		      End If
		      Dim conv As TextConverter = GetTextConverter(Data.Encoding, outen)
		      out = conv.convert(Data)
		    Else
		      out = Data
		    End If
		    Me.DataSocket.Write(out)
		  End Select
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Write(Command As String)
		  If Me.IsConnected Then
		    Super.Write(Command)
		    Me.Flush
		  Else
		    ErrorHandler(Me)
		  End If
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Disconnected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event FTPLog(LogLine As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferComplete(UserAborted As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferProgress(BytesSent As Integer, BytesLeft As Integer) As Boolean
	#tag EndHook


	#tag Note, Name = FTPSocket Notes
		This class provides both the control and data connections for a given FTP session.
		FTPClientSocket and FTP.Server are subclassed from FTPSocket. FTPSocket should 
		only know about the connections themselves without needing to know whether it's a 
		client or server flavor. Other non-socket data which is used in both clients and 
		servers are also dealt with in FTPSocket.
		
		This class is not intended to be used except as the superclass of another TCPSocket 
		that handles protocol layer stuff via the DataAvailable event and Write, WriteData,
		Read, and ReadData methods.
	#tag EndNote


	#tag Property, Flags = &h0
		Anonymous As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h21
		Private DataReadBuffer As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private DataSocket As TCPSocket
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected LoginOK As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		Passive As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h0
		Password As String
	#tag EndProperty

	#tag ComputedProperty, Flags = &h1
		#tag Getter
			Get
			  If DataSocket = Nil Then CreateDataSocket("")
			  Return IPv4_to_PASV(DataSocket.NetworkInterface.IPAddress, DataSocket.Port)
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  CreateDataSocket(value)
			End Set
		#tag EndSetter
		Protected PASVAddress As String
	#tag EndComputedProperty

	#tag Property, Flags = &h1
		Protected ServerFeatures() As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected ServerType As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected TransferInProgress As Boolean
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected TransferMode As Integer = 1
	#tag EndProperty

	#tag Property, Flags = &h0
		Username As String
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
