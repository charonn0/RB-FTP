#tag Class
Protected Class FTPSocket
Inherits TCPSocket
	#tag Event
		Sub Connected()
		  RaiseEvent ControlConnected()
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable()
		  Dim s As String = Me.Read
		  ParseResponse(s)
		End Sub
	#tag EndEvent

	#tag Event
		Sub Error()
		  RaiseEvent ControlError()
		End Sub
	#tag EndEvent

	#tag Event
		Sub SendComplete(userAborted as Boolean)
		  RaiseEvent ControlWriteComplete(UserAborted)
		End Sub
	#tag EndEvent

	#tag Event
		Function SendProgress(bytesSent as Integer, bytesLeft as Integer) As Boolean
		  Return RaiseEvent ControlWriteProgress(BytesSent, BytesLeft)
		End Function
	#tag EndEvent


	#tag Method, Flags = &h1
		Protected Sub Close()
		  If DataSocket <> Nil Then
		    DataSocket.Close
		    DataSocket = Nil
		  End If
		  OutputFile = Nil
		  
		  If OutputStream <> Nil Then
		    OutputStream.Close
		  End If
		  Super.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Connect()
		  DataSocket = New TCPSocket
		  DataSocket.Address = Me.Address
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
		  #pragma Unused Sender
		  RaiseEvent DataConnected()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function CRLF() As String
		  Return Encodings.ASCII.Chr(13) + Encodings.ASCII.Chr(10)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DataAvailableHandler(Sender As TCPSocket)
		  Dim s As String = Sender.ReadAll
		  If LastVerb.Verb = "LIST" Or LastVerb.Verb = "NLST" Then
		    DirList(Split(s, EndOfLine.Windows))
		  Else
		    OutputStream.Write(s)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ErrorHandler(Sender As TCPSocket)
		  #pragma Unused Sender
		  RaiseEvent DataError()
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
		    Return ""
		    
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

	#tag Method, Flags = &h21
		Private Sub ParseResponse(Data As String)
		  Dim Code As Integer
		  Dim msg As String
		  
		  Code = Val(Left(Data, 3))
		  msg = msg.Replace(Format(Code, "000"), "")
		  
		  Dim response As FTPResponse
		  response.Code = Code
		  Select Case Code \ 100
		  Case RT_Positive_Preliminary
		    response.Reply_Type = RT_Positive_Preliminary
		  Case RT_Positive_Complete
		    response.Reply_Type = RT_Positive_Complete
		  Case RT_Positive_Intermedite
		    response.Reply_Type = RT_Positive_Intermedite
		  Case RT_Negative_Transient
		    response.Reply_Type = RT_Negative_Transient
		  Case RT_Negative_Permanent
		    response.Reply_Type = RT_Negative_Permanent
		  Case RT_Protected
		    response.Reply_Type = RT_Protected
		  End Select
		  Select Case (Code - response.Reply_Type * 100) \ 10
		  Case RP_Auth
		    response.Reply_Purpose = RP_Auth
		  Case RP_Connection
		    response.Reply_Purpose = RP_Connection
		  Case RP_File_System
		    response.Reply_Purpose = RP_File_System
		  Case RP_Info
		    response.Reply_Purpose = RP_Info
		  Case RP_Syntax
		    response.Reply_Purpose = RP_Syntax
		  Case RP_Unspecified
		    response.Reply_Purpose = RP_Unspecified
		  End Select
		  response.Reply_Code = Code - (100 * response.Reply_Type) - (10 * response.Reply_Purpose)
		  response.Reply_Args = msg
		  ControlResponse(response)
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
		  ControlVerb(Verb)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function PathDecode(Path As String, NamePrefix As String = "") As String
		  If Path.Left(1) <> "/" Then Return Path
		  Path = ReplaceAll(Path, Chr(&o0), Chr(&o12))
		  Return ReplaceAll(NamePrefix + Path, "//", "/")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function PathEncode(Path As String, NamePrefix As String = "") As String
		  If NamePrefix.Right(1) <> "/" And NamePrefix.Trim <> "" Then NamePrefix = NamePrefix + "/"
		  Path = ReplaceAll(Path, Chr(&o12), Chr(&o0))
		  Return NamePrefix + Path
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function Read() As String
		  Dim la As String
		  
		  While Me.Lookahead.LenB > 0
		    la = la + Me.ReadAll
		    App.YieldToNextThread
		  Wend
		  
		  Return la
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function ReadData() As String
		  Return DataSocket.ReadAll
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SendCompleteHandler(Sender As TCPSocket, UserAborted As Boolean)
		  #pragma Unused Sender
		  OutputStream.Close
		  RaiseEvent DataWriteComplete(UserAborted)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SendProgressHandler(Sender As TCPSocket, BytesSent As Integer, BytesLeft As Integer) As Boolean
		  #pragma Unused Sender
		  Return RaiseEvent DataWriteProgress(BytesSent, BytesLeft)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Write(Command As String)
		  Super.Write(Command)
		  Me.Flush
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub WriteData(Data As String)
		  DataSocket.Write(Data)
		  DataSocket.Flush
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event ControlConnected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ControlError()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ControlReadProgress(BytesRead As Integer, BytesLeft As Integer) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ControlResponse(Response As FTPResponse)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ControlVerb(Verb As FTPVerb)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ControlWriteComplete(UserAborted As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ControlWriteProgress(BytesSent As Integer, BytesLeft As Integer) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DataConnected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DataError()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DataReadComplete(UserAborted As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DataReadProgress(BytesRead As Integer, BytesLeft As Integer) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DataWriteComplete(UserAborted As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DataWriteProgress(BytesSent As Integer, BytesLeft As Integer) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event DirList(List() As String)
	#tag EndHook


	#tag Property, Flags = &h0
		Anonymous As Boolean = False
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If DataSocket <> Nil Then
			    Return DataSocket.Address
			  End If
			End Get
		#tag EndGetter
		DataAddress As String
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If DataSocket <> Nil Then
			    Return DataSocket.IsConnected
			  End If
			End Get
		#tag EndGetter
		DataIsConnected As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If DataSocket <> Nil Then
			    Return DataSocket.LastErrorCode
			  End If
			End Get
		#tag EndGetter
		DataLastErrorCode As Integer
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If DataSocket <> Nil Then
			    Return DataSocket.Port
			  End If
			End Get
		#tag EndGetter
		DataPort As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h1
		Protected DataSocket As TCPSocket
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected LastVerb As FTPVerb
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected OutputFile As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected OutputStream As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h0
		Passive As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected ServerFeatures() As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected ServerType As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected TransferMode As Integer = 1
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected UTFMode As Boolean
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected WorkingDirectory As String = "/"
	#tag EndProperty


	#tag Constant, Name = ASCIIMode, Type = Double, Dynamic = False, Default = \"2", Scope = Public
	#tag EndConstant

	#tag Constant, Name = BinaryMode, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant

	#tag Constant, Name = RP_Auth, Type = Double, Dynamic = False, Default = \"3", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RP_Connection, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RP_File_System, Type = Double, Dynamic = False, Default = \"5", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RP_Info, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RP_Syntax, Type = Double, Dynamic = False, Default = \"0", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RP_Unspecified, Type = Double, Dynamic = False, Default = \"4", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RT_Negative_Permanent, Type = Double, Dynamic = False, Default = \"5", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RT_Negative_Transient, Type = Double, Dynamic = False, Default = \"4", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RT_Positive_Complete, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RT_Positive_Intermedite, Type = Double, Dynamic = False, Default = \"3", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RT_Positive_Preliminary, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = RT_Protected, Type = Double, Dynamic = False, Default = \"6", Scope = Protected
	#tag EndConstant


	#tag Structure, Name = FTPResponse, Flags = &h1
		Code As Integer
		  Reply_Type As Integer
		  Reply_Purpose As Integer
		  Reply_Code As Integer
		Reply_Args As String*496
	#tag EndStructure

	#tag Structure, Name = FTPVerb, Flags = &h1
		Verb As String*64
		Arguments As String*448
	#tag EndStructure


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
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataAddress"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataIsConnected"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataLastErrorCode"
			Group="Behavior"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DataPort"
			Group="Behavior"
			Type="Integer"
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
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
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
