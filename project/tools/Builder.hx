import haxe.io.Path;
import sys.FileSystem;

class Builder
{
   static function showUsage()
   {
      Sys.println("Usage : neko build.n [clean] [[link-]target[-arch][-arch] ...] [-debug] [-verbose] [-D...]");
      Sys.println("  target  : ios, android, windows, linux, mac, ios-legacy");
      Sys.println("            default (=current system)");
      Sys.println("  link    : ndll- or static-");
      Sys.println("            (none specified = both link types");
      Sys.println("  arch    : -armv5 -armv6 -armv7 -arm64 -x86 -m32 -m64");
      Sys.println("            (none specified = all valid architectures");
      Sys.println("  -D...   : defines passed to hxcpp build system");
      Sys.println(" eg: neko build.n clean ndll-mac-m32-m64 = rebuild both mac ndlls");
      Sys.println(" Specify target or 'default' to remove this message");
   }
   static function getDefault()
   {
      var sys = Sys.systemName();
      if (new EReg("window", "i").match(sys))
         return "windows";
      else if (new EReg("linux", "i").match(sys))
         return "linux";
      else if (new EReg("mac", "i").match(sys))
         return "mac";
      else
         throw "Unknown host system: " + sys;
      return "";
   }

   public static function main()
   {
      var args = Sys.args();
      var targets = new Map<String, Array<String>>();
      var buildArgs = new Array<String>();
      var debug = false;
      var verbose = false;

      try
      {
         var clean = false;
         var defaultTarget = true;
         for(arg in args)
         {
            if (arg=="-debug")
            {
               debug = true;
               continue;
            }
            else if (arg=="-v" || arg=="-verbose")
            {
               verbose = true;
               Sys.putEnv("HXCPP_VERBOSE", "1");
               continue;
            }
            if (arg=="clean")
            {
               clean = true;
               continue;
            }


            var parts = arg.split("-");
            var linkStatic = true;
            var linkNdll = true;
            if (parts[0]=="static")
            {
               linkNdll = false;
               parts.shift();
            }
            else if (parts[0]=="ndll")
            {
               linkStatic = false;
               parts.shift();
            }

            var target = parts.shift();
            if (target=="default")
               target = getDefault();

            switch(target)
            {
               case "ios", "android", "windows", "linux", "mac":
                  defaultTarget = false;
                  if (linkStatic)
                  {
                     var stat = "static-" + target;
                     targets.set(stat, parts);
                  }
                  if (linkNdll && target!="ios")
                     targets.set(target, parts);

               default:
                  if (arg.substr(0,2)=="-D")
                     buildArgs.push(arg);
                  else
                     throw "Unknown arg '" + arg + "'";
            }
         }

         if ( clean )
         {
            try
            {
               if (verbose)
                  Sys.println("delete obj...");
              deleteRecurse("obj");
            }
            catch(e:Dynamic)
            {
               Sys.println("Could not remove 'obj' directory");
               return;
            }
            if (defaultTarget) // Just clean
               return;
         }

         if (defaultTarget)
         {
            var target = getDefault();
            targets.set(target,[]);
            targets.set("static-" +target,[]);
            showUsage();
            Sys.println("\nUsing default = " + target);
         }


         for(target in targets.keys())
         {
            var archs = targets.get(target);
            var validArchs = new Map<String, Array<String>>();
            var isStatic = false;
            if (target.substr(0,7)=="static-")
            {
               isStatic = true;
               target = target.substr(7);
            }
            var staticFlag = isStatic ? "-Dstatic_link" : "";
            if (target=="ios")
               staticFlag = "-DHXCPP_CPP11";

            switch(target)
            {
               case "linux", "mac":
                  validArchs.set("m32", ["-D"+target, "-DHXCPP_M32", staticFlag] );
                  validArchs.set("m64", ["-D"+target, "-DHXCPP_M64", staticFlag] );

               case "windows":
                  validArchs.set("m32", ["-D"+target, "-DHXCPP_M32", staticFlag] );

               case "ios":
                  validArchs.set("armv6", ["-Diphoneos", staticFlag] );
                  validArchs.set("armv7", ["-Diphoneos", "-DHXCPP_ARMV7", staticFlag] );
                  //validArchs.push("armv64");
                  validArchs.set("x86", ["-Diphonesim", staticFlag] );

               case "android":
                  validArchs.set("armv5", ["-Dandroid", staticFlag] );
                  validArchs.set("armv7", ["-Dandroid", "-DHXCPP_ARMV7", staticFlag ] );
                  validArchs.set("x86", ["-Dandroid", "-DHXCPP_X86", staticFlag ] );
            }


            var valid = new Array<String>();
            for(key in validArchs.keys())
               valid.push(key);
            var buildArchs = archs.length==0 ? valid : archs;
            for(arch in buildArchs)
            {
               if (validArchs.exists(arch))
               {
                  var flags = validArchs.get(arch);
                  if (debug)
                     flags.push("-Ddebug");

                  flags = flags.concat(buildArgs);
                  var args = ["run", "hxcpp", "Build.xml"].concat(flags);

                  Sys.println('\nBuild $target, link=' + (isStatic?"lib":"ndll")+' arch=$arch');
                  Sys.println("haxelib " + args.join(" ")); 
                  if (Sys.command("haxelib",args)!=0)
                  {
                     Sys.println("#### Error building " + arch);
                  }
               }
            }
         }
      }
      catch( e:Dynamic )
      {
         if (e!="")
            Sys.println(e);
         showUsage();
      }
   }

   static public function deleteRecurse(inDir:String)
   {
      if (FileSystem.exists(inDir))
      {
         var contents = FileSystem.readDirectory(inDir);
         for(item in contents)
         {
            if (item!="." && item!="..")
            {
               var name = inDir + "/" + item;
               if (FileSystem.isDirectory(name))
                  deleteRecurse(name);
               else
                  FileSystem.deleteFile(name);
            }
    }
         FileSystem.deleteDirectory(inDir);
      }
   }
}
