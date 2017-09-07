  ;; This is used within the win-compile-browser.sh script, and is part of the
  ;; installer patching process.
  ;; It creates a shortcut within the installation directory so the user can
  ;; can start the application from there if necessary.
  CreateShortCut "$INSTDIR\${BrandFullName}.lnk" "$INSTDIR\${FileMainEXE}"
  ${If} ${FileExists} "$INSTDIR\${BrandFullName}.lnk"
    ;;ShellLink::SetShortCutWorkingDirectory "$INSTDIR\${BrandFullName}.lnk" "$INSTDIR"
    ${If} ${AtLeastWin7}
    ${AndIf} "$AppUserModelID" != ""
      ApplicationID::Set "$INSTDIR\${BrandFullName}.lnk" "$AppUserModelID" "true"
    ${EndIf}
    ${LogMsg} "Added Shortcut: $INSTDIR\${BrandFullName}.lnk"
  ${Else}
    ${LogMsg} "** ERROR Adding Shortcut: $INSTDIR\${BrandFullName}.lnk"
  ${EndIf}
  ;; The following newline is important; do not delete
  