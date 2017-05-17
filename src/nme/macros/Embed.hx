package nme.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.io.File;

@:nativeProperty
class Embed
{
   public static macro function embedAsset(inPrefix:String,inMetaName:String) :Array<Field> 
   {
      var classType = Context.getLocalClass().get();
      var metaData = classType.meta.get();
      var position = Context.currentPos();
      var fields = Context.getBuildFields();
      var path = "";

      for(meta in metaData)
      {
         if (meta.name == inMetaName)
         {
            if (meta.params.length > 0)
            {
               switch (meta.params[0].expr)
               {
                  case EConst(CString(filePath)):
                     path = Context.resolvePath(filePath);
                  default:
               }
            }
         }
      }
      
      if (path != null && path != "")
      {
         var bytes = File.getBytes(path);
         var resourceName = inPrefix + 
            (classType.pack.length > 0 ? classType.pack.join("_") + "_" : "") + classType.name;

         Context.addResource(resourceName, bytes);
         var fieldValue = { pos: position, expr: EConst(CString(resourceName)) };
         fields.push({ kind: FVar(macro :String, fieldValue), name: "resourceName", access: [ APublic, AStatic ], pos: position });

         return fields;
      }
      return fields;
   }
}



