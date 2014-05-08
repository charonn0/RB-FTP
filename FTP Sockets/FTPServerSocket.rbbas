#tag Class
Protected Class FTPServerSocket
Inherits FTPSocket
	#tag Event
		Sub Connected()
		  FTPLog("Remote host connected from " + Me.RemoteAddress + " on port " + Str(Me.Port))
		  DoResponse(220, Banner)
		  RaiseEvent Connected()
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable()
		  Dim i As Integer = InStrB(Me.Lookahead, CRLF)
		  Do Until i <= 0
		    Dim data As String = Me.Read(i + 1)
		    ParseVerb(data)
		    i = InStrB(Me.Lookahead, CRLF)
		  Loop
		  
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
		  #pragma Unused UserAborted
		  Me.CloseData()
		  DoResponse(226, "Transfer complete.")
		End Sub
	#tag EndEvent

	#tag Event
		Function TransferProgress(BytesSent As Integer, BytesLeft As Integer) As Boolean
		  If InactivityTimer <> Nil Then InactivityTimer.Reset()
		  Return RaiseEvent TransferProgress(BytesSent, BytesLeft)
		End Function
	#tag EndEvent


	#tag Method, Flags = &h1000
		Sub Constructor()
		  // Calling the overridden superclass constructor.
		  // Note that this may need modifications if there are multiple constructor choices.
		  // Possible constructor calls:
		  // Constructor() -- From TCPSocket
		  // Constructor() -- From SocketCore
		  Super.Constructor
		  Me.ServerFeatures = Split("PASV UTF8 MDTM SIZE")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub DoResponse(Code As Integer, Params As String = "")
		  If Params.Trim = "" Then Params = FTPCodeToMessage(Code)
		  params = Trim(Str(Code) + " " + Params)
		  If UTFMode Then params = ConvertEncoding(params, Encodings.UTF8)
		  Me.Write(params + CRLF)
		  FTPLog(params)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_CDUP(Verb As String, Argument As String)
		  #pragma Unused Verb
		  #pragma Unused Argument
		  If RootDirectory.AbsolutePath = mWorkingDirectory.Parent.AbsolutePath Or ChildOfParent(mWorkingDirectory.Parent, RootDirectory) Then
		    mWorkingDirectory = mWorkingDirectory.Parent
		    DoResponse(250)
		  Else
		    DoResponse(550)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_CWD(Verb As String, Argument As String)
		  #pragma Unused Verb
		  Dim g As FolderItem = FindFile(Argument)
		  If g <> Nil Then
		    If g.Directory Then
		      mWorkingDirectory = g
		      DoResponse(250)  'OK
		    Else
		      DoResponse(553, "That is not a directory")
		    End If
		    
		  Else
		    DoResponse(553, "Name not recognized.")  'bad file
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_DELE(Verb As String, Argument As String)
		  #pragma Unused Verb
		  
		  If Not AllowWrite Then
		    DoResponse(450, "Permission denied.")
		    Return
		  End If
		  
		  Dim g As FolderItem
		  If Argument.Trim <> "" Then
		    g = FindFile(Argument.Trim)
		  End If
		  
		  If g = Nil Then
		    DoResponse(553, "Name not recognized.")
		  Else
		    If Not g.Directory Then
		      g.Delete
		      If g.LastErrorCode = 0 Then
		        DoResponse(250, "Delete successful.")
		      Else
		        DoResponse(451, "System error: " + Str(g.LastErrorCode))
		      End If
		    Else
		      DoResponse(550, "That's a directory.")
		    End If
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_FEAT(Verb As String, Argument As String)
		  #pragma Unused Verb
		  #pragma Unused Argument
		  Me.Write("211-Features:" + CRLF)
		  For Each feature As String In Me.ServerFeatures
		    Me.Write(" " + feature + CRLF)
		  Next
		  DoResponse(211, "End")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_LIST(Verb As String, Argument As String)
		  If Argument = "-a" or Argument.Trim = "" Then Argument = WorkingDirectory
		  
		  Dim dir As FolderItem = FindFile(Argument)
		  If dir = Nil Then dir = Me.mWorkingDirectory
		  Dim s As String = FileListing(dir, Verb.Trim = "NLST")
		  If s.Trim <> "" Then
		    DoResponse(150)
		    If Me.UTFMode Then
		      s = ConvertEncoding(s, Encodings.UTF8)
		    Else
		      s = ConvertEncoding(s, Encodings.ASCII)
		    End If
		    TransmitData(s)
		  ElseIf dir.Exists Then
		    DoResponse(150)
		  Else
		    DoResponse(550, "That directory does not exist.")
		  End If
		  Me.CloseData
		  DoResponse(226)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_MDTM(Verb As String, Argument As String)
		  #pragma Unused Verb
		  Dim g As FolderItem
		  If Argument.Trim <> "" Then
		    g = FindFile(Argument.Trim)
		  End If
		  
		  If g = Nil Then
		    DoResponse(550, "Name not recognized.")
		  ElseIf g.Directory Then
		    DoResponse(550, "That's a directory.")
		  Else
		    Dim d As Date = g.ModificationDate
		    Dim y, m, dy, h, mt, s As String
		    y = Format(d.Year, "0000")
		    m = Format(d.Month, "00")
		    dy = Format(d.Day, "00")
		    h = Format(d.Hour, "00")
		    mt = Format(d.Minute, "00")
		    s = Format(d.Second, "00")
		    DoResponse(213, y + m + dy + h + mt + s)
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_MKD(Verb As String, Argument As String)
		  #pragma Unused Verb
		  
		  Dim dir As FolderItem = FindFile(Argument.Trim, True)
		  If dir = Nil Then
		    DoResponse(550, "invalid name")
		    Return
		  End If
		  If Not dir.Exists Then
		    dir.CreateAsFolder
		    If dir.Exists Then
		      DoResponse(257, "directory created")
		    Else
		      DoResponse(550, "directory NOT created")
		    End If
		  Else
		    DoResponse(550, "directory already exists")
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_OPTS(Verb As String, Argument As String)
		  #pragma Unused Verb
		  
		  Dim option As String
		  Dim value As Boolean
		  option = NthField(Argument, " ", 1).Trim
		  Argument = Replace(Argument, option, "").Trim
		  If Argument = "ON" Then
		    value = True
		  ElseIf Argument = "OFF" Then
		    value = False
		  Else
		    DoResponse(504)
		    Return 'Error
		  End If
		  Select Case option
		  Case "UTF8"
		    Me.UTFMode = value
		    DoResponse(200)
		  Else
		    If Not OPTS(option, value) Then
		      DoResponse(504)
		    End If
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_PASS(Verb As String, Argument As String)
		  #pragma Unused Verb
		  Password = Argument.Trim
		  If Username.Trim = "" Then
		    DoResponse(530, "USER not set.")  'USER not set!
		    LoginOK = False
		  ElseIf Me.Anonymous And Username = "anonymous" Then
		    Call UserLogon(Username, Password)  'anon users passwords don't matter
		    DoResponse(230) 'Logged in with pass
		    LoginOK = True
		  Else
		    If UserLogon(Username, Password) Then
		      DoResponse(230) 'Logged in with pass
		      LoginOK = True
		    Else
		      DoResponse(530, "Invalid USER or PASS.") 'Bad password!
		      LoginOK = False
		    End If
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_PASV(Verb As String, Argument As String)
		  #pragma Unused Verb
		  #pragma Unused Argument
		  If Not Me.IsDataConnected Then
		    Dim rand As New Random
		    Dim port As Integer = Rand.InRange(1024, 65534)
		    Me.ListenData(port)
		    App.DoEvents(100)
		    DoResponse(227, "Entering Passive Mode (" + Me.PASVAddress + ").")
		  Else
		    DoResponse(125)  //already open
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_PORT(Verb As String, Argument As String)
		  #pragma Unused Verb
		  DoResponse(200, Argument)
		  Me.ConnectData(Argument)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_PWD(Verb As String, Argument As String)
		  #pragma Unused Verb
		  #pragma Unused Argument
		  Dim dir As String = WorkingDirectory
		  If Right(dir, 1) = "\" Or Right(dir, 1) = "/" And dir.Len > 1 Then dir = Left(dir, dir.Len - 1)
		  Do Until InStr(dir, "//") = 0
		    dir = Replace(dir, "//", "/")
		  Loop
		  dir = ReplaceAll(dir, "\", "/")
		  DoResponse(257, """" + dir + """")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_REST(Verb As String, Argument As String)
		  #pragma Unused Verb
		  
		  DataBuffer.Position = Val(Argument)
		  DoResponse(350)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_RETR(Verb As String, Argument As String)
		  #pragma Unused Verb
		  If Me.IsDataConnected Then
		    Dim f As FolderItem = FindFile(Argument)
		    If f <> Nil Then
		      DataBuffer = BinaryStream.Open(f)
		    End If
		    
		    If DataBuffer <> Nil Then
		      DoResponse(150)
		      RETRTimer = New Timer
		      RETRTimer.Period = 200
		      AddHandler RETRTimer.Action, WeakAddressOf Me.RETRHandler
		      RETRTimer.Mode = Timer.ModeMultiple
		    Else
		      DoResponse(451) 'bad file
		    End If
		  Else
		    DoResponse(425) 'No data connection
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_RMD(Verb As String, Argument As String)
		  #pragma Unused Verb
		  
		  Dim dir As FolderItem = FindFile(Argument.Trim)
		  If dir = Nil Then
		    DoResponse(550, "no such directory")
		    Return
		  End If
		  If dir.Exists Then
		    If dir.Count = 0 Then
		      dir.Delete
		      DoResponse(250, "directory deleted")
		    Else
		      DoResponse(450, "directory is not empty")
		    End If
		  Else
		    DoResponse(550, "directory does not exist")
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_RNF(Verb As String, Argument As String)
		  #pragma Unused Verb
		  
		  If AllowWrite Then
		    If Argument.Trim <> "" Then
		      RNF = FindFile(Argument)
		      If RNF <> Nil Then
		        DoResponse(350, "Rename OK. Send new name now.")
		      Else
		        DoResponse(550, "File not found.")
		      End If
		    Else
		      DoResponse(501, "You must specify a file or directory.")
		    End If
		  Else
		    DoResponse(450, "Permission denied.")
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_RNTO(Verb As String, Argument As String)
		  #pragma Unused Verb
		  
		  If AllowWrite Then
		    If RNF <> Nil Then
		      If Argument.Trim <> "" Then
		        RNT = FindFile(Argument.Trim, True)
		        If RNT <> Nil Then
		          Dim newname As String = RNT.Name.Trim
		          RNF.Name = newname
		          If RNF.LastErrorCode = 0 Then
		            DoResponse(250, "Rename successful.")
		          Else
		            DoResponse(451, "System error: " + Str(RNF.LastErrorCode))
		          End If
		        Else
		          DoResponse(501, "You must specify a new name.")
		        End If
		      Else
		        DoResponse(553, "Name not recognized.")
		      End If
		    Else
		      DoResponse(503, "You must use RNFR before RNTO.")
		    End If
		    RNF = Nil
		    RNT = Nil
		    
		  Else
		    DoResponse(450, "Permission denied.")
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_SITE(Verb As String, Argument As String)
		  #pragma Unused Verb
		  Dim code As Integer = 504 ' not implemented
		  Dim msg As String
		  If Not RaiseEvent SITE(Argument, code, msg) Then
		    Select Case NthField(Argument, " ", 1).Trim.Uppercase
		    Case "CHMOD"
		      #If Not TargetWin32 Then
		        Dim f As FolderItem = FindFile(NthField(Argument, " ", 3).Trim)
		        If f <> Nil And AllowWrite Then
		          f.Permissions = Val("&u" + NthField(Argument, " ", 2).Trim)
		          code = 200
		        ElseIf AllowWrite Then
		          code = 451 ' action aborted due to error
		          msg = "Not found."
		        Else
		          code = 450 ' action not taken
		          msg = "Permission denied."
		        End If
		      #Else
		        code = 202 ' not implemented; superfluous
		      #endif
		    End Select
		  End If
		  
		  DoResponse(code, msg)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_SIZE(Verb As String, Argument As String)
		  #pragma Unused Verb
		  Dim g As FolderItem
		  If Argument.Trim <> "" Then
		    g = FindFile(Argument.Trim)
		  End If
		  
		  If g = Nil Then
		    DoResponse(550, "Name not recognized.")
		  ElseIf g.Directory Then
		    DoResponse(550, "That's a directory.")
		  Else
		    Dim bs As BinaryStream = BinaryStream.Open(g, False)
		    Dim data As String
		    Select Case Me.TransferMode
		    Case BinaryMode, LocalMode
		      data = bs.Read(bs.Length)
		      bs.Close
		    Case EBCDICMode
		      data = bs.Read(bs.Length)
		      bs.Close
		      Dim conv As TextConverter = GetTextConverter(Data.Encoding, GetTextEncoding(&h0C01))
		      data = conv.convert(Data)
		      
		    Case ASCIIMode
		      data = bs.Read(bs.Length)
		      bs.Close
		      Dim conv As TextConverter = GetTextConverter(Data.Encoding, Encodings.ASCII)
		      data = conv.convert(Data)
		    End Select
		    DoResponse(213, Format(data.LenB, "######################0"))
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_STAT(Verb As String, Argument As String)
		  #pragma Unused Verb
		  
		  If Argument.Trim <> "" Then ' file status
		    Dim g As FolderItem
		    If Argument.Trim <> "" Then
		      g = FindFile(Argument.Trim)
		    End If
		    
		    If g = Nil Or Not g.Exists Then
		      DoResponse(450, "Name not recognized.")
		    Else
		      Dim listing As String
		      If g.IsReadable Then
		        listing = listing + "r,"
		      End If
		      
		      If g.Directory Then
		        listing = listing + "/,"
		      Else
		        listing = listing + "s" + Str(g.Length) + ","
		      End If
		      
		      Dim epoch As New Date(1970, 1, 1, 0, 0, 0, 0) 'UNIX epoch
		      Dim filetime As Date = g.ModificationDate
		      filetime.GMTOffset = 0
		      listing = listing + "m" + Format(filetime.TotalSeconds - epoch.TotalSeconds, "#####################") + ","
		      #If TargetMacOS Or TargetLinux Then
		        listing = listing + "UP" + Format(g.Permissions, "000") + ","
		      #Else
		        Dim p As Integer
		        If g.IsReadable Then p = p + 4
		        If g.IsWriteable Then p = p + 2
		        p = p + 1 'executable
		        listing = listing + "UP" + Str(p) + Str(p) + Str(p)
		      #endif
		      Dim code As Integer
		      If g.Directory Then
		        code = 213
		      Else
		        code = 212
		      End If
		      Me.Write(Str(Code) + "-Status of " + g.Name + ": " + CRLF)
		      Me.Write(" " + listing + Encodings.ASCII.Chr(&o011) + g.Name + CRLF)
		      DoResponse(code, "End of status")
		    End If
		    
		  Else '  server status
		    Me.Write("211-FTP Server status:" + CRLF)
		    Me.Write(" Connected to " + Me.RemoteAddress + CRLF)
		    Me.Write(" Logged in as " + Me.Username + CRLF)
		    Me.Write(" Session timeout in seconds is " + Format(Me.TimeOutPeriod \ 1000, "###,##0") + CRLF)
		    Select Case Me.TransferMode
		    Case BinaryMode, LocalMode
		      Me.Write(" TYPE: BINARY" + CRLF)
		    Case ASCIIMode
		      Me.Write(" TYPE: ASCII" + CRLF)
		    Case EBCDICMode
		      Me.Write(" TYPE: EBCDIC" + CRLF)
		    End Select
		    DoResponse(211, "End of status")
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_STOR(Verb As String, Argument As String)
		  If Not AllowWrite Then
		    DoResponse(550, "Permission denied.")
		    Return
		  End If
		  If Not Me.IsDataConnected Then
		    DoResponse(425)
		    Return
		  End If
		  
		  Dim saveTo As FolderItem
		  Select Case Verb
		  Case "STOR"
		    saveTo = FindFile(Argument, True)
		    If saveTo.Exists Then
		      DoResponse(450, "Filename taken.")
		      Return
		    Else
		      Me.DataBuffer = BinaryStream.Create(saveTo, False)
		    End If
		    
		  Case "APPE"
		    saveTo = FindFile(Argument, True)
		    If Not saveTo.Exists Then
		      Me.DataBuffer = BinaryStream.Create(saveTo, False)
		    Else
		      Me.DataBuffer = BinaryStream.Open(saveTo, True)
		      Me.DataBuffer.Position = Me.DataBuffer.Length
		    End If
		    
		    
		  Case "STORU"
		    saveTo = GetTemporaryFolderItem()
		    saveTo.MoveFileTo(mWorkingDirectory.Child(Str(Microseconds)))
		    Me.DataBuffer = BinaryStream.Open(saveTo, True)
		  End Select
		  
		  DoResponse(150) 'Ready
		  Me.TransferInProgress = True
		  STORTimer = New Timer
		  STORTimer.Period = 200
		  AddHandler STORTimer.Action, WeakAddressOf Me.STORHandler
		  STORTimer.Mode = Timer.ModeMultiple
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_TYPE(Verb As String, Argument As String)
		  #pragma Unused Verb
		  Select Case Argument.Trim
		  Case "A", "A N"
		    Me.TransferMode = ASCIIMode
		    DoResponse(200)
		  Case "I", "L"
		    Me.TransferMode = BinaryMode
		    DoResponse(200)
		  Case "E"
		    Me.TransferMode = EBCDICMode
		    DoResponse(200)
		  Else
		    DoResponse(504) 'Command not implemented for param
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_USER(Verb As String, Argument As String)
		  #pragma Unused Verb
		  Username = Argument.Trim
		  If Me.Anonymous And Username = "anonymous" Then
		    DoResponse(331, "Anonymous login OK, send e-mail address as password.")
		  Else
		    DoResponse(331) 'Need PASS
		    LoginOK = False
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FileListing(Directory As FolderItem, NamesOnly As Boolean = False) As String
		  Dim listing As String
		  If NamesOnly Then
		    For i As Integer = 1 To Directory.Count
		      listing = listing + Directory.Item(i).Name + CRLF
		    Next
		  Else
		    'http://cr.yp.to/ftp/list/eplf.html
		    Dim count As Integer = Directory.Count
		    For i As Integer = 1 To Count
		      Dim item As FolderItem = Directory.Item(i)
		      listing = listing + Encodings.ASCII.Chr(&o053)
		      If item.IsReadable Then
		        listing = listing + "r,"
		      End If
		      
		      If item.Directory Then
		        listing = listing + "/,"
		      Else
		        listing = listing + "s" + Str(item.Length) + ","
		      End If
		      
		      Dim epoch As New Date(1970, 1, 1, 0, 0, 0, 0) 'UNIX epoch
		      Dim filetime As Date = item.ModificationDate
		      filetime.GMTOffset = 0
		      listing = listing + "m" + Format(filetime.TotalSeconds - epoch.TotalSeconds, "#####################") + ","
		      #If TargetMacOS Or TargetLinux Then
		        listing = listing + "UP" + Format(item.Permissions, "000") + ","
		      #Else
		        Dim p As Integer
		        If item.IsReadable Then p = p + 4
		        If item.IsWriteable Then p = p + 2
		        p = p + 1 'executable
		        listing = listing + "UP" + Str(p) + Str(p) + Str(p)
		      #endif
		      listing = listing + Encodings.ASCII.Chr(&o011) + item.Name + CRLF
		    Next
		  End If
		  'If listing.Trim = "" And Directory <> Nil And Directory.Exists And Directory.Directory Then listing = "." + CRLF + ".." + CRLF
		  Return listing
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FindFile(Name As String, AllowNonExistant As Boolean = False) As FolderItem
		  Name = Name.Trim
		  If Name = "" Then Return mWorkingDirectory
		  If Name = "/" Then Return RootDirectory
		  Dim path As String
		  If Left(Name, 1) = "/" Then 'Relative to root
		    path = RootDirectory.AbsolutePath
		    Name = Right(Name, Name.Len - 1)
		  Else 'Relative to WorkingDir
		    path = RootDirectory.AbsolutePath + WorkingDirectory
		  End If
		  
		  Dim found As FolderItem = GetFolderItem(path + Name)
		  
		  If (found.Exists Or AllowNonExistant) And ChildOfParent(found, Me.RootDirectory) Then
		    Return found
		  End If
		  
		Exception
		  Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub InactivityHandler(Sender As Timer)
		  //Handles the FTPServerSocket.InactivityTimer.Action event
		  If Me.IsConnected Then
		    Sender.Mode = Timer.ModeOff
		    If Me.TimeOutPeriod > 0 Then
		      DoResponse(421, "Inactivity timeout.")
		      Me.Close
		    End If
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Listen()
		  Super.Listen
		  FTPLog("Now listening on port " + Str(Me.Port))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseVerb(Data As String)
		  Dim vb, args As String
		  If UTFMode Then Data = DefineEncoding(Data, Encodings.UTF8)
		  If InStr(Data, " ") > 0 Then
		    vb = NthField(Data, " ", 1)
		    args = Data.Replace(vb + " ", "").Trim
		  Else
		    vb = Data
		  End If
		  
		  FTPLog(vb + " " + args)
		  If InactivityTimer <> Nil Then InactivityTimer.Reset()
		  
		  If LoginOK Or vb = "USER" Or vb = "PASS" Then
		    Select Case vb.Trim
		    Case "USER"
		      DoVerb_USER(vb, args)
		      
		    Case "PASS"
		      DoVerb_PASS(vb, args)
		      
		    Case "RETR"
		      DoVerb_RETR(vb, args)
		      
		    Case "STOR", "STORU", "APPE"
		      Me.DoVerb_STOR(vb, args)
		      
		    Case "SIZE"
		      DoVerb_SIZE(vb, args)
		    Case "MDTM"
		      DoVerb_MDTM(vb, args)
		      
		    Case "STAT"
		      DoVerb_STAT(vb, args)
		      
		    Case "FEAT"
		      DoVerb_FEAT(vb, args)
		      
		    Case "SYST"
		      'We'll claim to be UNIX even if we aren't
		      DoResponse(215, "UNIX Type: L8")
		      
		    Case "CWD", "XCWD"
		      DoVerb_CWD(vb, args)
		      
		    Case "PWD"
		      DoVerb_PWD(vb, args)
		      
		    Case "LIST", "NLST"
		      DoVerb_List(vb, args)
		      
		    Case "CDUP"
		      DoVerb_CDUP(vb, args)
		      
		    Case "PASV"
		      DoVerb_PASV(vb, args)
		      
		    Case "REST"
		      DoVerb_REST(vb, args)
		      
		    Case "PORT"
		      DoVerb_PORT(vb, args)
		      
		    Case "TYPE"
		      DoVerb_TYPE(vb, args)
		      
		    Case "MKD"
		      DoVerb_MKD(vb, args)
		      
		    Case "RMD"
		      DoVerb_RMD(vb, args)
		      
		    Case "DELE"
		      DoVerb_DELE(vb, args)
		      
		    Case "RNFR"
		      DoVerb_RNF(vb, args)
		      
		    Case "RNTO"
		      DoVerb_RNTO(vb, args)
		      
		    Case "QUIT"
		      DoResponse(221, "Bye.")
		      Me.Close
		      
		    Case "NOOP" 'Keep alive; no operation
		      DoResponse(200, "Nothing? I can do that!")
		      
		    Case "OPTS"
		      DoVerb_OPTS(vb, args)
		      
		    Case "SITE"
		      DoVerb_SITE(vb, args)
		      
		    Case "ACCT"
		      DoResponse(202) 'superfluous; not an error
		      
		    Else
		      DoResponse(500)  'syntax error or unknown verb
		      
		    End Select
		  Else
		    DoResponse(530)  'not logged in
		  End If
		  
		Exception Err
		  If Err IsA EndException Or Err IsA ThreadEndException Then Raise Err
		  DoResponse(500, "Runtime exception")
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RETRHandler(Sender As Timer)
		  //Handles the FTPServerSocket.RETRTimer.Action event
		  
		  TransmitData(DataBuffer.Read(DataBuffer.Length))
		  DoResponse(226)
		  DataBuffer.Close
		  Me.CloseData()
		  Sender.Mode = Timer.ModeOff
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub STORHandler(Sender As Timer)
		  //Handles the FTPServerSocket.STORTimer.Action event
		  If Not Me.TransferInProgress Then
		    Sender.Mode = Timer.ModeOff
		    DoResponse(226, "Upload complete")
		    Me.DataBuffer.Write(Me.GetData)
		    Me.DataBuffer.Close
		  End If
		  
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Connected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event OPTS(Name As String, Value As Boolean) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SITE(Arguments As String, ByRef ResponseCode As Integer, ByRef ResponseMessage As String) As Boolean
	#tag EndHook

	#tag Hook, Flags = &h0
		Event TransferProgress(BytesSent As Integer, BytesLeft As Integer) As Boolean
	#tag EndHook

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
		#tag Note
			600000ms = 1 minute
			Set to 0 for no timeout.
		#tag EndNote
		Private mTimeOutPeriod As Integer = 600000
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mWorkingDirectory As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RETRTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RNF As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RNT As FolderItem
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

	#tag Property, Flags = &h21
		Private STORTimer As Timer
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return mTimeOutPeriod
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  mTimeOutPeriod = value
			  InactivityTimer = New Timer
			  InactivityTimer.Period = mTimeOutPeriod
			  AddHandler InactivityTimer.Action, WeakAddressOf InactivityHandler
			  InactivityTimer.Mode = Timer.ModeMultiple
			End Set
		#tag EndSetter
		TimeOutPeriod As Integer
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		UTFMode As Boolean
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
			  Dim g As FolderItem = FindFile(value)
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
			Type="Integer"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
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
			Type="String"
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
			Type="Integer"
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
			Name="UTFMode"
			Group="Behavior"
			Type="Boolean"
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
