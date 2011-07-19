@if exist "%VS110COMNTOOLS%\vsvars32.bat" (
	@call "%VS110COMNTOOLS%\vsvars32.bat"
	@echo HXCPP_VARS
	@set
) else if exist "%VS100COMNTOOLS%\vsvars32.bat" (
	@call "%VS100COMNTOOLS%\vsvars32.bat"
	@echo HXCPP_VARS
	@set
) else if exist "%VS90COMNTOOLS%\vsvars32.bat" (
	@call "%VS90COMNTOOLS%\vsvars32.bat"
	@echo HXCPP_VARS
	@set
) else if exist "%VS80COMNTOOLS%\vsvars32.bat" (
	@call "%VS80COMNTOOLS%\vsvars32.bat"
	@echo HXCPP_VARS
	@set
) else if exist "%VS71COMNTOOLS%\vsvars32.bat" (
	@call "%VS71COMNTOOLS%\vsvars32.bat"
	@echo HXCPP_VARS
	@set
) else if exist "%VS70COMNTOOLS%\vsvars32.bat" (
	@call "%VS70COMNTOOLS%\vsvars32.bat"
	@echo HXCPP_VARS
	@set
) else (
	echo Warning: Could not find environment variables for Visual Studio
)