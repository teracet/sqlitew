  ;; This is used within the win-compile-browser.sh script, and is part of the
  ;; installer patching process.
  ;; It deletes a shortcut within the installation directory.
  ${If} ${FileExists} "$INSTDIR\${BrandFullName}.lnk"
    Delete "$INSTDIR\${BrandFullName}.lnk"
  ${EndIf}
  ;; The following newline is important; do not delete
