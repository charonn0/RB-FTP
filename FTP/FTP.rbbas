#tag Module
Protected Module FTP
	#tag Method, Flags = &h1
		Protected Function ChildOfParent(Child As FolderItem, Parent As FolderItem) As Boolean
		  'A method to determine whether the Child FolderItem is contained within the Parent
		  'FolderItem or one of its sub-directories.
		  #pragma BreakOnExceptions Off
		  If Not Parent.Directory Then Return False
		  While Child.Parent <> Nil
		    If Child.Parent.AbsolutePath = Parent.AbsolutePath Or Child.AbsolutePath = Parent.AbsolutePath Then
		      Return True
		    End If
		    Child = Child.Parent
		  Wend
		  
		Exception
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function CRLF() As String
		  Return Encodings.ASCII.Chr(13) + Encodings.ASCII.Chr(10)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function FormatCode(Code As Integer) As String
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

	#tag Method, Flags = &h1
		Protected Function IPv4_to_PASV(IPv4 As String, Port As Integer) As String
		  Dim p1, p2 As Integer
		  Dim h1, h2, h3, h4 As String
		  h1 = NthField(IPv4, ".", 1)
		  h2 = NthField(IPv4, ".", 2)
		  h3 = NthField(IPv4, ".", 3)
		  h4 = NthField(IPv4, ".", 4)
		  p1 = port \ 256
		  p2 = port Mod 256
		  Return h1 + "," + h2 + "," + h3 + "," + h4 + "," + Str(p1) + "," + Str(p2)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function PASV_to_IPv4(PASVParams As String) As String
		  Dim p1, p2 As Integer
		  Dim h1, h2, h3, h4 As String
		  PASVParams = NthField(PASVParams, " ", CountFields(PASVParams, " "))
		  Dim parentheticals() As String = Split("(){}[]<>", "")
		  For Each paren As String In parentheticals
		    PASVParams = Replace(PASVParams, paren, "")
		  Next
		  
		  h1 = NthField(PASVParams, ",", 1)
		  h2 = NthField(PASVParams, ",", 2)
		  h3 = NthField(PASVParams, ",", 3)
		  h4 = NthField(PASVParams, ",", 4)
		  p1 = Val(NthField(PASVParams, ",", 5))
		  p2 = Val(NthField(PASVParams, ",", 6))
		  
		  Return h1 + "." + h2 + "." + h3 + "." + h4 + ":" + Format(p1 * 256 + p2, "#####0")
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SocketErrorMessage(Sender As SocketCore) As String
		  Dim err As String = "Socket error " + Str(Sender.LastErrorCode)
		  Select Case Sender.LastErrorCode
		  Case 102
		    err = err + ": Disconnected."
		  Case 100
		    err = err + ": Could not create a socket!"
		  Case 103
		    err = err + ": Unable to contact host."
		  Case 105
		    err = err + ": That port number is already in use."
		  Case 106
		    err = err + ": You can't do that right now."
		  Case 107
		    err = err + ": Could not bind to port."
		  Case 108
		    err = err + ": Out of memory."
		  Else
		    If Not Sender.IsConnected Then
		      err = err + ": Socket not connected."
		    Else
		      err = err + ": System error code."
		    End If
		  End Select
		  
		  Return err
		End Function
	#tag EndMethod


	#tag Constant, Name = ASCIIMode, Type = Double, Dynamic = False, Default = \"2", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = BinaryMode, Type = Double, Dynamic = False, Default = \"1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = EBCDICMode, Type = Double, Dynamic = False, Default = \"4", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LocalMode, Type = Double, Dynamic = False, Default = \"3", Scope = Protected
	#tag EndConstant


	#tag Structure, Name = FTPListEntry, Flags = &h0
		FileName As String*256
		  Owner As String*64
		  Group As String*64
		  EntryType As Integer
		  OwnerPerms As Integer
		  GroupPerms As Integer
		  WorldPerms As Integer
		  FileSize As Integer
		Timestamp As String*64
	#tag EndStructure

	#tag Structure, Name = FTPVerb, Flags = &h1
		Verb As String*64
		Arguments As String*448
	#tag EndStructure


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
End Module
#tag EndModule
