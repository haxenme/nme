;--------------------------------

!include "MUI.nsh"
!include "LogicLib.nsh"
!include "WordFunc.nsh"

;--------------------------------

; Define version info
!define VERSION "3.3.0"

!define HAXE_VERSION "2.08"
!define NEKO_VERSION "1.8.2"
!define HXCPP_VERSION "2.08.3"
!define JEASH_VERSION "0.8.7"
!define ACTUATE_VERSION "1.38"
!define SWF_VERSION "1.11"


; Installer details
VIAddVersionKey "CompanyName" "NME"
VIAddVersionKey "ProductName" "NME Installer"
VIAddVersionKey "LegalCopyright" "NME 2007-2012"
VIAddVersionKey "FileDescription" "NME Installer"
VIAddVersionKey "ProductVersion" "${VERSION}.0"
VIAddVersionKey "FileVersion" "${VERSION}.0"
VIProductVersion "${VERSION}.0"


; The name of the installer
Name "NME ${VERSION}"

; The captions of the installer
Caption "NME ${VERSION} Setup"
UninstallCaption "NME ${VERSION} Uninstall"

; The file to write
OutFile "bin\NME-${VERSION}-Windows.exe"

; Default installation folder
;InstallDir "$PROGRAMFILES\Motion-Twin\"


InstallDir "C:\Motion-Twin"



; Define executable files
!define EXECUTABLE "$INSTDIR\haxe\haxe.exe"
!define HAXELIB "$INSTDIR\haxe\haxelib.exe"
!define NEKOEXE "$INSTDIR\neko\neko.exe"

; Vista redirects $SMPROGRAMS to all users without this
RequestExecutionLevel admin

; Use replace and version compare
!insertmacro WordReplace
!insertmacro VersionCompare

; Required props
SetFont /LANG=${LANG_ENGLISH} "Tahoma" 8
SetCompressor /SOLID lzma
CRCCheck on
XPStyle on

;--------------------------------

; Interface Configuration

!define MUI_HEADERIMAGE
!define MUI_ABORTWARNING
!define MUI_HEADERIMAGE_BITMAP "images\Banner.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "images\Wizard.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "images\Wizard.bmp"
!define MUI_PAGE_HEADER_SUBTEXT "Please view the license before installing NME ${VERSION}."
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of $(^NameDA).\r\n\r\nIt is recommended that you close all other applications before starting Setup. This will make it possible to update relevant system files without having to reboot your computer.\r\n\r\n$_CLICK"

;--------------------------------

; Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_COMPONENTS
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH
!insertmacro MUI_LANGUAGE "English"

;--------------------------------

; InstallTypes

InstType "Default"
InstType "un.Default"
InstType "un.Full"

;--------------------------------

; Functions



Function .onInit
	
	ReadEnvStr $0 HAXEPATHSS
	
FunctionEnd

;--------------------------------

; Install Sections

Section "haXe [${HAXE_VERSION}]" Main
	
	SectionIn 1
	SetOverwrite on
	
	SetOutPath "$INSTDIR\haxe"
	
	File /r /x .svn /x *.db /x Exceptions.log /x .local /x .multi /x *.pdb /x *.vshost.exe /x *.vshost.exe.config /x *.vshost.exe.manifest "resources\haxe\*.*"
	
	ExecWait "$INSTDIR\haxe\haxesetup.exe -silent"
	
	WriteUninstaller "$INSTDIR\Uninstall.exe"
	
SectionEnd

Section "Neko [${NEKO_VERSION}]" Neko
	
	SectionIn 1
	SetOverwrite on
	
	SetOutPath "$INSTDIR\neko"
	
	File /r /x .svn /x *.db /x Exceptions.log /x .local /x .multi /x *.pdb /x *.vshost.exe /x *.vshost.exe.config /x *.vshost.exe.manifest "resources\neko\*.*"
	
SectionEnd

Section "NME [${VERSION}]" NME
	
	SectionIn 1
	SetOverwrite on
	SetShellVarContext all
	
	SetOutPath "$INSTDIR\haxe\lib\nme"
	
	File /r /x .svn "resources\nme\*.*"
	
	SetOutPath "$INSTDIR\haxe"
	
	File /r /x .svn "..\..\command-line\bin\nme.bat"
	
SectionEnd

Section "HXCPP [${HXCPP_VERSION}]" HXCPP
	
	SectionIn 1
	SetOverwrite on
	SetShellVarContext all
	
	SetOutPath "$INSTDIR\haxe\lib\hxcpp"
	
	File /r /x .svn "resources\hxcpp\*.*"
	
SectionEnd

Section "Jeash [${JEASH_VERSION}]" Jeash
	
	SectionIn 1
	SetOverwrite on
	SetShellVarContext all
	
	SetOutPath "$INSTDIR\haxe\lib\jeash"
	
	File /r /x .svn "resources\jeash\*.*"
	
SectionEnd

Section "Actuate [${ACTUATE_VERSION}]" Actuate

	SectionIn 1
	SetOverwrite on
	SetShellVarContext all
	
	SetOutPath "$INSTDIR\haxe\lib\actuate"
	
	File /r /x .svn "resources\actuate\*.*"
	
SectionEnd

Section "SWF [${SWF_VERSION}]" SWF

	SectionIn 1
	SetOverwrite on
	SetShellVarContext all
	
	SetOutPath "$INSTDIR\haxe\lib\swf"
	
	File /r /x .svn "resources\swf\*.*"
	
SectionEnd



;--------------------------------

; Install section strings

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
!insertmacro MUI_DESCRIPTION_TEXT ${Main} "Installs the haXe language compiler and core files (Required)"
!insertmacro MUI_DESCRIPTION_TEXT ${Neko} "Installs Neko, which is required by various haXe tools (Required)"
!insertmacro MUI_DESCRIPTION_TEXT ${NME} "Installs the NME library for haXe"
!insertmacro MUI_DESCRIPTION_TEXT ${HXCPP} "Installs the HXCPP library, which adds C/C++ support (Required for Neko and C++)"
!insertmacro MUI_DESCRIPTION_TEXT ${Jeash} "Installs the Jeash library, which provides support for HTML5 applications, using Canvas ((Required for HTML5)"
!insertmacro MUI_DESCRIPTION_TEXT ${Actuate} "Flexible 'tween' library for adding animations."
!insertmacro MUI_DESCRIPTION_TEXT ${SWF} "Provides SWF asset support."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------

; Uninstall Sections

Section "un.haXe" UninstMain
	
	RMDir /r "$INSTDIR\haxe"
	
SectionEnd

Section "un.Neko" UninstNeko
	
	RMDir /r "$INSTDIR\neko"
	
SectionEnd

;--------------------------------

; Uninstall section strings

!insertmacro MUI_UNFUNCTION_DESCRIPTION_BEGIN
!insertmacro MUI_DESCRIPTION_TEXT ${UninstMain} "Uninstalls haXe and all installed libraries"
!insertmacro MUI_DESCRIPTION_TEXT ${UninstNeko} "Uninstalls Neko"
!insertmacro MUI_UNFUNCTION_DESCRIPTION_END

;--------------------------------
