import haxe.io.Path;
import sys.FileSystem;

class Builder
{
   static function showUsage()
   {
      Sys.println("Usage : neko builder.n [target ...] [arch] [-debug] [-verbose] [-D...]");
      Sys.println("  target  : clean, ios, android, windows, linux, mac, ios-legacy");
      Sys.println("          : static-android, static-windows, static-linux, static-mac,");
      Sys.println("            default (=current system)");
      Sys.println("  arch    : -armv5 -armv6 -armv7 -arm64 -x86 -m32 -m64");
      Sys.println("            (none specified = all valid architectures");
      Sys.println("  -D...   : defines passed to hxcpp build system");
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
      var targets = new Array<String>();
      var archs = new Array<String>();
      var buildArgs = new Array<String>();
      var debug = false;

      try
      {
         for(arg in args)
         {
            if (arg=="default")
            {
               arg = getDefault();
            }

            switch(arg)
            {
               case "clean":
                  if (!Lambda.exists(targets, function(x)return x==arg))
                     targets.push(arg);

               case "ios", "android", "windows", "linux", "mac":
                  var stat = "static-" + arg;
                  if (!Lambda.exists(targets, function(x)return x==stat))
                     targets.push(stat);
                  if (arg!="ios")
                  {
                     var dyn = arg;
                     if (!Lambda.exists(targets, function(x)return x==dyn))
                        targets.push(dyn);
                  }

               case "ndll-android", "ndll-windows", "ndll-linux", "ndll-mac":
                     var dyn = arg.substr(5);
                     if (!Lambda.exists(targets, function(x)return x==dyn))
                        targets.push(dyn);

               case "static-ios", "static-android", "static-windows", "static-linux", "static-mac" :
                  if (!Lambda.exists(targets, function(x)return x==arg))
                     targets.push(arg);

               case "ios-legacy", "android-ndll", "windows-ndll", "linux-ndll", "mac-ndll" :
                  var target = arg.split("-")[0];
                  if (!Lambda.exists(targets, function(x)return x==target))
                     targets.push(target);

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
         {
            var target = getDefault();
            targets.push(target);
            showUsage();
            Sys.println("\nusing default =" + target);
         }

         if ( targets.remove("clean"))
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
            if (targets.length==0) // Just clean
               return;
         }

         if (!FileSystem.exists("bin"))
            FileSystem.createDirectory("bin");
         sys.io.File.copy("build/Build.xml", "bin/Build.xml" );

         Sys.setCwd("bin");

         for(target in targets)
         {
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
