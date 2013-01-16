#tag Class
Protected Class FTPClientSocket
Inherits FTPSocket
	#tag Event
		Sub Connected()
		  FTPLog("Connected to " + Me.RemoteAddress + ":" + Str(Me.Port))
		  VerbDispatchTimer = New Timer
		  VerbDispatchTimer.Period = 100
		  AddHandler VerbDispatchTimer.Action, AddressOf VerbDispatchHandler
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable()
		  Dim s As String = Me.Read
		  ParseResponse(s)
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub Disconnected()
		  Me.Close()
		End Sub
	#tag EndEvent

	#tag Event
		Sub TransferComplete(UserAborted As Boolean)
		  #pragma Unused UserAborted
		  Me.CloseData
		  VerbDispatchTimer.Mode = Timer.ModeMultiple
		End Sub
	#tag EndEvent

	#tag Event
		Function TransferProgress(BytesSent As Integer, BytesLeft As Integer) As Boolean
		  Return RaiseEvent TransferProgress(BytesSent * 100 / (BytesLeft + BytesSent))
		End Function
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub ABOR()
		  If TransferInProgress Then
		    Me.Write("ABOR" + CRLF)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub APPE(RemoteFileName As String, LocalFile As FolderItem, Mode As Integer = 1)
		  DataBuffer = BinaryStream.Open(LocalFile)
		  TYPE = Mode
		  If Me.Passive Then
		    PASV()
		  Else
		    PORT(Me.Port + 1)
		  End If
		  DoVerb("APPE", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CDUP()
		  DoVerb("CDUP")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub Close()
		  VerbDispatchTimer = Nil
		  mWorkingDirectory = ""
		  LastVerb.Verb = ""
		  LastVerb.Arguments = ""
		  Super.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Connect()
		  VerbDispatchTimer = Nil
		  ReDim PendingVerbs(-1)
		  Super.Connect()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CWD(NewDirectory As String)
		  'Change the WorkingDirectory
		  DoVerb("CWD", NewDirectory)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DELE(RemoteFileName As String)
		  'Delete the file named RemoteFileName on the FTP server
		  DoVerb("DELE", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub DoVerb(Verb As String, Params As String = "")
		  'Use this method to queue up verbs to be executed
		  Dim nextverb As FTPVerb
		  nextverb.Verb = Uppercase(Verb)
		  nextverb.Arguments = Trim(Params)
		  PendingVerbs.Append(nextverb)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub FEAT()
		  DoVerb("FEAT")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub InsertVerb(Verb As String, Params As String = "")
		  'Some verbs can't wait in line
		  Dim nextverb As FTPVerb
		  nextverb.Verb = Uppercase(Verb)
		  nextverb.Arguments = Trim(Params)
		  PendingVerbs.Insert(0, nextverb)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub List(TargetDirectory As String = "")
		  'Retrieves a directory listing
		  TargetDirectory = PathEncode(TargetDirectory)
		  If Me.Passive Then
		    PASV()
		  Else
		    PORT(Me.Port + 1)
		  End If
		  DoVerb("LIST", TargetDirectory)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MDTM(RemoteFileName As String)
		  DoVerb("MDTM", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MKD(NewDirectoryName As String)
		  DoVerb("MKD", NewDirectoryName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub NLST(TargetDirectory As String = "")
		  'Retrieves a directory listing
		  TargetDirectory = PathEncode(TargetDirectory)
		  If Me.Passive Then
		    PASV()
		  Else
		    PORT(Me.Port + 1)
		  End If
		  DoVerb("NLST", TargetDirectory)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub NOOP()
		  DoVerb("NOOP")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseResponse(Data As String)
		  Dim Code As Integer = Val(Left(Data, 3))
		  Dim msg As String = data.Replace(Format(Code, "000"), "")
		  
		  If msg.Trim <> "" Then
		    FTPLog(Str(Code) + " " + msg.Trim)
		  Else
		    FTPLog(Str(Code) + " " + FTPCodeToMessage(Code).Trim)
		  End If
		  
		  Select Case LastVerb.Verb
		  Case "USER"
		    Select Case Code
		    Case 230  'Logged in W/O pass
		      LoginOK = True
		      RaiseEvent Connected()
		    Case 331, 332  'Need PASS/ACCT
		      InsertVerb("PASS", Me.Password)
		    End Select
		    
		  Case "PASS"
		    Select Case Code
		    Case 230 'Logged in with pass
		      LoginOK = True
		      RaiseEvent Connected()
		    Case 530  'USER not set!
		      InsertVerb("USER", Me.Username) 'Warning: some FTP servers (Microsoft IIS) send this code for ALL errors, resulting in an infinite loop.
		    End Select
		  Case "RETR"
		    Select Case Code
		    Case 150 'About to start data transfer
		      Dim size As String = NthField(msg, "(", 2)
		      size = NthField(size, ")", 1)
		    Case 425, 426 'Data connection not ready
		    Case 451, 551 'Disk read error
		    Case 226 'Done
		      DataBuffer.Write(Me.GetData)
		      DataBuffer.Close
		      TransferComplete()
		    End Select
		    
		  Case "STOR", "APPE"
		    Select Case Code
		    Case 150  'Ready
		      Me.TransmitData(DataBuffer.Read(DataBuffer.Length))
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
		    ServerFeatures = Split(msg, EndOfLine.Windows)
		    ServerFeatures.Remove(ServerFeatures.Ubound)
		    ServerFeatures.Remove(0)
		    For Each Feature As String In ServerFeatures
		      Feature = Feature.Trim
		      FTPLog("   " + Feature)
		    Next
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
		      Case "P"
		        Me.TransferMode = PortalMode
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
		      InsertVerb("USER", Me.Username)
		    ElseIf Code = 421 Then  'Timeout
		      Me.Close
		    End If
		  End Select
		  If VerbDispatchTimer <> Nil Then VerbDispatchTimer.Mode = Timer.ModeMultiple
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PASV()
		  'You must call either PASV or PORT before transferring anything over the DataSocket
		  DoVerb("PASV")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PORT(PortNumber As Integer)
		  'You must call either PASV or PORT before transferring anything over the DataSocket
		  'Data port.
		  Me.ListenData(PortNumber)
		  DoVerb("PORT", Me.PASVAddress)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PWD()
		  DoVerb("PWD")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Quit()
		  DoVerb("QUIT")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Rename(OriginalName As String, NewName As String)
		  RNF = OriginalName
		  RNT = NewName
		  DoVerb("RNFR", RNF)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub REST(StartPosition As Integer = 0)
		  DoVerb("REST", Str(StartPosition))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RETR(RemoteFileName As String, SaveTo As FolderItem, Mode As Integer = 1)
		  TYPE = Mode
		  If Me.Passive Then
		    PASV()
		  Else
		    PORT(Me.Port + 1)
		  End If
		  DataBuffer = BinaryStream.Create(SaveTo, True)
		  DoVerb("RETR", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RMD(RemovedDirectoryName As String)
		  DoVerb("RMD", RemovedDirectoryName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SIZE(RemoteFileName As String)
		  DoVerb("SIZE", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub STAT(RemoteFileName As String = "")
		  DoVerb("STAT", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub STOR(RemoteFileName As String, LocalFile As FolderItem, Mode As Integer = 1)
		  TYPE = Mode
		  If Me.Passive Then
		    PASV()
		  Else
		    PORT(Me.Port + 1)
		  End If
		  DataBuffer = BinaryStream.Open(LocalFile)
		  DoVerb("STOR", RemoteFileName)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SYST()
		  DoVerb("SYST")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub TYPE(Assigns TransferType As Integer)
		  Select Case TransferType
		  Case ASCIIMode
		    DoVerb("TYPE", "A")
		  Case LocalMode
		    DoVerb("TYPE", "L8")
		  Case BinaryMode
		    DoVerb("TYPE", "I")
		  Case PortalMode
		    DoVerb("TYPE", "V")
		  Case EBCDICMode
		    DoVerb("TYPE", "E")
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub VerbDispatchHandler(Sender As Timer)
		  //Handles the FTPClientSocket.VerbDispatchTimer.Action event
		  If Not TransferInProgress And UBound(PendingVerbs) > -1 Then
		    Dim nextverb As FTPVerb = PendingVerbs(0)
		    PendingVerbs.Remove(0)
		    FTPLog(nextverb.Verb + " " + nextverb.Arguments)
		    Me.Write(nextverb.Verb + " " + nextverb.Arguments + CRLF)
		    LastVerb = nextverb
		    Sender.Mode = Timer.ModeOff
		  End If
		  
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Connected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ListResponse(Listing() As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferComplete()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferProgress(PercentComplete As Single) As Boolean
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

	#tag Note, Name = FTPClientSocket Notes
		This class subclasses FTPSocket and provides a client socket.
		
		When an FTP control connnection is established, the client waits for the server to
		initiate the FTP handshake. Once the handshake is completed, the Connected event is
		raised and commands may be sent to the server.
		
		Commands
	#tag EndNote


	#tag Property, Flags = &h1
		Protected DataBuffer As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected LastVerb As FTPVerb
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mWorkingDirectory As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private PendingVerbs() As FTPVerb
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RNF As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RNT As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private VerbDispatchTimer As Timer
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mWorkingDirectory
			End Get
		#tag EndGetter
		WorkingDirectory As String
	#tag EndComputedProperty


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
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
