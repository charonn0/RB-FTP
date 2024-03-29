#tag Class
Protected Class Server
Inherits FTP.Connection
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
		  // Constructor() -- From TCPSocket
		  Super.Constructor
		  Me.ServerFeatures = Array("PASV", "UTF8", "MDTM", "SIZE", "REST STREAM", "TVFS", "MLST", "XPWD", "XCWD")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Sub DoResponse(Code As Integer, Params As String = "")
		  ' Sends an FTP response. If Params is not specified then the
		  ' default message for the Code is used.
		  
		  If Params.Trim = "" Then Params = FTP.FormatCode(Code)
		  params = Trim(Str(Code) + " " + Params)
		  If UTFMode Then params = ConvertEncoding(params, Encodings.UTF8)
		  Me.Write(params + CRLF)
		  FTPLog(params)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_CDUP(Verb As String, Argument As String)
		  ' Move up one directory.
		  
		  #pragma Unused Verb
		  #pragma Unused Argument
		  If RootDirectory.AbsolutePath_ = mWorkingDirectory.Parent.AbsolutePath_ Or ChildOfParent(mWorkingDirectory.Parent, RootDirectory) Then
		    mWorkingDirectory = mWorkingDirectory.Parent
		    DoResponse(250)
		  Else
		    DoResponse(550)
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_CWD(Verb As String, Argument As String)
		  ' Change the working directory
		  
		  #pragma Unused Verb
		  
		  Dim g As FolderItem = FindFile(Argument)
		  
		  If g = Nil Then
		    DoResponse(553, "Name not recognized.")  'bad file
		    Return
		  End If
		  
		  If g.Directory Then
		    mWorkingDirectory = g
		    DoResponse(250)  'OK
		  Else
		    DoResponse(553, "That is not a directory")
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_DELE(Verb As String, Argument As String)
		  ' Delete the specified file.
		  
		  #pragma Unused Verb
		  
		  If Not AllowWrite Then
		    DoResponse(550, "Permission denied.")
		    Return
		  End If
		  
		  Dim g As FolderItem
		  If Argument.Trim <> "" Then
		    g = FindFile(Argument.Trim)
		  End If
		  
		  If g = Nil Then
		    DoResponse(553, "Name not recognized.")
		    Return
		  ElseIf g.Directory Then
		    DoResponse(550, "The DELE command cannot be used on a directory.")
		    Return
		  End If
		  
		  g.Delete()
		  If g.LastErrorCode = 0 Then
		    DoResponse(250, "Delete successful.")
		  Else
		    DoResponse(451, "System error: " + Str(g.LastErrorCode))
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_FEAT(Verb As String, Argument As String)
		  ' Send the list of supported features.
		  
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
		  ' Generate a directory listing.
		  
		  If Not Me.IsDataConnected Then
		    DoResponse(503, "You must use PASV or PORT to open the data connection before using this command.")
		    Return
		  End If
		  
		  If Argument = "-a" or Argument.Trim = "" Then Argument = WorkingDirectory
		  
		  Dim dir As FolderItem = FindFile(Argument)
		  If dir = Nil Then dir = mWorkingDirectory
		  Dim s As String = FileListing(dir, Verb.Trim)
		  
		  Select Case True
		  Case s.Trim = "" And Not dir.Exists
		    DoResponse(550, "That directory does not exist.")
		  Case s.Trim <> ""
		    DoResponse(125)
		    If Me.UTFMode Then
		      s = ConvertEncoding(s, Encodings.UTF8)
		    Else
		      s = ConvertEncoding(s, Encodings.ASCII)
		    End If
		    TransmitData(s)
		  Case dir.Exists
		    DoResponse(150)
		  Else
		    DoResponse(553, "Name not recognized.")
		    Return
		  End Select
		  Me.CloseData
		  DoResponse(226)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_MDTM(Verb As String, Argument As String)
		  ' Query a file's modification date
		  
		  #pragma Unused Verb
		  Dim g As FolderItem
		  If Argument.Trim <> "" Then
		    g = FindFile(Argument.Trim)
		  End If
		  
		  If g = Nil Then
		    DoResponse(550, "Name not recognized.")
		    Return
		  ElseIf g.Directory Then
		    DoResponse(550, "That's a directory.")
		    Return
		  End If
		  
		  Dim d As Date = g.ModificationDate
		  Dim y, m, dy, h, mt, s As String
		  y = Format(d.Year, "0000")
		  m = Format(d.Month, "00")
		  dy = Format(d.Day, "00")
		  h = Format(d.Hour, "00")
		  mt = Format(d.Minute, "00")
		  s = Format(d.Second, "00")
		  DoResponse(213, y + m + dy + h + mt + s)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_MKD(Verb As String, Argument As String)
		  ' Make a new directory
		  
		  #pragma Unused Verb
		  
		  If Not AllowWrite Then
		    DoResponse(550, "Permission denied.")
		    Return
		  End If
		  
		  Dim dir As FolderItem = FindFile(Argument.Trim, True)
		  If dir = Nil Then
		    DoResponse(550, "Invalid directory name.")
		    Return
		  ElseIf dir.Exists Then
		    If dir.Directory Then
		      DoResponse(550, "That directory already exists.")
		    Else
		      DoResponse(550, "A file with that name already exists.")
		    End If
		    Return
		  End If
		  
		  dir.CreateAsFolder
		  If dir.Exists Then
		    DoResponse(257, "The directory was created.")
		  Else
		    DoResponse(550, "The directory was NOT created.")
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_MLST(Verb As String, Argument As String)
		  ' Generate a machine-readable directory listing and send it over the control connection.
		  
		  If Argument = "-a" or Argument.Trim = "" Then Argument = WorkingDirectory
		  
		  Dim dir As FolderItem = FindFile(Argument)
		  If dir = Nil Then dir = Me.mWorkingDirectory
		  Dim s As String = FileListing(dir, Verb.Trim)
		  
		  Select Case True
		  Case s.Trim = "" And Not dir.Exists
		    DoResponse(550, "That directory does not exist.")
		    
		  Case s.Trim <> ""
		    Me.Write("250- Listing " + dir.Name + CRLF)
		    If Me.UTFMode Then
		      s = ConvertEncoding(s, Encodings.UTF8)
		    Else
		      s = ConvertEncoding(s, Encodings.ASCII)
		    End If
		    Me.Write(s)
		    DoResponse(250, "End")
		    
		  Case dir.Exists
		    DoResponse(150)
		    
		  Else
		    DoResponse(553, "Name not recognized.")
		  End Select
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_OPTS(Verb As String, Argument As String)
		  ' Turn an optional server option on or off. Raises the OPTS event.
		  
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
		  ' Checks that the password is valid for the user. Raises the UserLogon event.
		  
		  #pragma Unused Verb
		  Password = Argument.Trim
		  If Username.Trim = "" Then
		    DoResponse(530, "USER not set.")  'USER not set!
		    LoginOK = False
		  ElseIf RaiseEvent UserLogon(Username, Password) Or (Me.Anonymous And Username = "anonymous") Then  'anon users passwords don't matter
		    LoginOK = True
		    DoResponse(230) 'Logged in with pass
		  Else
		    LoginOK = False
		    DoResponse(530, "Invalid USER or PASS.") 'Bad password!
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_PASV(Verb As String, Argument As String)
		  ' Open a new data connection for the client to connect to.
		  
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
		  ' Connects the data connection to the address and port provided by the client.
		  
		  #pragma Unused Verb
		  DoResponse(200, Argument)
		  Me.ConnectData(Argument)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_PWD(Verb As String, Argument As String)
		  ' Print the current working directory
		  
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
		  ' Restart an interrupted transfer
		  
		  #pragma Unused Verb
		  If IsNumeric(Argument.Trim) Then
		    RestartPos = Val(Argument)
		    DoResponse(350)
		  Else
		    DoResponse(554) ' invalid REST param.
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_RETR(Verb As String, Argument As String)
		  ' Transfer a file to the client using the data connection.
		  
		  #pragma Unused Verb
		  If Not Me.IsDataConnected Then
		    DoResponse(503, "You must use PASV or PORT to open the data connection before using this command.")
		    Return
		  End If
		  
		  Dim f As FolderItem = FindFile(Argument)
		  If f = Nil Then
		    DoResponse(451, "Name not recognized.")
		    Return
		  ElseIf f.Directory Then
		    DoResponse(451, "That's a directory.")
		    Return
		  End If
		  
		  DataBuffer = BinaryStream.Open(f)
		  DoResponse(150)
		  RETRTimer = New Timer
		  RETRTimer.Period = 200
		  AddHandler RETRTimer.Action, WeakAddressOf Me.RETRHandler
		  RETRTimer.Mode = Timer.ModeMultiple
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_RMD(Verb As String, Argument As String)
		  ' Remove a directory
		  
		  #pragma Unused Verb
		  
		  If Not AllowWrite Then
		    DoResponse(550, "Permission denied.")
		    Return
		  End If
		  
		  Dim dir As FolderItem = FindFile(Argument.Trim)
		  If dir = Nil Then
		    DoResponse(550, "Invalid directory name.")
		    Return
		  ElseIf Not dir.Exists Then
		    DoResponse(550, "That directory does not exist.")
		    Return
		  End If
		  
		  If dir.Count = 0 Then
		    dir.Delete
		    DoResponse(250, "The directory was deleted successfully.")
		  Else
		    DoResponse(450, "The directory is not empty.")
		  End If
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_RNF(Verb As String, Argument As String)
		  ' Specify a file to be renamed.
		  
		  #pragma Unused Verb
		  
		  If Not AllowWrite Then
		    DoResponse(550, "Permission denied.")
		    Return
		  End If
		  
		  If Argument.Trim = "" Then
		    DoResponse(501, "You must specify a file or directory.")
		    Return
		  End If
		  
		  RNF = FindFile(Argument)
		  If RNF = Nil Then
		    DoResponse(550, "No such file or directory exists.")
		    Return
		  End If
		  
		  DoResponse(350, "The rename operation is pending. Proceed by sending the new name.")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_RNTO(Verb As String, Argument As String)
		  ' Specify the new name in a RNFR operation.
		  
		  #pragma Unused Verb
		  
		  If Not AllowWrite Then
		    DoResponse(550, "Permission denied.")
		    Return
		  ElseIf RNF = Nil Then
		    DoResponse(503, "You must use RNFR before RNTO.")
		    Return
		  ElseIf Argument.Trim = "" Then
		    DoResponse(553, "You must provide a new name with RNTO.")
		    Return
		  End If
		  
		  RNT = FindFile(Argument.Trim, True)
		  If RNT = Nil Then
		    DoResponse(501, "You must specify a new name.")
		    Return
		  End If
		  
		  RNF.MoveFileTo(RNT)
		  If RNF.LastErrorCode = 0 Then
		    DoResponse(250, "Rename successful.")
		  Else
		    DoResponse(451, "System error: " + Str(RNF.LastErrorCode))
		  End If
		  
		  RNF = Nil
		  RNT = Nil
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_SITE(Verb As String, Argument As String)
		  ' Custom/site-specific commands. Raises The SITE event.
		  
		  #pragma Unused Verb
		  Dim code As Integer = 504 ' not implemented
		  Dim msg As String
		  If RaiseEvent SITE(Argument, code, msg) Then Return ' subclass handled it
		  
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
		  
		  DoResponse(code, msg)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DoVerb_SIZE(Verb As String, Argument As String)
		  ' Writes the size of a file to the control connection
		  
		  #pragma Unused Verb
		  Dim g As FolderItem
		  If Argument.Trim <> "" Then
		    g = FindFile(Argument.Trim)
		  End If
		  
		  If g = Nil Then
		    DoResponse(550, "Name not recognized.")
		    Return
		  ElseIf g.Directory Then
		    DoResponse(550, "That's a directory.")
		    Return
		  End If
		  
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
		    Me.Write(" Connected to " + Me.LocalAddress + CRLF)
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
		  ElseIf Not Me.IsDataConnected Then
		    DoResponse(503, "You must use PASV or PORT to open the data connection before using this command.")
		    Return
		  End If
		  
		  Dim saveTo As FolderItem
		  Dim msg As String
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
		      If RestartPos > -1 Then
		        If RestartPos > Me.DataBuffer.Length Then
		          DoResponse(554) ' invalid REST param
		        Else
		          Me.DataBuffer.Position = RestartPos
		        End If
		      Else
		        Me.DataBuffer.Position = Me.DataBuffer.Length
		      End If
		    End If
		    
		    
		  Case "STOU"
		    saveTo = GetTemporaryFolderItem()
		    saveTo.MoveFileTo(mWorkingDirectory.Child(Str(Microseconds)))
		    Me.DataBuffer = BinaryStream.Open(saveTo, True)
		    msg = saveTo.Name
		  End Select
		  
		  DoResponse(150, msg) 'Ready
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
		Protected Function FileListing(Directory As FolderItem, Verb As String) As String
		  ' Generates a file listing for the specified directory in the format
		  ' specified by the Verb
		  
		  Dim listing As New MemoryBlock(0)
		  Dim output As New BinaryStream(listing)
		  Dim count As Integer = Directory.Count
		  
		  For i As Integer = 1 To Count
		    Dim item As FolderItem
		    If Directory.Directory Then item = Directory.Item(i) Else item = Directory
		    Select Case Verb
		    Case "NLST" ' names only
		      output.Write(item.Name + CRLF)
		      Continue
		      
		    Case "LIST" ' The server may use any format
		      ' This implements the Easily Parsed LIST Format: http://cr.yp.to/ftp/list/eplf.html
		      output.Write(Encodings.ASCII.Chr(&o053))
		      If item.IsReadable Then output.Write("r,")
		      If item.Directory Then output.Write("/,") Else output.Write("s" + Str(item.Length) + ",")
		      Dim epoch As New Date(1970, 1, 1, 0, 0, 0, 0) 'UNIX epoch
		      Dim filetime As Date = item.ModificationDate
		      filetime.GMTOffset = 0
		      output.Write("m" + Format(filetime.TotalSeconds - epoch.TotalSeconds, "#####################") + ",")
		      #If TargetMacOS Or TargetLinux Then
		        output.Write("UP" + Format(item.Permissions, "000") + ",")
		      #Else
		        Dim p As Integer
		        If item.IsReadable Then p = p + 4
		        If item.IsWriteable Then p = p + 2
		        p = p + 1 'executable
		        output.Write("UP" + Str(p) + Str(p) + Str(p))
		      #endif
		      output.Write(Encodings.ASCII.Chr(&o011) + item.Name + CRLF)
		      
		    Case "MLST", "MLSD" ' Listings for Machine Processing
		      ' https://tools.ietf.org/html/rfc3659
		      Dim facts() As String
		      If item.Directory Then facts.Append("Type=dir") Else facts.Append("Type=file")
		      If Not item.Directory Then facts.Append("Size=" + Format(item.Length, "#########################0")) Else facts.Append("Type=file")
		      Dim d As Date = item.ModificationDate
		      facts.Append("Modify=" + Str(d.Year, "0000") + Str(d.Month, "00") + Str(d.Day, "00") + Str(d.Hour, "00") + Str(d.Minute, "00") + Str(d.Second, "00"))
		      d = item.CreationDate
		      facts.Append("Create=" + Str(d.Year, "0000") + Str(d.Month, "00") + Str(d.Day, "00") + Str(d.Hour, "00") + Str(d.Minute, "00") + Str(d.Second, "00"))
		      Dim path As String
		      If Verb = "MLSD" Then
		        path = item.Name
		      Else
		        path = FindPath(item)
		      End If
		      output.Write(" " + Join(facts, ";") + " " + path + CRLF)
		      
		    End Select
		  Next
		  output.Close
		  Return listing
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FindFile(Name As String, AllowNonExistant As Boolean = False) As FolderItem
		  Dim out As FolderItem
		  If Left(Name, 1) = "/" Then ' absolute
		    out = RootDirectory
		  Else
		    out = RootDirectory
		    For i As Integer = 0 To CountFields(WorkingDirectory, "/")
		      If NthField(WorkingDirectory, "/", i).Trim <> "" Then
		        out = out.Child(NthField(WorkingDirectory, "/", i).Trim)
		      End If
		    Next
		  End If
		  Dim rootpath As String = RootDirectory.AbsolutePath_
		  
		  For i As Integer = 1 To CountFields(Name, "/")
		    Dim element As String = DecodeURLComponent(NthField(Name, "/", i))
		    If element = "" Then Continue
		    Select Case element.Trim
		    Case ".." ' up one
		      If out.Parent = Nil Then Return Nil ' cannot go up from the volume root
		      Dim pp As String = out.Parent.AbsolutePath_
		      If StrComp(Left(pp, rootpath.Len), rootpath, 0) <> 0 Then Return Nil ' not contained within root; case sensitive
		      out = out.Parent
		    Case ".", "" ' current
		      out = out ' No-op
		    Case Else
		      out = out.Child(element)
		      If Not out.Exists And Not AllowNonExistant Then Return Nil
		    End Select
		  Next
		  Return out
		  
		Exception
		  Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function FindPath(Item As FolderItem) As String
		  Dim s() As String
		  Do Until Item.AbsolutePath_ = mRootDirectory.AbsolutePath_
		    s.Insert(0, Item.Name)
		    Item = Item.Parent
		  Loop Until Item = Nil
		  Return Join(s, "/")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub InactivityHandler(Sender As Timer)
		  //Handles the FTP.Server.InactivityTimer.Action event
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
		  
		  If Not LoginOK And vb <> "USER" And vb <> "PASS" Then
		    DoResponse(530)  'not logged in
		    Return
		  End If
		  
		  Select Case vb.Trim
		  Case "ACCT"
		    DoResponse(202) 'superfluous; not an error
		    
		  Case "CDUP"
		    DoVerb_CDUP(vb, args)
		    
		  Case "CWD", "XCWD"
		    DoVerb_CWD(vb, args)
		    
		  Case "DELE"
		    DoVerb_DELE(vb, args)
		    
		  Case "FEAT"
		    DoVerb_FEAT(vb, args)
		    
		  Case "LIST", "NLST", "MLSD"
		    DoVerb_List(vb, args)
		    
		  Case "MDTM"
		    DoVerb_MDTM(vb, args)
		    
		  Case "MKD"
		    DoVerb_MKD(vb, args)
		    
		  Case "MLST"
		    DoVerb_MLST(vb, args)
		    
		  Case "NOOP" 'Keep alive; no operation
		    DoResponse(200)
		    
		  Case "OPTS"
		    DoVerb_OPTS(vb, args)
		    
		  Case "PASS"
		    DoVerb_PASS(vb, args)
		    
		  Case "PASV"
		    DoVerb_PASV(vb, args)
		    
		  Case "PORT"
		    DoVerb_PORT(vb, args)
		    
		  Case "PWD", "XPWD"
		    DoVerb_PWD(vb, args)
		    
		  Case "QUIT"
		    DoResponse(221, "Goodbye.")
		    Me.Close
		    
		  Case "REST"
		    DoVerb_REST(vb, args)
		    
		  Case "RETR"
		    DoVerb_RETR(vb, args)
		    
		  Case "RMD"
		    DoVerb_RMD(vb, args)
		    
		  Case "RNFR" ' ReNameFRom
		    DoVerb_RNF(vb, args)
		    
		  Case "RNTO" ' ReNameTO
		    DoVerb_RNTO(vb, args)
		    
		  Case "SITE"
		    DoVerb_SITE(vb, args)
		    
		  Case "SIZE"
		    DoVerb_SIZE(vb, args)
		    
		  Case "STAT"
		    DoVerb_STAT(vb, args)
		    
		  Case "STOR", "STORU", "APPE"
		    DoVerb_STOR(vb, args)
		    
		  Case "SYST"
		    'We'll claim to be UNIX even if we aren't
		    DoResponse(215, "UNIX Type: L8")
		    
		  Case "TYPE"
		    DoVerb_TYPE(vb, args)
		    
		  Case "USER"
		    DoVerb_USER(vb, args)
		    
		  Else
		    DoResponse(500)  'syntax error or unknown verb
		    
		  End Select
		  
		Exception Err As RuntimeException
		  If Err IsA EndException Or Err IsA ThreadEndException Then Raise Err
		  DoResponse(500, "Runtime exception")
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RETRHandler(Sender As Timer)
		  //Handles the FTP.Server.RETRTimer.Action event
		  
		  TransmitData(DataBuffer.Read(DataBuffer.Length))
		  DoResponse(226)
		  DataBuffer.Close
		  Me.CloseData()
		  Sender.Mode = Timer.ModeOff
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub STORHandler(Sender As Timer)
		  //Handles the FTP.Server.STORTimer.Action event
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
		Private RestartPos As Integer = -1
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
			  If mTimeOutPeriod > 0 Then
			    InactivityTimer = New Timer
			    InactivityTimer.Period = mTimeOutPeriod
			    AddHandler InactivityTimer.Action, WeakAddressOf InactivityHandler
			    InactivityTimer.Mode = Timer.ModeMultiple
			  Else
			    InactivityTimer = Nil
			  End If
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
			    return Replace(mWorkingDirectory.AbsolutePath_, RootDirectory.AbsolutePath_, "/")
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
