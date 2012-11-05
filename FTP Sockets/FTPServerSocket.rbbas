#tag Class
Protected Class FTPServerSocket
Inherits FTPSocket
	#tag Event
		Sub Connected()
		  FTPLog("Remote host connected from " + Me.RemoteAddress + " on port " + Str(Me.Port))
		  InactivityTimer.Mode = Timer.ModeMultiple
		  DoResponse(220, Banner)
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable()
		  Dim s As String = Me.Read
		  ParseVerb(s)
		End Sub
	#tag EndEvent

	#tag Event
		Sub Disconnected()
		  FTPLog("Remote host closed the connection.")
		  Me.Close
		End Sub
	#tag EndEvent

	#tag Event
		Sub TransferComplete(UserAborted As Boolean)
		  Me.CloseData()
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h1
		Protected Sub DoResponse(Code As Integer, Params As String = "")
		  If Params.Trim = "" Then Params = FTPCodeToMessage(Code)
		  params = Trim(Str(Code) + " " + Params)
		  Me.Write(params + CRLF)
		  FTPLog(params)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FileListing(Directory As FolderItem) As String
		  If Directory = Nil Then
		    DoResponse(451, "That directory does not exist.")
		    Return ""
		  End If
		  Dim thelist As String = "." + CRLF + ".." + CRLF
		  For i As Integer = 1 To Directory.Count
		    Dim fsize, fname, fperms, fowner, fgroup, fmoddate As String
		    fperms = "FOROWOXGRGWGXWRWWWX"
		    fsize = Str(Directory.TrueItem(i).Length)
		    fname =  Directory.TrueItem(i).Name
		    
		    If Directory.TrueItem(i).IsReadable Then
		      fperms = Replace(fperms, "OR", "r")
		      fperms = Replace(fperms, "GR", "r")
		      fperms = Replace(fperms, "WR", "r")
		    Else
		      fperms = Replace(fperms, "OR", "-")
		      fperms = Replace(fperms, "GR", "-")
		      fperms = Replace(fperms, "WR", "-")
		    End If
		    
		    If Directory.TrueItem(i).IsWriteable Then
		      fperms = Replace(fperms, "OW", "w")
		      fperms = Replace(fperms, "GW", "w")
		      fperms = Replace(fperms, "WW", "w")
		    Else
		      fperms = Replace(fperms, "OW", "-")
		      fperms = Replace(fperms, "GW", "-")
		      fperms = Replace(fperms, "WW", "-")
		    End If
		    
		    If Directory.TrueItem(i).Directory Then
		      fperms = Replace(fperms, "F", "D")
		    Else
		      fperms = Replace(fperms, "F", "-")
		    End If
		    
		    If Directory.TrueItem(i).IsWriteable And Directory.TrueItem(i).IsReadable Then
		      fperms = Replace(fperms, "OX", "x")
		      fperms = Replace(fperms, "GX", "x")
		      fperms = Replace(fperms, "WX", "x")
		    Else
		      fperms = Replace(fperms, "OX", "-")
		      fperms = Replace(fperms, "GX", "-")
		      fperms = Replace(fperms, "WX", "-")
		    End If
		    
		    fmoddate = Directory.TrueItem(i).ModificationDate.ShortDate
		    
		    'thelist = thelist + fperms + " 1 " + fowner + " " + fgroup + " " + fsize + " " + fmoddate + " " + fname + CRLF
		    thelist = thelist + fname + CRLF
		  Next
		  
		  Return thelist
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FindDirectory(Name As String) As FolderItem
		  If Name.Trim = "" Then Name = "/"
		  Dim g As FolderItem
		  If Left(Name, 1) = "/" Then //relative to RootDirectory
		    g = RootDirectory
		    Name = Replace(Name, "/", "")
		  Else //relative to WorkingDirectory
		    g = mWorkingDirectory
		  End If
		  
		  For i As Integer = 1 To CountFields(Name, "/") - 1
		    g = g.Child(NthField(Name, "/", i))
		  Next
		  
		  If ChildOfParent(g, RootDirectory) Then
		    Return g
		  Else
		    Return Nil
		  End If
		  
		Exception NilObjectException
		  Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FindFile(Name As String) As FolderItem
		  Dim g As FolderItem = FindDirectory(Name)
		  Dim file As String = NthField(Name, "/", CountFields(Name, "/"))
		  If file.Trim = "" Then Return Nil
		  g = g.Child(file)
		  Return g
		  
		Exception NilObjectException
		  Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub InactivityHandler(Sender As Timer)
		  //Handles the FTPServerSocket.InactivityTimer.Action event
		  Sender.Mode = Timer.ModeOff
		  DoResponse(421, "Inactivity timeout.")
		  Me.Close
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Listen()
		  Super.Listen
		  FTPLog("Now listening on port " + Str(Me.Port))
		  InactivityTimer = New Timer
		  InactivityTimer.Period = TimeOutPeriod
		  AddHandler InactivityTimer.Action, AddressOf InactivityHandler
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
		  
		  FTPLog(Verb.Verb + " " + Verb.Arguments)
		  InactivityTimer.Reset()
		  Select Case Verb.Verb.Trim
		  Case "USER"
		    Username = Verb.Arguments.Trim
		    If Me.Anonymous And Username = "anonymous" Then
		      DoResponse(331, "Anonymous login OK, send e-mail address as password.")
		    Else
		      DoResponse(331) 'Need PASS
		    End If
		    
		  Case "PASS"
		    Password = Verb.Arguments.Trim
		    If Username.Trim = "" Then
		      DoResponse(530)  'USER not set!
		    ElseIf Me.Anonymous And Username = "anonymous" Then
		      Call UserLogon(Username, Password)  'anon users passwords don't matter
		      DoResponse(230) 'Logged in with pass
		      LoginOK = True
		    Else
		      If UserLogon(Username, Password) Then
		        DoResponse(230) 'Logged in with pass
		        LoginOK = True
		      Else
		        DoResponse(530) 'Bad password!
		      End If
		    End If
		  Case "RETR"
		    If LoginOK Then
		      If Me.IsDataConnected Then
		        If DataBuffer <> Nil Then
		          DoResponse(150)
		          While Not DataBuffer.EOF
		            TransmitData(DataBuffer.Read(DataBuffer.Length))
		            App.YieldToNextThread
		          Wend
		          DoResponse(226)
		          Me.CloseData()
		        Else
		          DoResponse(451) 'bad file
		        End If
		      Else
		        DoResponse(425) 'No data connection
		      End If
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "STOR"
		    If LoginOK Then
		      If RootDirectory.Child(Verb.Arguments).Exists And Not AllowWrite Then
		        DoResponse(450, "Filename taken.")
		      Else
		        DoResponse(150) 'Ready
		      End If
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "FEAT"
		    If LoginOK Then
		      Me.Write("211-Features:" + CRLF + " PASV" + CRLF)
		      DoResponse(211, "End")
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "SYST"
		    If LoginOK Then
		      'We'll claim to be UNIX even if we aren't
		      DoResponse(215, "UNIX Type: L8")
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "CWD", "XCWD"
		    If LoginOK Then
		      Dim g As FolderItem = FindDirectory(Verb.Arguments)
		      If g <> Nil Then
		        mWorkingDirectory = g
		        DoResponse(250)  'OK
		      Else
		        DoResponse(550)  'bad file
		      End If
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "PWD"
		    If LoginOK Then
		      DoResponse(257, """" + WorkingDirectory + """")
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "LIST"
		    If LoginOK Then
		      If Me.IsDataConnected Then
		        Dim s As String = FileListing(FindDirectory(Verb.Arguments))
		        If s.Trim <> "" Then
		          DoResponse(150)
		          TransmitData(s)
		          Me.CloseData
		          DoResponse(226)
		        Else
		          DoResponse(451, "No list.")
		        End If
		      Else
		        DoResponse(425) //no connection
		      End If
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "CDUP"
		    If LoginOK Then
		      If ChildOfParent(mWorkingDirectory.Parent, RootDirectory) Then
		        mWorkingDirectory = mWorkingDirectory.Parent
		        DoResponse(250)
		      Else
		        DoResponse(550)
		      End If
		      'DoResponse(502)  'Not implemented FIXME
		      ' 200  'OK
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "PASV"
		    If LoginOK Then
		      If Not Me.IsDataConnected Then
		        Dim rand As New Random
		        Dim port As Integer = Rand.InRange(1024, 65534)
		        Me.ListenData(port)
		        DoResponse(227, "Entering Passive Mode (" + Me.PASVAddress + ").")
		      Else
		        DoResponse(125)  //already open
		      End If
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "REST"
		    If LoginOK Then
		      DataBuffer.Position = Val(Verb.Arguments)
		      DoResponse(350)
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "PORT"
		    If LoginOK Then
		      DoResponse(200, Verb.Arguments)
		      Me.ConnectData(Verb.Arguments)
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "TYPE"
		    If LoginOK Then
		      Select Case Verb.Arguments.Trim
		      Case "A", "A N"
		        Me.TransferMode = ASCIIMode
		        DoResponse(200)
		      Case "I", "L"
		        Me.TransferMode = BinaryMode
		        DoResponse(200)
		      Else
		        DoResponse(504) 'Command not implemented for param
		      End Select
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "MKD"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		      ' 257
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "RMD"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		      
		    Else
		      DoResponse(530)  'not logged in
		    End If
		    
		  Case "DELE"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "RNFR"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "RNTO"
		    If LoginOK Then
		      DoResponse(502)  'Not implemented FIXME
		    Else
		      DoResponse(530)  'not logged in
		    End If
		  Case "QUIT"
		    DoResponse(221, "Bye.")
		    Me.Close
		  Case "NOOP" 'Keep alive; no operation
		    DoResponse(200)
		  Else
		    DoResponse(500)  'syntax error or unknown verb
		  End Select
		  
		  
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event UserLogon(UserName As String, Password As String) As Boolean
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


	#tag Property, Flags = &h0
		AllowWrite As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		Banner As String = "Welcome to BSFTPd!"
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected DataBuffer As BinaryStream
	#tag EndProperty

	#tag Property, Flags = &h21
		Private InactivityTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRootDirectory As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mWorkingDirectory As FolderItem
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mRootDirectory = Nil Then mRootDirectory = App.ExecutableFile.Parent
			  return mRootDirectory
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  mRootDirectory = value
			  mWorkingDirectory = value
			End Set
		#tag EndSetter
		RootDirectory As FolderItem
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		#tag Note
			600000ms = 10 minutes
		#tag EndNote
		TimeOutPeriod As Integer = 600000
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  If mWorkingDirectory <> Nil And RootDirectory <> Nil Then
			    return Replace(mWorkingDirectory.AbsolutePath, RootDirectory.AbsolutePath, "/")
			  Else
			    Return "/"
			  End If
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Dim g As FolderItem = FindDirectory(value)
			  If g = Nil Then g = RootDirectory
			  If ChildOfParent(g, RootDirectory) Then
			    mWorkingDirectory = g
			  Else
			    mWorkingDirectory = mRootDirectory
			  End If
			End Set
		#tag EndSetter
		WorkingDirectory As String
	#tag EndComputedProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Address"
			Group="Behavior"
			Type="String"
			EditorType="MultiLineEditor"
			InheritedFrom="TCPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowWrite"
			Visible=true
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
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
			Name="Banner"
			Visible=true
			Group="Behavior"
			InitialValue="Welcome to BSFTPd!"
			Type="String"
			EditorType="MultiLineEditor"
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
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
			InheritedFrom="FTPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Password"
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
			InheritedFrom="TCPSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="TimeOutPeriod"
			Visible=true
			Group="Behavior"
			InitialValue="600000"
			Type="Integer"
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
