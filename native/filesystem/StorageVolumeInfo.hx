package native.filesystem;


import native.events.EventDispatcher;
import native.Loader;


class StorageVolumeInfo extends EventDispatcher {
	
	
	public static inline var isSupported = true;
	public static var storageVolumeInfo (get_storageVolumeInfo, null):StorageVolumeInfo;
	
	private static var nmeStorageVolumeInfo:StorageVolumeInfo;

	private var volumes:Array<StorageVolume>;
	

	private function new () {
		
		super ();
		
		volumes = [];
		nme_filesystem_get_volumes (volumes, function (args:Array<Dynamic>)
			return new StorageVolume(new File(args[0]), args[1], args[2], args[3], args[4], args[5]));
		
	}
	
	
	public function getStorageVolumes ():Array<StorageVolume> {
		
		return volumes.copy ();
		
	}
	
	
	public static function getInstance () {
		
		if (nmeStorageVolumeInfo == null)
			nmeStorageVolumeInfo = new StorageVolumeInfo ();
		
		return nmeStorageVolumeInfo;
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private static function get_storageVolumeInfo () { return getInstance (); }
	
	
	
	
	// Native Methods
	
	
	
	
	private static var nme_filesystem_get_volumes = Loader.load ("nme_filesystem_get_volumes", 2);
	
	
}