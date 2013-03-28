class ApplicationMain
{
   #if waxe
   static public var frame : wx.Frame;
   static public var autoShowFrame : Bool = true;
   #if nme
   static public var nmeStage : wx.NMEStage;
   #end
   #end

   public static function main()
   {
      nme.Lib.setPackage("::APP_COMPANY::", "::APP_FILE::", "::APP_PACKAGE::", "::APP_VERSION::");
      ::if (sslCaCert != "")::
      nme.net.URLLoader.initialize(nme.installer.Assets.getResourceName("::sslCaCert::"));
      ::end::

      #if waxe
      wx.App.boot(function()
      {
         ::if (APP_FRAME != null)::
         frame = wx.::APP_FRAME::.create(null, null, "::APP_TITLE::", null, { width: ::WIN_WIDTH::, height: ::WIN_HEIGHT:: });
         ::else::
         frame = wx.Frame.create(null, null, "::APP_TITLE::", null, { width: ::WIN_WIDTH::, height: ::WIN_HEIGHT:: });
         ::end::
         #if nme
         var stage = wx.NMEStage.create(frame, null, null, { width: ::WIN_WIDTH::, height: ::WIN_HEIGHT:: });
         #end

         ::APP_MAIN::.main();

         if (autoShowFrame)
         {
            wx.App.setTopWindow(frame);
            frame.shown = true;
         }
      });
      #else

      nme.Lib.create(function()
         { 
            if (::WIN_WIDTH:: == 0 && ::WIN_HEIGHT:: == 0)
            {
               nme.Lib.current.stage.align = nme.display.StageAlign.TOP_LEFT;
               nme.Lib.current.stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;
            }

            ::APP_MAIN::.main(); 
         },
         ::WIN_WIDTH::, ::WIN_HEIGHT::, 
         ::WIN_FPS::, 
         ::WIN_BACKGROUND::,
         (::WIN_HARDWARE:: ? nme.Lib.HARDWARE : 0) |
         (::WIN_RESIZEABLE:: ? nme.Lib.RESIZABLE : 0) |
         (::WIN_BORDERLESS:: ? nme.Lib.BORDERLESS : 0) |
         (::WIN_VSYNC:: ? nme.Lib.VSYNC : 0) |
         (::WIN_FULLSCREEN:: ? nme.Lib.FULLSCREEN : 0) |
         (::WIN_ANTIALIASING:: == 4 ? nme.Lib.HW_AA_HIRES : 0) |
         (::WIN_ANTIALIASING:: == 2 ? nme.Lib.HW_AA : 0),
         "::APP_TITLE::"
         ::if (WIN_ICON!=null)::
         , getAsset("::WIN_ICON::")
         ::end::
      );
      #end
   }

   public static function getAsset(inName:String):Dynamic
   {
      ::foreach assets::
      if (inName == "::id::")
      {
         ::if (type=="image")::
         return nme.Assets.getBitmapData("::id::");
         ::elseif (type=="sound")::
         return nme.Assets.getSound("::id::");
         ::elseif (type=="music")::
         return nme.Assets.getSound("::id::");
         ::elseif (type== "font")::
         return nme.Assets.getFont("::id::");
         ::else::
         return nme.Assets.getBytes("::id::");
         ::end::
      }
      ::end::
      return null;
   }

	#if neko
	public static function __init__ () {
		
		untyped $loader.path = $array ("@executable_path/", $loader.path);
		
	}
	#end
	

}
