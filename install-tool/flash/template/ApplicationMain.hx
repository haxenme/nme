
::foreach assets::
class NME_::flatName:: extends ::flashClass:: { }
::end::




class ApplicationMain
{
   static var mPreloader:NMEPreloader;

   public static function main()
   {
      var call_real = true;
      ::if (PRELOADER_NAME!="")::
         var loaded = flash.Lib.current.loaderInfo.bytesLoaded;
         var total = flash.Lib.current.loaderInfo.bytesTotal;
         if (loaded<total)
         {
            call_real = false;
            mPreloader = new ::PRELOADER_NAME::();
            flash.Lib.current.addChild(mPreloader);
            mPreloader.onInit();
            mPreloader.onUpdate(loaded,total);
            flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, onEnter);
         }
      ::end::

      if (call_real)
         ::APP_MAIN::.main();
   }

   static function onEnter(_)
   {
      var loaded = flash.Lib.current.loaderInfo.bytesLoaded;
      var total = flash.Lib.current.loaderInfo.bytesTotal;
      mPreloader.onUpdate(loaded,total);
      if (loaded>=total)
      {
         mPreloader.onLoaded();
         flash.Lib.current.removeEventListener(flash.events.Event.ENTER_FRAME, onEnter);
         flash.Lib.current.removeChild(mPreloader);
         mPreloader = null;

         ::APP_MAIN::.main();
      }
   }

   public static function getAsset(inName:String) : Dynamic
   {
      ::foreach assets::
      if (inName=="::name::")
         return haxe.io.Bytes.ofData( new NME_::flatName::() );
      ::end::

      return null;
   }
}
