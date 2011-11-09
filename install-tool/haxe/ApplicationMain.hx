import nme.Assets;


class ApplicationMain
{
   #if waxe
   static public var frame : wx.Frame;
   static public var autoShowFrame : Bool = true;
   static public var nmeStage : wx.NMEStage;
   #end

   public static function main()
   {
      #if waxe
      wx.App.boot( function()
      {
         frame = wx.Frame.create(null,null,"::APP_TITLE::",null,{width: ::WIN_WIDTH::, height: ::WIN_HEIGHT:: });
         var stage = wx.NMEStage.create(frame,null,null,{width:::WIN_WIDTH::,height:::WIN_HEIGHT::});
         ::APP_MAIN::.main();
         if (autoShowFrame)
         {
            wx.App.setTopWindow(frame);
            frame.shown = true;
         }
      } );
      #else
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
       #end
   }

   public static function getAsset(inName:String):Dynamic
   {
      ::foreach assets::
      if (inName=="::id::")
      {
         ::if (type=="image")::
            return Assets.getBitmapData ("::id::");
         ::elseif (type=="sound")::
            return Assets.getSound ("::id::");
         ::elseif (type=="music")::
            return Assets.getSound ("::id::");
		 ::elseif (type== "font")::
			 return Assets.getFont ("::id::");
         ::else::
            return Assets.getBytes ("::id::");
         ::end::
      }
      ::end::
      return null;
   }
}

