package installers;


import haxe.io.Path;
import neko.Lib;
import sys.io.File;
import sys.io.Process;


class NekoInstaller extends DesktopInstaller {
	
	
	override function copyResultTo (inExe:String) {
		
		var nekoExecutablePath = NME + "/tools/command-line/neko/bin/neko-" + targetName + get64 ();
		var nekoExecutableContents = File.getBytes (nekoExecutablePath);
		
		var applicationFilePath = getBuildDir () + "/ApplicationMain.n";
		var applicationFileContents = File.getBytes (applicationFilePath);
		
		var output = File.write (inExe, true);
		output.write (nekoExecutableContents);
		output.write (applicationFileContents);
		output.writeString ("NEKO");
		output.writeUInt30 (nekoExecutableContents.length);
		output.close ();
		
		recursiveCopy (NME + "/tools/command-line/neko/ndll/" + targetName + get64 () + "/", getExeDir (), false);
		
		/*
		
		var exe_content = neko.io.File.getBytes("bin/xcross-"+os);
		var p = new neko.io.Path(file);
		if( os == "win" )
			p.ext = "exe";
		else
			p.ext = null;
		p.file += "-"+os;
		var exe_file = p.toString();
		var out = neko.io.File.write(exe_file,true);
		out.write(exe_content);
		out.write(content);
		out.writeString("NEKO");
		out.writeUInt30(exe_content.length);
		out.close();
		return exe_file;
		
		*/
		
		
		//runCommand (getBuildDir (), "nekotools", ["boot", "ApplicationMain.n"]);
		//copyIfNewer (getBuildDir () + "/ApplicationMain" + extension, inExe);
		
	}


	override function generateContext ():Void {
		
		super.generateContext ();
		
		context.NEKO_FILE = getBuildDir () + "/ApplicationMain.n";
		context.HXML_PATH = NME + "/tools/command-line/neko/hxml/" + (debug ? "debug" : "release") + ".hxml";
		
	}
   
   
	override function getVM () {
	   
		return "neko";
		
	}
	
	
}