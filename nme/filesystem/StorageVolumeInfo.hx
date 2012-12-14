package nme.filesystem;
#if display


/**
 * The StorageVolumeInfo object dispatches a StorageVolumeChangeEvent object
 * when a storage volume is mounted or unmounted. The
 * <code>StorageVolume.storageVolume</code> static property references the
 * singleton StorageVolumeInfo object, which dispatches the events. The
 * StorageVolumeInfo class also defines a <code>getStorageVolumes</code>
 * method for listing currently mounted storage volumes.
 *
 * <p><i>AIR profile support:</i> This feature is supported on all desktop
 * operating systems, but it is not supported on all AIR for TV devices. It is
 * also not supported on mobile devices. You can test for support at run time
 * using the <code>StorageVolumeInfo.isSupported</code> property. See <a
 * href="http://help.adobe.com/en_US/air/build/WS144092a96ffef7cc16ddeea2126bb46b82f-8000.html">
 * AIR Profile Support</a> for more information regarding API support across
 * multiple profiles.</p>
 *
 * <p>On modern Linux distributions, the StorageVolumeInfo object only
 * dispatches <code>storageVolumeMount</code> and
 * <code>storageVolumeUnmount</code> events for physical devices and network
 * drives mounted at particular locations.</p>
 * 
 * @event storageVolumeMount   Dispatched when a storage volume has been
 *                             mounted.
 *
 *                             <p>On modern Linux distributions, the
 *                             StorageVolumeInfo object only dispatches
 *                             <code>storageVolumeMount</code> and
 *                             <code>storageVolumeUnmount</code> events for
 *                             physical devices and network drives mounted at
 *                             particular locations.</p>
 * @event storageVolumeUnmount Dispatched when a storage volume has been
 *                             unmounted.
 *
 *                             <p>On modern Linux distributions, the
 *                             StorageVolumeInfo object only dispatches
 *                             <code>storageVolumeMount</code> and
 *                             <code>storageVolumeUnmount</code> events for
 *                             physical devices and network drives mounted at
 *                             particular locations.</p>
 */
extern class StorageVolumeInfo extends nme.events.EventDispatcher
{

   /**
    * The <code>isSupported</code> property is set to <code>true</code> if the
    * StorageVolumeInfo class is supported on the current platform, otherwise
    * it is set to <code>false</code>.
    */
   static var isSupported;

   /**
    * The singleton instance of the StorageVolumeInfo object. Register event
    * listeners on this object for the <code>storageVolumeMount</code> and
    * <code>storageVolumeUnmount</code> events.
    */
   static var storageVolumeInfo(getInstance,null):StorageVolumeInfo;

   /**
    * Returns vector of StorageVolume objects corresponding to the currently
    * mounted storage volumes.
    *
    * <p>On modern Linux distributions, this method returns objects
    * corresponding to physical devices and network drives mounted at
    * particular locations.</p>
    * 
    */
   function getStorageVolumes():Array<StorageVolume>;
   static function getInstance():StorageVolumeInfo;
}


#elseif (cpp || neko)
typedef StorageVolumeInfo = native.filesystem.StorageVolumeInfo;
#end
