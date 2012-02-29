import documentation.DocumentationGenerator;
import generate.GenerateJavaExterns;
import buildhx.installers.AndroidInstaller;
import buildhx.installers.CPPInstaller;
import buildhx.installers.FlashInstaller;
import buildhx.installers.HTML5Installer;
import buildhx.installers.InstallerBase;
import buildhx.installers.IOSInstaller;
import buildhx.installers.NekoInstaller;
import buildhx.installers.WebOSInstaller;
import neko.Lib;
import neko.Sys;
import nme.Loader;
import setup.PlatformSetup;


class InstallTool extends BuildHX {
	
	
	override private function createInstaller (templateBase:String, command:String, defines:Hash <String>, includePaths:Array <String>, projectFile:String, target:String, targetFlags:Hash <String>, debug:Bool, args:Array<String>) {
		
		var installer:InstallerBase = null;
		
		if (command == "document") {
			
			installer = new DocumentationGenerator ();
			
		} else {
			
			switch (target) {
				
				case "android":
					
					installer = new AndroidInstaller ();
				
				case "cpp":
					
					installer = new CPPInstaller ();
				
				case "ios":
					
					installer = new IOSInstaller ();
				
				case "webos":
					
					installer = new WebOSInstaller ();
				
				case "flash":
					
					installer = new FlashInstaller ();
				
				case "neko":
					
					installer = new NekoInstaller ();
				
				case "html5":
					
					installer = new HTML5Installer ();
				
				default:
					
					error ("'" + target + "' is not a valid target");
					return;
				
			}
			
		}
		
		installer.create (this, templateBase, command, defines, includePaths, projectFile, target, targetFlags, debug, args);
		
	}
	
	
	override private function displayHelp ():Void {
		
		Lib.println ("NME Command-Line Tools 3.3.0");
		Lib.println ("");
		Lib.println (" Usage : nme setup (target)");
		Lib.println (" Usage : nme help");
		Lib.println (" Usage : nme [update|build|run|test|display] <project> <target> [options]");
		Lib.println (" Usage : nme document <project> (target)");
		Lib.println (" Usage : nme generate <args> [options]");
		Lib.println ("");
		Lib.println (" Commands : ");
		Lib.println ("");
		Lib.println ("  setup : Setup NME or a specific target");
		Lib.println ("  help : Show this information");
		Lib.println ("  update : Copy assets for the specified project/target");
		Lib.println ("  build : Compile and package for the specified project/target");
		Lib.println ("  run : Install and run for the specified project/target");
		Lib.println ("  test : Update, build and run in one command");
		Lib.println ("  display : Display information for the specified project/target");
		Lib.println ("  document : Generate documentation using haxedoc");
		Lib.println ("  generate : Tools to help create source code automatically");
		Lib.println ("");
		Lib.println (" Targets : ");
		Lib.println ("");
		Lib.println ("  android : Create Google Android applications");
		Lib.println ("  flash : Create SWF applications for Adobe Flash Player");
		Lib.println ("  html5 : Create HTML5 canvas applications using Jeash");
		Lib.println ("  ios : Create Apple iOS applications");
		Lib.println ("  linux : Create Linux applications");
		Lib.println ("  mac : Create Apple Mac OS X applications");
		Lib.println ("  webos : Create HP webOS applications");
		Lib.println ("  windows : Create Microsoft Windows applications");
		Lib.println ("");
		Lib.println (" Options : ");
		Lib.println ("");
		Lib.println ("  -debug : Use debug configuration instead of release");
		Lib.println ("  -verbose : Print additional information (when available)");
		Lib.println ("  -hxml : Print HXML information (for use with display)");
		Lib.println ("  -nmml : Print NMML information (for use with display)");
		Lib.println ("  -xml : Generate XML type information, for use with document");
		Lib.println ("  -java-externs : Generate Haxe source code from compiled Java classes");
		Lib.println ("  [windows|mac|linux] -neko : Build with Neko instead of C++");
		Lib.println ("  [linux] -64 : Compile for 64-bit instead of 32-bit");
		Lib.println ("  [flash] -web : Generate web template files");
		Lib.println ("  [flash] -chrome : Generate Google Chrome app template files");
		Lib.println ("  [flash] -opera : Generate an Opera Widget");
		Lib.println ("  [ios] -simulator : Build/test for the iPhone Simulator");
		Lib.println ("  [ios] -simulator -ipad : Builds/test for the iPad Simulator");
		Lib.println ("  [run|test] -args a0 a1 a1 ... : pass remainder of the commandline to executable");
		
	}
	
	
	override private function displayInfo ():Void {
		
		Lib.println ("NME Command-Line Tools 1.0.0");
		Lib.println ("Use \"nme setup\" to configure NME or \"nme help\" for more commands");
		
	}
	
	
	override public function error (message:String = "", e:Dynamic = null):Void {
		
		if (message != "") {
			
			try {
				
				nme_error_output ("Error: " + message + "\n");
				
			} catch (e:Dynamic) {}
			
		}
		
		if (verbose && e != null) {
			
			Lib.rethrow (e);
			
		}
		
		Sys.exit (1);
		
	}
	
	
	override private function initialize ():Void {
		
		super.initialize ();
		
		validCommands.push ("setup");
		validCommands.push ("document");
		validCommands.push ("generate");
		
	}
	
	
	override private function processCommand ():Void {
		
		templateBase = libDirectory + "/templates/";
		
		if (command == "setup") {
			
			if (words.length == 0) {
				
				PlatformSetup.run (this);
				
			} else if (words.length == 1) {
				
				PlatformSetup.run (this, words[0]);
				
			} else {
				
				error ("Incorrect number of arguments for command '" + command + "'");
				return;
				
			}
			
		} else if (command == "generate") {
			
			if (targetFlags.exists ("java-externs")) {
				
				if (words.length != 2) {
					
					error ("To use 'generate -java-externs' you need to provide two arguments: an input path with compiled Java classes, and an output directory");
					return;
					
				}
				
				new GenerateJavaExterns (this, words[0], words[1]);
				
			}
			
		} else {
			
			if (command == "document" && words.length != 1) {
				
				error ("Incorrect number of arguments for command '" + command + "'");
				return;
				
			}
			
			super.processCommand ();
			
		}
		
	}
	
	
	
	
	public static function main () {
		
		new InstallTool ();
		
	}
	
	
	private static var nme_error_output = Loader.load ("nme_error_output", 1);
	
	
}
