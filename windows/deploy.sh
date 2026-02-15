#!/bin/bash

# Script to go all the way from building to compiling to creating an installer
# Install MSYS2 then run prep.sh before this to prep your box
# Very tweaked version of the deploy.sh from SuperCamel: https://github.com/supercamel/ValaOnWindows

# Run this from base directory, not ./windows

# Run the exe of your app in deploy/bin :
# From the MSYS2 console to check you have all packages necessary for it to run on windows
# From windows Explorer by double-click to check if everything it needs is in the deploy folder
# Copy stuff from /c/MSYS2/mingw64/ everything needed should be kinda there

#--------------------------------
# Variables.
# Write path UNIX-style ("/"). Script will invert the slash where relevant.
app_name="Reminduck"
build_dir="builddir"
theme_name="io.elementary.stylesheet.banana"
icon_theme="elementary"
version="$(cat meson.build | grep version | cut -d \' -f 2)"
publisher="ellie-commons"

deploy_dir="windows/deploy"
exe_name="io.github.ellie_commons.jorts.exe"

#--------------------------------
# Rebuild and compile the exe as a release build
rm -rfd ${build_dir}
meson setup --buildtype release ${build_dir}
ninja -C ${build_dir}

#--------------------------------
# Prepare structure
mkdir -p "${deploy_dir}"
mkdir -p "${deploy_dir}/bin"
mkdir -p "${deploy_dir}/etc"
mkdir -p "${deploy_dir}/share"
mkdir -p "${deploy_dir}/lib"
mkdir -p "${deploy_dir}/include"

cp "${build_dir}/src/${exe_name}" "${deploy_dir}/bin"
cp -r "windows/icons" "${deploy_dir}"

# Detect what DLL we need and slorp it into bin
echo "Copying DLLs..."
dlls=$(ldd "${deploy_dir}/bin/${exe_name}" | grep "/mingw64" | awk '{print $3}')
for dll in $dlls 
do 
    cp "$dll" "${deploy_dir}/bin"
done

# These are not detected but needed to display icons properly
# Dont ask me how many tears of blood it took to figure out these idiots
cp -rnv /mingw64/bin/rsvg-convert.exe ${deploy_dir}/bin/
cp -rnv /mingw64/bin/librsvg-2-2.dll ${deploy_dir}/bin/
cp -rnv /mingw64/bin/libxml2-16.dll ${deploy_dir}/bin/

# Copy other required things for Gtk to work nicely
echo "Copying other necessary files..."
cp -nv /mingw64/bin/gdbus.exe ${deploy_dir}/bin/
cp -rnv /mingw64/etc/fonts ${deploy_dir}/etc/
cp -rnv /mingw64/share/glib-2.0 ${deploy_dir}/share/
cp -rnv /mingw64/share/gtk-4.0 ${deploy_dir}/share/
cp -rnv /mingw64/share/locale ${deploy_dir}/share/
cp -rnv /mingw64/share/themes/ ${deploy_dir}/share/
cp -rnv /mingw64/share/gettext/ ${deploy_dir}/share/
cp -rnv /mingw64/share/fontconfig/ ${deploy_dir}/share/
cp -rnv /mingw64/share/GConf/ ${deploy_dir}/share/
cp -rnv /mingw64/lib/gettext/ ${deploy_dir}/lib/

# We need this to properly display icons too. 
cp -rnv /mingw64/include/librsvg-2.0 ${deploy_dir}/include/
cp -rnv /mingw64/lib/gdk-pixbuf-2.0/ ${deploy_dir}/lib/
#export GDK_PIXBUF_MODULEDIR=lib/gdk-pixbuf-2.0/2.10.0/loaders
#gdk-pixbuf-query-loaders > ${deploy_dir}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache

# Make sure this one is actually copied, manually, in the deploy
# That file caused so many issues trying to build
cat windows/loaders.cache > ${deploy_dir}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache

#--------------------------------
# ICONS. Only what we need. Shits heavy af
# Honestly you could get away with copying the whole icon theme. The script goes into the weeds only to shave off MBs
# TODO: No matter what, the edit-find icon in the searchfield of emoji-popover shows as missing
# TODO: Abstract this into a script. A better coded one.

cp -rnv /mingw64/share/icons/elementary/ ${deploy_dir}/share/icons/elementary/
gtk4-update-icon-cache.exe -f ${deploy_dir}/share/icons/elementary/

#--------------------------------
# Write the theme to gtk settings
# The NSIS below handles installing the font, as it works differently on windows

mkdir -v ${deploy_dir}/etc/gtk-4.0/
cat << EOF > ${deploy_dir}/etc/gtk-4.0/settings.ini
[Settings]
gtk-theme-name=${theme_name}
gtk-icon-theme-name=${icon_theme}
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintful
gtk-xft-rgba=rgb
EOF

glib-compile-schemas ${deploy_dir}/share/glib-2.0/schemas

#================================================================
# Create NSIS script
echo "Creating NSIS script..."
cat << EOF > windows/${app_name}-Installer.nsi
!include "MUI2.nsh"
!include WinMessages.nsh

Name ${app_name}

VIAddVersionKey /LANG=0 "ProductName" "${app_name}"
VIAddVersionKey /LANG=0 "FileVersion" "${version}"
VIAddVersionKey /LANG=0 "ProductVersion" "${version}"
VIAddVersionKey /LANG=0 "FileDescription" "https://github.com/ellie-commons/reminduck"
VIAddVersionKey /LANG=0 "LegalCopyright" "GNU GPL v3 ellie-commons"
VIProductVersion "${version}.0"

Outfile "${app_name}-Installer.exe"
InstallDir "\$LOCALAPPDATA\\Programs\\${app_name}"

# RequestExecutionLevel admin  ; Request administrative privileges 
RequestExecutionLevel user

# Set the title of the installer window
Caption "${app_name} Installer"
BrandingText "Jorts ${version}, ${publisher} 2025"

# Set the title and text on the welcome page
!define MUI_WELCOMEPAGE_TITLE "Welcome to ${app_name} setup"
!define MUI_WELCOMEPAGE_TEXT "This bitch will guide you through the installation of ${app_name}."
!define MUI_INSTFILESPAGE_TEXT "Please wait while ${app_name} is being installed."
!define MUI_ICON "icons\install.ico"
!define MUI_UNICON "icons\uninstall.ico"

!define MUI_FINISHPAGE_LINK "Source code and wiki"
!define MUI_FINISHPAGE_LINK_LOCATION "https://github.com/ellie-commons/reminduck"
!define MUI_FINISHPAGE_RUN "\$INSTDIR\bin\io.github.ellie_commons.reminduck.exe"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

!macro GetCleanDir INPUTDIR
  ; ATTENTION: USE ON YOUR OWN RISK!
  ; Please report bugs here: http://stefan.bertels.org/
  !define Index_GetCleanDir 'GetCleanDir_Line\${__LINE__}'
  Push \$R0
  Push \$R1
  StrCpy \$R0 "\${INPUTDIR}"
  StrCmp \$R0 "" \${Index_GetCleanDir}-finish
  StrCpy \$R1 "\$R0" "" -1
  StrCmp "\$R1" "\" \${Index_GetCleanDir}-finish
  StrCpy \$R0 "\$R0\"
\${Index_GetCleanDir}-finish:
  Pop \$R1
  Exch \$R0
  !undef Index_GetCleanDir
!macroend

; ################################################################
; similar to "RMDIR /r DIRECTORY", but does not remove DIRECTORY itself
; example: !insertmacro RemoveFilesAndSubDirs "\$INSTDIR"
!macro RemoveFilesAndSubDirs DIRECTORY
  ; ATTENTION: USE ON YOUR OWN RISK!
  ; Please report bugs here: http://stefan.bertels.org/
  !define Index_RemoveFilesAndSubDirs 'RemoveFilesAndSubDirs_\${__LINE__}'

  Push \$R0
  Push \$R1
  Push \$R2

  !insertmacro GetCleanDir "\${DIRECTORY}"
  Pop \$R2
  FindFirst \$R0 \$R1 "\$R2*.*"
\${Index_RemoveFilesAndSubDirs}-loop:
  StrCmp \$R1 "" \${Index_RemoveFilesAndSubDirs}-done
  StrCmp \$R1 "." \${Index_RemoveFilesAndSubDirs}-next
  StrCmp \$R1 ".." \${Index_RemoveFilesAndSubDirs}-next
  IfFileExists "\$R2\$R1\*.*" \${Index_RemoveFilesAndSubDirs}-directory
  ; file
  Delete "\$R2\$R1"
  goto \${Index_RemoveFilesAndSubDirs}-next
\${Index_RemoveFilesAndSubDirs}-directory:
  ; directory
  RMDir /r "\$R2\$R1"
\${Index_RemoveFilesAndSubDirs}-next:
  FindNext \$R0 \$R1
  Goto \${Index_RemoveFilesAndSubDirs}-loop
\${Index_RemoveFilesAndSubDirs}-done:
  FindClose \$R0

  Pop \$R2
  Pop \$R1
  Pop \$R0
  !undef Index_RemoveFilesAndSubDirs
!macroend

Section "Install"
    SetOutPath "\$INSTDIR"
    File /r "deploy\\*"
    CreateDirectory \$SMPROGRAMS\\${app_name}



    ; Start menu
    CreateShortCut "\$SMPROGRAMS\\${app_name}\\${app_name}.lnk" "\$INSTDIR\\bin\\${exe_name}" "" "\$INSTDIR\\icons\\icon-mini.ico" 0
    
    ; Autostart
    CreateShortCut "\$SMPROGRAMS\\Startup\\${app_name}.lnk" "\$INSTDIR\\bin\\${exe_name}" "--headless" "\$INSTDIR\\icons\\icon-mini.ico" 0
    

    WriteRegStr HKCU "Software\\${app_name}" "" \$INSTDIR
    WriteUninstaller "\$INSTDIR\Uninstall.exe"
    
    ; Add to Add/Remove programs list
    WriteRegStr HKCU "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${app_name}" "DisplayName" "${app_name}"
    WriteRegStr HKCU "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${app_name}" "DisplayIcon" "\$INSTDIR\\icons\\icon.ico"
    WriteRegStr HKCU "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${app_name}" "InstallLocation" "\$INSTDIR\\"
    WriteRegStr HKCU "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${app_name}" "UninstallString" "\$INSTDIR\\Uninstall.exe"
    WriteRegStr HKCU "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${app_name}" "Publisher" "${publisher}"
    WriteRegStr HKCU "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${app_name}" "URLInfoAbout" "https://github.com/ellie-commons/reminduck"
    WriteRegDWORD HKCU "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${app_name}" "EstimatedSize" "0x00028294" ;164,5 MB
SectionEnd

Section "Uninstall"

    ; Remove Start Menu shortcut
    Delete "\$SMPROGRAMS\\${app_name}\\${app_name}.lnk"
    Delete "\$SMPROGRAMS\\Startup\\${app_name}.lnk"

    ; Remove uninstaller
    Delete "\$INSTDIR\Uninstall.exe"
    
    ; Remove files and folders
    !insertmacro RemoveFilesAndSubDirs "\$INSTDIR"

    ; Remove directories used
    RMDir \$SMPROGRAMS\\${app_name}
    RMDir "\$INSTDIR"

    ; Remove font
    Delete "\$LOCALAPPDATA\\Microsoft\\Windows\\Fonts\\RedactedScript-Regular.ttf"
    DeleteRegKey HKCU "Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts\\Redacted Script Regular (TrueType)"
    Delete "\$LOCALAPPDATA\\Microsoft\\Windows\\Fonts\\InterVariable.ttf"
    DeleteRegKey HKCU "Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts\\Inter Variable (TrueType)"

    ; Remove registry keys
    DeleteRegKey HKCU "Software\\${app_name}"
    DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\\${app_name}"

SectionEnd

EOF


#--------------------------------
# Build the final exe installer.
# Test out the deploy bin just in case though.

echo "Running NSIS..."
makensis windows/${app_name}-Installer.nsi

echo "Done"

