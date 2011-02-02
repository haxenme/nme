class CreateAndroid
{
   var mVars:Dynamic;

   public function new(inHXCPP:String,inPackage:String)
   {
      var base = inPackage;
      mVars = {};
      mVars.pkg = inPackage;
      mVars.PROJ = "MyProj";
      cp_recurse(inHXCPP + "/projects/android/template",base);

      var parts = inPackage.split(".");
      var dir = base + "/src/" + parts.join("/");
      mkdir(dir);
      cp_file(inHXCPP + "/projects/android/MainActivity.java", dir + "/MainActivity.java");
   }

   public function cp_file(inSrcFile:String,inDestFile:String)
   {
      var ext = neko.io.Path.extension(inSrcFile);
      if (ext=="xml" || ext=="java")
      {
         neko.Lib.println("process " + inSrcFile + " " + inDestFile );
         var contents = neko.io.File.getContent(inSrcFile);
         var tmpl = new haxe.Template(contents);
         var result = tmpl.execute(mVars);
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
      var args = neko.Sys.args();
      if (args.length!=1)
      {
         neko.Lib.println("Usgage: CreateAndroid com.yourcompany.yourapp");
      }
      else
      {
         var proc = new neko.io.Process("haxelib",["path", "hxcpp"]);
         var hxcpp = proc.stdout.readLine();
         proc.close();
         trace(hxcpp);
   
         new CreateAndroid(hxcpp,args[0]);
      }
   }


}



