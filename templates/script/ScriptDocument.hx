
class ScriptDocument extends ::APP_MAIN::
{
   public function new()
   {
      #if nme
      var added:nme.display.DisplayObject = null;

      var appMain = Type.resolveClass("ApplicationMain");
      if (appMain!=null)
         Reflect.field(appMain,"setAndroidViewHaxeObject")(this);

      if (Std.isOfType(this, nme.display.DisplayObject))
      {
         added = cast this;
         nme.Lib.current.addChild(cast this);
      }

      super();

      if (added!=null && added.stage!=null)
         added.dispatchEvent(new nme.events.Event(nme.events.Event.ADDED_TO_STAGE, false, false));
      #end
   }
}

