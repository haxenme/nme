package nme.filesystem;
#if code_completion


extern class StorageVolume
{
	function new(inRootDirPath:File, inName:String, inWritable:Bool, inRemovable:Bool, inFileSysType:String, inDrive:String):Void;
	var drive(default,null) : String;
	var fileSystemType(default,null) : String;
	var isRemovable(default,null) : Bool;
	var isWritable(default,null) : Bool;
	var name(default,null) : String;
	var rootDirectory(default,null) : File;
}


#elseif (cpp || neko)
typedef StorageVolume = neash.filesystem.StorageVolume;
#end