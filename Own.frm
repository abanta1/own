VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Form1"
   ClientHeight    =   3030
   ClientLeft      =   120
   ClientTop       =   450
   ClientWidth     =   4560
   LinkTopic       =   "Form1"
   ScaleHeight     =   3030
   ScaleWidth      =   4560
   StartUpPosition =   3  'Windows Default
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

' Global constants we must use with security descriptor
Private Const SECURITY_DESCRIPTOR_REVISION = 1
Private Const OWNER_SECURITY_INFORMATION = 1&

' Access Token constants
Private Const TOKEN_ASSIGN_PRIMARY = &H1
Private Const TOKEN_DUPLICATE = &H2
Private Const TOKEN_IMPERSONATE = &H4
Private Const TOKEN_QUERY = &H8
Private Const TOKEN_QUERY_SOURCE = &H10
Private Const TOKEN_ADJUST_PRIVILEGES = &H20
Private Const TOKEN_ADJUST_GROUPS = &H40
Private Const TOKEN_ADJUST_DEFAULT = &H80
Private Const TOKEN_ALL_ACCESS = TOKEN_ASSIGN_PRIMARY _
      + TOKEN_DUPLICATE + TOKEN_IMPERSONATE + TOKEN_QUERY _
      + TOKEN_QUERY_SOURCE + TOKEN_ADJUST_PRIVILEGES _
      + TOKEN_ADJUST_GROUPS + TOKEN_ADJUST_DEFAULT
Private Const ANYSIZE_ARRAY = 1

' Token Privileges constants
Private Const SE_RESTORE_NAME = "SeRestorePrivilege"
Private Const SE_PRIVILEGE_ENABLED = 2&

' ACL structure
Private Type ACL
   AclRevision As Byte
   Sbz1 As Byte
   AclSize As Integer
   AceCount As Integer
   Sbz2 As Integer
End Type

Private Type SECURITY_DESCRIPTOR
   Revision As Byte
   Sbz1 As Byte
   Control As Long
   Owner As Long
   Group As Long
   Sacl As ACL
   Dacl As ACL
End Type

' Token structures
Private Type LARGE_INTEGER
   lowpart As Long
   highpart As Long
End Type

Private Type LUID
   lowpart As Long
   highpart As Long
End Type

Private Type LUID_AND_ATTRIBUTES
   pLuid As LUID
   Attributes As Long
End Type

Private Type TOKEN_PRIVILEGES
   PrivilegeCount As Long
   Privileges(ANYSIZE_ARRAY) As LUID_AND_ATTRIBUTES
End Type

' Win32 API calls
Private Declare Function LookupAccountName Lib "advapi32.dll" _
      Alias "LookupAccountNameA" (ByVal lpSystemName As String, _
      ByVal lpAccountName As String, Sid As Byte, cbSid As Long, _
      ByVal ReferencedDomainName As String, _
      cbReferencedDomainName As Long, peUse As Integer) As Long
      
Private Declare Function InitializeSecurityDescriptor _
      Lib "advapi32.dll" (pSecurityDescriptor As SECURITY_DESCRIPTOR, _
      ByVal dwRevision As Long) As Long
      
Private Declare Function SetSecurityDescriptorOwner _
      Lib "advapi32.dll" (pSecurityDescriptor As SECURITY_DESCRIPTOR, _
      pOwner As Any, ByVal bOwnerDefaulted As Long) As Long
      
Private Declare Function SetFileSecurity Lib "advapi32.dll" _
      Alias "SetFileSecurityA" (ByVal lpFileName As String, _
      ByVal SecurityInformation As Long, _
      pSecurityDescriptor As SECURITY_DESCRIPTOR) As Long
      
Private Declare Function OpenProcessToken Lib "advapi32.dll" _
      (ByVal ProcessHandle As Long, ByVal DesiredAccess As Long, _
      TokenHandle As Long) As Long
      
Private Declare Function GetCurrentProcess Lib "kernel32" () As Long

Private Declare Function LookupPrivilegeValue Lib "advapi32.dll" _
      Alias "LookupPrivilegeValueA" (ByVal lpSystemName As String, _
      ByVal lpName As String, lpLuid As LUID) As Long
      
Private Declare Function AdjustTokenPrivileges Lib "advapi32.dll" _
      (ByVal TokenHandle As Long, ByVal DisableAllPrivileges As Long, _
      NewState As TOKEN_PRIVILEGES, ByVal BufferLength As Long, _
      ByVal PreviousState As Long, ByVal ReturnLength As Long) As Long
      
Private Declare Function CloseHandle Lib "kernel32" _
      (ByVal hObject As Long) As Long

Public Function ChangeOwnerOfFile(FileName As String, _
      OwnerAccountName As String)

   ' variables for the LookupAccountName API Call
   Dim Sid(255) As Byte             ' Buffer for the SID
   Dim nBufferSize As Long          ' Length of SID Buffer
   Dim szDomainName As String * 255 ' Domain Name Buffer
   Dim nDomain As Long              ' Length of Domain Name buffer
   Dim peUse As Integer             ' SID type
   Dim Result As Long               ' Return value of Win32 API call
   
   ' variables for the InitializeSecurityDescriptor API Call
   Dim SecDesc As SECURITY_DESCRIPTOR
   Dim Revision As Long
   
   Enable_Privilege (SE_RESTORE_NAME)
   
   nBufferSize = 255
   nDomain = 255
   
   Result = LookupAccountName(vbNullString, OwnerAccountName, _
         Sid(0), nBufferSize, szDomainName, nDomain, peUse)
   If (Result = 0) Then
      MsgBox "Couldn't find that account name, check and try again"
      'MsgBox "LookupAccountName failed with error code " & Err.LastDllError
      Exit Function
   End If
   
   Result = InitializeSecurityDescriptor(SecDesc, _
         SECURITY_DESCRIPTOR_REVISION)
   If (Result = 0) Then
      MsgBox "Follow the instructions, Try Again!"
      'MsgBox "InitializeSecurityDescriptor failed with error code " & Err.LastDllError
      End
      Exit Function
   End If
   
   Result = SetSecurityDescriptorOwner(SecDesc, Sid(0), 0)
   If (Result = 0) Then
      MsgBox "Follow the instructions, Try Again!"
      'MsgBox "SetSecurityDescriptorOwner failed with error code " & Err.LastDllError
      End
      Exit Function
   End If
   
   Result = SetFileSecurity(FileName, OWNER_SECURITY_INFORMATION, _
         SecDesc)
   If (Result = 0) Then
      MsgBox "Follow the instructions, Try Again!"
      'MsgBox "SetFileSecurity failed with error code " & Err.LastDllError
      End
      Exit Function
   Else
      MsgBox "Owner of " & FileName & " changed to " & OwnerAccountName
   End If
   Disable_Privilege (SE_RESTORE_NAME)
End Function

Public Function Hello(Text As String) As String
MsgBox Text
End Function

Public Function Enable_Privilege(Privilege As String) As Boolean
   Enable_Privilege = ModifyState(Privilege, True)
End Function

Public Function Disable_Privilege(Privilege As String) As Boolean
   Disable_Privilege = ModifyState(Privilege, False)
End Function

Public Function ModifyState(Privilege As String, _
      Enable As Boolean) As Boolean
    
   Dim MyPrives As TOKEN_PRIVILEGES
   Dim PrivilegeId As LUID
   Dim ptrPriv As Long    ' Pointer to Privileges Structure
   Dim hToken As Long     ' Token Handle
   Dim Result As Long     ' Return Value
   
   Result = OpenProcessToken(GetCurrentProcess(), _
         TOKEN_ADJUST_PRIVILEGES, hToken)
   If (Result = 0) Then
      ModifyState = False
      MsgBox "Follow the instructions, Try Again!"
      'MsgBox "OpenProcessToken failed with error code " _
            & Err.LastDllError
      End
      Exit Function
   End If
   
   Result = LookupPrivilegeValue(vbNullString, Privilege, PrivilegeId)
   If (Result = 0) Then
      ModifyState = False
      MsgBox "Follow the instructions, Try Again!"
      'MsgBox "LookupPrivilegeValue failed with error code " _
            & Err.LastDllError
      End
      Exit Function
   End If
   
   MyPrives.Privileges(0).pLuid = PrivilegeId
   MyPrives.PrivilegeCount = 1
   If (Enable) Then
      MyPrives.Privileges(0).Attributes = SE_PRIVILEGE_ENABLED
   Else
      MyPrives.Privileges(0).Attributes = 0
   End If
    
   Result = AdjustTokenPrivileges(hToken, False, MyPrives, 0, 0, 0)
   If (Result = 0 Or Err.LastDllError <> 0) Then
      ModifyState = False
      MsgBox "Follow the instructions, Try Again!"
      'MsgBox "AdjustTokenPrivileges failed with error code " _
            & Err.LastDllError
      End
      Exit Function
   End If
   
   CloseHandle hToken
   
   ModifyState = True

End Function

Private Sub Form_Load()
Form1.Hide
Dim bob() As String
Dim sue As String
If Command = "" Or Command = "/?" Or InStr(1, Command, ",") = 0 Then
MsgBox "This program will change ownership on a file system object to any user unlike" & vbLf & _
    "takeown (only changes owner to administrators group or current user)" & vbLf & vbLf & _
    "This program has to be run from an elevated prompt" & vbLf & vbLf & _
    "Usage: own.exe C:\path\to\file or folder,username" & vbLf & vbLf & _
    "Do not use quotes around the" & " file path, it doesnt like it!" & vbLf & _
    "Do not put spaces between the path and the username." & vbLf & _
    " You can use a group instead of username."
End
End If

bob = Split(Command, ",")
Dim FolderName As String
FolderName = bob(0)
Dim Username As String
Username = bob(1)

Call ChangeOwnerOfFile(FolderName, Username)
End
'ChangeOwnerOfFile(FolderName,Username)
End Sub
