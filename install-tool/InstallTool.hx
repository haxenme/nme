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
   var mIncludePath:Array<String>;
   var mTargets : Array<Target>;
   var NME:String;

   var mWinWidth:Int;
   var mWinHeight:Int;
   var mWinOrientation:String;
   var mWinFPS:Int;
   var mWinBackground:Int;
   var mWinHardware:Bool;
   var mWinResizeable:Bool;

   var mAppFile:String;
   var mAppTitle:String;
   var mAppPackage:String;
   var mAppVersion:String;
   var mAppCompany:String;
   var mAppDescription:String;

   public function new(inNME:String,
                       inMakefile:String,
                       inDefines:Hash<String>,
                       inTargets:Array<String>,
                       inIncludePath:Array<String> )
   {
      NME = inNME;
      mDefines = inDefines;
      mIncludePath = inIncludePath;
      mTargets = [];

      // trace(NME);

      mWinWidth = 640;
      mWinHeight = 480;
      mWinOrientation = "";
      mWinFPS = 60;
      mWinBackground = 0xffffff;
      mWinHardware = true;
      mWinResizeable = true;

      mAppFile = "MyApplication";
      mAppTitle = "My Application";
      mAppPackage = "com.example.myapp";
      mAppVersion = "1.0";
      mAppCompany = "Example Inc";
      mAppDescription = "Example Application";

      var make_contents = neko.io.File.getContent(inMakefile);
      var xml_slow = Xml.parse(make_contents);
      var xml = new haxe.xml.Fast(xml_slow.firstElement());

      parseXML(xml,"");

      if (inTargets.length==0)
         for(t in mTargets)
            inTargets.push(t.name);


      for(target in mTargets)
      {
         if (inTargets.length>0 &&
                !Lambda.exists(inTargets,function (t) return t==target.name ))
            continue;
         buildTarget(target);
      }

      /*
      var base = inPackage;
      mDefines.pkg = inPackage;
      mDefines.PROJ = "MyProj";
      cp_recurse(inHXCPP + "/projects/android/template",base);

      var parts = inPackage.split(".");
      var dir = base + "/src/" + parts.join("/");
      mkdir(dir);
      cp_file(inHXCPP + "/projects/android/MainActivity.java", dir + "/MainActivity.java");
      */
   }

   function buildTarget(inTarget:Target)
   {
      trace(inTarget);
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


   function appSettings(el:haxe.xml.Fast)
   {
      if (el.has.file)
      {
         mAppFile = substitute(el.att.file);
         mAppTitle = mAppFile;
         mAppDescription = mAppTitle;
      }
      if (el.has.title)
      {
         mAppTitle = substitute(el.att.title);
         mAppDescription = mAppTitle;
      }
      if (el.has.resolve("package"))
         mAppPackage = substitute(el.att.resolve("package"));
      if (el.has.version)
         mAppVersion = substitute(el.att.version);
      if (el.has.company)
         mAppCompany = substitute(el.att.company);
      if (el.has.description)
         mAppDescription = substitute(el.att.description);
   }

   function windowSettings(el:haxe.xml.Fast)
   {
      if (el.has.width)
         mWinWidth = substitutei(el.att.width);
      if (el.has.height)
         mWinHeight = substitutei(el.att.height);
      if (el.has.orientation)
         mWinOrientation = substitute(el.att.orientation);
      if (el.has.fps)
         mWinFPS = substitutei(el.att.fps);
      if (el.has.background)
         mWinBackground = substitutei(el.att.background);
      if (el.has.resizeable)
         mWinResizeable = substituteb(el.att.resizeable);
      if (el.has.hardware)
         mWinHardware = substituteb(el.att.hardware);
   }



   public function cp_file(inSrcFile:String,inDestFile:String)
   {
      var ext = neko.io.Path.extension(inSrcFile);
      if (ext=="xml" || ext=="java")
      {
         neko.Lib.println("process " + inSrcFile + " " + inDestFile );
         var contents = neko.io.File.getContent(inSrcFile);
         var tmpl = new haxe.Template(contents);
         var result = tmpl.execute(mDefines);
         var f = neko.io.File.write(inDestFile,false);
         f.writeString(result);
         f.close();
      }
      else
      {
         neko.Lib.println("cp " + inSrcFile + " " + inDestFile );
         neko.io.File.copy( inSrcFile, inDestFile );
      }
   }

   public function cp_recurse(inSrc:String,inDestDir:String)
   {
      if (!neko.FileSystem.exists(inDestDir))
      {
         neko.Lib.println("mkdir " + inDestDir);
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


   static public function mkdir(inDir:String)
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
               neko.Lib.println("mkdir " + total);
               neko.FileSystem.createDirectory(total);
            }
         }
      }
   }


   
   public static function main()
   {
      var targets = new Array<String>();
      var defines = new Hash<String>();
      var include_path = new Array<String>();
      var makefile:String="";

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
         if (arg.substr(0,2)=="-I")
            include_path.push(arg.substr(2));
         else if (makefile.length==0)
            makefile = arg;
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



      if (makefile=="")
      {
         neko.Lib.println("Usage :  haxelib run nme build.nmml [-DFLAG -Dname=val... ] [target1 target2 ...]");
      }
      else
      {
         for(e in env.keys())
            defines.set(e, neko.Sys.getEnv(e) );

         if ( !defines.exists("NME_CONFIG") )
            defines.set("NME_CONFIG",".hxcpp_config.xml");

         new InstallTool(NME,makefile,defines,targets,include_path);
      }
   }

}



