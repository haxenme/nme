package native.filesystem;


class StorageVolume {
	
	
	public var drive (default, null):String;
	public var fileSystemType (default, null):String;
	public var isRemovable (default, null):Bool;
	public var isWritable (default, null):Bool;
	public var name (default, null):String;
	public var rootDirectory (default, null):File;
	
	
	public function new (inRootDirPath:File, inName:String, inWritable:Bool, inRemovable:Bool, inFileSysType:String, inDrive:String) {
		
		rootDirectory = inRootDirPath;
		name = inName;
		fileSystemType = inFileSysType;
		isRemovable = inRemovable;
		isWritable = inWritable;
		drive = inDrive;
		
		if (drive == "") drive = null;
		
	}
	
	
}