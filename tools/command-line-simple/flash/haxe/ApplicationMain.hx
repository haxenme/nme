import ::APP_MAIN_PACKAGE::::APP_MAIN_CLASS::;
import nme.Assets;
import nme.events.Event;

class ApplicationMain 
{
   static var mPreloader:NMEPreloader;

   public static function main() 
   {
      var call_real = true;

      ::if (PRELOADER_NAME!="")::
      var loaded:Int = nme.Lib.current.loaderInfo.bytesLoaded;
      var total:Int = nme.Lib.current.loaderInfo.bytesTotal;

      if (loaded < total || true) /* Always wait for event */ 
      {
         call_real = false;
         mPreloader = new ::PRELOADER_NAME::();
         nme.Lib.current.addChild(mPreloader);
         mPreloader.onInit();
         mPreloader.onUpdate(loaded,total);
         nme.Lib.current.addEventListener(nme.events.Event.ENTER_FRAME, onEnter);
      }
      ::end::

      if (call_real)
         ::APP_MAIN_CLASS::.main();
   }

   static function onEnter(_) 
   {
      var loaded:Int = nme.Lib.current.loaderInfo.bytesLoaded;
      var total:Int = nme.Lib.current.loaderInfo.bytesTotal;
      mPreloader.onUpdate(loaded,total);

      if (loaded >= total) 
      {
         nme.Lib.current.removeEventListener(nme.events.Event.ENTER_FRAME, onEnter);
         mPreloader.addEventListener(Event.COMPLETE, preloader_onComplete);
         mPreloader.onLoaded();
      }
   }

   public static function getAsset(inName:String):Dynamic 
   {
      ::foreach assets::
      if (inName=="::id::")
          ::if (type=="image")::
            return Assets.getBitmapData("::id::");
         ::elseif (type=="sound")::
            return Assets.getSound("::id::");
         ::elseif (type=="music")::
            return Assets.getSound("::id::");
       ::elseif (type== "font")::
          return Assets.getFont("::id::");
         ::else::
            return Assets.getBytes("::id::");
         ::end::
      ::end::

      return null;
   }

   private static function preloader_onComplete(event:Event):Void 
   {
      mPreloader.removeEventListener(Event.COMPLETE, preloader_onComplete);

      nme.Lib.current.removeChild(mPreloader);
      mPreloader = null;

      ::APP_MAIN_CLASS::.main();
   }
}

::foreach assets::
   ::if (type=="image")::
   @:bitmap("::sourcePath::") 
      class NME_::flatName:: extends nme.display.BitmapData { public function new() { super(0, 0); } }
   ::else::
   @:file("::sourcePath::") 
      class NME_::flatName:: extends ::flashClass:: { }
   ::end::
::end::
