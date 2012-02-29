package setup;


import haxe.Http;
import haxe.io.Eof;
import buildhx.installers.InstallerBase;
import neko.io.File;
import neko.io.Path;
import neko.zip.Reader;
import neko.FileSystem;
import neko.Sys;
import neko.Lib;


/**
 * ...
 * @author Joshua Granick
 */

class PlatformSetup {
	
	
	private static var androidLinuxNDKPath = "http://dl.google.com/android/ndk/android-ndk-r7b-linux-x86.tar.bz2";
	private static var androidLinuxSDKPath = "http://dl.google.com/android/android-sdk_r16-linux.tgz";
	private static var androidMacNDKPath = "http://dl.google.com/android/ndk/android-ndk-r7b-darwin-x86.tar.bz2";
	private static var androidMacSDKPath = "http://dl.google.com/android/android-sdk_r16-macosx.zip";
	private static var androidWindowsNDKPath = "http://dl.google.com/android/ndk/android-ndk-r7b-windows.zip";
	private static var androidWindowsSDKPath = "http://dl.google.com/android/android-sdk_r16-windows.zip";
	private static var apacheAntUnixPath = "http://apache.mesi.com.ar//ant/binaries/apache-ant-1.8.2-bin.tar.gz";
	private static var apacheAntWindowsPath = "http://apache.mesi.com.ar//ant/binaries/apache-ant-1.8.2-bin.zip";
	private static var appleXCodeURL = "http://developer.apple.com/xcode/";
	private static var codeSourceryWindowsPath = "http://sourcery.mentor.com/public/gnu_toolchain/arm-none-linux-gnueabi/arm-2009q1-203-arm-none-linux-gnueabi.exe";
	private static var javaJDKURL = "http://www.oracle.com/technetwork/java/javase/downloads/jdk-6u31-download-1501634.html";
	private static var linuxX64Packages = "ia32-libs gcc-multilib g++-multilib";
	private static var webOSLinuxX64NovacomPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/palm-novacom_1.0.80_amd64.deb";
	private static var webOSLinuxX86NovacomPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/palm-novacom_1.0.80_i386.deb";
	private static var webOSLinuxSDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/palm-sdk_3.0.5-svn528736-pho676_i386.deb";
	private static var webOSMacSDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/Palm_webOS_SDK.3.0.5.676.dmg";
	private static var webOSWindowsX64SDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/HP_webOS_SDK-Win-3.0.5-676-x64.exe";
	private static var webOSWindowsX86SDKPath = "http://cdn.downloads.palm.com/sdkdownloads/3.0.5.676/sdkBinaries/HP_webOS_SDK-Win-3.0.5-676-x86.exe";
	private static var windowsVisualStudioCPPPath = "http://download.microsoft.com/download/1/D/9/1D9A6C0E-FC89-43EE-9658-B9F0E3A76983/vc_web.exe";

	private static var backedUpConfig:Bool = false;
	private static var buildTool:BuildHX;
	
	
	private static function ask (question:String):Answer {
		
		while (true) {
			
			Lib.print (question + " [y/n/a] ? ");
			
			switch (File.stdin ().readLine ()) {
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
				
				buildTool.mkdir (defaultPath);
				return defaultPath;
				
			} else {
				
				buildTool.mkdir (path);
				return path;
				
			}
			
		} catch (e:Dynamic) {
			
			throwPermissionsError ();
			return "";
			
		}
		
	}
	
	
	private static function downloadFile (remotePath:String, localPath:String = ""):Void {
		
		if (localPath == "") {
			
			localPath = Path.withoutDirectory (remotePath);
			
		}
		
		if (FileSystem.exists (localPath)) {
			
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
		
		Lib.println ("Downloading " + localPath + "...");
		h.customRequest (false, progress);
		
	}
	
	
	private static function extractFile (sourceZIP:String, targetPath:String, ignoreRootFolder:String = ""):Void {
		
		var extension = Path.extension (sourceZIP);
		
		if (extension != "zip") {
			
			var arguments = "xvzf";			
						
			if (extension == "bz2") {
				
				arguments = "xvjf";
				
			}	
			
			if (ignoreRootFolder != "") {
				
				buildTool.runCommand ("", "tar", [ arguments, sourceZIP ]);
				buildTool.runCommand ("", "cp", [ "-R", ignoreRootFolder + "/*", targetPath ]);
				Sys.command ("rm", [ "-r", ignoreRootFolder ]);
				
			} else {
				
				//buildTool.runCommand (targetPath, "tar", [ arguments, FileSystem.fullPath (sourceZIP) ]);
				
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
							buildTool.mkdir (targetPath + "/" + path);
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
			
			value = param (description + " [" + value + "]");
			
			if (value != "") {
				
				defines.set (name, value);
				
			} else if (value == Sys.getEnv (name)) {
				
				defines.remove (name);
				
			}
			
		}
		
		return defines;
		
	}
	
	
	public static function installNME ():Void {
		
		if (buildTool.isWindows) {
			
			var haxePath = Sys.getEnv ("HAXEPATH");
			
			if (haxePath == null || haxePath == "") {
				
				haxePath = "C:\\Motion-Twin\\haxe\\";
				
			}
			
			File.copy (buildTool.libDirectory + "\\tools\\command-line\\bin\\nme.bat", haxePath + "\\nme.bat");
			
		} else {
			
			File.copy (buildTool.libDirectory + "/tools/command-line/bin/nme.sh", "/usr/lib/haxe/nme");
			Sys.command ("chmod", [ "755", "/usr/lib/haxe/nme" ]);
			link ("haxe", "nme", "/usr/bin");
			
		}
		
		if (buildTool.isMac) {
			
			var defines = getDefines ();
			defines.set ("MAC_USE_CURRENT_SDK", "1");
			writeConfig (defines.get ("HXCPP_CONFIG"), defines);
			
		}
		
	}
	
	
	private static function link (dir:String, file:String, dest:String):Void {
		
		Sys.command("rm -rf " + dest + "/" + file);
		Sys.command("ln -s " + "/usr/lib" +"/" + dir + "/" + file + " " + dest + "/" + file);
		
	}
	
	
	private static function param (name:String, ?passwd:Bool):String {
		
		Lib.print (name + " : ");
		
		if (passwd) {
			var s = new StringBuf ();
			var c;
			while ((c = File.getChar (false)) != 13)
				s.addChar (c);
			Lib.print ("");
			return s.toString ();
		}
		
		try {
			
			return File.stdin ().readLine ();
			
		} catch (e:Eof) {
			
			return "";
			
		}
		
	}
	
	
	public static function run (buildTool:BuildHX, target:String = "") {
		
		PlatformSetup.buildTool = buildTool;
		
		try {
			
			switch (target) {
				
				case "android":
					
					setupAndroid ();
				
				case "blackberry":
					
					setupBlackBerry ();
				
				case "html5":
					
					setupHTML5 ();
				
				case "ios":
					
					if (buildTool.isMac) {
						
						setupMac ();
						
					}
				
				case "linux":
					
					if (buildTool.isLinux) {
						
						setupLinux ();
						
					}
				
				case "mac":
					
					if (buildTool.isMac) {
						
						setupMac ();
						
					}
				
				case "webos":
					
					setupWebOS ();
				
				case "windows":
					
					if (buildTool.isWindows) {
						
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
		
		if (buildTool.isWindows) {
			
			try {
				
				Lib.println (message);
				buildTool.runCommand ("", "call", [ path ]);
				Lib.println ("Done");
				
			} catch (e:Dynamic) {}
			
		} else if (buildTool.isLinux) {
			
			if (Path.extension (path) == "deb") {
				
				buildTool.runCommand ("", "sudo", [ "dpkg", "-i", "--force-architecture", path ]);
				
			} else {
				
				Lib.println (message);
				buildTool.runCommand ("", path, []);
				Lib.println ("Done");
				
			}
			
		} else {
			
			if (Path.extension (path) == "") {
				
				Lib.println (message);
				Sys.command ("chmod", [ "755", path ]);
				buildTool.runCommand ("", path, []);
				Lib.println ("Done");
			
			} else {
				
				buildTool.runCommand ("", "open", [ path ]);
				
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
			
			if (buildTool.isWindows) {
				
				downloadPath = androidWindowsSDKPath;
				defaultInstallPath = "C:\\Development\\Android SDK";
			
			} else if (buildTool.isLinux) {
				
				downloadPath = androidLinuxSDKPath;
				defaultInstallPath = "/opt/Android SDK";
				ignoreRootFolder = "android-sdk-linux";
				
			} else if (buildTool.isMac) {
				
				downloadPath = androidMacSDKPath;
				defaultInstallPath = "/opt/Android SDK";
				ignoreRootFolder = "android-sdk-mac";
				
			}

			downloadFile (downloadPath);
			
			var path = param ("Output directory [" + defaultInstallPath + "]");
			path = createPath (path, defaultInstallPath);
			
			extractFile (Path.withoutDirectory (downloadPath), path, ignoreRootFolder);
			
			if (!buildTool.isWindows) {
				
				buildTool.runCommand (path + "/tools", "chmod", [ "755", "*" ]);
				
			}
			
			Lib.println ("Launching the Android SDK Manager to install packages");
			Lib.println ("Please install Android API 8 and SDK Platform-tools");
			
			if (buildTool.isWindows) {
				
				runInstaller (path + "/SDK Manager.exe");
				
			} else {
				
				runInstaller (path + "/tools/android");
				
			}
			
			if (buildTool.isMac) {
				
				buildTool.runCommand ("", "cp", [ buildTool.libDirectory + "/tools/command-line/bin/debug.keystore", "~/.android/debug.keystore" ] );
				
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
			var ignoreRootFolder = "android-ndk-r6b";
			
			if (buildTool.isWindows) {
				
				downloadPath = androidWindowsNDKPath;
				defaultInstallPath = "C:\\Development\\Android NDK";
				
			} else if (buildTool.isLinux) {
				
				downloadPath = androidLinuxNDKPath;
				defaultInstallPath = "/opt/Android NDK";
				
			} else {
				
				downloadPath = androidMacNDKPath;
				defaultInstallPath = "/opt/Android NDK";
				
			}
			
			downloadFile (downloadPath);
			
			var path = param ("Output directory [" + defaultInstallPath + "]");
			path = createPath (path, defaultInstallPath);
			
			extractFile (Path.withoutDirectory (downloadPath), path, ignoreRootFolder);
			
			setAndroidNDK = true;
			defines.set ("ANDROID_NDK_ROOT", path);
			writeConfig (defines.get ("HXCPP_CONFIG"), defines);
			Lib.println ("");
			
		}
		
		if (!buildTool.isMac) {
			
			if (answer == Always) {
				
				Lib.println ("Download and install Apache Ant? [y/n/a] a");
			
			} else {
				
				answer = ask ("Download and install Apache Ant?");
			
			}
			
			if (answer == Yes || answer == Always) {
				
				var downloadPath = "";
				var defaultInstallPath = "";
				var ignoreRootFolder = "apache-ant-1.8.2";
			
				if (buildTool.isWindows) {
					
					downloadPath = apacheAntWindowsPath;
					defaultInstallPath = "C:\\Development\\Apache Ant";
				
				} else {
					
					downloadPath = apacheAntUnixPath;
					defaultInstallPath = "/opt/Apache Ant";
					
				}
				
				downloadFile (downloadPath);
				
				var path = param ("Output directory [" + defaultInstallPath + "]");
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
			
				Lib.println ("You must visit the Oracle website to download the Java JDK for your platform");
				var secondAnswer = ask ("Would you like to go there now?");
			
				if (secondAnswer != No) {
				
					if (buildTool.isWindows) {
					
						Sys.command ("explorer", [ javaJDKURL ]);
					
					} else if (buildTool.isLinux) {
						
						buildTool.runCommand ("", "firefox", [ javaJDKURL ]);
					
					} else {
						
						buildTool.runCommand ("", "open", [ javaJDKURL ]);
						
					}
					
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
		
		if (!buildTool.isMac && !setApacheAnt) {
			
			requiredVariables.push ("ANT_HOME");
			requiredVariableDescriptions.push ("Path to Apache Ant");
			ignoreValues.push ("/SDKs//ant");
			
		}
		
		if (!buildTool.isMac && !setJavaJDK) {
			
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
			
			if (buildTool.isMac) {
				
				defines.remove ("ANT_HOME");
				defines.remove ("JAVA_HOME");
				
			}
			
			writeConfig (defines.get ("HXCPP_CONFIG"), defines);
			
		}
		
	}
	
	
	public static function setupBlackBerry ():Void {
		
		var defines = getDefines ([ "BLACKBERRY_SDK_ROOT" ], [ "Path to BlackBerry Native SDK" ]);
		
		defines.set ("BLACKBERRY_SETUP", "true");
		
		if (defines != null) {
			
			writeConfig (defines.get ("HXCPP_CONFIG"), defines);
			
		}
		
	}
	
	
	public static function setupHTML5 ():Void {
		
		buildTool.runCommand ("", "haxelib", [ "install", "jeash" ]);
		
	}


	public static function setupLinux ():Void {
		
		var parameters = [ "apt-get", "install" ].concat (linuxX64Packages.split (" "));
		buildTool.runCommand ("", "sudo", parameters);
		
	}
	
	
	public static function setupMac ():Void {
		
		var answer = ask ("Download and install Apple XCode?");
		
		if (answer == Yes || answer == Always) {
			
			Lib.println ("You must purchase XCode from the Mac App Store or download using a paid");
			Lib.println ("member account with Apple.");
			var secondAnswer = ask ("Would you like to open the download page?");
			
			if (secondAnswer != No) {
				
				buildTool.runCommand ("", "open", [ appleXCodeURL ]);
				
			}
			
		}
		
	}	
	
	
	public static function setupWebOS ():Void {
		
		var answer = ask ("Download and install the HP webOS SDK?");
		
		if (answer == Yes || answer == Always) {
						
			var sdkPath = "";
			
			if (buildTool.isWindows) {
				
				if (Sys.environment ().exists ("PROCESSOR_ARCHITEW6432") && Sys.getEnv ("PROCESSOR_ARCHITEW6432").indexOf ("64") > -1) {
					
					sdkPath = webOSWindowsX64SDKPath;
					
				} else {
					
					sdkPath = webOSWindowsX86SDKPath;
					
				}
				
			} else if (buildTool.isLinux) {
				
				sdkPath = webOSLinuxSDKPath;
				
			} else {
				
				sdkPath = webOSMacSDKPath;
				
			}

			downloadFile (sdkPath);
			runInstaller (Path.withoutDirectory (sdkPath));
			Lib.println ("");
			
		}
		
		if (buildTool.isWindows) {
			
			if (answer == Always) {
				
				Lib.println ("Download and install the CodeSourcery C++ toolchain? [y/n/a] a");
				
			} else {
				
				answer = ask ("Download and install the CodeSourcery C++ toolchain?");
				
			}

			if (answer != No) {
				
				downloadFile (codeSourceryWindowsPath);
				runInstaller (Path.withoutDirectory (codeSourceryWindowsPath));
				
			}
			
		} else if (buildTool.isLinux) {
			
			if (answer == Always) {
				
				Lib.println ("Download and install Novacom? [y/n/a] a");
				
			} else {
				
				answer = ask ("Download and install Novacom?");
				
			}

			if (answer != No) {

				var process = new neko.io.Process("uname", ["-m"]);
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
		
		if (buildTool.isWindows) {
			
			Lib.println ("Unable to access directory. Perhaps you need to run \"setup\" with administrative privileges?");
			
		} else {
			
			Lib.println ("Unable to access directory. Perhaps you should run \"setup\" again using \"sudo\"");
			
		}
		
		Sys.exit (1);
		
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
			
				var backup = File.write (path + ".bak", false);
				backup.writeBytes (bytes, 0, bytes.length);
				backup.close ();
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
			neko.Lib.print(cur+" bytes\r");
		else
			neko.Lib.print(cur+"/"+max+" ("+Std.int((cur*100.0)/max)+"%)\r");
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
		neko.Lib.print("Download complete : "+cur+" bytes in "+time+"s ("+speed+"KB/s)\n");
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
