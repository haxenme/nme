import ImportAll;

@:build(CreateExports.init())
class Export
{
   @:native("typeof")
   extern inline static function typeOf(d:Dynamic):String
   {
      return untyped js.Syntax.code("typeof(d)");
   }


   public static function main()
   {
      untyped __define_feature__("use.$iterator", {});
      untyped __define_feature__("use.$bind", {});

      var global:Dynamic = untyped js.Syntax.code("$global");
      global.nmeClassesLoaded = true;
      // String map hack
      #if (js_es < 5)
      global.__map_reserved = untyped __map_reserved;
      #end

      if (typeOf(global.nmeOnClasses) == 'function')
         global.nmeOnClasses();
   }
}
