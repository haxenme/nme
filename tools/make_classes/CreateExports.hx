import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Type;

class CreateExports
{
   public static function init()
   {
      Context.onGenerate(onGenerate);
      return Context.getBuildFields();
   }

   static function onGenerate(types:Array<Type>):Void
   {
      var exports = [];
      for(type in types)
      {
         switch(type)
         {
            case TEnum(e,_):
               var e = e.get();
               var pack = e.pack.length==0 ? "" : e.pack.join(".") + ".";
               exports.push("enum " + pack + e.name);
            case TInst(i,_):
               var i = i.get();
               var pack = i.pack.length==0 ? "" : i.pack.join(".") + ".";
               exports.push((i.isInterface ? "class " : "interface ") + pack + i.name);
            default:
         }
      }
      sys.io.File.saveContent("gen/export_classes.info", exports.join("\n"));
   }
}

