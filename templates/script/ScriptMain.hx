import cpp.cppia.HostClasses;


class ScriptMain
{
   public static var winBackground = ::WIN_BACKGROUND::;
   public static var winWidth = ::WIN_WIDTH::;
   public static var winHeight = ::WIN_HEIGHT::;

   public static function main()
   {
      var waitForResize = false;
      #if nme
         nme.app.Application.setPackage("::APP_COMPANY::", "::APP_FILE::", "::APP_PACKAGE::", "::APP_VERSION::");

         nme.text.Font.useNative = ::NATIVE_FONTS::;

         var stage = nme.Lib.current.stage;
         stage.frameRate = ::WIN_FPS::;
         stage.opaqueBackground = ::WIN_BACKGROUND::;
         nme.app.Application.initWidth = ::WIN_WIDTH::;
         nme.app.Application.initHeight = ::WIN_HEIGHT::;

         var window = stage.window;
         if (window.displayState==nme.display.StageDisplayState.NORMAL &&
              (stage.stageWidth!=::WIN_WIDTH:: && stage.stageHeight!=::WIN_HEIGHT::) )
         {
            //waitForResize = true;
            var cx = window.x + window.width*0.5;
            var cy = window.y + window.height*0.5;
            window.resize(::WIN_WIDTH::,::WIN_HEIGHT::);
            var x0 = window.x;
            var y0 = window.y;
            var px = Std.int(x0 + (window.width-::WIN_WIDTH::)*0.5);
            if (px<0 && x0>=0)
               px = 0;
            var py = Std.int(y0 + (window.height-::WIN_HEIGHT::)*0.5);
            if (py<0 && y0>=0)
               py = 0;
            window.setPosition(px,py);
         }
         //icon  : Assets.info.get("::WIN_ICON::")==null ? null : getAsset("::WIN_ICON::")


         nme.app.Application.setFixedOrientation(
            ::if (WIN_ORIENTATION == "portrait")::
               nme.app.Application.OrientationPortraitAny
            ::elseif (WIN_ORIENTATION == "landscape")::
               nme.app.Application.OrientationLandscapeAny
            ::else::
               nme.app.Application.OrientationAny
             ::end::
         );

      #end

      if (waitForResize)
      {
         haxe.Timer.delay( function() {
            nme.ScriptData.create();
            ApplicationBoot.createInstance("ScriptDocument");
            sendFakeResize();
         }, 1 );
      } 
      else
      {
         nme.ScriptData.create();
         ApplicationBoot.createInstance("ScriptDocument");
         sendFakeResize();
      }
   }

   public static function onLoaded() { }

   static function sendFakeResize()
   {
      /*
      #if nme
         haxe.Timer.delay( function() {
            var stage = nme.Lib.current.stage;
            trace("Fake resize " + stage.stageWidth + "x" +  stage.stageHeight );
            stage.onResize( stage.stageWidth, stage.stageHeight );
         }, 1 );
      #end
      */
   }
   
}

