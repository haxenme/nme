import haxe.io.Path;
import sys.FileSystem;

class Builder
{
   static function showUsage()
   {
      Sys.println("Usage : neko builder.n targets [arch] [-debug] [-D...]");
      Sys.println("  targets : clean, ios, android, windows, linux, mac,");
      Sys.println("            default (=current system)");
      Sys.println("  arch    : -armv5 -armv6 -armv7 -arm64 -x86 -m32 -m64");
      Sys.println("            (none specified = all valid architectures");
      Sys.println("  -D...   : defines passed to hxcpp build system");
   }

   public static function main()
   {
      var args = Sys.args();
      var targets = new Array<String>();
      var archs = new Array<String>();
      var buildArgs = new Array<String>();
      var debug = false;

      try
      {
         if (args.length<1)
            throw "";

         for(arg in args)
         {
            if (arg=="default")
            {
               var sys = Sys.systemName();
               if (new EReg("window", "i").match(sys))
                  arg = "windows";
               else if (new EReg("linux", "i").match(sys))
                  arg = "linux";
               else if (new EReg("mac", "i").match(sys))
                  arg = "mac";
               else
                  throw "Unknown host system: " + sys;
            }

            switch(arg)
            {
               case "clean", "ios", "android", "windows", "linux", "mac":
                  if (!Lambda.exists(targets, function(x)return x==arg))
                     targets.push(arg);

               case "-armv5", "-armv6", "-armv7", "-arm64", "-x86", "-m32", "-m64":
                  var arch = arg.substr(1);
                  if (!Lambda.exists(archs, function(x)return x==arch))
                     archs.push(arch);

               case "-debug":
                  debug = true;

               default:
                  if (arg.substr(0,2)=="-D")
                     buildArgs.push(arg);
                  else
                     throw "Unknown arg '" + arg + "'";
            }
         }

         if (targets.length==0)
            throw "No target specified";
         if ( Lambda.exists(targets, function(x)return x=="clean"))
         {
            try
            {
              deleteRecurse("bin");
            }
            catch(e:Dynamic)
            {
               Sys.println("Could not remove 'bin' directory");
               return;
            }
            if (targets.length==1) // Just clean
               return;
         }

         if (!FileSystem.exists("bin"))
            FileSystem.createDirectory("bin");
         sys.io.File.copy("build/Build.xml", "bin/Build.xml" );

         Sys.setCwd("bin");

         for(target in targets)
         {
            var validArchs = new Map<String, Array<String>>();
            switch(target)
            {
               case "linux", "mac":
                  validArchs.set("m32", ["-D"+target, "-DHXCPP_M32"] );
                  validArchs.set("m64", ["-D"+target, "-DHXCPP_M64"] );

               case "windows":
                  validArchs.set("m32", ["-D"+target, "-DHXCPP_M32"] );

               case "ios":
                  validArchs.set("armv6", ["-Diphoneos"] );
                  validArchs.set("armv7", ["-Diphoneos", "-DHXCPP_ARMV7"] );
                  //validArchs.push("armv64");
                  validArchs.set("x86", ["-Diphonesim"] );

               case "android":
                  validArchs.set("armv5", ["-Dandroid"] );
                  validArchs.set("armv7", ["-Dandroid", "-DHXCPP_ARMV7" ] );
                  validArchs.set("x86", ["-Dandroid", "-DHXCPP_X86" ] );
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
