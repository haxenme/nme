#if !flash


package nme.filesystem;

import StringTools;

class File 
{
  public static var applicationDirectory(nmeGetApplicationDirectory, null):File;

  public var url(default, nmeSetURL):String;
  public var nativePath(default, nmeSetNativePath):String;

  private static function nmeGetApplicationDirectory():File
  {
    return new File(nme_get_resource_path());
  }

  public function new(?path:String=null)
  {
    nmeSetURL(path);
    nmeSetNativePath(path);
  }

  private function nmeSetURL(inPath:String):String {
    if (inPath == null) {
      url = null;
    }
    else {
      url = StringTools.replace(inPath, " ", "%20");
      if (StringTools.startsWith(inPath, nme_get_resource_path())) {
	url = "app:" + url;
      }
      else {
	url = "file:" + url;
      }
    }
    return url;
  }

  private function nmeSetNativePath(inPath:String):String {
    nativePath = inPath;
    return nativePath;
  }

  static var nme_get_resource_path = nme.Loader.load("nme_get_resource_path", 0);

}


#end