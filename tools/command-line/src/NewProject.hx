import haxe.Template;
import sys.io.File;
import sys.io.FileOutput;
import sys.FileSystem;


class NewProject
{
   public function new(inNme:String, inNmmlName:String,defines:Hash<String>)
   {
      var defaults = new Hash<String>();
      defaults.set("file","Application");
      defaults.set("title","NME Application");
      defaults.set("package","org.haxe.nme");
      defaults.set("main","Main");
      defaults.set("src","src");

      // Defaults with warnings ...
      var warnings = new Array<String>();
      for(key in defaults.keys())
      {
         if (!defines.exists(key) || defines.get(key)=="" || defines.get(key)==null )
         {
             defines.set( key, defaults.get(key) );
             if (key=="src")
                warnings.push("Using default : src = " + defaults.get(key) + " you might want to use 'src=.'" );
             else
                warnings.push("Using default : " + key + " = " + defaults.get(key) );
         }
      }

      if (warnings.length>0)
      {
         for(warn in warnings)
            Sys.println(warn);
        
         Sys.println("You can set default on the command-line (name=value) or with environment variables.");
      }

	   var pack =  defines.get("package");
	   if (defines.get("package").split(".").length < 3)
      {
			
			throw("Your application package must have at least three segments, like <meta package=\"com.example.myapp\" />");
		}
		
      var context = {};
      for(key in defines.keys())
         Reflect.setField(context,key,defines.get(key));
 
      transform(inNme + "/tools/command-line/project/template.nmml", inNmmlName, context );

      var mainParts = defines.get("main").split(".");
      var mainClass = mainParts.pop();
      var c0 = mainClass.charCodeAt(0);
      if (c0<"A".charCodeAt(0) || c0>"Z".charCodeAt(0))
         throw "Error - main class should start with capital letter [A-Z]";
      Reflect.setField(context,"mainPackage", mainParts.join("."));
      Reflect.setField(context,"main", mainClass);

      var dir = defines.get("src");
      if (dir.length>0)
      {
         mkdir(dir);
         dir += "/";
      }

      for(part in mainParts)
      {
         dir+=part + "/";
         mkdir(dir);
      }

      var classFile = dir + mainClass + ".hx";
      if (FileSystem.exists(classFile))
      {
          Sys.println("File " + classFile + " already exists.  Not touching.");
      }
      else
      {
         transform(inNme + "/tools/command-line/project/Main.hx", classFile, context );
      }
   }

   public static function transform(inSource:String, inDest:String, inContext:Dynamic)
   {
      var src:String = "";
      try
      {
        src = File.getContent(inSource);
      } catch(e:Dynamic)
      {
         throw "Could not load template " + inSource;
      }

      var template:Template = new Template(src);
      var result:String = template.execute(inContext);
         
      try
      {
         var fileOutput:FileOutput = File.write(inDest, true);
         fileOutput.writeString(result);
         fileOutput.close();
      } catch(e:Dynamic)
      {
         throw("Could not write " + inDest);
      }
   }

   public static function mkdir(inName:String)
   {
      if (!FileSystem.exists(inName))
      {
         try
         {
            FileSystem.createDirectory(inName);
         } catch (e:Dynamic)
         {
            throw "Could not create directory " + inName;
         }
      }
   }
}

