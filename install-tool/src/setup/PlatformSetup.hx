package setup;


import haxe.Http;
import haxe.io.Eof;
import installers.InstallerBase;
import neko.io.File;
import neko.io.Path;
import neko.FileSystem;
import neko.Sys;
import neko.Lib;


/**
 * ...
 * @author Joshua Granick
 */

class PlatformSetup {
	
	
	private static var androidLinuxNDKPath = "http://dl.google.com/android/ndk/android-ndk-r6b-linux-x86.tar.bz2";
	private static var androidLinuxSDKPath = "http://dl.google.com/android/android-sdk_r15-linux.tgz";
	private static var androidMacNDKPath = "http://dl.google.com/android/ndk/android-ndk-r6b-darwin-x86.tar.bz2";
	private static var androidMacSDKPath = "http://dl.google.com/android/android-sdk_r15-macosx.zip";
	private static var androidWindowsNDKPath = "http://dl.google.com/android/ndk/android-ndk-r6b-windows.zip";
	private static var androidWindowsSDKPath = "http://dl.google.com/android/android-sdk_r15-windows.zip";
	private static var apacheAntUnixPath = "http://apache.mesi.com.ar//ant/binaries/apache-ant-1.8.2-bin.tar.gz";
	private static var apacheAntWindowsPath = "http://apache.mesi.com.ar//ant/binaries/apache-ant-1.8.2-bin.zip";
	private static var appleXCodeURL = "http://developer.apple.com/xcode/";
	private static var codeSourceryWindowsPath = "https://sourcery.mentor.com/public/gnu_toolchain/arm-none-linux-gnueabi/arm-2009q1-203-arm-none-linux-gnueabi.exe";
	private static var javaJDKLinuxX64Path = "http://download.oracle.com/otn-pub/java/jdk/7u1-b08/jdk-7u1-linux-x64.tar.gz";
	private static var javaJDKLinuxX86Path = "http://download.oracle.com/otn-pub/java/jdk/7u1-b08/jdk-7u1-linux-i586.tar.gz";
	private static var javaJDKWindowsX64Path = "http://download.oracle.com/otn-pub/java/jdk/7u1-b08/jdk-7u1-windows-x64.exe";
	private static var javaJDKWindowsX86Path = "http://download.oracle.com/otn-pub/java/jdk/7u1-b08/jdk-7u1-windows-i586.exe";
	private static var linuxX64Packages = "ia32-libs gcc-multilib g++-multilib";
	private static var webOSLinuxX64NovacomPath = "https://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/palm-novacom_1.0.80_amd64.deb";
	private static var webOSLinuxX86NovacomPath = "https://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/palm-novacom_1.0.80_i386.deb";
	private static var webOSLinuxSDKPath = "https://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/palm-sdk_3.0.4-svn519870-pho669_i386.deb";
	private static var webOSMacSDKPath = "https://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/Palm_webOS_SDK.3.0.4.669.dmg";
	private static var webOSWindowsX64SDKPath = "https://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/HP_webOS_SDK-Win-3.0.4-669-x64.exe";
	private static var webOSWindowsX86SDKPath = "https://cdn.downloads.palm.com/sdkdownloads/3.0.4.669/sdkBinaries/HP_webOS_SDK-Win-3.0.4-669-x86.exe";
	private static var windowsVisualStudioCPPPath = "http://download.microsoft.com/download/1/D/9/1D9A6C0E-FC89-43EE-9658-B9F0E3A76983/vc_web.exe";
	
	
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
	
	
	private static function downloadFile (remotePath:String, localPath:String = ""):Void {
		
		if (localPath == "") {
			
			localPath = Path.withoutDirectory (remotePath);
			
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
	
	
	private static function getDefines (names:Array < String > = null, descriptions:Array <String> = null):Hash < String > {
		
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
			var value = "";
			
			if (defines.exists (name)) {
				
				value = defines.get (name);
				
			} else if (env.exists (name)) {
				
				value = Sys.getEnv (name);
				
			}
			
			value = param (description + " [" + value + "]");
			
			if (value != "" && value != Sys.getEnv (name)) {
				
				defines.set (name, value);
				
			}
			
		}
		
		return defines;
		
	}
	
	
	public static function installNME ():Void {
		
		if (InstallTool.isWindows) {
			
			File.copy (InstallTool.nme + "\\install-tool\\bin\\nme.bat", "C:\\Motion-Twin\\haxe\\nme.bat");
			
		} else {
			
			File.copy (InstallTool.nme + "/install-tool/bin/nme.sh", "/usr/lib/haxe/nme");
			Sys.command ("chmod", [ "755", "/usr/lib/haxe/nme" ]);
			link ("haxe", "nme", "/usr/bin");
			
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
	
	
	private static function runInstaller (path:String):Void {
		
		if (InstallTool.isWindows) {
			
			try {
				
				Lib.println ("Waiting for setup to complete...");
				InstallTool.runCommand ("", "call", [ path ]);
				Lib.println ("Done");
				
			} catch (e:Dynamic) {}
			
		}
		
	}
	
	
	public static function setupAndroid ():Void {
		
		var defines = getDefines ([ "ANDROID_SDK", "ANDROID_NDK_ROOT", "ANT_HOME", "JAVA_HOME" ], [ "Path to Android SDK", "Path to Android NDK", "Path to Apache Ant", "Path to Java JDK" ]);
		
		defines.set ("ANDROID_SETUP", "true");
		
		if (defines != null) {
			
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
	
	
	public static function setupWebOS ():Void {
		
		var answer = ask ("Download and install the HP webOS SDK?");
		
		if (answer == Yes || answer == Always) {
			
			if (InstallTool.isWindows) {
				
				var sdkPath = "";
				
				if (Sys.environment ().exists ("PROCESSOR_ARCHITEW6432") && Sys.getEnv ("PROCESSOR_ARCHITEW6432").indexOf ("64") > -1) {
					
					sdkPath = webOSWindowsX64SDKPath;
					
				} else {
					
					sdkPath = webOSWindowsX86SDKPath;
					
				}
				
				downloadFile (sdkPath);
				runInstaller (Path.withoutDirectory (sdkPath));
				
			}
			
		}
		
		if (InstallTool.isWindows) {
			
			if (answer == Always) {
				
				Lib.println ("Download and install the CodeSourcery C++ toolchain? [y/n/a] a");
				
			} else {
				
				answer = ask ("Download and install the CodeSourcery C++ toolchain?");
				
				if (answer == Yes) {
					
					downloadFile (codeSourceryWindowsPath);
					runInstaller (Path.withoutDirectory (codeSourceryWindowsPath));
					
				}
				
			}
			
		}
		
	}
	
	
	private static function writeConfig (path:String, defines:Hash <String>):Void {
		
		var newContent = "";
		var definesText = "";
		
		for (key in defines.keys ()) {
			
			if (key != "HXCPP_CONFIG") {
				
				definesText += "		<set name=\"" + key + "\" value=\"" + defines.get (key) + "\" />\n";
				
			}
			
		}
		
		if (FileSystem.exists (path)) {
			
			var input = File.read (path, false);
			var bytes = input.readAll ();
			input.close ();
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