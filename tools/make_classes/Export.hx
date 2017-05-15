import ImportAll;

@:build(CreateExports.init())
class Export
{
   @:native("typeof")
   @:extern inline static function typeOf(d:Dynamic):String
   {
      return untyped __js__("typeof(d)");
   }

   public static function main()
   {
      var hxClasses:Dynamic = untyped __js__("$hxClasses");
      var classes = {};
      Reflect.setField(hxClasses,"package",classes );
      untyped __js__("$global['hxClasses'] = $hxClasses");

      for(name in ImportAll.classNames)
      {
         var parts = name.split(".");
         var className = parts.pop();
         var root = classes;
         for(p in parts)
         {
            if (Reflect.field(root,p)==null)
               Reflect.setField(root,p,{});
            root = Reflect.field(root,p);
         }
         Reflect.setField(root, className, Reflect.field(hxClasses,name));
      }

      var global:Dynamic = untyped __js__("$global");
      global.nmeClassesLoaded = true;
      if (typeOf(global.nmeOnClasses) == 'function')
         global.nmeOnClasses();
   }
}
