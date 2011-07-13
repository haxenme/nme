class ApplicationMain
{
   public static function main()
   {
      nme.Lib.create(
           function(){ ::APP_MAIN::.main(); },
           ::WIN_WIDTH::, ::WIN_HEIGHT::,
           ::WIN_FPS::,
           ::WIN_BACKGROUND::,
             ( ::WIN_HARDWARE::   ? nme.Lib.HARDWARE  : 0) |
             ( ::WIN_RESIZEABLE:: ? nme.Lib.RESIZABLE : 0),
          "::APP_TITLE::", 
          "::APP_PACKAGE::"
          ::if (WIN_ICON!=null)::
             , getAsset("::WIN_ICON::")
          ::end::
          );
   }

   public static function getAsset(inName:String):Dynamic
   {
      ::foreach assets::
      if (inName=="::id::")
      {
         ::if (type=="image")::
            return nme.display.BitmapData.load("::resourceName::");
         ::elseif (type=="sound")::
            return new nme.media.Sound(new nme.net.URLRequest("::resourceName::"),null,false);
         ::elseif (type=="music")::
            return new nme.media.Sound(new nme.net.URLRequest("::resourceName::"),null,true);
         ::else::
            return nme.utils.ByteArray.readFile("::resourceName::");
         ::end::
      }
      ::end::
      return null;
   }
}

