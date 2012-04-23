package nme.filesystem;
#if code_completion


extern class File 
{
	static var applicationDirectory(nmeGetAppDir, null):File;
	static var applicationStorageDirectory(nmeGetStorageDir,null) : File;
	static var desktopDirectory(nmeGetDesktopDir,null) : File;
	static var documentsDirectory(nmeGetDocsDir,null) : File;
	static var userDirectory(nmeGetUserDir,null) : File;
	var nativePath(default, nmeSetNativePath):String;
	var url(default, nmeSetURL):String;
	function new(?path:String = null);
}


#elseif (cpp || neko)
typedef File = neash.filesystem.File;
#end