package nme.filesystem;
#if display


/**
 * A File object represents a path to a file or directory. This can be an
 * existing file or directory, or it can be one that does not yet exist; for
 * instance, it can represent the path to a file or directory that you plan to
 * create.
 *
 * <p>The File class has a number of properties and methods for getting
 * information about the file system and for performing operations, such as
 * copying files and directories.</p>
 *
 * <p>You can use File objects along with the FileStream class to read and
 * write files. </p>
 *
 * <p>The File class extends the FileReference class. The FileReference class,
 * which is available in Flash<sup>®</sup> Player as well as
 * Adobe<sup>®</sup> AIR<sup>®</sup>, represents a pointer to a file, but
 * the File class adds properties and methods that are not exposed in Flash
 * Player (in a SWF running in a browser), due to security considerations.</p>
 *
 * <p>The File class includes static properties that let you reference
 * commonly used directory locations. These static properties include:</p>
 *
 * <ul>
 *   <li><code>File.applicationStorageDirectory</code> - a storage directory
 * unique to each installed AIR application</li>
 *   <li><code>File.applicationDirectory</code> - the read-only directory
 * where the application is installed (along with any installed assets)</li>
 *   <li><code>File.desktopDirectory</code> - the user's desktop
 * directory</li>
 *   <li><code>File.documentsDirectory</code> - the user's documents
 * directory</li>
 *   <li><code>File.userDirectory</code> - the user directory</li>
 * </ul>
 *
 * <p>These properties have meaningful values on different operating systems.
 * For example, Mac OS, Linux, and Windows each have different native paths to
 * the user's desktop directory. However, the
 * <code>File.desktopDirectory</code> property points to the correct desktop
 * directory path on each of these platforms. To write applications that work
 * well across platforms, use these properties as the basis for referencing
 * other files used by the application. Then use the
 * <code>resolvePath()</code> method to refine the path. For example, this
 * code points to the preferences.xml file in the application storage
 * directory:</p>
 *
 * <p>The application storage directory is particularly useful. It gives an
 * application-specific storage directory for the AIR application. It is
 * defined by the <code>File.applicationStorageDirectory</code> property.</p>
 *
 * <p>Do not add or remove content from the application directory (where the
 * AIR application is installed). Doing so can break an AIR application and
 * invalidate the application signature. AIR does not let you write to the
 * application directory by default, because the directory is not writable to
 * all user accounts on all operating systems. Use the application storage
 * directory to write internal application files. Use the documents directory
 * to write files that a user expects to use outside your application, such as
 * edited pictures or text files.</p>
 * 
 * @event cancel           Dispatched when a pending asynchronous operation is
 *                         canceled.
 * @event complete         Dispatched when an asynchronous operation is
 *                         complete.
 * @event directoryListing Dispatched when a directory list is available as a
 *                         result of a call to the
 *                         <code>getDirectoryListingAsync()</code> method.
 * @event ioError          Dispatched when an error occurs during an
 *                         asynchronous file operation.
 * @event securityError    Dispatched when an operation violates a security
 *                         constraint.
 * @event select           Dispatched when the user selects a file or
 *                         directory from a file- or directory-browsing dialog
 *                         box.
 * @event selectMultiple   Dispatched when the user selects files from the
 *                         dialog box opened by a call to the
 *                         <code>browseForOpenMultiple()</code> method.
 */
extern class File 
{

	/**
	 * The folder containing the application's installed files.
	 *
	 * <p>The <code>url</code> property for this object uses the <code>app</code>
	 * URL scheme (not the <code>file</code> URL scheme). This means that the
	 * <code>url</code> string is specified starting with <code>"app:"</code>
	 * (not <code>"file:"</code>). Also, if you create a File object relative to
	 * the <code>File.applicationDirectory</code> directory (by using the
	 * <code>resolvePath()</code> method), the <code>url</code> property of the
	 * File object also uses the <code>app</code> URL scheme. </p>
	 *
	 * <p><i>Note:</i> You cannot write to files or directories that have paths
	 * that use the <code>app:</code> URL scheme. Also, you cannot delete or
	 * create files or folders that have paths that use the <code>app:</code> URL
	 * scheme. Modifying content in the application directory is a bad practice,
	 * for security reasons, and is blocked by the operating system on some
	 * platforms. If you want to store application-specific data, consider using
	 * the application storage directory
	 * (<code>File.applicationStorageDirectory</code>). If you want any of the
	 * content in the application storage directory to have access to the
	 * application-privileged functionality (AIR APIs), you can expose that
	 * functionality by using a sandbox bridge.</p>
	 *
	 * <p>The <code>applicationDirectory</code> property provides a way to
	 * reference the application directory that works across platforms. If you
	 * set a File object to reference the application directory using the
	 * <code>nativePath</code> or <code>url</code> property, it will only work on
	 * the platform for which that path is valid.</p>
	 *
	 * <p>On Android, the <code>nativePath</code> property of a File object
	 * pointing to the application directory is an empty string. Use the
	 * <code>url</code> property to access application files.</p>
	 */
	static var applicationDirectory(nmeGetAppDir, null):File;

	/**
	 * The application's private storage directory.
	 *
	 * <p>Each AIR application has a unique, persistent application storage
	 * directory, which is created when you first access
	 * <code>File.applicationStorageDirectory</code>. This directory is a
	 * convenient location to store application-specific data.</p>
	 *
	 * <p>When you uninstall an AIR application, whether the uninstaller deletes
	 * the application storage directory and its files depends on the
	 * platform.</p>
	 *
	 * <p>The <code>url</code> property for this object uses the
	 * <code>app-storage</code> URL scheme (not the <code>file</code> URL
	 * scheme). This means that the <code>url</code> string is specified starting
	 * with <code>"app-storage:"</code> (not <code>"file:"</code>). Also, if you
	 * create a File object relative to the
	 * <code>File.applicationStoreDirectory</code> directory (by using the
	 * <code>resolvePath()</code> method), the <code>url</code> of the File
	 * object also uses the <code>app-storage</code> URL scheme (as in the
	 * example).</p>
	 *
	 * <p>The <code>applicationStorageDirectory</code> property provides a way to
	 * reference the application storage directory that works across platforms.
	 * If you set a File object to reference the application storage directory
	 * using the <code>nativePath</code> or <code>url</code> property, it will
	 * only work on the platform for which that path is valid.</p>
	 */
	static var applicationStorageDirectory(nmeGetStorageDir,null) : File;

	/**
	 * The user's desktop directory.
	 *
	 * <p>The <code>desktopDirectory</code> property provides a way to reference
	 * the desktop directory that works across platforms. If you set a File
	 * object to reference the desktop directory using the
	 * <code>nativePath</code> or <code>url</code> property, it will only work on
	 * the platform for which that path is valid.</p>
	 *
	 * <p>If an operating system does not support a desktop directory, a suitable
	 * directory in the file system is used instead.</p>
	 *
	 * <p>AIR for TV devices have no concept of a user's desktop directory.
	 * Therefore, the <code>desktopDirectory</code> property references the same
	 * directory location as <code>File.userDirectory</code> property. The user
	 * directory is unique to the application.</p>
	 */
	static var desktopDirectory(nmeGetDesktopDir,null) : File;

	/**
	 * The user's documents directory.
	 *
	 * <p>On Windows, this is the My Documents directory (for example,
	 * C:\Documents and Settings\userName\My Documents). On Mac OS, the default
	 * location is /Users/userName/Documents. On Linux, the default location is
	 * /home/userName/Documents (on an English system), and the property observes
	 * the <code>xdg-user-dirs</code> setting.</p>
	 *
	 * <p>The <code>documentsDirectory</code> property provides a way to
	 * reference the documents directory that works across platforms. If you set
	 * a File object to reference the documents directory using the
	 * <code>nativePath</code> or <code>url</code> property, it will only work on
	 * the platform for which that path is valid.</p>
	 *
	 * <p>If an operating system does not support a documents directory, a
	 * suitable directory in the file system is used instead.</p>
	 *
	 * <p>AIR for TV devices have no concept of a user's documents directory.
	 * Therefore, the <code>documentsDirectory</code> property references the
	 * same directory location as the <code>File.userDirectory</code> property.
	 * The user directory is unique to the application.</p>
	 */
	static var documentsDirectory(nmeGetDocsDir,null) : File;

	/**
	 * The user's directory.
	 *
	 * <p>On Windows, this is the parent of the My Documents directory (for
	 * example, C:\Documents and Settings\userName). On Mac OS, it is
	 * /Users/userName. On Linux, it is /home/userName.</p>
	 *
	 * <p>The <code>userDirectory</code> property provides a way to reference the
	 * user directory that works across platforms. If you set the
	 * <code>nativePath</code> or <code>url</code> property of a File object
	 * directly, it will only work on the platform for which that path is
	 * valid.</p>
	 *
	 * <p>If an operating system does not support a user directory, a suitable
	 * directory in the file system is used instead.</p>
	 *
	 * <p>On AIR for TV devices, the <code>userDirectory</code> property
	 * references a user directory that is unique to the application.</p>
	 */
	static var userDirectory(nmeGetUserDir,null) : File;

	/**
	 * The full path in the host operating system representation. On Mac OS and
	 * Linux, the forward slash (/) character is used as the path separator.
	 * However, in Windows, you can <i>set</i> the <code>nativePath</code>
	 * property by using the forward slash character or the backslash (\)
	 * character as the path separator, and AIR automatically replaces forward
	 * slashes with the appropriate backslash character.
	 *
	 * <p>Before writing code to <i>set</i> the <code>nativePath</code> property
	 * directly, consider whether doing so may result in platform-specific code.
	 * For example, a native path such as <code>"C:\\Documents and
	 * Settings\\bob\\Desktop"</code> is only valid on Windows. It is far better
	 * to use the following static properties, which represent commonly used
	 * directories, and which are valid on all platforms:</p>
	 *
	 * <ul>
	 *   <li><code>File.applicationDirectory</code></li>
	 *   <li><code>File.applicationStorageDirectory</code></li>
	 *   <li><code>File.desktopDirectory</code></li>
	 *   <li><code>File.documentsDirectory</code></li>
	 *   <li><code>File.userDirectory</code></li>
	 * </ul>
	 *
	 * <p>You can use the <code>resolvePath()</code> method to get a path
	 * relative to these directories.</p>
	 *
	 * <p>Some Flex APIs, such as the <code>source</code> property of the
	 * SWFLoader class, use a URL (the <code>url</code> property of a File
	 * object), not a native path (the <code>nativePath</code> property).</p>
	 * 
	 * @throws ArgumentError The syntax of the path is invalid.
	 * @throws SecurityError The caller is not in the application security
	 *                       sandbox.
	 */
	var nativePath(default, nmeSetNativePath):String;

	/**
	 * The URL for this file path.
	 *
	 * <p>If this is a reference to a path in the application storage directory,
	 * the URL scheme is <code>"app-storage"</code>; if it is a reference to a
	 * path in the application directory, the URL scheme is <code>"app"</code>;
	 * otherwise the scheme is <code>"file"</code>. </p>
	 *
	 * <p>You can use blank space characters (rather than <code>"%20"</code>)
	 * when <i>assigning</i> a value to the <code>url</code> property; AIR
	 * automatically encodes the strings (for instance, converting spaces to
	 * <code>"%20"</code>).</p>
	 * 
	 * @throws ArgumentError The URL syntax is invalid.
	 * @throws SecurityError The caller is not in the application security
	 *                       sandbox.
	 */
	var url(default, nmeSetURL):String;

	/**
	 * The constructor function for the File class.
	 *
	 * <p>If you pass a <code>path</code> argument, the File object points to the
	 * specified path, and the <code>nativePath</code> property and and
	 * <code>url</code> property are set to reflect that path.</p>
	 *
	 * <p>Although you can pass a <code>path</code> argument to specify a file
	 * path, consider whether doing so may result in platform-specific code. For
	 * example, a native path such as <code>"C:\\Documents and
	 * Settings\\bob\\Desktop"</code> or a URL such as
	 * <code>"file:///C:/Documents%20and%20Settings/bob/Desktop"</code> is only
	 * valid on Windows. It is far better to use the following static properties,
	 * which represent commonly used directories, and which are valid on all
	 * platforms:</p>
	 *
	 * <ul>
	 *   <li><code>File.applicationDirectory</code></li>
	 *   <li><code>File.applicationStorageDirectory</code></li>
	 *   <li><code>File.desktopDirectory</code></li>
	 *   <li><code>File.documentsDirectory</code></li>
	 *   <li><code>File.userDirectory</code></li>
	 * </ul>
	 *
	 * <p>You can then use the <code>resolvePath()</code> method to get a path
	 * relative to these directories. For example, the following code sets up a
	 * File object to point to the settings.xml file in the application storage
	 * directory:</p>
	 * 
	 * @param path The path to the file. You can specify the path by using either
	 *             a URL or native path (platform-specific) notation.
	 *
	 *             <p>If you specify a URL, you can use any of the following URL
	 *             schemes: <code>file</code>, <code>app</code>, or
	 *             <code>app-storage</code>. The following are valid values for
	 *             the <code>path</code> parameter using URL notation: </p>
	 *
	 *             <ul>
	 *               <li><code>"app:/DesktopPathTest.xml"</code></li>
	 *               <li><code>"app-storage:/preferences.xml"</code></li>
	 *
	 *             <li><code>"file:///C:/Documents%20and%20Settings/bob/Desktop"</code>
	 *             (the desktop on Bob's Windows computer)</li>
	 *               <li><code>"file:///Users/bob/Desktop"</code> (the desktop on
	 *             Bob's Mac computer)</li>
	 *             </ul>
	 *
	 *             <p>The <code>app</code> and <code>app-storage</code> URL
	 *             schemes are useful because they can point to a valid file on
	 *             all file systems. However, in the other two examples, which
	 *             use the <code>file</code> URL scheme to point to the user's
	 *             desktop directory, it would be better to pass <i>no</i>
	 *             <code>path</code> argument to the <code>File()</code>
	 *             constructor and then assign <code>File.desktopDirectory</code>
	 *             to the File object, as a way to access the desktop directory
	 *             that is both platform- and user-independent.</p>
	 *
	 *             <p>If you specify a native path, on Windows you can use either
	 *             the backslash character or the forward slash character as the
	 *             path separator in this argument; on Mac OS and Linux, use the
	 *             forward slash. The following are valid values for the
	 *             <code>path</code> parameter using native path notation:</p>
	 *
	 *             <ul>
	 *               <li><code>"C:/Documents and
	 *             Settings/bob/Desktop"</code></li>
	 *               <li><code>"/Users/bob/Desktop"</code></li>
	 *             </ul>
	 *
	 *             <p>However, for these two examples, you should pass <i>no</i>
	 *             <code>path</code> argument to the <code>File()</code>
	 *             constructor and then assign <code>File.desktopDirectory</code>
	 *             to the File object, as a way to access the desktop directory
	 *             that is both platform- and user-independent.</p>
	 * @throws ArgumentError The syntax of the <code>path</code> parameter is
	 *                       invalid.
	 */
	function new(?path:String = null):Void;
}


#elseif (cpp || neko)
typedef File = native.filesystem.File;
#end
