class ScriptMain
{
   public static function main()
   {
      #if nme
         nme.app.Application.setPackage("::APP_COMPANY::", "::APP_FILE::", "::APP_PACKAGE::", "::APP_VERSION::");

         var stage = nme.Lib.current.stage;
         stage.frameRate = ::WIN_FPS::;
         stage.opaqueBackground = ::WIN_BACKGROUND::;
         nme.app.Application.initWidth = ::WIN_WIDTH::;
         nme.app.Application.initHeight = ::WIN_HEIGHT::;

         stage.resize(::WIN_WIDTH::,::WIN_HEIGHT::);
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

      nme.ScriptData.create();
   
      ApplicationBoot.createInstance("ScriptDocument");
   }
   
}

