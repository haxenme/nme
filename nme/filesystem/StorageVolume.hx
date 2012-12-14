package nme.filesystem;
#if display


/**
 * A StorageVolume object includes properties defining a mass storage volume.
 * This class is used in two ways:
 * <ul>
 *   <li>The <code>storageVolume</code> property of a StorageVolumeChangeEvent
 * object is a StorageVolume object. This object represents the storage volume
 * that has been mounted or unmounted.</li>
 *   <li>The
 * <code>StorageVolumeInfo.storageVolumeInfo.getStorageVolumes()</code> method
 * returns a vector of StorageVolume objects. Each of these StorageVolume
 * objects represents a mounted storage volume.</li>
 * </ul>
 */
extern class StorageVolume
{

	/**
	 * The constructor function. Generally, you do not call this constructor
	 * function directly (to create new StorageVolume objects). Rather, you
	 * reference StorageVolume objects by accessing the
	 * <code>storageVolume</code> property of a StorageVolumeChangeEvent object
	 * or by calling
	 * <code>StorageVolumeInfo.storageVolumeInfo.getStorageVolumes()</code>.
	 */
	function new(inRootDirPath:File, inName:String, inWritable:Bool, inRemovable:Bool, inFileSysType:String, inDrive:String):Void;

	/**
	 * The volume drive letter on Windows. On other platforms, this property is
	 * set to <code>null</code>.
	 */
	var drive(default,null) : String;

	/**
	 * The type of file system on the storage volume (such as <code>"FAT"</code>,
	 * <code>"NTFS"</code>, <code>"HFS"</code>, or <code>"UFS"</code>).
	 */
	var fileSystemType(default,null) : String;

	/**
	 * Whether the operating system considers the storage volume to be removable
	 * (<code>true</code>) or not (<code>false</code>).
	 *
	 * <p>The following table lists the values
	 * <code>StorageVolume.isRemovable</code> property for various types of
	 * devices:</p>
	 *
	 * <p><sup>1</sup> Linux does not have a concept of a shared volume.</p>
	 *
	 * <p><sup>2</sup> On Windows, an empty card reader is listed as a
	 * non-removable device. On Mac OS and Linux, empty car readers are not
	 * listed as storage volumes.</p>
	 */
	var isRemovable(default,null) : Bool;

	/**
	 * Whether a volume is writable (<code>true</code>) or not
	 * (<code>false</code>).
	 *
	 * <p><b>Note:</b> You can determine the amount of space available on a
	 * volume by calling the <code>rootDirectory.spaceAvailble</code> property of
	 * the StorageVolume object.</p>
	 */
	var isWritable(default,null) : Bool;

	/**
	 * The name of the volume. If there is no name, this property is set to
	 * <code>null</code>.
	 */
	var name(default,null) : String;

	/**
	 * A File object corresponding to the root directory of the volume.
	 */
	var rootDirectory(default,null) : File;
}


#elseif (cpp || neko)
typedef StorageVolume = native.filesystem.StorageVolume;
#end
