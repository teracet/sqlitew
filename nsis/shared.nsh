# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

!macro PostUpdate
  ; PostUpdate is called from both session 0 and from the user session
  ; for service updates, make sure that we only register with the user session
  ; Otherwise ApplicationID::Set can fail intermittently with a file in use error.
  System::Call "kernel32::GetCurrentProcessId() i.r0"
  System::Call "kernel32::ProcessIdToSessionId(i $0, *i ${NSIS_MAX_STRLEN} r9)"

  ${CreateShortcutsLog}

  ; Remove registry entries for non-existent apps and for apps that point to our
  ; install location in the Software\Teracet key and uninstall registry entries
  ; that point to our install location for both HKCU and HKLM.
  SetShellVarContext current  ; Set SHCTX to the current user (e.g. HKCU)
  ${RegCleanMain} "Software\Teracet"
  ${RegCleanUninstall}

  ; setup the application model id registration value
  ${InitHashAppModelId} "$INSTDIR" "Software\Teracet\${AppName}\TaskBarIDs"

  ; Win7 taskbar and start menu link maintenance
  Call FixShortcutAppModelIDs

  ClearErrors
  WriteRegStr HKLM "Software\Teracet" "${BrandShortName}InstallerTest" "Write Test"
  ${If} ${Errors}
    StrCpy $TmpVal "HKCU" ; used primarily for logging
  ${Else}
    SetShellVarContext all    ; Set SHCTX to all users (e.g. HKLM)
    DeleteRegValue HKLM "Software\Teracet" "${BrandShortName}InstallerTest"
    StrCpy $TmpVal "HKLM" ; used primarily for logging
    ${RegCleanMain} "Software\Teracet"
    ${RegCleanUninstall}
    ${SetAppLSPCategories} ${LSP_CATEGORIES}

    ; Win7 taskbar and start menu link maintenance
    Call FixShortcutAppModelIDs

    ; Add the Firewall entries after an update
    Call AddFirewallEntries

    ReadRegStr $0 HKLM "Software\teracet.com\Teracet" "CurrentVersion"
    ${If} "$0" != "${GREVersion}"
      WriteRegStr HKLM "Software\teracet.com\Teracet" "CurrentVersion" "${GREVersion}"
    ${EndIf}
  ${EndIf}

  ; Migrate the application's Start Menu directory to a single shortcut in the
  ; root of the Start Menu Programs directory.
  ${MigrateStartMenuShortcut}

  ; Update lastwritetime of the Start Menu shortcut to clear the tile cache.
  ${If} ${AtLeastWin8}
  ${AndIf} ${FileExists} "$SMPROGRAMS\${BrandFullName}.lnk"
    FileOpen $0 "$SMPROGRAMS\${BrandFullName}.lnk" a
    FileClose $0
  ${EndIf}

  ; Adds a pinned Task Bar shortcut (see MigrateTaskBarShortcut for details).
  ${MigrateTaskBarShortcut}

  ${RemoveDeprecatedKeys}

  ${SetAppKeys}
  ${FixClassKeys}
  ${SetUninstallKeys}

  ; Remove files that may be left behind by the application in the
  ; VirtualStore directory.
  ${CleanVirtualStore}

  ${RemoveDeprecatedFiles}

  ; Fix the distribution.ini file if applicable
  ${FixDistributionsINI}

  RmDir /r /REBOOTOK "$INSTDIR\${TO_BE_DELETED}"

!ifdef MOZ_MAINTENANCE_SERVICE
  Call IsUserAdmin
  Pop $R0
  ${If} $R0 == "true"
  ; Only proceed if we have HKLM write access
  ${AndIf} $TmpVal == "HKLM"
    ; We check to see if the maintenance service install was already attempted.
    ; Since the Maintenance service can be installed either x86 or x64,
    ; always use the 64-bit registry for checking if an attempt was made.
    ${If} ${RunningX64}
      SetRegView 64
    ${EndIf}
    ReadRegDWORD $5 HKLM "Software\Teracet\MaintenanceService" "Attempted"
    ClearErrors
    ${If} ${RunningX64}
      SetRegView lastused
    ${EndIf}

    ; Add the registry keys for allowed certificates.
    ${AddMaintCertKeys}

    ; If the maintenance service is already installed, do nothing.
    ; The maintenance service will launch:
    ; maintenanceservice_installer.exe /Upgrade to upgrade the maintenance
    ; service if necessary.   If the update was done from updater.exe without
    ; the service (i.e. service is failing), updater.exe will do the update of
    ; the service.  The reasons we do not do it here is because we don't want
    ; to have to prompt for limited user accounts when the service isn't used
    ; and we currently call the PostUpdate twice, once for the user and once
    ; for the SYSTEM account.  Also, this would stop the maintenance service
    ; and we need a return result back to the service when run that way.
    ${If} $5 == ""
      ; An install of maintenance service was never attempted.
      ; We know we are an Admin and that we have write access into HKLM
      ; based on the above checks, so attempt to just run the EXE.
      ; In the worst case, in case there is some edge case with the
      ; IsAdmin check and the permissions check, the maintenance service
      ; will just fail to be attempted to be installed.
      nsExec::Exec "$\"$INSTDIR\maintenanceservice_installer.exe$\""
    ${EndIf}
  ${EndIf}
!endif
!macroend
!define PostUpdate "!insertmacro PostUpdate"

; The following empty macros have been kept to avoid compiler errors if they're
; called from other installer files (like common.nsh).
!macro SetAsDefaultAppGlobal
!macroend
!define SetAsDefaultAppGlobal "!insertmacro SetAsDefaultAppGlobal"

!macro HideShortcuts
!macroend
!define HideShortcuts "!insertmacro HideShortcuts"

!macro ShowShortcuts
!macroend
!define ShowShortcuts "!insertmacro ShowShortcuts"

!macro AddAssociationIfNoneExist FILE_TYPE KEY
!macroend
!define AddAssociationIfNoneExist "!insertmacro AddAssociationIfNoneExist"

!macro SetHandlers
!macroend
!define SetHandlers "!insertmacro SetHandlers"

!macro SetStartMenuInternet RegKey
!macroend
!define SetStartMenuInternet "!insertmacro SetStartMenuInternet"

!macro FixShellIconHandler RegKey
!macroend
!define FixShellIconHandler "!insertmacro FixShellIconHandler"

; Add Software\Teracet\ registry entries (uses SHCTX).
!macro SetAppKeys
  ; Check if this is an ESR release and if so add registry values so it is
  ; possible to determine that this is an ESR install (bug 726781).
  ClearErrors
  ${WordFind} "${UpdateChannel}" "esr" "E#" $3
  ${If} ${Errors}
    StrCpy $3 ""
  ${Else}
    StrCpy $3 " ESR"
  ${EndIf}

  ${GetLongPath} "$INSTDIR" $8
  StrCpy $0 "Software\Teracet\${BrandFullNameInternal}\${AppVersion}$3 (${ARCH} ${AB_CD})\Main"
  ${WriteRegStr2} $TmpVal "$0" "Install Directory" "$8" 0
  ${WriteRegStr2} $TmpVal "$0" "PathToExe" "$8\${FileMainEXE}" 0

  StrCpy $0 "Software\Teracet\${BrandFullNameInternal}\${AppVersion}$3 (${ARCH} ${AB_CD})\Uninstall"
  ${WriteRegStr2} $TmpVal "$0" "Description" "${BrandFullNameInternal} ${AppVersion}$3 (${ARCH} ${AB_CD})" 0

  StrCpy $0 "Software\Teracet\${BrandFullNameInternal}\${AppVersion}$3 (${ARCH} ${AB_CD})"
  ${WriteRegStr2} $TmpVal  "$0" "" "${AppVersion}$3 (${ARCH} ${AB_CD})" 0
  ${If} "$3" == ""
    DeleteRegValue SHCTX "$0" "ESR"
  ${Else}
    ${WriteRegDWORD2} $TmpVal "$0" "ESR" 1 0
  ${EndIf}

  StrCpy $0 "Software\Teracet\${BrandFullNameInternal} ${AppVersion}$3\bin"
  ${WriteRegStr2} $TmpVal "$0" "PathToExe" "$8\${FileMainEXE}" 0

  StrCpy $0 "Software\Teracet\${BrandFullNameInternal} ${AppVersion}$3\extensions"
  ${WriteRegStr2} $TmpVal "$0" "Components" "$8\components" 0
  ${WriteRegStr2} $TmpVal "$0" "Plugins" "$8\plugins" 0

  StrCpy $0 "Software\Teracet\${BrandFullNameInternal} ${AppVersion}$3"
  ${WriteRegStr2} $TmpVal "$0" "GeckoVer" "${GREVersion}" 0
  ${If} "$3" == ""
    DeleteRegValue SHCTX "$0" "ESR"
  ${Else}
    ${WriteRegDWORD2} $TmpVal "$0" "ESR" 1 0
  ${EndIf}

  StrCpy $0 "Software\Teracet\${BrandFullNameInternal}$3"
  ${WriteRegStr2} $TmpVal "$0" "" "${GREVersion}" 0
  ${WriteRegStr2} $TmpVal "$0" "CurrentVersion" "${AppVersion}$3 (${ARCH} ${AB_CD})" 0
!macroend
!define SetAppKeys "!insertmacro SetAppKeys"

; Add uninstall registry entries. This macro tests for write access to determine
; if the uninstall keys should be added to HKLM or HKCU.
!macro SetUninstallKeys
  ; Check if this is an ESR release and if so add registry values so it is
  ; possible to determine that this is an ESR install (bug 726781).
  ClearErrors
  ${WordFind} "${UpdateChannel}" "esr" "E#" $3
  ${If} ${Errors}
    StrCpy $3 ""
  ${Else}
    StrCpy $3 " ESR"
  ${EndIf}

  StrCpy $0 "Software\Microsoft\Windows\CurrentVersion\Uninstall\${BrandFullNameInternal} ${AppVersion}$3 (${ARCH} ${AB_CD})"

  StrCpy $2 ""
  ClearErrors
  WriteRegStr HKLM "$0" "${BrandShortName}InstallerTest" "Write Test"
  ${If} ${Errors}
    ; If the uninstall keys already exist in HKLM don't create them in HKCU
    ClearErrors
    ReadRegStr $2 "HKLM" $0 "DisplayName"
    ${If} $2 == ""
      ; Otherwise we don't have any keys for this product in HKLM so proceeed
      ; to create them in HKCU.  Better handling for this will be done in:
      ; Bug 711044 - Better handling for 2 uninstall icons
      StrCpy $1 "HKCU"
      SetShellVarContext current  ; Set SHCTX to the current user (e.g. HKCU)
    ${EndIf}
    ClearErrors
  ${Else}
    StrCpy $1 "HKLM"
    SetShellVarContext all     ; Set SHCTX to all users (e.g. HKLM)
    DeleteRegValue HKLM "$0" "${BrandShortName}InstallerTest"
  ${EndIf}

  ${If} $2 == ""
    ${GetLongPath} "$INSTDIR" $8

    ; Write the uninstall registry keys
    ${WriteRegStr2} $1 "$0" "Comments" "${BrandFullNameInternal} ${AppVersion}$3 (${ARCH} ${AB_CD})" 0
    ${WriteRegStr2} $1 "$0" "DisplayIcon" "$8\${FileMainEXE},0" 0
    ${WriteRegStr2} $1 "$0" "DisplayName" "${BrandFullNameInternal} ${AppVersion}$3 (${ARCH} ${AB_CD})" 0
    ${WriteRegStr2} $1 "$0" "DisplayVersion" "${AppVersion}" 0
    ${WriteRegStr2} $1 "$0" "HelpLink" "${HelpLink}" 0
    ${WriteRegStr2} $1 "$0" "InstallLocation" "$8" 0
    ${WriteRegStr2} $1 "$0" "Publisher" "Teracet" 0
    ${WriteRegStr2} $1 "$0" "UninstallString" "$\"$8\uninstall\helper.exe$\"" 0
    DeleteRegValue SHCTX "$0" "URLInfoAbout"
; Don't add URLUpdateInfo which is the release notes url except for the release
; and esr channels since nightly, aurora, and beta do not have release notes.
; Note: URLUpdateInfo is only defined in the official branding.nsi.
!ifdef URLUpdateInfo
!ifndef BETA_UPDATE_CHANNEL
    ${WriteRegStr2} $1 "$0" "URLUpdateInfo" "${URLUpdateInfo}" 0
!endif
!endif
    ${WriteRegStr2} $1 "$0" "URLInfoAbout" "${URLInfoAbout}" 0
    ${WriteRegDWORD2} $1 "$0" "NoModify" 1 0
    ${WriteRegDWORD2} $1 "$0" "NoRepair" 1 0

    ${GetSize} "$8" "/S=0K" $R2 $R3 $R4
    ${WriteRegDWORD2} $1 "$0" "EstimatedSize" $R2 0

    ${If} "$TmpVal" == "HKLM"
      SetShellVarContext all     ; Set SHCTX to all users (e.g. HKLM)
    ${Else}
      SetShellVarContext current  ; Set SHCTX to the current user (e.g. HKCU)
    ${EndIf}
  ${EndIf}
!macroend
!define SetUninstallKeys "!insertmacro SetUninstallKeys"

; The following empty macros have been kept to avoid compiler errors if they're
; called from other installer files (like common.nsh).
!macro FixBadFileAssociation FILE_TYPE
!macroend
!define FixBadFileAssociation "!insertmacro FixBadFileAssociation"

!macro FixClassKeys
!macroend
!define FixClassKeys "!insertmacro FixClassKeys"

!macro UpdateProtocolHandlers
!macroend
!define UpdateProtocolHandlers "!insertmacro UpdateProtocolHandlers"

!ifdef MOZ_MAINTENANCE_SERVICE
; Adds maintenance service certificate keys for the install dir.
; For the cert to work, it must also be signed by a trusted cert for the user.
!macro AddMaintCertKeys
  Push $R0
  ; Allow main Mozilla cert information for updates
  ; This call will push the needed key on the stack
  ServicesHelper::PathToUniqueRegistryPath "$INSTDIR"
  Pop $R0
  ${If} $R0 != ""
    ; More than one certificate can be specified in a different subfolder
    ; for example: $R0\1, but each individual binary can be signed
    ; with at most one certificate.  A fallback certificate can only be used
    ; if the binary is replaced with a different certificate.
    ; We always use the 64bit registry for certs.
    ${If} ${RunningX64}
      SetRegView 64
    ${EndIf}

    ; PrefetchProcessName was originally used to experiment with deleting
    ; Windows prefetch as a speed optimization.  It is no longer used though.
    DeleteRegValue HKLM "$R0" "prefetchProcessName"

    ; Setting the Attempted value will ensure that a new Maintenance Service
    ; install will never be attempted again after this from updates.  The value
    ; is used only to see if updates should attempt new service installs.
    WriteRegDWORD HKLM "Software\Teracet\MaintenanceService" "Attempted" 1

    ; These values associate the allowed certificates for the current
    ; installation.
    WriteRegStr HKLM "$R0\0" "name" "${CERTIFICATE_NAME}"
    WriteRegStr HKLM "$R0\0" "issuer" "${CERTIFICATE_ISSUER}"
    ; These values associate the allowed certificates for the previous
    ; installation, so that we can update from it cleanly using the
    ; old updater.exe (which will still have this signature).
    WriteRegStr HKLM "$R0\1" "name" "${CERTIFICATE_NAME_PREVIOUS}"
    WriteRegStr HKLM "$R0\1" "issuer" "${CERTIFICATE_ISSUER_PREVIOUS}"
    ${If} ${RunningX64}
      SetRegView lastused
    ${EndIf}
    ClearErrors
  ${EndIf}
  ; Restore the previously used value back
  Pop $R0
!macroend
!define AddMaintCertKeys "!insertmacro AddMaintCertKeys"
!endif

; Removes various registry entries for reasons noted below (does not use SHCTX).
!macro RemoveDeprecatedKeys
  StrCpy $0 "SOFTWARE\Classes"
  ; Remove support for launching chrome urls from the shell during install or
  ; update if the DefaultIcon is from firefox.exe (Bug 301073).
  ${RegCleanAppHandler} "chrome"

  ; Remove protocol handler registry keys added by the MS shim
  DeleteRegKey HKLM "Software\Classes\Firefox.URL"
  DeleteRegKey HKCU "Software\Classes\Firefox.URL"
!macroend
!define RemoveDeprecatedKeys "!insertmacro RemoveDeprecatedKeys"

; Removes various directories and files for reasons noted below.
!macro RemoveDeprecatedFiles
  ; Remove talkback if it is present (remove after bug 386760 is fixed)
  ${If} ${FileExists} "$INSTDIR\extensions\talkback@mozilla.org"
    RmDir /r /REBOOTOK "$INSTDIR\extensions\talkback@mozilla.org"
  ${EndIf}

  ; Remove the Java Console extension (bug 1165156)
  ${If} ${FileExists} "$INSTDIR\extensions\{CAFEEFAC-0016-0000-0031-ABCDEFFEDCBA}"
    RmDir /r /REBOOTOK "$INSTDIR\extensions\{CAFEEFAC-0016-0000-0031-ABCDEFFEDCBA}"
  ${EndIf}
  ${If} ${FileExists} "$INSTDIR\extensions\{CAFEEFAC-0016-0000-0034-ABCDEFFEDCBA}"
    RmDir /r /REBOOTOK "$INSTDIR\extensions\{CAFEEFAC-0016-0000-0034-ABCDEFFEDCBA}"
  ${EndIf}
  ${If} ${FileExists} "$INSTDIR\extensions\{CAFEEFAC-0016-0000-0039-ABCDEFFEDCBA}"
    RmDir /r /REBOOTOK "$INSTDIR\extensions\{CAFEEFAC-0016-0000-0039-ABCDEFFEDCBA}"
  ${EndIf}
  ${If} ${FileExists} "$INSTDIR\extensions\{CAFEEFAC-0016-0000-0045-ABCDEFFEDCBA}"
    RmDir /r /REBOOTOK "$INSTDIR\extensions\{CAFEEFAC-0016-0000-0045-ABCDEFFEDCBA}"
  ${EndIf}
  ${If} ${FileExists} "$INSTDIR\extensions\{CAFEEFAC-0017-0000-0000-ABCDEFFEDCBA}"
    RmDir /r /REBOOTOK "$INSTDIR\extensions\{CAFEEFAC-0017-0000-0000-ABCDEFFEDCBA}"
  ${EndIf}
!macroend
!define RemoveDeprecatedFiles "!insertmacro RemoveDeprecatedFiles"

; Converts specific partner distribution.ini from ansi to utf-8 (bug 882989)
!macro FixDistributionsINI
  StrCpy $1 "$INSTDIR\distribution\distribution.ini"
  StrCpy $2 "$INSTDIR\distribution\utf8fix"
  StrCpy $0 "0" ; Default to not attempting to fix

  ; Check if the distribution.ini settings are for a partner build that needs
  ; to have its distribution.ini converted from ansi to utf-8.
  ${If} ${FileExists} "$1"
    ${Unless} ${FileExists} "$2"
      ReadINIStr $3 "$1" "Preferences" "app.distributor"
      ${If} "$3" == "yahoo"
        ReadINIStr $3 "$1" "Preferences" "app.distributor.channel"
        ${If} "$3" == "de"
        ${OrIf} "$3" == "es"
        ${OrIf} "$3" == "e1"
        ${OrIf} "$3" == "mx"
          StrCpy $0 "1"
        ${EndIf}
      ${EndIf}
      ; Create the utf8fix so this only runs once
      FileOpen $3 "$2" w
      FileClose $3
    ${EndUnless}
  ${EndIf}

  ${If} "$0" == "1"
    StrCpy $0 "0"
    ClearErrors
    ReadINIStr $3 "$1" "Global" "version"
    ${Unless} ${Errors}
      StrCpy $4 "$3" 2
      ${If} "$4" == "1."
        StrCpy $4 "$3" "" 2 ; Everything after "1."
        ${If} $4 < 23
          StrCpy $0 "1"
        ${EndIf}
      ${EndIf}
    ${EndUnless}
  ${EndIf}

  ${If} "$0" == "1"
    ClearErrors
    FileOpen $3 "$1" r
    ${If} ${Errors}
      FileClose $3
    ${Else}
      StrCpy $2 "$INSTDIR\distribution\distribution.new"
      ClearErrors
      FileOpen $4 "$2" w
      ${If} ${Errors}
        FileClose $3
        FileClose $4
      ${Else}
        StrCpy $0 "0" ; Default to not replacing the original distribution.ini
        ${Do}
          FileReadByte $3 $5
          ${If} $5 == ""
            ${Break}
          ${EndIf}
          ${If} $5 == 233 ; ansi é
            StrCpy $0 "1"
            FileWriteByte $4 195
            FileWriteByte $4 169
          ${ElseIf} $5 == 241 ; ansi ñ
            StrCpy $0 "1"
            FileWriteByte $4 195
            FileWriteByte $4 177
          ${ElseIf} $5 == 252 ; ansi ü
            StrCpy $0 "1"
            FileWriteByte $4 195
            FileWriteByte $4 188
          ${ElseIf} $5 < 128
            FileWriteByte $4 $5
          ${EndIf}
        ${Loop}
        FileClose $3
        FileClose $4
        ${If} "$0" == "1"
          ClearErrors
          Rename "$1" "$1.bak"
          ${Unless} ${Errors}
            Rename "$2" "$1"
            Delete "$1.bak"
          ${EndUnless}
        ${Else}
          Delete "$2"
        ${EndIf}
      ${EndIf}
    ${EndIf}
  ${EndIf}
!macroend
!define FixDistributionsINI "!insertmacro FixDistributionsINI"

; Adds a pinned shortcut to Task Bar on update for Windows 7 and above if this
; macro has never been called before and the application is default (see
; PinToTaskBar for more details).
; Since defaults handling is handled by Windows in Win8 and later, we always
; attempt to pin a taskbar on that OS.  If Windows sets the defaults at
; installation time, then we don't get the opportunity to run this code at
; that time.
!macro MigrateTaskBarShortcut
  ${GetShortcutsLogPath} $0
  ${If} ${FileExists} "$0"
    ClearErrors
    ReadINIStr $1 "$0" "TASKBAR" "Migrated"
    ${If} ${Errors}
      ClearErrors
      WriteIniStr "$0" "TASKBAR" "Migrated" "true"
      ${If} ${AtLeastWin7}
        ; If we didn't run the stub installer, AddTaskbarSC will be empty.
        ; We determine whether to pin based on whether we're the default
        ; browser, or if we're on win8 or later, we always pin.
        ${If} $AddTaskbarSC == ""
          ; No need to check the default on Win8 and later
          ${If} ${AtMostWin2008R2}
            ; Check if the Firefox is the http handler for this user
            SetShellVarContext current ; Set SHCTX to the current user
            ${IsHandlerForInstallDir} "http" $R9
            ${If} $TmpVal == "HKLM"
              SetShellVarContext all ; Set SHCTX to all users
            ${EndIf}
          ${EndIf}
          ${If} "$R9" == "true"
          ${OrIf} ${AtLeastWin8}
            ${PinToTaskBar}
          ${EndIf}
        ${ElseIf} $AddTaskbarSC == "1"
          ${PinToTaskBar}
        ${EndIf}
      ${EndIf}
    ${EndIf}
  ${EndIf}
!macroend
!define MigrateTaskBarShortcut "!insertmacro MigrateTaskBarShortcut"

; Adds a pinned Task Bar shortcut on Windows 7 if there isn't one for the main
; application executable already. Existing pinned shortcuts for the same
; application model ID must be removed first to prevent breaking the pinned
; item's lists but multiple installations with the same application model ID is
; an edgecase. If removing existing pinned shortcuts with the same application
; model ID removes a pinned pinned Start Menu shortcut this will also add a
; pinned Start Menu shortcut.
!macro PinToTaskBar
  ${If} ${AtLeastWin7}
    StrCpy $8 "false" ; Whether a shortcut had to be created
    ${IsPinnedToTaskBar} "$INSTDIR\${FileMainEXE}" $R9
    ${If} "$R9" == "false"
      ; Find an existing Start Menu shortcut or create one to use for pinning
      ${GetShortcutsLogPath} $0
      ${If} ${FileExists} "$0"
        ClearErrors
        ReadINIStr $1 "$0" "STARTMENU" "Shortcut0"
        ${Unless} ${Errors}
          SetShellVarContext all ; Set SHCTX to all users
          ${Unless} ${FileExists} "$SMPROGRAMS\$1"
            SetShellVarContext current ; Set SHCTX to the current user
            ${Unless} ${FileExists} "$SMPROGRAMS\$1"
              StrCpy $8 "true"
              CreateShortCut "$SMPROGRAMS\$1" "$INSTDIR\${FileMainEXE}"
              ${If} ${FileExists} "$SMPROGRAMS\$1"
                ShellLink::SetShortCutWorkingDirectory "$SMPROGRAMS\$1" \
                                                       "$INSTDIR"
                ${If} "$AppUserModelID" != ""
                  ApplicationID::Set "$SMPROGRAMS\$1" "$AppUserModelID" "true"
                ${EndIf}
              ${EndIf}
            ${EndUnless}
          ${EndUnless}

          ${If} ${FileExists} "$SMPROGRAMS\$1"
            ; Count of Start Menu pinned shortcuts before unpinning.
            ${PinnedToStartMenuLnkCount} $R9

            ; Having multiple shortcuts pointing to different installations with
            ; the same AppUserModelID (e.g. side by side installations of the
            ; same version) will make the TaskBar shortcut's lists into an bad
            ; state where the lists are not shown. To prevent this first
            ; uninstall the pinned item.
            ApplicationID::UninstallPinnedItem "$SMPROGRAMS\$1"

            ; Count of Start Menu pinned shortcuts after unpinning.
            ${PinnedToStartMenuLnkCount} $R8

            ; If there is a change in the number of Start Menu pinned shortcuts
            ; assume that unpinning unpinned a side by side installation from
            ; the Start Menu and pin this installation to the Start Menu.
            ${Unless} $R8 == $R9
              ; Pin the shortcut to the Start Menu. 5381 is the shell32.dll
              ; resource id for the "Pin to Start Menu" string.
              InvokeShellVerb::DoIt "$SMPROGRAMS" "$1" "5381"
            ${EndUnless}

            ; Pin the shortcut to the TaskBar. 5386 is the shell32.dll resource
            ; id for the "Pin to Taskbar" string.
            InvokeShellVerb::DoIt "$SMPROGRAMS" "$1" "5386"

            ; Delete the shortcut if it was created
            ${If} "$8" == "true"
              Delete "$SMPROGRAMS\$1"
            ${EndIf}
          ${EndIf}

          ${If} $TmpVal == "HKCU"
            SetShellVarContext current ; Set SHCTX to the current user
          ${Else}
            SetShellVarContext all ; Set SHCTX to all users
          ${EndIf}
        ${EndUnless}
      ${EndIf}
    ${EndIf}
  ${EndIf}
!macroend
!define PinToTaskBar "!insertmacro PinToTaskBar"

; Adds a shortcut to the root of the Start Menu Programs directory if the
; application's Start Menu Programs directory exists with a shortcut pointing to
; this installation directory. This will also remove the old shortcuts and the
; application's Start Menu Programs directory by calling the RemoveStartMenuDir
; macro.
!macro MigrateStartMenuShortcut
  ${GetShortcutsLogPath} $0
  ${If} ${FileExists} "$0"
    ClearErrors
    ReadINIStr $5 "$0" "SMPROGRAMS" "RelativePathToDir"
    ${Unless} ${Errors}
      ClearErrors
      ReadINIStr $1 "$0" "STARTMENU" "Shortcut0"
      ${If} ${Errors}
        ; The STARTMENU ini section doesn't exist.
        ${LogStartMenuShortcut} "${BrandFullName}.lnk"
        ${GetLongPath} "$SMPROGRAMS" $2
        ${GetLongPath} "$2\$5" $1
        ${If} "$1" != ""
          ClearErrors
          ReadINIStr $3 "$0" "SMPROGRAMS" "Shortcut0"
          ${Unless} ${Errors}
            ${If} ${FileExists} "$1\$3"
              ShellLink::GetShortCutTarget "$1\$3"
              Pop $4
              ${If} "$INSTDIR\${FileMainEXE}" == "$4"
                CreateShortCut "$SMPROGRAMS\${BrandFullName}.lnk" \
                               "$INSTDIR\${FileMainEXE}"
                ${If} ${FileExists} "$SMPROGRAMS\${BrandFullName}.lnk"
                  ShellLink::SetShortCutWorkingDirectory "$SMPROGRAMS\${BrandFullName}.lnk" \
                                                         "$INSTDIR"
                  ${If} ${AtLeastWin7}
                  ${AndIf} "$AppUserModelID" != ""
                    ApplicationID::Set "$SMPROGRAMS\${BrandFullName}.lnk" \
                                       "$AppUserModelID" "true"
                  ${EndIf}
                ${EndIf}
              ${EndIf}
            ${EndIf}
          ${EndUnless}
        ${EndIf}
      ${EndIf}
      ; Remove the application's Start Menu Programs directory, shortcuts, and
      ; ini section.
      ${RemoveStartMenuDir}
    ${EndUnless}
  ${EndIf}
!macroend
!define MigrateStartMenuShortcut "!insertmacro MigrateStartMenuShortcut"

; Removes the application's start menu directory along with its shortcuts if
; they exist and if they exist creates a start menu shortcut in the root of the
; start menu directory (bug 598779). If the application's start menu directory
; is not empty after removing the shortucts the directory will not be removed
; since these additional items were not created by the installer (uses SHCTX).
!macro RemoveStartMenuDir
  ${GetShortcutsLogPath} $0
  ${If} ${FileExists} "$0"
    ; Delete Start Menu Programs shortcuts, directory if it is empty, and
    ; parent directories if they are empty up to but not including the start
    ; menu directory.
    ${GetLongPath} "$SMPROGRAMS" $1
    ClearErrors
    ReadINIStr $2 "$0" "SMPROGRAMS" "RelativePathToDir"
    ${Unless} ${Errors}
      ${GetLongPath} "$1\$2" $2
      ${If} "$2" != ""
        ; Delete shortucts in the Start Menu Programs directory.
        StrCpy $3 0
        ${Do}
          ClearErrors
          ReadINIStr $4 "$0" "SMPROGRAMS" "Shortcut$3"
          ; Stop if there are no more entries
          ${If} ${Errors}
            ${ExitDo}
          ${EndIf}
          ${If} ${FileExists} "$2\$4"
            ShellLink::GetShortCutTarget "$2\$4"
            Pop $5
            ${If} "$INSTDIR\${FileMainEXE}" == "$5"
              Delete "$2\$4"
            ${EndIf}
          ${EndIf}
          IntOp $3 $3 + 1 ; Increment the counter
        ${Loop}
        ; Delete Start Menu Programs directory and parent directories
        ${Do}
          ; Stop if the current directory is the start menu directory
          ${If} "$1" == "$2"
            ${ExitDo}
          ${EndIf}
          ClearErrors
          RmDir "$2"
          ; Stop if removing the directory failed
          ${If} ${Errors}
            ${ExitDo}
          ${EndIf}
          ${GetParent} "$2" $2
        ${Loop}
      ${EndIf}
      DeleteINISec "$0" "SMPROGRAMS"
    ${EndUnless}
  ${EndIf}
!macroend
!define RemoveStartMenuDir "!insertmacro RemoveStartMenuDir"

; Creates the shortcuts log ini file with the appropriate entries if it doesn't
; already exist.
!macro CreateShortcutsLog
  ${GetShortcutsLogPath} $0
  ${Unless} ${FileExists} "$0"
    ${LogStartMenuShortcut} "${BrandFullName}.lnk"
    ${LogQuickLaunchShortcut} "${BrandFullName}.lnk"
    ${LogDesktopShortcut} "${BrandFullName}.lnk"
  ${EndUnless}
!macroend
!define CreateShortcutsLog "!insertmacro CreateShortcutsLog"

; The files to check if they are in use during (un)install so the restart is
; required message is displayed. All files must be located in the $INSTDIR
; directory.
!macro PushFilesToCheck
  ; The first string to be pushed onto the stack MUST be "end" to indicate
  ; that there are no more files to check in $INSTDIR and the last string
  ; should be ${FileMainEXE} so if it is in use the CheckForFilesInUse macro
  ; returns after the first check.
  Push "end"
  Push "AccessibleMarshal.dll"
  Push "IA2Marshal.dll"
  Push "freebl3.dll"
  Push "nssckbi.dll"
  Push "nspr4.dll"
  Push "nssdbm3.dll"
  Push "mozsqlite3.dll"
  Push "xpcom.dll"
  Push "crashreporter.exe"
  Push "minidump-analyzer.exe"
  Push "pingsender.exe"
  Push "updater.exe"
  Push "${FileMainEXE}"
!macroend
!define PushFilesToCheck "!insertmacro PushFilesToCheck"


; Pushes the string "true" to the top of the stack if the Firewall service is
; running and pushes the string "false" to the top of the stack if it isn't.
!define SC_MANAGER_ALL_ACCESS 0x3F
!define SERVICE_QUERY_CONFIG 0x0001
!define SERVICE_QUERY_STATUS 0x0004
!define SERVICE_RUNNING 0x4

!macro IsFirewallSvcRunning
  Push $R9
  Push $R8
  Push $R7
  Push $R6
  Push "false"

  System::Call 'advapi32::OpenSCManagerW(n, n, i ${SC_MANAGER_ALL_ACCESS}) i.R6'
  ${If} $R6 != 0
    ; MpsSvc is the Firewall service.
    ; When opening the service with SERVICE_QUERY_CONFIG the return value will
    ; be 0 if the service is not installed.
    System::Call 'advapi32::OpenServiceW(i R6, t "MpsSvc", i ${SERVICE_QUERY_CONFIG}) i.R7'
    ${If} $R7 != 0
      System::Call 'advapi32::CloseServiceHandle(i R7) n'
      ; Open the service with SERVICE_QUERY_CONFIG so its status can be queried.
      System::Call 'advapi32::OpenServiceW(i R6, t "MpsSvc", i ${SERVICE_QUERY_STATUS}) i.R7'
    ${Else}
      ; SharedAccess is the Firewall service on Windows XP.
      ; When opening the service with SERVICE_QUERY_CONFIG the return value will
      ; be 0 if the service is not installed.
      System::Call 'advapi32::OpenServiceW(i R6, t "SharedAccess", i ${SERVICE_QUERY_CONFIG}) i.R7'
      ${If} $R7 != 0
        System::Call 'advapi32::CloseServiceHandle(i R7) n'
        ; Open the service with SERVICE_QUERY_CONFIG so its status can be
        ; queried.
        System::Call 'advapi32::OpenServiceW(i R6, t "SharedAccess", i ${SERVICE_QUERY_STATUS}) i.R7'
      ${EndIf}
    ${EndIf}
    ; Did the calls to OpenServiceW succeed?
    ${If} $R7 != 0
      System::Call '*(i,i,i,i,i,i,i) i.R9'
      ; Query the current status of the service.
      System::Call 'advapi32::QueryServiceStatus(i R7, i $R9) i'
      System::Call '*$R9(i, i.R8)'
      System::Free $R9
      System::Call 'advapi32::CloseServiceHandle(i R7) n'
      IntFmt $R8 "0x%X" $R8
      ${If} $R8 == ${SERVICE_RUNNING}
        Pop $R9
        Push "true"
      ${EndIf}
    ${EndIf}
    System::Call 'advapi32::CloseServiceHandle(i R6) n'
  ${EndIf}

  Exch 1
  Pop $R6
  Exch 1
  Pop $R7
  Exch 1
  Pop $R8
  Exch 1
  Pop $R9
!macroend
!define IsFirewallSvcRunning "!insertmacro IsFirewallSvcRunning"
!define un.IsFirewallSvcRunning "!insertmacro IsFirewallSvcRunning"

; The following empty function has been kept to avoid compiler errors if it's
; called from other installer files (like common.nsh).
Function SetAsDefaultAppUserHKCU
FunctionEnd

; Helper for updating the shortcut application model IDs.
Function FixShortcutAppModelIDs
  ${If} ${AtLeastWin7}
  ${AndIf} "$AppUserModelID" != ""
    ${UpdateShortcutAppModelIDs} "$INSTDIR\${FileMainEXE}" "$AppUserModelID" $0
  ${EndIf}
FunctionEnd

; Helper for adding Firewall exceptions during install and after app update.
Function AddFirewallEntries
  ${IsFirewallSvcRunning}
  Pop $0
  ${If} "$0" == "true"
    liteFirewallW::AddRule "$INSTDIR\${FileMainEXE}" "${BrandShortName} ($INSTDIR)"
  ${EndIf}
FunctionEnd

; The !ifdef NO_LOG prevents warnings when compiling the installer.nsi due to
; this function only being used by the uninstaller.nsi.
!ifdef NO_LOG

; The following empty function has been kept to avoid compiler errors if it's
; called from other installer files (like common.nsh).
Function SetAsDefaultAppUser
FunctionEnd
!define SetAsDefaultAppUser "Call SetAsDefaultAppUser"

!endif ; NO_LOG
