package nme.filesystem;

class StorageVolumeInfo extends nme.events.EventDispatcher
{
   static inline public var isSupported = true;
   static public var storageVolumeInfo(getInstance,null):StorageVolumeInfo;
   static var nmeStorageVolumeInfo:StorageVolumeInfo;

   /** @private */ var volumes:Array<StorageVolume>;

   function new()
   {
      super();
      volumes = [];
      nme_filesystem_get_volumes(volumes, function(args:Array<Dynamic>)
        return new StorageVolume(new File(args[0]),args[1],args[2],args[3],args[4],args[5]) );
   }

   public function getStorageVolumes():Array<StorageVolume>
   {
     return volumes.copy();
   }
   public static function getInstance()
   {
      if (nmeStorageVolumeInfo==null)
         nmeStorageVolumeInfo = new StorageVolumeInfo();
      return nmeStorageVolumeInfo;
   }

   static var nme_filesystem_get_volumes = nme.Loader.load("nme_filesystem_get_volumes", 2);
}

