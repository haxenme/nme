package native.filesystem;


import StringTools;
import native.Loader;

#if android
import native.JNI;
#end


class File {
	
	
	public static var applicationDirectory (get_applicationDirectory, null):File;
	public static var applicationStorageDirectory (get_applicationStorageDirectory,null) : File;
	public static var desktopDirectory(get_desktopDirectory,null) : File;
	public static var documentsDirectory(get_documentsDirectory,null) : File;
	public static var userDirectory(get_userDirectory, null) : File;
	
	static inline var APP = 0;
	static inline var STORAGE = 1;
	static inline var DESKTOP = 2;
	static inline var DOCS = 3;
	static inline var USER = 4;
	
	public var nativePath (default, set_nativePath):String;
	public var url (default, set_url):String;
	
	
	public function new (?path:String = null) {
		
		this.url = path;
		this.nativePath = path;
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private static function get_applicationDirectory ():File { return new File (nme_filesystem_get_special_dir (APP)); }
	private static function get_applicationStorageDirectory ():File { return new File (nme_filesystem_get_special_dir (STORAGE)); }
	private static function get_desktopDirectory ():File { return new File (nme_filesystem_get_special_dir (DESKTOP)); }
	private static function get_documentsDirectory ():File { return new File (nme_filesystem_get_special_dir (DOCS)); }
	private static function get_userDirectory ():File { return new File (nme_filesystem_get_special_dir (USER)); }
	
	
	private function set_nativePath (inPath:String):String {
		
		nativePath = inPath;
		return nativePath;
		
	}
	
	
	private function set_url (inPath:String):String {
		
		if (inPath == null) {
			
			url = null;
			
		} else {
			
			url = StringTools.replace (inPath, " ", "%20");
			
			#if iphone
			if (StringTools.startsWith (inPath, nme_get_resource_path ())) {
				
				url = "app:" + url;
				
			} else
			#end
			
			{
				url = "file:" + url;
			}
			
		}
		
		return url;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if iphone
	private static var nme_get_resource_path = Loader.load ("nme_get_resource_path", 0);
	#end
	
	#if !android
	private static var nme_filesystem_get_special_dir = Loader.load ("nme_filesystem_get_special_dir", 1);
	#else
	
	static var jni_filesystem_get_special_dir:Dynamic = null;
	
	static function nme_filesystem_get_special_dir (inWhich:Int):String {
		
		if (jni_filesystem_get_special_dir == null)
			jni_filesystem_get_special_dir = JNI.createStaticMethod ("org.haxe.nme.GameActivity", "getSpecialDir", "(I)Ljava/lang/String;");
		
		return jni_filesystem_get_special_dir (inWhich);
		
	}
	
	#end
	
	
}