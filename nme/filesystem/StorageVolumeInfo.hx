package nme.filesystem;
#if code_completion


extern class StorageVolumeInfo extends nme.events.EventDispatcher
{
   static var isSupported;
   static var storageVolumeInfo(getInstance,null):StorageVolumeInfo;
   function getStorageVolumes():Array<StorageVolume>;
   static function getInstance():StorageVolumeInfo;
}


#elseif (cpp || neko)
typedef StorageVolumeInfo = neash.filesystem.StorageVolumeInfo;
#end