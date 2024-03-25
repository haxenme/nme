
class ApplicationDocument extends ::APP_MAIN::
{
   public function new()
   {
      #if nme
      var added:nme.display.DisplayObject = null;
      ApplicationMain.setAndroidViewHaxeObject(this);
      if (#if (haxe_ver>="4.1") Std.isOfType #else Std.is #end(this, nme.display.DisplayObject))
      {
         added = cast this;
         nme.Lib.current.addChild(added);
      }
      #end

      ::if (APP_BOOT_TYPE=="BootTypeAuto")::
      ApplicationBoot.callSuper();
      ::else::
      super();
      ::end::

      #if nme
      if (added!=null && added.stage!=null)
      {
         added.dispatchEvent(new nme.events.Event(nme.events.Event.ADDED_TO_STAGE, false, false));
         added.dispatchEvent(new nme.events.Event(nme.events.Event.ADDED, false, false));
      }
      #end
   }
}

