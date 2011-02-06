class Target
{
   public var name:String;
   public var runtime:String;

   public function new(inName:String, inRuntime:String)
   {
      name = inName;
      runtime = inRuntime;
   }
}


class InstallTool
{
   var mDefines : Hash<String>;
   var mContext : Dynamic;
   var mIncludePath:Array<String>;
   var mHaxeFlags:Array<String>;
   var mTargets : Array<Target>;
   var NME:String;
	var mVerbose:Bool;
	var mDebug:Bool;

   var mBuildDir:String;

   public function new(inNME:String,
                       inCommand:String,
                       inDefines:Hash<String>,
                       inTargets:Array<String>,
                       inIncludePath:Array<String>,
							  inVerbose:Bool,
							  inDebug:Bool
							  )
   {
      NME = inNME;
      mDefines = inDefines;
      mIncludePath = inIncludePath;
      mTargets = [];
      mHaxeFlags = [];
		mVerbose = inVerbose;
		mDebug = inDebug;

      // trace(NME);
		// trace(inCommand);

      if (inCommand=="update" || inCommand=="create")
		{
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
			setDefault("APP_COMPANY","Example Inc.");

			setDefault("BUILD_DIR","bin");

			var makefile = inTargets.pop();
			var make_contents = neko.io.File.getContent(makefile);
			var xml_slow = Xml.parse(make_contents);
			var xml = new haxe.xml.Fast(xml_slow.firstElement());

			parseXML(xml,"");

			mBuildDir = mDefines.get("BUILD_DIR");

			if (inTargets.length==0)
				for(t in mTargets)
					inTargets.push(t.name);

			mContext = {};
			for(key in mDefines.keys())
				Reflect.setField(mContext,key, mDefines.get(key) );
			//trace(mDefines);

			for(target in mTargets)
			{
				if (inTargets.length>0 &&
						 !Lambda.exists(inTargets,function (t) return t==target.name ))
					continue;
				updateTarget(target);
			}
		}
		if (inCommand=="run" || inCommand=="make")
		{
			if (inCommand=="run" && inTargets.length!=1)
			{
			   neko.Lib.println("'run' command should have exactly 1 target");
			}
			else
			{
				for(target in inTargets)
				{
					var hxml = "bin/" + target + "/haxe/" + (mDebug ? "debug" : "release") + ".hxml";
					Print("Running : haxe " + hxml);
					var result = neko.Sys.command( "haxe", [hxml] );
			      if (result!=0)
			      {
						throw("Error running: haxe " + hxml);
					}
				}
			}
		}
  }

  function Print(inString)
  {
     if (mVerbose)
	    neko.Lib.println(inString);
  }

   function updateTarget(inTarget:Target)
   {
      mContext.HAXE_FLAGS = mHaxeFlags.length==0 ? "" : "\n" + mHaxeFlags.join("\n");
      switch(inTarget.name)
      {
         case "android":
           updateAndroid(inTarget.runtime);
      }
   }

   function updateAndroid(inRuntime:String)
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

                case "classpath" : 
                   mHaxeFlags.push("-cp " + substitute(el.att.name) );

                case "window" : 
                   windowSettings(el);

                case "target" : 
                   mTargets.push( new Target(substitute(el.att.name),
                                el.has.runtime ? substitute(el.att.runtime) : "" ) );

                case "section" : 
                   parseXML(el,"");
            }
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
      if (ext=="xml" || ext=="java" || ext=="hx" || ext=="hxml")
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

   static function copyIfNewer(inFrom:String, inTo:String, inVerbose:Bool)
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
      neko.Lib.println(" COMMAND : update|create build.nmml [-DFLAG -Dname=val... ]");
      neko.Lib.println(" COMMAND : make [-debug] target1 [target2...]");
      neko.Lib.println(" COMMAND : run [-debug] target");
   }


   
   public static function main()
   {
      var targets = new Array<String>();
      var defines = new Hash<String>();
      var include_path = new Array<String>();
      var command:String="";
      var makefile:String="";
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
            targets.push(arg);
      }

      include_path.push(".");
      var env = neko.Sys.environment();
      if (env.exists("HOME"))
        include_path.push(env.get("HOME"));
      if (env.exists("USERPROFILE"))
        include_path.push(env.get("USERPROFILE"));
      include_path.push(NME + "/install-tool");



      if (command=="copy-if-newer")
      {
         if (targets.length!=2)
         {
            neko.Lib.println("wrong number of arguements");
            usage();
            return;
         }
         copyIfNewer(targets[0], targets[1], verbose);
      }
      else if (command=="")
      {
         usage();
      }
      else
      {
         for(e in env.keys())
            defines.set(e, neko.Sys.getEnv(e) );

         if ( !defines.exists("NME_CONFIG") )
            defines.set("NME_CONFIG",".hxcpp_config.xml");

         new InstallTool(NME,command,defines,targets,include_path,verbose,debug);
      }
   }

}



