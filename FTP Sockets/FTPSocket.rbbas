#tag Class
Protected Class FTPSocket
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
		Protected Shared Function ChildOfParent(Child As FolderItem, Parent As FolderItem) As Boolean
		  'A method to determine whether the Child FolderItem is contained within the Parent
		  'FolderItem or one of its sub-directories.
		  
		  If Not Parent.Directory Then Return False
		  While Child.Parent <> Nil
		    If Child.Parent.AbsolutePath = Parent.AbsolutePath Or Child.AbsolutePath = Parent.AbsolutePath Then
		      Return True
		    End If
		    Child = Child.Parent
		  Wend
		End Function
	#tag EndMethod

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
		Protected Sub ConnectData(PASVparams As String)
		  Me.CreateDataSocket(PASVparams)
		  Me.DataSocket.Connect()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub CreateDataSocket(PASVParams As String)
		  Me.CloseData
		  DataSocket = New TCPSocket
		  DataSocket.NetworkInterface = Self.NetworkInterface
		  AddHandler DataSocket.DataAvailable, AddressOf DataAvailableHandler
		  AddHandler DataSocket.Error, AddressOf ErrorHandler
		  AddHandler DataSocket.SendComplete, AddressOf SendCompleteHandler
		  AddHandler DataSocket.SendProgress, AddressOf SendProgressHandler
		  
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
		    DataSocket.Address = Me.NetworkInterface.IPAddress
		    DataSocket.Port = Rand.InRange(1025, 65534)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function CRLF() As String
		  Return Encodings.ASCII.Chr(13) + Encodings.ASCII.Chr(10)
		End Function
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
		Protected Shared Function IPv4_to_PASV(IPv4 As String, Port As Integer) As String
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
		Protected Shared Function ParseFileList(Raw As String) As Dictionary
		  'work in progress
		  Dim lines() As String = Split(Raw, CRLF)
		  Dim res As New Dictionary
		  
		  For i As Integer = 0 To UBound(lines)
		    Dim item As New Dictionary
		    Dim nm As String = NthField(lines(i), Encodings.ASCII.Chr(&o11), 2).Trim
		    lines(i) = Replace(lines(i), nm, "").Trim
		    Dim facts() As String = Split(lines(i), ",")
		    For j As Integer = 0 To UBound(facts)
		      Dim fact As String = facts(j)
		      Dim char As String = Left(fact, 1)
		      If char = "+" Then 
		        fact = Replace(fact, "+", "")
		        char = Left(fact, 1)
		      ElseIf char = "u" Then
		        If Left(fact, 2) = "up" Then
		          char = Left(fact, 2)
		        Else
		          Raise New UnsupportedFormatException
		        End If
		      End If
		      fact = Replace(fact, char, "")
		      
		      Select Case char
		      Case "r" ' file
		        item.Value("Directory") = False
		      Case "/" ' directory
		        item.Value("Directory") = True
		      Case "s" 'size
		        item.Value("Size") = CDbl(fact)
		        
		      Case "m" ' modification time
		        Dim d As Date
		        If ParseDate(fact, d) Then
		          item.Value("Modified") = d
		        End If
		        
		      Case "i" ' identifier
		        
		      Case "u" ' UP; Permissions
		        
		      Else
		        Continue For j
		      End Select
		    Next
		    res.Value(nm) = item
		  Next
		  
		  Return res
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function PASV_to_IPv4(PASVParams As String) As String
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

	#tag Method, Flags = &h1
		Protected Shared Function PathDecode(Path As String) As String
		  Return ReplaceAll(Path, Chr(&o0), Chr(&o12))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Shared Function PathEncode(Path As String) As String
		  Return ReplaceAll(Path, Chr(&o12), Chr(&o0))
		End Function
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

	#tag Method, Flags = &h21
		Private Shared Function SocketErrorMessage(Sender As SocketCore) As String
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

	#tag Method, Flags = &h1
		Protected Sub TransmitData(Data As String)
		  Me.DataSocket.Write(Data)
		  
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


	#tag Note, Name = Copying
		Copyright ©2012 Andrew Lambert, All Rights Reserved.
		
		This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as 
		published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
		
		This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
		
		You should have received a copy of the GNU Lesser General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
		
		---
		                   GNU LESSER GENERAL PUBLIC LICENSE
		                       Version 3, 29 June 2007
		
		 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
		 Everyone is permitted to copy and distribute verbatim copies
		 of this license document, but changing it is not allowed.
		
		
		  This version of the GNU Lesser General Public License incorporates
		the terms and conditions of version 3 of the GNU General Public
		License, supplemented by the additional permissions listed below.
		
		  0. Additional Definitions.
		
		  As used herein, "this License" refers to version 3 of the GNU Lesser
		General Public License, and the "GNU GPL" refers to version 3 of the GNU
		General Public License.
		
		  "The Library" refers to a covered work governed by this License,
		other than an Application or a Combined Work as defined below.
		
		  An "Application" is any work that makes use of an interface provided
		by the Library, but which is not otherwise based on the Library.
		Defining a subclass of a class defined by the Library is deemed a mode
		of using an interface provided by the Library.
		
		  A "Combined Work" is a work produced by combining or linking an
		Application with the Library.  The particular version of the Library
		with which the Combined Work was made is also called the "Linked
		Version".
		
		  The "Minimal Corresponding Source" for a Combined Work means the
		Corresponding Source for the Combined Work, excluding any source code
		for portions of the Combined Work that, considered in isolation, are
		based on the Application, and not on the Linked Version.
		
		  The "Corresponding Application Code" for a Combined Work means the
		object code and/or source code for the Application, including any data
		and utility programs needed for reproducing the Combined Work from the
		Application, but excluding the System Libraries of the Combined Work.
		
		  1. Exception to Section 3 of the GNU GPL.
		
		  You may convey a covered work under sections 3 and 4 of this License
		without being bound by section 3 of the GNU GPL.
		
		  2. Conveying Modified Versions.
		
		  If you modify a copy of the Library, and, in your modifications, a
		facility refers to a function or data to be supplied by an Application
		that uses the facility (other than as an argument passed when the
		facility is invoked), then you may convey a copy of the modified
		version:
		
		   a) under this License, provided that you make a good faith effort to
		   ensure that, in the event an Application does not supply the
		   function or data, the facility still operates, and performs
		   whatever part of its purpose remains meaningful, or
		
		   b) under the GNU GPL, with none of the additional permissions of
		   this License applicable to that copy.
		
		  3. Object Code Incorporating Material from Library Header Files.
		
		  The object code form of an Application may incorporate material from
		a header file that is part of the Library.  You may convey such object
		code under terms of your choice, provided that, if the incorporated
		material is not limited to numerical parameters, data structure
		layouts and accessors, or small macros, inline functions and templates
		(ten or fewer lines in length), you do both of the following:
		
		   a) Give prominent notice with each copy of the object code that the
		   Library is used in it and that the Library and its use are
		   covered by this License.
		
		   b) Accompany the object code with a copy of the GNU GPL and this license
		   document.
		
		  4. Combined Works.
		
		  You may convey a Combined Work under terms of your choice that,
		taken together, effectively do not restrict modification of the
		portions of the Library contained in the Combined Work and reverse
		engineering for debugging such modifications, if you also do each of
		the following:
		
		   a) Give prominent notice with each copy of the Combined Work that
		   the Library is used in it and that the Library and its use are
		   covered by this License.
		
		   b) Accompany the Combined Work with a copy of the GNU GPL and this license
		   document.
		
		   c) For a Combined Work that displays copyright notices during
		   execution, include the copyright notice for the Library among
		   these notices, as well as a reference directing the user to the
		   copies of the GNU GPL and this license document.
		
		   d) Do one of the following:
		
		       0) Convey the Minimal Corresponding Source under the terms of this
		       License, and the Corresponding Application Code in a form
		       suitable for, and under terms that permit, the user to
		       recombine or relink the Application with a modified version of
		       the Linked Version to produce a modified Combined Work, in the
		       manner specified by section 6 of the GNU GPL for conveying
		       Corresponding Source.
		
		       1) Use a suitable shared library mechanism for linking with the
		       Library.  A suitable mechanism is one that (a) uses at run time
		       a copy of the Library already present on the user's computer
		       system, and (b) will operate properly with a modified version
		       of the Library that is interface-compatible with the Linked
		       Version.
		
		   e) Provide Installation Information, but only if you would otherwise
		   be required to provide such information under section 6 of the
		   GNU GPL, and only to the extent that such information is
		   necessary to install and execute a modified version of the
		   Combined Work produced by recombining or relinking the
		   Application with a modified version of the Linked Version. (If
		   you use option 4d0, the Installation Information must accompany
		   the Minimal Corresponding Source and Corresponding Application
		   Code. If you use option 4d1, you must provide the Installation
		   Information in the manner specified by section 6 of the GNU GPL
		   for conveying Corresponding Source.)
		
		  5. Combined Libraries.
		
		  You may place library facilities that are a work based on the
		Library side by side in a single library together with other library
		facilities that are not Applications and are not covered by this
		License, and convey such a combined library under terms of your
		choice, if you do both of the following:
		
		   a) Accompany the combined library with a copy of the same work based
		   on the Library, uncombined with any other library facilities,
		   conveyed under the terms of this License.
		
		   b) Give prominent notice with the combined library that part of it
		   is a work based on the Library, and explaining where to find the
		   accompanying uncombined form of the same work.
		
		  6. Revised Versions of the GNU Lesser General Public License.
		
		  The Free Software Foundation may publish revised and/or new versions
		of the GNU Lesser General Public License from time to time. Such new
		versions will be similar in spirit to the present version, but may
		differ in detail to address new problems or concerns.
		
		  Each version is given a distinguishing version number. If the
		Library as you received it specifies that a certain numbered version
		of the GNU Lesser General Public License "or any later version"
		applies to it, you have the option of following the terms and
		conditions either of that published version or of any later version
		published by the Free Software Foundation. If the Library as you
		received it does not specify a version number of the GNU Lesser
		General Public License, you may choose any version of the GNU Lesser
		General Public License ever published by the Free Software Foundation.
		
		  If the Library as you received it specifies that a proxy can decide
		whether future versions of the GNU Lesser General Public License shall
		apply, that proxy's public statement of acceptance of any version is
		permanent authorization for you to choose that version for the
		Library.
	#tag EndNote

	#tag Note, Name = FTPSocket Notes
		This class provides both the control and data connections for a given FTP session.
		FTPClientSocket and FTPServerSocket are subclassed from FTPSocket. FTPSocket should 
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


	#tag Constant, Name = ASCIIMode, Type = Double, Dynamic = False, Default = \"2", Scope = Public
	#tag EndConstant

	#tag Constant, Name = BinaryMode, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant

	#tag Constant, Name = EBCDICMode, Type = Double, Dynamic = False, Default = \"4", Scope = Public
	#tag EndConstant

	#tag Constant, Name = FTPVersion, Type = Double, Dynamic = False, Default = \"0.1", Scope = Protected
	#tag EndConstant

	#tag Constant, Name = LocalMode, Type = Double, Dynamic = False, Default = \"3", Scope = Public
	#tag EndConstant

	#tag Constant, Name = PortalMode, Type = Double, Dynamic = False, Default = \"-1", Scope = Public
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
