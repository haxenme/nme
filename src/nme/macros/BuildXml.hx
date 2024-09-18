package nme.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.io.Path;

using haxe.macro.PositionTools;

class BuildXml
{
   public static macro function importRelative(inFilename:String, compileDef:String, mergeTarget:String ):Array<Field>
   {
      var dir = Path.directory(Context.currentPos().getInfos().file);
      if (!Path.isAbsolute(dir))
      {
         var here = Sys.getCwd();
         var last = here.charAt( here.length-1 );
         if (last!="\\" && last!="/")
            here += "/";
         dir = here + dir;
      }
      var xmlInject =
        "<set name='"+ compileDef + "' value='1' />\n" + 
        "<import name='" +  Path.normalize( dir+inFilename )  + "'/>\n" + 
        "<target id='haxe'>\n" + 
        "  <merge id='" + mergeTarget + "'/>\n" + 
        "</target>;\n";
      var p = Context.currentPos();
      Context.getLocalClass().get().meta.add(":buildXml", [ { expr:EConst( CString( xmlInject ) ), pos:p } ], p  );
      return Context.getBuildFields();
   }
}



