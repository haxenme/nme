
class ScriptDocument extends ::APP_MAIN::
{
   public function new()
   {
      #if nme
      var appMain = Type.resolveClass("ApplicationMain");
      if (appMain!=null)
         Reflect.field(appMain,"setAndroidViewHaxeObject")(this);

      if (Std.is(this, nme.display.DisplayObject))
      {
         nme.Lib.current.addChild(cast this);
      }
      #end

      super();
   }
}

