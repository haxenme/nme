package setup;


import haxe.Http;
import haxe.io.Eof;
import haxe.io.Path;
import installers.InstallerBase;
import neko.zip.Reader;
import neko.Lib;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


/**
 * ...
 * @author Joshua Granick
 */

class PlatformSetup {
	
	
	private static var androidLinuxNDKPath = "http://dl.google.com/android/ndk/android-ndk-r8-linux-x86.tar.bz2";
	private static var androidLinuxSDKPath = "http://dl.google.com/android/android-sdk_r18-linux.tgz";
	private static var androidMacNDKPath = "http://dl.google.com/android/ndk/android-ndk-r8-darwin-x86.tar.bz2";
	private static var androidMacSDKPath = "http://dl.google.com/android/android-sdk_r18-macosx.zip";
	private static var androidWindowsNDKPath = "http://dl.google.com/android/ndk/android-ndk-r8-windows.zip";
	private static var androidWindowsSDKPath = "http://dl.google.com/android/android-sdk_r18-windows.zip";
	private static var apacheAntUnixPath = "http://archive.apache.org/dist/ant/binaries/apache-ant-1.8.4-bin.tar.gz";
	private static var apacheAntWindowsPath = "http://archive.apache.org/dist/ant/binaries/apache-ant-1.8.4-bin.zip";
	private static var appleXCodeURL = "http://developer.apple.com/xcode/";
	private static var blackBerryCodeSigningURL = "https://www.blackberry.com/SignedKeys/";
	private static var blackBerryLinuxNativeSDKPath = "https://developer.blackberry.com/native/downloads/fetch/installer-bbndk-2.1.0-beta1-linux-560-201206041807-201206052239.bin";
	private static var blackBerryMacNativeSDKPath = "https://developer.blackberry.com/native/downloads/fetch/installer-bbndk-2.1.0-beta1-macosx-560-201206041807-201206052239.dmg";
	private static var blackBerryWindowsNativeSDKPath = "https://developer.blackberry.com/native/downloads/fetch/installer-bbndk-2.1.0-beta1-win32-560-201206041807-201206052239.exe";
	private static var codeSourceryWindowsPath = "http://sourcery.mentor.com/public/gnu_toolchain/arm-none-linux-gnueabi/arm-2009q1-203-arm-none-linux-gnueabi.exe";
	private static var javaJDKURL = "http://www.oracle.com/technetwork/java/javase/downloads/jdk-6u32-downloads-1594644.html";
	private static var linuxX64Packages = "ia32-libs-multiarch gcc-multilib g++-multilib";
	private static var webOSLinuxX64NovacomPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/palm-novacom_1.0.80_amd64.deb";
	private static var webOSLinuxX86NovacomPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/palm-novacom_1.0.80_i386.deb";
	private static var webOSLinuxSDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/palm-sdk_3.0.5-svn528736-pho676_i386.deb";
	private static var webOSMacSDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/Palm_webOS_SDK.3.0.5.676.dmg";
	private static var webOSWindowsX64SDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/HP_webOS_SDK-Win-3.0.5-676-x64.exe";
	private static var webOSWindowsX86SDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/HP_webOS_SDK-Win-3.0.5-676-x86.exe";
	private static var windowsVisualStudioCPPPath = "http://download.microsoft.com/download/1/D/9/1D9A6C0E-FC89-43EE-9658-B9F0E3A76983/vc_web.exe";

	private static var backedUpConfig:Bool = false;
	private static var triedSudo:Bool = false;
	
   static inline function readLine()
   {
   #if haxe_209
		return Sys.stdin ().readLine ();
   #else
		return File.stdin ().readLine ();
   #end
   }
	
	private static function ask (question:String):Answer {
		
		while (true) {
			
			Lib.print (question + " [y/n/a] ? ");
			
			switch (readLine ()) {
				case "n": return No;
				case "y": return Yes;
				case "a": return Always;
			}
			
		}
		
		return null;
		
	}
	
	
	private static function createPath (path:String, defaultPath:String):String {
		
		try {
			
			if (path == "") {
				
				InstallTool.mkdir (defaultPath);
				return defaultPath;
				
			} else {
				
				InstallTool.mkdir (path);
				return path;
				
			}
			
		} catch (e:Dynamic) {
			
			throwPermissionsError ();
			return "";
			
		}
		
	}
	
	
	private static function downloadFile (remotePath:String, localPath:String = "", followingLocation:Bool = false):Void {
		
		if (localPath == "") {
			
			localPath = Path.withoutDirectory (remotePath);
			
		}
		
		if (!followingLocation && FileSystem.exists (localPath)) {
			
			var answer = ask ("File found. Install existing file?");
			
			if (answer != No) {
				
				return;
				
			}
			
		}
		
		var out = File.write (localPath, true);
		var progress = new Progress (out);
		var h = new Http (remotePath);
		
		h.onError = function (e) {
			progress.close();
			FileSystem.deleteFile (localPath);
			throw e;
		};
		
		if (!followingLocation) {
			
			Lib.println ("Downloading " + localPath + "...");
			
		}
		
		h.customRequest (false, progress);
		
		if (h.responseHeaders != null && h.responseHeaders.exists ("Location")) {
			
			var location = h.responseHeaders.get ("Location");
			
			if (location != remotePath) {
				
				downloadFile (location, localPath, true);
				
			}
			
		}
		
	}
	
	
	private static function extractFile (sourceZIP:String, targetPath:String, ignoreRootFolder:String = ""):Void {
		
		var extension = Path.extension (sourceZIP);
		
		if (extension != "zip") {
			
			var arguments = "xvzf";			
						
			if (extension == "bz2") {
				
				arguments = "xvjf";
				
			}	
			
			if (ignoreRootFolder != "") {
				
				InstallTool.runCommand ("", "tar", [ arguments, sourceZIP ]);
				InstallTool.runCommand ("", "cp", [ "-R", ignoreRootFolder + "/*", targetPath ]);
				Sys.command ("rm", [ "-r", ignoreRootFolder ]);
				
			} else {
				
				//InstallTool.runCommand (targetPath, "tar", [ arguments, FileSystem.fullPath (sourceZIP) ]);
				
			}
			
			Sys.command ("chmod", [ "-R", "755", targetPath ]);
			
		} else {
			
			var file = File.read (sourceZIP, true);
			var entries = Reader.readZip (file);
			file.close ();
		
			for (entry in entries) {
			
				var fileName = entry.fileName;
			
				if (fileName.charAt (0) != "/" && fileName.charAt (0) != "\\" && fileName.split ("..").length <= 1) {
				
					var dirs = ~/[\/\\]/g.split(fileName);
				
					if ((ignoreRootFolder != "" && dirs.length > 1) || ignoreRootFolder == "") {
					
						if (ignoreRootFolder != "") {
						
							dirs.shift ();
						
						}
					
						var path = "";
						var file = dirs.pop();
						for( d in dirs ) {
							path += d;
							InstallTool.mkdir (targetPath + "/" + path);
							path += "/";
						}
					
						if( file == "" ) {
							if( path != "" ) Lib.println("  Created "+path);
							continue; // was just a directory
						}
						path += file;
						Lib.println ("  Install " + path);
					
						var data = Reader.unzip (entry);
						var f = File.write (targetPath + "/" + path, true);
						f.write (data);
						f.close ();
					
					}
				
				}
			
			}
			
		}
		
		Lib.println ("Done");
		
	}
	
	
	private static function getDefines (names:Array <String> = null, descriptions:Array <String> = null, ignored:Array <String> = null):Hash <String> {
		
		var parser = new InstallerBase ();
		parser.parseHXCPPConfig ();
		
		var defines:Hash <String> = parser.defines;
		var env = Sys.environment ();
		var path = "";
		
		if (!defines.exists ("HXCPP_CONFIG")) {
			
			var home = "";
			
			if (env.exists ("HOME")) {
				
				home = env.get ("HOME");
				
			} else if (env.exists ("USERPROFILE")) {
				
				home = env.get ("USERPROFILE");
				
			} else {
				
				Lib.println ("Warning : No 'HOME' variable set - .hxcpp_config.xml might be missing.");
				
				return null;
				
			}
			
			defines.set ("HXCPP_CONFIG", home + "/.hxcpp_config.xml");
			
		}
		
		if (names == null) {
			
			return defines;
			
		}
		
		var values = new Array <String> ();
		
		for (i in 0...names.length) {
			
			var name = names[i];
			var description = descriptions[i];
			
			var ignore = "";
			
			if (ignored != null && ignored.length > i) {
				
				ignore = ignored[i];
				
			}
			
			var value = "";
			
			if (defines.exists (name) && defines.get (name) != ignore) {
				
				value = defines.get (name);
				
			} else if (env.exists (name)) {
				
				value = Sys.getEnv (name);
				
			}
			
			value = unescapePath (param (description + " [" + value + "]"));
			
			if (value != "") {
				
				defines.set (name, value);
				
			} else if (value == Sys.getEnv (name)) {
				
				defines.remove (name);
				
			}
			
		}
		
		return defines;
		
	}
	
	
	public static function installNME ():Void {
		
		if (InstallTool.isWindows) {
			
			var haxePath = Sys.getEnv ("HAXEPATH");
			
			if (haxePath == null || haxePath == "") {
				
				haxePath = "C:\\Motion-Twin\\haxe\\";
				
			}
			
			File.copy (InstallTool.nme + "\\tools\\command-line\\bin\\nme.bat", haxePath + "\\nme.bat");
			
		} else {
			
			File.copy (InstallTool.nme + "/tools/command-line/bin/nme.sh", "/usr/lib/haxe/nme");
			Sys.command ("chmod", [ "755", "/usr/lib/haxe/nme" ]);
			link ("haxe", "nme", "/usr/bin");
			
		}
		
		if (InstallTool.isMac) {
			
			var defines = getDefines ();
			defines.set ("MAC_USE_CURRENT_SDK", "1");
			writeConfig (defines.get ("HXCPP_CONFIG"), defines);
			
		}
		
	}
	
	
	private static function link (dir:String, file:String, dest:String):Void {
		
		Sys.command("rm -rf " + dest + "/" + file);
		Sys.command("ln -s " + "/usr/lib" +"/" + dir + "/" + file + " " + dest + "/" + file);
		
	}
	
	
	inline static function getChar() {
	   #if haxe_209
		  return Sys.getChar(false);
	   #else
		  return File.getChar(false);
	   #end
   }
   
   
	private static function openURL (url:String):Void {
		
		if (InstallTool.isWindows) {
			
			Sys.command ("explorer", [ url ]);
			
		} else if (InstallTool.isLinux) {
			
			InstallTool.runCommand ("", "xdg-open", [ url ]);
			
		} else {
			
			InstallTool.runCommand ("", "open", [ url ]);
			
		}
		
   }
	
	
	private static function param (name:String, ?passwd:Bool):String {
		
		Lib.print (name + " : ");
		
		if (passwd) {
			var s = new StringBuf ();
			var c;
			while ((c = getChar ()) != 13)
				s.addChar (c);
			Lib.print ("");
			return s.toString ();
		}
		
		try {
			
			return readLine ();
			
		} catch (e:Eof) {
			
			return "";
			
		}
		
	}
	
	
	public static function run (target:String = "") {
		
		try {
			
			switch (target) {
				
				case "android":
					
					setupAndroid ();
				
				case "blackberry":
					
					setupBlackBerry ();
				
				//case "html5":
					
					//setupHTML5 ();
				
				case "ios":
					
					if (InstallTool.isMac) {
						
						setupMac ();
						
					}
				
				case "linux":
					
					if (InstallTool.isLinux) {
						
						setupLinux ();
						
					}
				
				case "mac":
					
					if (InstallTool.isMac) {
						
						setupMac ();
						
					}
				
				case "webos":
					
					setupWebOS ();
				
				case "windows":
					
					if (InstallTool.isWindows) {
						
						setupWindows ();
						
					}
				
				case "":
					
					installNME ();
				
				default:
					
					Lib.println ("No setup is required for " + target + ", or it is not a valid target");
					return;
				
			}
			
		} catch (e:Eof) {
			
			
			
		}
		
	}
	
	
	private static function runInstaller (path:String, message:String = "Waiting for process to complete..."):Void {
		
		if (InstallTool.isWindows) {
			
			try {
				
				Lib.println (message);
				InstallTool.runCommand ("", "call", [ path ]);
				Lib.println ("Done");
				
			} catch (e:Dynamic) {}
			
		} else if (InstallTool.isLinux) {
			
			if (Path.extension (path) == "deb") {
				
				InstallTool.runCommand ("", "sudo", [ "dpkg", "-i", "--force-architecture", path ]);
				
			} else {
				
				Lib.println (message);
				InstallTool.runCommand ("", path, []);
				Lib.println ("Done");
				
			}
			
		} else {
			
			if (Path.extension (path) == "") {
				
				Lib.println (message);
				Sys.command ("chmod", [ "755", path ]);
				InstallTool.runCommand ("", path, []);
				Lib.println ("Done");
				
			} else if (Path.extension (path) == "dmg") {
				
				var process = new Process("hdiutil", [ "mount", path ]);
				var ret = process.stdout.readAll().toString();
				process.exitCode(); //you need this to wait till the process is closed!
				process.close();
				
				var volumePath = "";
				
				if (ret != null && ret != "") {
					
					volumePath = StringTools.trim (ret.substr (ret.indexOf ("/Volumes")));
					
				}
				
				if (volumePath != "" && FileSystem.exists (volumePath)) {
					
					var apps = [];
					var packages = [];
					var executables = [];
					
					var files:Array <String> = FileSystem.readDirectory (volumePath);
					
					for (file in files) {
						
						switch (Path.extension (file)) {
							
							case "app":
								
								apps.push (file);
								
							case "pkg", "mpkg":
								
								packages.push (file);
							
							case "bin":
								
								executables.push (file);
							
						}
						
					}
					
					var file = "";
					
					if (apps.length == 1) {
						
						file = apps[0];
						
					} else if (packages.length == 1) {
						
						file = packages[0];
						
					} else if (executables.length == 1) {
						
						file = executables[0];
						
					}
					
					if (file != "") {
						
						Lib.println (message);
						InstallTool.runCommand ("", "open", [ "-W", volumePath + "/" + file ]);
						Lib.println ("Done");
						
					}
					
					try {
						
						var process = new Process("hdiutil", [ "unmount", path ]);
						process.exitCode(); //you need this to wait till the process is closed!
						process.close();
						
					} catch (e:Dynamic) {
					
					}
					
					if (file == "") {
						
						InstallTool.runCommand ("", "open", [ path ]);
						
					}
					
				} else {
					
					InstallTool.runCommand ("", "open", [ path ]);
					
				}
				
			} else {
				
				InstallTool.runCommand ("", "open", [ path ]);
				
			}
			
		}
		
	}
	
	
	public static function setupAndroid ():Void {
		
		var setAndroidSDK = false;
		var setAndroidNDK = false;
		var setApacheAnt = false;
		var setJavaJDK = false;
		
		var defines = getDefines ();
		var answer = ask ("Download and install the Android SDK?");
		
		if (answer == Yes || answer == Always) {
			
			var downloadPath = "";
			var defaultInstallPath = "";
			var ignoreRootFolder = "android-sdk";
			
			if (InstallTool.isWindows) {
				
				downloadPath = androidWindowsSDKPath;
				defaultInstallPath = "C:\\Development\\Android SDK";
			
			} else if (InstallTool.isLinux) {
				
				downloadPath = androidLinuxSDKPath;
				defaultInstallPath = "/opt/Android SDK";
				ignoreRootFolder = "android-sdk-linux";
				
			} else if (InstallTool.isMac) {
				
				downloadPath = androidMacSDKPath;
				defaultInstallPath = "/opt/Android SDK";
				ignoreRootFolder = "android-sdk-mac";
				
			}

			downloadFile (downloadPath);
			
			var path = unescapePath (param ("Output directory [" + defaultInstallPath + "]"));
			path = createPath (path, defaultInstallPath);
			
			extractFile (Path.withoutDirectory (downloadPath), path, ignoreRootFolder);
			
			if (!InstallTool.isWindows) {
				
				InstallTool.runCommand (path + "/tools", "chmod", [ "755", "*" ]);
				
			}
			
			Lib.println ("Launching the Android SDK Manager to install packages");
			Lib.println ("Please install Android API 8 and SDK Platform-tools");
			
			if (InstallTool.isWindows) {
				
				runInstaller (path + "/SDK Manager.exe");
				
			} else {
				
				runInstaller (path + "/tools/android");
				
			}
			
			if (InstallTool.isMac) {
				
				InstallTool.runCommand ("", "cp", [ InstallTool.nme + "/tools/command-line/bin/debug.keystore", "~/.android/debug.keystore" ] );
				
			}
			
			setAndroidSDK = true;
			defines.set ("ANDROID_SDK", path);
			writeConfig (defines.get ("HXCPP_CONFIG"), defines);
			Lib.println ("");
			
		}
		
		if (answer == Always) {
			
			Lib.println ("Download and install the Android NDK? [y/n/a] a");
			
		} else {
			
			answer = ask ("Download and install the Android NDK?");
			
		}
		
		if (answer == Yes || answer == Always) {
			
			var downloadPath = "";
			var defaultInstallPath = "";
			var ignoreRootFolder = "android-ndk-r8";
			
			if (InstallTool.isWindows) {
				
				downloadPath = androidWindowsNDKPath;
				defaultInstallPath = "C:\\Development\\Android NDK";
				
			} else if (InstallTool.isLinux) {
				
				downloadPath = androidLinuxNDKPath;
				defaultInstallPath = "/opt/Android NDK";
				
			} else {
				
				downloadPath = androidMacNDKPath;
				defaultInstallPath = "/opt/Android NDK";
				
			}
			
			downloadFile (downloadPath);
			
			var path = unescapePath (param ("Output directory [" + defaultInstallPath + "]"));
			path = createPath (path, defaultInstallPath);
			
			extractFile (Path.withoutDirectory (downloadPath), path, ignoreRootFolder);
			
			setAndroidNDK = true;
			defines.set ("ANDROID_NDK_ROOT", path);
			writeConfig (defines.get ("HXCPP_CONFIG"), defines);
			Lib.println ("");
			
		}
		
		if (!InstallTool.isMac) {
			
			if (answer == Always) {
				
				Lib.println ("Download and install Apache Ant? [y/n/a] a");
			
			} else {
				
				answer = ask ("Download and install Apache Ant?");
			
			}
			
			if (answer == Yes || answer == Always) {
				
				var downloadPath = "";
				var defaultInstallPath = "";
				var ignoreRootFolder = "apache-ant-1.8.4";
			
				if (InstallTool.isWindows) {
					
					downloadPath = apacheAntWindowsPath;
					defaultInstallPath = "C:\\Development\\Apache Ant";
				
				} else {
					
					downloadPath = apacheAntUnixPath;
					defaultInstallPath = "/opt/Apache Ant";
					
				}
				
				downloadFile (downloadPath);
				
				var path = unescapePath (param ("Output directory [" + defaultInstallPath + "]"));
				path = createPath (path, defaultInstallPath);
				
				extractFile (Path.withoutDirectory (downloadPath), path, ignoreRootFolder);
				
				setApacheAnt = true;
				defines.set ("ANT_HOME", path);
				writeConfig (defines.get ("HXCPP_CONFIG"), defines);
				
			}
			
			if (answer == Always) {
			
				Lib.println ("Download and install the Java JDK? [y/n/a] a");
			
			} else {
			
				answer = ask ("Download and install the Java JDK?");
			
			}
		
			if (answer == Yes || answer == Always) {
			
				Lib.println ("You must visit the Oracle website to download the Java 6 JDK for your platform");
				var secondAnswer = ask ("Would you like to go there now?");
			
				if (secondAnswer != No) {
					
					openURL (javaJDKURL);
					
				}
				
				Lib.println ("");
			
			}
			
		}
			
		var requiredVariables = new Array <String> ();
		var requiredVariableDescriptions = new Array <String> ();
		var ignoreValues = new Array <String> ();
		
		if (!setAndroidSDK) {
			
			requiredVariables.push ("ANDROID_SDK");
			requiredVariableDescriptions.push ("Path to Android SDK");
			ignoreValues.push ("/SDKs//android-sdk");
			
		}
		
		if (!setAndroidNDK) {
			
			requiredVariables.push ("ANDROID_NDK_ROOT");
			requiredVariableDescriptions.push ("Path to Android NDK");
			ignoreValues.push ("/SDKs//android-ndk-r6");
			
		}
		
		if (!InstallTool.isMac && !setApacheAnt) {
			
			requiredVariables.push ("ANT_HOME");
			requiredVariableDescriptions.push ("Path to Apache Ant");
			ignoreValues.push ("/SDKs//ant");
			
		}
		
		if (!InstallTool.isMac && !setJavaJDK) {
			
			requiredVariables.push ("JAVA_HOME");
			requiredVariableDescriptions.push ("Path to Java JDK");
			ignoreValues.push ("/SDKs//java_jdk");
			
		}
		
		if (!setAndroidSDK && !setAndroidNDK && !setApacheAnt) {
			
			Lib.println ("");
			
		}
		
		var defines = getDefines (requiredVariables, requiredVariableDescriptions, ignoreValues);
		
		if (defines != null) {
			
			defines.set ("ANDROID_SETUP", "true");
			
			if (InstallTool.isMac) {
				
				defines.remove ("ANT_HOME");
				defines.remove ("JAVA_HOME");
				
			}
			
			writeConfig (defines.get ("HXCPP_CONFIG"), defines);
			
		}
		
	}
	
	
	public static function setupBlackBerry ():Void {
		
		var answer = ask ("Download and install the BlackBerry Native SDK?");
		
		if (answer == Yes || answer == Always) {
			
			var downloadPath = "";
			var defaultInstallPath = "";
			
			if (InstallTool.isWindows) {
				
				downloadPath = blackBerryWindowsNativeSDKPath;
				//defaultInstallPath = "C:\\Development\\Android NDK";
				
			} else if (InstallTool.isLinux) {
				
				downloadPath = blackBerryLinuxNativeSDKPath;
				//defaultInstallPath = "/opt/Android NDK";
				
			} else {
				
				downloadPath = blackBerryMacNativeSDKPath;
				//defaultInstallPath = "/opt/Android NDK";
				
			}
			
			downloadFile (downloadPath);
			runInstaller (Path.withoutDirectory (downloadPath));
			Lib.println ("");
			
			/*var path = unescapePath (param ("Output directory [" + defaultInstallPath + "]"));
			path = createPath (path, defaultInstallPath);
			
			extractFile (Path.withoutDirectory (downloadPath), path, ignoreRootFolder);
			
			setAndroidNDK = true;
			defines.set ("ANDROID_NDK_ROOT", path);
			writeConfig (defines.get ("HXCPP_CONFIG"), defines);
			Lib.println ("");*/
			
		}
		
		var defines = getDefines ([ "BLACKBERRY_NDK_ROOT" ], [ "Path to BlackBerry Native SDK" ]);
		
		if (defines != null) {
			
			writeConfig (defines.get ("HXCPP_CONFIG"), defines);
			
		}
		
		var binDirectory = "";
		
		if (InstallTool.isWindows) {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/win32/x86/usr/bin/";
			
		} else if (InstallTool.isMac) {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/macosx/x86/usr/bin/";
			
		} else {
			
			binDirectory = defines.get ("BLACKBERRY_NDK_ROOT") + "/host/linux/x86/usr/bin/";
			
		}
		
		if (answer == Always) {
			
			Lib.println ("Configure a BlackBerry device? [y/n/a] a");
			
		} else {
			
			answer = ask ("Configure a BlackBerry device?");
			
		}
		
		var debugTokenPath:String = null;
		
		if (answer == Yes || answer == Always) {

			var secondAnswer = ask ("Do you have a valid debug token?");
			
			if (secondAnswer == No) {
				
				secondAnswer = ask ("Have you requested code signing keys?");
				
				if (secondAnswer == No) {
					
					secondAnswer = ask ("Would you like to request them now?");
					
					if (secondAnswer != No) {
						
						openURL (blackBerryCodeSigningURL);
						
					}
					
					Lib.println ("");
					Lib.println ("It can take up to two hours for code signing keys to arrive");
					Lib.println ("Please run \"nme setup blackberry\" again at that time");
					Sys.exit (0);
					
				} else {
					
					secondAnswer = ask ("Have you created a keystore file?");
					
					var cskPassword:String = null;
					var keystorePath:String = null;
					var keystorePassword:String = null;
					var outputPath:String = null;
					
					if (secondAnswer == No) {
						
						var pbdtFile = unescapePath (param ("Path to client-PBDT-*.csj file"));
						var rdkFile = unescapePath (param ("Path to client-RDK-*.csj file"));
						var cskPIN = param ("Code signing key PIN");
						cskPassword = param ("Code signing key password");
						
						Lib.println ("Registering code signing keys...");
						
						try {
							
							InstallTool.runCommand ("", binDirectory + "blackberry-signer", [ "-csksetup", "-cskpass", cskPassword ]);
							
						} catch (e:Dynamic) { }
						
						try {
							
							InstallTool.runCommand ("", binDirectory + "blackberry-signer", [ "-register", "-cskpass", cskPassword, "-csjpin", cskPIN, pbdtFile ]);
							InstallTool.runCommand ("", binDirectory + "blackberry-signer", [ "-register", "-cskpass", cskPassword, "-csjpin", cskPIN, rdkFile ]);
							
							Lib.println ("Done.");
							
						} catch (e:Dynamic) {}
						
						keystorePassword = param ("Keystore password");
						var companyName = param ("Company name");
						outputPath = unescapePath (param ("Output directory"));
						keystorePath = outputPath + "/author.p12";
						
						Lib.println ("Creating keystore...");
						
						try {
							
							InstallTool.runCommand ("", binDirectory + "blackberry-keytool", [ "-genkeypair", "-keystore", keystorePath, "-storepass", keystorePassword, "-dname", "cn=(" + companyName + ")", "-alias", "author" ]);
							
							Lib.println ("Done.");
							
						} catch (e:Dynamic) {
							
							Sys.exit (1);
							
						}
						
					}
					
					var names:Array<String> = [];
					var descriptions:Array<String> = [];
					
					if (cskPassword == null) {
						
						cskPassword = param ("Code signing key password");
						
					}
					
					if (keystorePath == null) {
						
						keystorePath = unescapePath (param ("Path to keystore (*.p12) file"));
						
					}
					
					if (keystorePassword == null) {
						
						keystorePassword = param ("Keystore password");
						
					}
					
					var deviceIDs = [ param ("Device PIN") ];
					
					while (ask ("Would you like to add another device PIN?") != No) {
						
						deviceIDs.push (param ("Device PIN"));
						
					}
					
					if (outputPath == null) {
						
						outputPath = unescapePath (param ("Output directory"));
						
					}
					
					debugTokenPath = outputPath + "/debugToken.bar";
					
					Lib.println ("Requesting debug token...");
					
					try {
						
						var params = [ "-cskpass", cskPassword, "-keystore", keystorePath, "-storepass", keystorePassword ];
						
						for (id in deviceIDs) {
							
							params.push ("-deviceId");
							params.push ("0x" + id);
							
						}
						
						params.push (debugTokenPath);
						
						InstallTool.runCommand ("", binDirectory + "/blackberry-debugtokenrequest", params);
						
						Lib.println ("Done.");
						
					} catch (e:Dynamic) {
						
						Sys.exit (1);
						
					}
					
					var defines = getDefines ();
					defines.set ("BLACKBERRY_DEBUG_TOKEN", debugTokenPath);
					writeConfig (defines.get ("HXCPP_CONFIG"), defines);
					
				}
				
			}
			
			if (answer == Yes || answer == Always) {
				
				var names:Array<String> = [];
				var descriptions:Array<String> = [];
				
				if (debugTokenPath == null) {
					
					names.push ("BLACKBERRY_DEBUG_TOKEN");
					descriptions.push ("Path to debug token");
					
				}
				
				names = names.concat ([ "BLACKBERRY_DEVICE_IP", "BLACKBERRY_DEVICE_PASSWORD" ]);
				descriptions = descriptions.concat ([ "Device IP address", "Device password" ]);
				
				var defines = getDefines (names, descriptions);
				
				if (defines != null) {
					
					defines.set ("BLACKBERRY_SETUP", "true");
					writeConfig (defines.get ("HXCPP_CONFIG"), defines);
					
				}
				
				var secondAnswer = ask ("Install debug token on device?");
				
				if (secondAnswer != No) {
					
					Lib.println ("Installing debug token...");
					
					try {
						
						InstallTool.runCommand ("", binDirectory + "/blackberry-deploy", [ "-installDebugToken", defines.get ("BLACKBERRY_DEBUG_TOKEN"), "-device", defines.get ("BLACKBERRY_DEVICE_IP"), "-password", defines.get ("BLACKBERRY_DEVICE_PASSWORD") ]);
						
						Lib.println ("Done.");
						
					} catch (e:Dynamic) {
						
						Sys.exit (1);
						
					}
					
				}
				
			}
			
		}
		
		if (answer == Always) {
			
			Lib.println ("Configure the BlackBerry simulator? [y/n/a] a");
			
		} else {
			
			answer = ask ("Configure the BlackBerry simulator?");
			
		}
		
		if (answer == Yes || answer == Always) {
			
			var defines = getDefines ([ "BLACKBERRY_SIMULATOR_IP" ], [ "Simulator IP address" ]);
			
			if (defines != null) {
				
				writeConfig (defines.get ("HXCPP_CONFIG"), defines);
				
			}
			
		}
		
		var defines = getDefines ();
		defines.set ("BLACKBERRY_SETUP", "true");
		writeConfig (defines.get ("HXCPP_CONFIG"), defines);
		
	}
	
	
	public static function setupHTML5 ():Void {
		
		//InstallTool.runCommand ("", "haxelib", [ "install", "jeash" ]);
		
	}


	public static function setupLinux ():Void {
		
		var parameters = [ "apt-get", "install" ].concat (linuxX64Packages.split (" "));
		InstallTool.runCommand ("", "sudo", parameters);
		
	}
	
	
	public static function setupMac ():Void {
		
		var answer = ask ("Download and install Apple XCode?");
		
		if (answer == Yes || answer == Always) {
			
			Lib.println ("You must purchase XCode from the Mac App Store or download using a paid");
			Lib.println ("member account with Apple.");
			var secondAnswer = ask ("Would you like to open the download page?");
			
			if (secondAnswer != No) {
				
				InstallTool.runCommand ("", "open", [ appleXCodeURL ]);
				
			}
			
		}
		
	}	
	
	
	public static function setupWebOS ():Void {
		
		var answer = ask ("Download and install the HP webOS SDK?");
		
		if (answer == Yes || answer == Always) {
			
			var sdkPath = "";
			
			if (InstallTool.isWindows) {
				
				if (Sys.environment ().exists ("PROCESSOR_ARCHITEW6432") && Sys.getEnv ("PROCESSOR_ARCHITEW6432").indexOf ("64") > -1) {
					
					sdkPath = webOSWindowsX64SDKPath;
					
				} else {
					
					sdkPath = webOSWindowsX86SDKPath;
					
				}
				
			} else if (InstallTool.isLinux) {
				
				sdkPath = webOSLinuxSDKPath;
				
			} else {
				
				sdkPath = webOSMacSDKPath;
				
			}

			downloadFile (sdkPath);
			runInstaller (Path.withoutDirectory (sdkPath));
			Lib.println ("");
			
		}
		
		if (InstallTool.isWindows) {
			
			if (answer == Always) {
				
				Lib.println ("Download and install the CodeSourcery C++ toolchain? [y/n/a] a");
				
			} else {
				
				answer = ask ("Download and install the CodeSourcery C++ toolchain?");
				
			}

			if (answer != No) {
				
				downloadFile (codeSourceryWindowsPath);
				runInstaller (Path.withoutDirectory (codeSourceryWindowsPath));
				
			}
			
		} else if (InstallTool.isLinux) {
			
			if (answer == Always) {
				
				Lib.println ("Download and install Novacom? [y/n/a] a");
				
			} else {
				
				answer = ask ("Download and install Novacom?");
				
			}

			if (answer != No) {

				var process = new Process("uname", ["-m"]);
				var ret = process.stdout.readAll().toString();
				var ret2 = process.stderr.readAll().toString();
				process.exitCode(); //you need this to wait till the process is closed!
				process.close();
			
				var novacomPath = webOSLinuxX86NovacomPath;

				if (ret.indexOf ("64") > -1) {
				
					novacomPath = webOSLinuxX64NovacomPath;
				
				}
				
				downloadFile (novacomPath);
				runInstaller (Path.withoutDirectory (novacomPath));
			
			}
		
		}
		
	}
	
	
	public static function setupWindows ():Void {
		
		var answer = ask ("Download and install Visual Studio C++ Express?");
		
		if (answer == Yes || answer == Always) {
			
			downloadFile (windowsVisualStudioCPPPath);
			runInstaller (Path.withoutDirectory (windowsVisualStudioCPPPath));
			
		}
		
	}
	
	
	private static function stripQuotes (path:String):String {
		
		return path.split ("\"").join ("");
		
	}
	
	
	private static function throwPermissionsError () {
		
		if (InstallTool.isWindows) {
			
			Lib.println ("Unable to access directory. Perhaps you need to run \"setup\" with administrative privileges?");
			
		} else {
			
			Lib.println ("Unable to access directory. Perhaps you should run \"setup\" again using \"sudo\"");
			
		}
		
		Sys.exit (1);
		
	}
	
	
	private static function unescapePath (path:String):String {
		
		path = StringTools.replace (path, "\\ ", " ");
		
		if (!InstallTool.isWindows && StringTools.startsWith (path, "~/")) {
			
			path = Sys.getEnv ("HOME") + "/" + path.substr (2);
			
		}
		
		return path;
		
	}
	
	
	private static function writeConfig (path:String, defines:Hash <String>):Void {
		
		var newContent = "";
		var definesText = "";
		
		for (key in defines.keys ()) {
			
			if (key != "HXCPP_CONFIG") {
				
				definesText += "		<set name=\"" + key + "\" value=\"" + stripQuotes (defines.get (key)) + "\" />\n";
				
			}
			
		}
		
		if (FileSystem.exists (path)) {
			
			var input = File.read (path, false);
			var bytes = input.readAll ();
			input.close ();
			
			if (!backedUpConfig) {
				
				try {
					
					var backup = File.write (path + ".bak", false);
					backup.writeBytes (bytes, 0, bytes.length);
					backup.close ();
					
				} catch (e:Dynamic) { }
				
				backedUpConfig = true;
			
			}
			
			var content = bytes.readString (0, bytes.length);
			
			var startIndex = content.indexOf ("<section id=\"vars\">");
			var endIndex = content.indexOf ("</section>", startIndex);
			
			newContent += content.substr (0, startIndex) + "<section id=\"vars\">\n		\n";
			newContent += definesText;
			newContent += "		\n	" + content.substr (endIndex);
			
		} else {
			
			newContent += "<xml>\n\n";
			newContent += "	<section id=\"vars\">\n\n";
			newContent += definesText;
			newContent += "	</section>\n\n</xml>";
			
		}
		
		var output = File.write (path, false);
		output.writeString (newContent);
		output.close ();
		
	}
	
	
}


class Progress extends haxe.io.Output {

	var o : haxe.io.Output;
	var cur : Int;
	var max : Int;
	var start : Float;

	public function new(o) {
		this.o = o;
		cur = 0;
		start = haxe.Timer.stamp();
	}

	function bytes(n) {
		cur += n;
		if( max == null )
			Lib.print(cur+" bytes\r");
		else
			Lib.print(cur+"/"+max+" ("+Std.int((cur*100.0)/max)+"%)\r");
	}

	public override function writeByte(c) {
		o.writeByte(c);
		bytes(1);
	}

	public override function writeBytes(s,p,l) {
		var r = o.writeBytes(s,p,l);
		bytes(r);
		return r;
	}

	public override function close() {
		super.close();
		o.close();
		var time = haxe.Timer.stamp() - start;
		var speed = (cur / time) / 1024;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;
		
		if (cur > 0) {
			
			Lib.print("Download complete : " + cur + " bytes in " + time + "s (" + speed + "KB/s)\n");
			
		}
		
	}

	public override function prepare(m) {
		max = m;
	}

}


enum Answer {
	Yes;
	No;
	Always;
}
