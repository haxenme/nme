package nme.net;
#if (cpp || neko)


#if cpp

import cpp.FileSystem;
import cpp.io.File;
import cpp.io.FileInput;
import cpp.io.FileOutput;
import cpp.io.Path;
import cpp.Sys;
import nme.Loader;

#elseif neko

import neko.FileSystem;
import neko.io.File;
import neko.io.FileInput;
import neko.io.FileOutput;
import neko.io.Path;
import neko.Sys;
import nme.Loader;

#end

import haxe.Serializer;
import haxe.Unserializer;
import haxe.io.Eof;
import nme.events.EventDispatcher;


class SharedObject extends EventDispatcher
{
	
	public var data(default, null):Dynamic;
	
	private var localPath:String;
	private var name:String;
	
	
	private function new(name:String, localPath:String, data:Dynamic)
	{
		super ();
		
		this.name = name;
		this.localPath = localPath;
		this.data = data;
	}
	
	
	public function clear():Void
	{
		#if (iphone || android)
			
			untyped nme_clear_user_preference(name);
			
		#else
			
			var filePath = getFilePath(name, localPath);
			
			if (FileSystem.exists(filePath))
			{
				FileSystem.deleteFile(filePath);
			}
			
		#end
	}
	
	
	public function flush(minDiskSpace:Int = 0):SharedObjectFlushStatus
	{
		var encodedData:String = Serializer.run(data);
		
		#if (iphone || android)
			
			untyped nme_set_user_preference(name, encodedData);
			
		#else
			
			var filePath = getFilePath(name, localPath);
			var folderPath = Path.directory(filePath);
			
			if (!FileSystem.exists(folderPath))
			{
				FileSystem.createDirectory(folderPath);
			}
			
			var output:FileOutput = File.write(filePath, false);
			output.writeString(encodedData);
			output.close();
			
		#end
		
		return SharedObjectFlushStatus.FLUSHED;
	}
	
	
	private static function getFilePath(name:String, localPath:String):String
	{
		var path:String = "";
		
		/*if (Sys.environment.exists ("LOCALAPPDATA")) {
			
			path = Sys.getEnv ("LOCALAPPDATA");
			
		} else {
			
			path = Sys.getEnv ("APPDATA");
			
		}
		
		path += "\\NME";
		
		if (!FileSystem.exists (path)) {
			
			FileSystem.createDirectory (path);
			
		}
		
		path += "\\SharedObjects";
		
		if (!FileSystem.exists (path)) {
			
			FileSystem.createDirectory (path);
			
		}
		
		path += "\\" + localPath + "\\";
		
		if (!FileSystem.exists (path)) {
			
			FileSystem.createDirectory (path);
			
		}*/
		
		path = Path.directory(Sys.executablePath()) + "/sharedobjects/";
		
		path += name + ".sol";
		
		return path;
	}
	
	
	public static function getLocal(name:String, ?localPath:String, secure:Bool = false):SharedObject
	{
		if (localPath == null)
		{
			localPath = "";
		}
		
		#if (iphone || android)
			
			var rawData:String = untyped nme_get_user_preference(name);
			
		#else
			
			var filePath = getFilePath(name, localPath);
			var rawData:String = "";
			
			if (FileSystem.exists(filePath))
			{
				var input:FileInput = File.read(filePath, false);
				
				try
				{
					while (true)
					{
						rawData += input.readLine();
					}
					
				}
				catch (ex:Eof) { }
				
				input.close ();
			}
			
		#end
		
		var loadedData:Dynamic = { };
		
		if (rawData == "" || rawData == null)
		{
			loadedData = { };
		}
		else
		{
			loadedData = Unserializer.run(rawData);
		}
		
		var so:SharedObject = new SharedObject(name, localPath, loadedData);
		
		return so;
	}
	
	
	
	// Native Methods
	
	
	
	#if (iphone || android)
	private static var nme_get_user_preference = Loader.load ("nme_get_user_preference", 1);
	private static var nme_set_user_preference = Loader.load ("nme_set_user_preference", 2);
	private static var nme_clear_user_preference = Loader.load ("nme_clear_user_preference", 1);
	#end
	
}


#else
typedef SharedObject = flash.net.SharedObject;
#end