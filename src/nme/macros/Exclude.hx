package nme.macros;

import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Type;


class Exclude
{
   #if macro
   public static function exclude()
   {
      Context.onGenerate(onGenerate);
      return Context.getBuildFields();
   }

   static function onGenerate(types:Array<Type>):Void
   {
      var externs = new Map<String,Bool>();

      var tried = new Map<String, Bool>();
      for(path in Context.getClassPath())
      {
         if (path=="") path = ".";
         path = path + "/../ndll/Emscripten/export_classes.info";
         if (!tried.exists(path))
         {
             tried.set(path,true);
             parseClassInfo(externs,path);
         }
      }

      for(type in types)
      {
         switch(type)
         {
            case TInst(classRef, params):
               if (externs.exists(classRef.toString()))
                  classRef.get().exclude();
            case TEnum(enumRef, params):
               if (externs.exists(enumRef.toString()))
                    enumRef.get().exclude();
            case TAbstract(absRef, params):
               if (externs.exists(absRef.toString()))
               {
                  var exclude = absRef.get().exclude;
                  if (exclude!=null)
                     exclude();
               }
            default:
         }
      }
   }


   static function parseClassInfo(externs:Map<String,Bool>, filename:String)
   {
      if (sys.FileSystem.exists(filename))
      {
         var file = sys.io.File.read(filename);
         try
         {
            while(true)
            {
               var line = file.readLine();
               var parts = line.split(" ");
               if (parts[0]=="class" || parts[0]=="interface" || parts[0]=="enum")
                  externs.set(parts[1],true);
            }
         } catch( e : Dynamic ) { }
         if (file!=null)
            file.close();
      }
   }
   #end
}


