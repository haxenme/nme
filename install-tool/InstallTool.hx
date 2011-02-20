
class Asset
{
   public var name:String;
   public var dest:String;
   public var type:String;
   public var id:String;
   public var resourceIndex:Int;
   public var flatName:String;
   public var resourceName:String;

   static var usedRes = new Hash<Bool>();


   public function new(inName:String, inDest:String, inType:String,inID:String)
   {
      name = inName;
      dest = inDest;
      type = inType;
      id = inID=="" ? name : inID;
      var chars = id.toLowerCase();
      flatName ="";
      for(i in 0...chars.length)
      {
         var code = chars.charCodeAt(i);
         if ( (i>0 && code >= "0".charCodeAt(0) && code<="9".charCodeAt(0) ) ||
              (code >= "a".charCodeAt(0) && code<="z".charCodeAt(0) ) ||
                (code=="_".charCodeAt(0)) )
             flatName += chars.charAt(i);
         else
             flatName += "_";
      }
      if (flatName=="")
         flatName="_";
      while( usedRes.exists(flatName) )
         flatName += "_";
      usedRes.set(flatName,true);
   }

   function getExtension()
   {
      return "." + neko.io.Path.extension(name);
   }

   public function getSrc()
   {
      return name;
   }

   public function getDest(inBase:String,inTarget:String)
   {
      if (inTarget=="android")
      {
         switch(type)
         {
            case "sound":
              return inBase + "/" + dest + "/res/raw/" + flatName + getExtension();
            case "music":
              return inBase + "/" + dest + "/res/raw/" + flatName + getExtension();
            default:
              return inBase + "/" + dest + "/assets/" + id;
         }
      }

      return inBase + "/" + dest + "/" + id;
   }
}



class NDLL
{
   public var name:String;
   public var haxelib:String;
   public var srcDir:String;
   public var needsNekoApi:Bool;

   public function new(inName:String, inHaxelib:String,inNeedsNekoApi:Bool)
   {
      name = inName;
      haxelib = inHaxelib;
      srcDir = "";
		needsNekoApi = inNeedsNekoApi;

		if (haxelib!="")
		   srcDir = getHaxelib(haxelib);
   }

	static public function getHaxelib(inLibrary:String)
	{
		var proc = new neko.io.Process("haxelib", ["path", inLibrary ]);
		var result = "";
		try{
			while(true)
			{
				var line = proc.stdout.readLine();
				if (line.substr(0,1)!="-")
					result = line;
		}
		} catch (e:Dynamic) { };
		proc.close();
      //trace("Found " + haxelib + " at " + srcDir );
      if (result=="")
         throw("Could not find haxelib path  " + inLibrary + " - perhaps you need to install it?");
		return result;
	}

   public function copy(inPrefix:String, inSuffix:String, inDir:String, inCPP:Bool, inVerbose:Bool)
   {
	   var src=srcDir;
		if (src=="")
		{
         if (inCPP)
			{
			   src = getHaxelib("hxcpp") + "/bin/" +inPrefix;
				inSuffix = switch(InstallTool.mOS)
				   {
					   case "Windows","Windows64" : ".dll";
					   case "Linux","Linux64" : ".dso";
					   case "Mac","Mac64" : ".dylib";
						default: ".so";
					};
			}
         else
            src = InstallTool.getNeko();
		}
		else
		  src += inPrefix;

      src = src + name + inSuffix;
      if (!neko.FileSystem.exists(src))
      {
         throw ("Could not find ndll " + src + " required by project" );
      }
      var dest = inDir + name + inSuffix;
      InstallTool.copyIfNewer(src,dest,inVerbose);
   }
}

class InstallTool
{
   var mDefines : Hash<String>;
   var mContext : Dynamic;
   var mIncludePath:Array<String>;
   var mHaxeFlags:Array<String>;
	var mCommand:String;
   var mTarget:String;
   var mNDLLs : Array<NDLL>;
   var mAssets : Array<Asset>;
   var NME:String;
	var mVerbose:Bool;
	var mDebug:Bool;
   public static var mOS:String = neko.Sys.systemName();

   var mBuildDir:String;

   public function new(inNME:String,
                       inCommand:String,
                       inDefines:Hash<String>,
                       inIncludePath:Array<String>,
                       inProjectFile:String,
                       inTarget:String,
							  inVerbose:Bool,
							  inDebug:Bool
							  )
   {
      NME = inNME;
      mDefines = inDefines;
      mIncludePath = inIncludePath;
      mTarget = inTarget;
      mHaxeFlags = [];
		mCommand = inCommand;
		mVerbose = inVerbose;
		mDebug = inDebug;
      mNDLLs = [];
      mAssets = [];

      // trace(NME);
		// trace(inCommand);

			setDefault("WIN_WIDTH","640");
			setDefault("WIN_HEIGHT","480");
			setDefault("WIN_ORIENTATION","");
			setDefault("WIN_FPS","60");
			setDefault("WIN_BACKGROUND","0xffffff");
			setDefault("WIN_HARDWARE","true");
			setDefault("WIN_RESIZEABLE","true");

			setDefault("APP_FILE","MyAplication");
			setDefault("APP_PACKAGE","com.example.myapp");
			setDefault("APP_VERSION","1.0");
			setDefault("APP_ICON","");
			setDefault("APP_COMPANY","Example Inc.");

			setDefault("BUILD_DIR","bin");

			var make_contents = neko.io.File.getContent(inProjectFile);
			var xml_slow = Xml.parse(make_contents);
			var xml = new haxe.xml.Fast(xml_slow.firstElement());

			parseXML(xml,"");

			mBuildDir = mDefines.get("BUILD_DIR");

			mContext = {};
			for(key in mDefines.keys())
				Reflect.setField(mContext,key, mDefines.get(key) );
			Reflect.setField(mContext,"ndlls", mNDLLs );
			Reflect.setField(mContext,"assets", mAssets );
			//trace(mDefines);

		if (inCommand=="uninstall")
      {
         switch(inTarget)
         {
            case "android":
					uninstallAndroid();
         }
      }
      else
      {
         mContext.HAXE_FLAGS = mHaxeFlags.length==0 ? "" : "\n" + mHaxeFlags.join("\n");

         if (inCommand=="run" || inCommand=="build" || inCommand=="update")
         {
			   var build = inCommand=="build" || inCommand=="run";
            var hxml = "bin/" + inTarget + "/haxe/" + (mDebug ? "debug" : "release") + ".hxml";
            switch(inTarget)
            {
               case "android":
                 updateAndroid();
                 run("", "haxe", [hxml]);
					  if (build)
                    buildAndroid();
                 if (inCommand=="run")
                    runAndroid();
               case "neko":
                 updateNeko();
                 run("", "haxe", [hxml]);
					  if (build)
                    buildNeko();
                 if (inCommand=="run")
                   runNeko();
               case "cpp":
                 updateCpp();
                 run("", "haxe", [hxml]);
					  if (build)
                    buildCpp();
                 if (inCommand=="run")
                   runCpp();
					case "gph":
                 updateGph();
                 run("", "haxe", [hxml]);
					  if (build)
                    buildGph();
                 if (inCommand=="run")
                   runGph();
            }
         }
      }
  }

  static public function getNeko()
  {
      var n = neko.Sys.getEnv("NEKO_INSTPATH");
      if (n==null || n=="")
         n = neko.Sys.getEnv("NEKO_INSTALL_PATH");
      return n + "/";
  }

  function Print(inString)
  {
     if (mVerbose)
	    neko.Lib.println(inString);
  }

   function updateAndroid()
   {
      var dest = mBuildDir + "/android/project";

      mkdir(dest);
      cp_recurse(NME + "/install-tool/android/template",dest);

      var pkg = mDefines.get("APP_PACKAGE");
      var parts = pkg.split(".");
      var dir = dest + "/src/" + parts.join("/");
      mkdir(dir);
      cp_file(NME + "/install-tool/android/MainActivity.java", dir + "/MainActivity.java");

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/android/haxe");
      cp_recurse(NME + "/install-tool/android/hxml",mBuildDir + "/android/haxe");

      for(ndll in mNDLLs)
         ndll.copy("Android/lib", ".so", dest + "/libs/armeabi/lib", true, mVerbose);

		var icon = mDefines.get("APP_ICON");
		if (icon!="")
		   copyIfNewer(icon, dest + "/res/drawable-mdpi/icon.png",mVerbose);

   }

   function buildAndroid()
   {
      var ant:String = mDefines.get("ANT_HOME");
      if (ant=="" || ant==null)
      {
         //throw("ANT_HOME not defined.");
         ant = "ant";
      }
      else
         ant += "/bin/ant";

      var dest = mBuildDir + "/android/project";

      addAssets(dest,"android");

      var build = mDefines.exists("KEY_STORE") ? "release" : "debug";
      run(dest, ant, [build] );
   }


   function getAdb()
   {
   	var adb = mDefines.get("ANDROID_SDK") + "/tools/adb";
      if (mDefines.exists("windows_host"))
         adb += ".exe";
      if (!neko.FileSystem.exists(adb) )
      {
		   adb = mDefines.get("ANDROID_SDK") + "/platform-tools/adb";
         if (mDefines.exists("windows_host"))
            adb += ".exe";
      }
      return adb;
   }

   function runAndroid()
	{
      var build = mDefines.exists("KEY_STORE") ? "release" : "debug";
      var apk = mBuildDir + "/android/project/bin/" + mDefines.get("APP_FILE")+ "-" + build+".apk";
		var adb = getAdb();

		run("", adb, ["install", "-r", apk] );

      var pak = mDefines.get("APP_PACKAGE");
		run("", adb, ["shell", "am start -a android.intent.action.MAIN -n " + pak + "/" +
		    pak +".MainActivity" ]);
		run("", adb, ["logcat", "*"] );
	}


   function uninstallAndroid()
   {
		var adb = getAdb();
      var pak = mDefines.get("APP_PACKAGE");

		run("", adb, ["uninstall", pak] );
   }

	// --- Neko -----------------------------------------------------------

	function updateNeko()
   {
      var dest = mBuildDir + "/neko/" + mOS + "/";
		var dot_n = dest+"/"+mDefines.get("APP_FILE")+".n";
		mContext.NEKO_FILE = dot_n;

      mkdir(dest);

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/neko/haxe");
      cp_recurse(NME + "/install-tool/neko/hxml",mBuildDir + "/neko/haxe");

      var needsNekoApi = false;
      for(ndll in mNDLLs)
		{
         ndll.copy("ndll/" + mOS + "/", ".ndll", dest, false, mVerbose);
			if (ndll.needsNekoApi)
			   needsNekoApi = true;
		}
		if (needsNekoApi)
		{
			var src = NDLL.getHaxelib("hxcpp") + "/bin/" + mOS + "/nekoapi.ndll";
         InstallTool.copyIfNewer(src,dest + "/nekoapi.ndll",mVerbose);
		}

		var icon = mDefines.get("APP_ICON");
		if (icon!="")
		   copyIfNewer(icon, dest + "/icon.png",mVerbose);

      var neko = getNeko();
		if (mOS=="Windows")
		{
		   copyIfNewer(neko + "gc.dll", dest + "/gc.dll",mVerbose);
		   copyIfNewer(neko + "neko.dll", dest + "/neko.dll",mVerbose);
		}

      addAssets(dest,"neko");
   }


   function buildNeko()
	{
      var dest = mBuildDir + "/neko/" + neko.Sys.systemName()  + "/";
      run(dest,"nekotools",["boot",mDefines.get("APP_FILE")+".n"]);
	}

	function runNeko()
	{
	   var dest = mBuildDir + "/neko/" + neko.Sys.systemName() + "/";

		run(dest, "./" + mDefines.get("APP_FILE"), [] );
	}

	// --- Cpp ---------------------------------------------------------------

	function updateCpp()
   {
      var dest = mBuildDir + "/cpp/" + mOS + "/";
		mContext.CPP_DIR = mBuildDir + "/cpp/bin";

      mkdir(dest);

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/cpp/haxe");
      cp_recurse(NME + "/install-tool/cpp/hxml",mBuildDir + "/cpp/haxe");

		for(ndll in mNDLLs)
         ndll.copy("ndll/" + mOS + "/", ".ndll", dest, false, mVerbose);


		var icon = mDefines.get("APP_ICON");
		if (icon!="")
		   copyIfNewer(icon, dest + "/icon.png",mVerbose);

      addAssets(dest,"cpp");
   }

   function buildCpp()
	{
      var dest = mBuildDir + "/cpp/" + neko.Sys.systemName()  + "/";
		var ext = mOS=="Windows" ? ".exe" : "";
		copyIfNewer(mBuildDir+"/cpp/bin/ApplicationMain"+ext,
		   dest + mDefines.get("APP_FILE")+ ext,mVerbose);
	}

	function runCpp()
	{
	   var dest = mBuildDir + "/cpp/" + neko.Sys.systemName() + "/";

		run(dest, mDefines.get("APP_FILE"), [] );
	}

	// --- GPH ---------------------------------------------------------------

	function updateGph()
   {
      var dest = mBuildDir + "/gph/game/" + mDefines.get("APP_FILE") + "/";
		mContext.CPP_DIR = mBuildDir + "/gph/bin";

      mkdir(dest);

      cp_recurse(NME + "/install-tool/haxe",mBuildDir + "/gph/haxe");
      cp_recurse(NME + "/install-tool/gph/hxml",mBuildDir + "/gph/haxe");
      cp_file(NME + "/install-tool/gph/game.ini",mBuildDir + "/gph/game/"  + mDefines.get("APP_FILE") + ".ini" );
      var boot = mDebug ? "Boot-debug.gpe" : "Boot-release.gpe";
      cp_file(NME + "/install-tool/gph/" + boot,mBuildDir + "/gph/game/"  + mDefines.get("APP_FILE") + "/Boot.gpe" );

		for(ndll in mNDLLs)
         ndll.copy("ndll/GPH/", ".ndll", dest, false, mVerbose);

		var icon = mDefines.get("APP_ICON");
		if (icon!="")
		   copyIfNewer(icon, dest + "/icon.png",mVerbose);

      addAssets(dest,"cpp");
   }

   function buildGph()
	{
      var file = mDefines.get("APP_FILE");
      var dest = mBuildDir + "/gph/game/" + file + "/" + file + ".gpe";
		copyIfNewer(mBuildDir+"/gph/bin/ApplicationMain.gpe", dest, mVerbose);
	}

	function runGph()
	{
	}


   // -------------------------------------------------

   function addAssets(inDest:String,inTarget:String)
   {
      for(asset in mAssets)
      {
         var src = asset.getSrc();
         var dest = asset.getDest(inDest,inTarget);
         mkdir(neko.io.Path.directory(dest));
         copyIfNewer(src,dest,mVerbose);
      }
   }


   function run(inPath:String, inCommand:String, inArgs:Array<String>)
   {
      var where = inPath=="" ? "" : (" in " + inPath);
      var old = "";
      if (inPath!="")
      {
         Print("cd " + inPath);
         old = neko.Sys.getCwd();
         neko.Sys.setCwd(inPath);
      }

      Print(inCommand + " " + inArgs.join(" "));
		var result = neko.Sys.command(inCommand, inArgs);
		if (result==0 && mVerbose)
         neko.Lib.println("Ok.");

      if (old!="")
         neko.Sys.setCwd(old);

		if (result!=0)
			throw("Error running:" + inCommand + " " + inArgs.join(" ") + where );


   }

   static var mVarMatch = new EReg("\\${(.*?)}","");
   public function substitute(str:String) : String
   {
      while( mVarMatch.match(str) )
      {
         var sub = mDefines.get( mVarMatch.matched(1) );
         if (sub==null) sub="";
         str = mVarMatch.matchedLeft() + sub + mVarMatch.matchedRight();
      }

      return str;
   }
   public function substitutei(str:String) : Int
   {
      return Std.parseInt( substitute(str) );
   }

   public function substituteb(str:String) : Bool
   {
      var s = substitute(str);
      return s=="true" || s=="1";
   }




   function findIncludeFile(inBase:String) : String
   {
      if (inBase=="") return "";
     var c0 = inBase.substr(0,1);
     if (c0!="/" && c0!="\\")
     {
        var c1 = inBase.substr(1,1);
        if (c1!=":")
        {
           for(p in mIncludePath)
           {
              var name = p + "/" + inBase;
              if (neko.FileSystem.exists(name))
                 return name;
           }
           return "";
        }
     }
     if (neko.FileSystem.exists(inBase))
        return inBase;
      return "";
   }


   public function valid(inEl:haxe.xml.Fast,inSection:String) : Bool
   {
      if (inEl.x.get("if")!=null)
         if (!defined(inEl.x.get("if"))) return false;

      if (inEl.has.unless)
         if (defined(inEl.att.unless)) return false;

      if (inSection!="")
      {
         if (inEl.name!="section")
            return false;
         if (!inEl.has.id)
            return false;
         if (inEl.att.id!=inSection)
            return false;
      }

      return true;
   }

   public function defined(inString:String) : Bool
   {
      return mDefines.exists(inString);
   }
   



   function parseXML(inXML:haxe.xml.Fast,inSection :String)
   {
      for(el in inXML.elements)
      {
         if (valid(el,inSection))
         {
            switch(el.name)
            {
                case "set" : 
                   var name = el.att.name;
                   var value = substitute(el.att.value);
                   mDefines.set(name,value);
                case "unset" : 
                   var name = el.att.name;
                   mDefines.remove(name);
                case "setenv" : 
                   var name = el.att.name;
                   var value = substitute(el.att.value);
                   mDefines.set(name,value);
                   neko.Sys.putEnv(name,value);
                case "error" : 
                   var error = substitute(el.att.value);
                   throw(error);
                case "path" : 
                   var path = substitute(el.att.name);
                   var os = neko.Sys.systemName();
                   var sep = mDefines.exists("windows_host") ? ";" : ":";
                   neko.Sys.putEnv("PATH", path + sep + neko.Sys.getEnv("PATH"));
                    //trace(neko.Sys.getEnv("PATH"));

                case "include" : 
                   var name = substitute(el.att.name);
                   var full_name = findIncludeFile(name);
                   if (full_name!="")
                   {
                      var make_contents = neko.io.File.getContent(full_name);
                      var xml_slow = Xml.parse(make_contents);
                      var section = el.has.section ? el.att.section : "";

                      parseXML(new haxe.xml.Fast(xml_slow.firstElement()),section);
                   }
                   else if (!el.has.noerror)
                   {
                      throw "Could not find include file " + name;
                   }
                case "app" : 
                   appSettings(el);

                case "haxelib" : 
                   mHaxeFlags.push("-lib " + substitute(el.att.name) );

                case "ndll" : 
                   mNDLLs.push(new NDLL(substitute(el.att.name),
						    el.has.haxelib ? substitute(el.att.haxelib) : "",
							 el.has.nekoapi ? substitute(el.att.nekoapi)!="" : false ) );

                case "classpath" : 
                   mHaxeFlags.push("-cp " + substitute(el.att.name) );

                case "window" : 
                   windowSettings(el);

                case "assets" : 
                   readAssets(el);

                case "section" : 
                   parseXML(el,"");
            }
         }
      }
   }

   function readAssets(inXML:haxe.xml.Fast)
   {
      var dest:String = inXML.has.dest ? substitute(inXML.att.dest) : "";
      var type:String = inXML.has.type ? substitute(inXML.att.type) : "";
      for(el in inXML.elements)
      {
         var d = el.has.dest ? substitute(el.att.dest) : dest;
         var id= el.has.id ? substitute(el.att.id) : "";
         switch(el.name)
         {
            case "asset":
               var t = el.has.type ? substitute(el.att.type) : type;
               mAssets.push( new Asset( substitute(el.att.name),d,t,id ) );
            case "sound":
               mAssets.push( new Asset( substitute(el.att.name),d,"sound",id ) );
            case "music":
               mAssets.push( new Asset( substitute(el.att.name),d,"music",id ) );
            case "image":
               mAssets.push( new Asset( substitute(el.att.name),d,"image",id ) );

         }
      }
   }
 

   function setDefault(inName:String, inValue:String)
   {
      if (!mDefines.exists(inName))
         mDefines.set(inName, inValue);
   }

   function appSettings(el:haxe.xml.Fast)
   {
      for(e in el.x.attributes())
      {
         var att = e;
         var name = "APP_" + att.toUpperCase();
         mDefines.set( name, substitute(el.att.resolve(att)) );
      }
      setDefault("APP_TITLE", mDefines.get("APP_FILE"));
      setDefault("APP_DESCRIPTION", mDefines.get("APP_TITLE"));
   }

   function windowSettings(el:haxe.xml.Fast)
   {
      for(e in el.x.attributes())
      {
         var att = e;
         var name = "WIN_" + att.toUpperCase();
         mDefines.set( name, substitute(el.att.resolve(att)) );
      }
   }



   public function cp_file(inSrcFile:String,inDestFile:String)
   {
      var ext = neko.io.Path.extension(inSrcFile);
      if (ext=="xml" || ext=="java" || ext=="hx" || ext=="hxml" || ext=="ini" || ext=="gpe")
      {
         Print("process " + inSrcFile + " " + inDestFile );
         var contents = neko.io.File.getContent(inSrcFile);
         var tmpl = new haxe.Template(contents);
         var result = tmpl.execute(mContext);
         var f = neko.io.File.write(inDestFile,false);
         f.writeString(result);
         f.close();
      }
      else
      {
         Print("cp " + inSrcFile + " " + inDestFile );
         neko.io.File.copy( inSrcFile, inDestFile );
      }
   }

   public function cp_recurse(inSrc:String,inDestDir:String)
   {
      if (!neko.FileSystem.exists(inDestDir))
      {
         Print("mkdir " + inDestDir);
         neko.FileSystem.createDirectory(inDestDir);
      }

      var files = neko.FileSystem.readDirectory(inSrc);
      for(file in files)
      {
         if (file.substr(0,1)!=".")
         {
            var dest = inDestDir + "/" + file;
            var src = inSrc + "/" + file;
            if (neko.FileSystem.isDirectory(src))
               cp_recurse(src, dest );
            else
               cp_file(src,dest);
         }
      }
   }


   public function mkdir(inDir:String)
   {
      var parts = inDir.split("/");
      var total = "";
      for(part in parts)
      {
         if (part!="." && part!="")
         {
            if (total!="") total+="/";
            total += part;
            if (!neko.FileSystem.exists(total))
            {
               Print("mkdir " + total);
               neko.FileSystem.createDirectory(total);
            }
         }
      }
   }

   public static function copyIfNewer(inFrom:String, inTo:String, inVerbose:Bool)
   {
      if (!neko.FileSystem.exists(inFrom))
      {
         neko.Lib.println("Error: " + inFrom + " does not exist");
         return;
      }

      if (neko.FileSystem.exists(inTo))
      {
         if (neko.FileSystem.stat(inFrom).mtime.getTime() <
             neko.FileSystem.stat(inTo).mtime.getTime() )
           return;
      }

      if (inVerbose)
		   neko.Lib.println("Copy " + inFrom + " to " + inTo );
      neko.io.File.copy(inFrom, inTo);
   }

   static function usage()
   {
      neko.Lib.println("Usage :  haxelib run nme [-v] COMMAND ...");
      neko.Lib.println(" COMMAND : copy-if-newer from to");
      neko.Lib.println(" COMMAND : update build.nmml [-DFLAG -Dname=val... ]");
      neko.Lib.println(" COMMAND : (update|build|run) [-debug] build.nmml target");
      neko.Lib.println(" COMMAND : uninstall build.nmml target");
   }


   
   public static function main()
   {
      var words = new Array<String>();
      var defines = new Hash<String>();
      var include_path = new Array<String>();
      var command:String="";
		var verbose = false;
		var debug = false;

      include_path.push(".");

      var args = neko.Sys.args();
      var NME = "";
      // Check for calling from haxelib ...
      if (args.length>0)
      {
         var last:String = (new neko.io.Path(args[args.length-1])).toString();
         var slash = last.substr(-1);
         if (slash=="/"|| slash=="\\") 
            last = last.substr(0,last.length-1);
         if (neko.FileSystem.exists(last) && neko.FileSystem.isDirectory(last))
         {
            // When called from haxelib, the last arg is the original directory, and
            //  the current direcory is the library directory.
            NME = neko.Sys.getCwd();
            defines.set("NME",NME);
            args.pop();
            neko.Sys.setCwd(last);
         }
      }

      var os = neko.Sys.systemName();
		if ( (new EReg("window","i")).match(os) )
      {
		   defines.set("windows", "1");
		   defines.set("windows_host", "1");
		   defines.set("HOST", "windows");
      }
      else if ( (new EReg("linux","i")).match(os) )
      {
         defines.set("linux","1");
         defines.set("HOST","linux");
      }
      else if ( (new EReg("mac","i")).match(os) )
      {
         defines.set("macos","1");
         defines.set("HOST","darwin-x86");
      }


      for(arg in args)
      {
         if (arg.substr(0,2)=="-D")
            defines.set(arg.substr(2),"");
         else if (arg.substr(0,2)=="-I")
            include_path.push(arg.substr(2));
         else if (arg=="-v")
            verbose = true;
         else if (arg=="-debug")
            debug = true;
         else if (command.length==0)
            command = arg;
         else
            words.push(arg);
      }

      include_path.push(".");
      var env = neko.Sys.environment();
      if (env.exists("HOME"))
        include_path.push(env.get("HOME"));
      if (env.exists("USERPROFILE"))
        include_path.push(env.get("USERPROFILE"));
      include_path.push(NME + "/install-tool");


      var valid_commands = ["copy-if-newer", "run", "build","update", "uninstall"];
      if (!Lambda.exists(valid_commands,function(c) return command==c))
      {
         if (command!="")
            neko.Lib.println("Unknown command : " + command);
         usage();
         return;
      }

      if (command=="copy-if-newer")
      {
         if (words.length!=2)
         {
            neko.Lib.println("wrong number of arguements");
            usage();
            return;
         }
         copyIfNewer(words[0], words[1], verbose);
      }
      else
      {
         if (words.length!=2)
         {
            neko.Lib.println("wrong number of arguements");
            usage();
            return;
         }
 
         if (!neko.FileSystem.exists(words[0]))
         {
            neko.Lib.println("Error : " + command + ", .nmml file must be specified");
            usage();
            return;
         }

         for(e in env.keys())
            defines.set(e, neko.Sys.getEnv(e) );

         if ( !defines.exists("NME_CONFIG") )
            defines.set("NME_CONFIG",".hxcpp_config.xml");

         new InstallTool(NME,command,defines,include_path,words[0],words[1],verbose,debug);
      }
   }

}



