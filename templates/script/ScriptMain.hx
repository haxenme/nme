class ScriptMain
{
   public static function main()
   {
      #if nme
         nme.app.Application.setPackage("::APP_COMPANY::", "::APP_FILE::", "::APP_PACKAGE::", "::APP_VERSION::");


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

