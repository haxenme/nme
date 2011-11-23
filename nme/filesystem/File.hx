package nme.filesystem;
#if (cpp || neko)


import StringTools;
import nme.Loader;


class File 
{
	
	public static var applicationDirectory(nmeGetApplicationDirectory, null):File;
	
	public var nativePath(default, nmeSetNativePath):String;
	public var url(default, nmeSetURL):String;
	
	
	public function new(?path:String = null)
	{
		nmeSetURL(path);
		nmeSetNativePath(path);
	}
	
	
	
	// Getters & Setters
	
	
	
	private static function nmeGetApplicationDirectory():File
	{
		return new File(nme_get_resource_path());
	}
	
	
	private function nmeSetNativePath(inPath:String):String
	{
		nativePath = inPath;
		return nativePath;
	}
	
	
	private function nmeSetURL(inPath:String):String
	{
		if (inPath == null)
		{
			url = null;
		}
		else
		{
			url = StringTools.replace(inPath, " ", "%20");
			if (StringTools.startsWith(inPath, nme_get_resource_path()))
			{
				url = "app:" + url;
			}
			else
			{
				url = "file:" + url;
			}
		}
		return url;
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_get_resource_path = Loader.load("nme_get_resource_path", 0);
	
}


#end