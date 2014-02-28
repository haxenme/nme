
class ApplicationDocument extends ::APP_MAIN::
{
   public function new()
   {
      #if nme
      ApplicationMain.setAndroidViewHaxeObject(this);
      if (Std.is(this, nme.display.DisplayObject))
      {
         nme.Lib.current.addChild(cast this);
      }
      #end

      super();
   }
}

