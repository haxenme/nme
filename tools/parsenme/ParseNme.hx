class ParseNme
{
   public static function parseNme() : String
   {
      try {
         var module:Dynamic = untyped window.Module;
         var data:js.html.ArrayBuffer = module.nmeApp;
         var bytes = haxe.io.Bytes.ofData(data);
   
         var magic = bytes.getString(0,4);
         if (magic!="NME$")
            return "alert('Bad magic in .nme file')";
         var len = bytes.getInt32(4);
         var headerString = bytes.getString(8,len);
         var header = haxe.Json.parse(headerString);
         var pos = len+8;
         len = bytes.getInt32(pos);
         pos+=4;
         var itemsString = bytes.getString(pos,len);
         var items:Array<Dynamic> = haxe.Json.parse(itemsString);
         pos+=len;
         module.nmeAppDataBase = pos;
         module.nmeAppHeader = header;
         module.nmeAppItems = {};
         var script:String = null;
         for(i in items)
         {
            if (i.id=="jsScript")
               script = bytes.getString(pos+i.offset, i.length);
            else
            {
               i.value = bytes.sub(pos+i.offset, i.length);
               Reflect.setField(module.nmeAppItems,i.id,i);
            }
         }
         module.nmeApp = null;
         if (script!=null)
            return script;

         return "alert('Could not find jsScript in .nme file')";
      } catch(e:Dynamic) {
         return "alert('Error parsing .nme file " + e + "')";
      }
   }

   public static function main()
   {
      (untyped window).parseNme = parseNme;
   }
}
