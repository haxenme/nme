import nme.Assets;



#if !cocktail
class ApplicationDocument extends ::APP_MAIN::
{
   public function new()
   {
      if (Std.is(this, nme.display.DisplayObject))
      {
         nme.Lib.current.addChild(cast this);
      }
      
      super();
   }
}
#end



@:buildXml("
<files id='__lib__'>
<compilerflag value='-Iinclude'/>
  <file name='src/__lib__.cpp'>
   <depend name='include/ApplicationMain.h'/>
  </file>
  <file name='FrameworkInterface.mm'>
  </file>
</files>
")

class ApplicationMain
{
   // This will get called by 'hxRunLibrary' above on creation of first view
   public static function main()
   {
      nme.AssetData.create();

      nme.Lib.setPackage("::APP_COMPANY::", "::APP_FILE::", "::APP_PACKAGE::", "::APP_VERSION::");
      ::if (sslCaCert != "")::
      nme.net.URLLoader.initialize(nme.installer.Assets.getResourceName("::sslCaCert::"));
      ::end::
   
      nme.display.Stage.shouldRotateInterface = function(orientation:Int):Bool
      {
         ::if (WIN_ORIENTATION == "portrait")::
         if (orientation == nme.display.Stage.OrientationPortrait ||
             orientation == nme.display.Stage.OrientationPortraitUpsideDown)
         {
            return true;
         }
         return false;
         ::elseif (WIN_ORIENTATION == "landscape")::
         if (orientation == nme.display.Stage.OrientationLandscapeLeft ||
             orientation == nme.display.Stage.OrientationLandscapeRight)
         {
            return true;
         }
         return false;
         ::else::
         return true;
         ::end::
      }
      
      var hasMain = false;
      for (methodName in Type.getClassFields(::APP_MAIN::))
      {
         if (methodName == "main")
         {
            hasMain = true;
            break;
         }
      }


        nme.Lib.create(function()
         { 
            //if ((::WIN_WIDTH:: == 0 && ::WIN_HEIGHT:: == 0) || ::WIN_FULLSCREEN::)
            //{
               nme.Lib.current.stage.align = nme.display.StageAlign.TOP_LEFT;
               nme.Lib.current.stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;
               nme.Lib.current.loaderInfo = nme.display.LoaderInfo.create (null);
            //}
            
            
            if (hasMain)
            {
               Reflect.callMethod (::APP_MAIN::, Reflect.field (::APP_MAIN::, "main"), []);
            }
            else
            {
               #if (nme && !waxe && !cocktail)
               new ApplicationDocument();
               #else
               Type.createInstance(::APP_MAIN::, []);
               #end
            }
         },
         ::WIN_WIDTH::, ::WIN_HEIGHT::, 
         ::WIN_FPS::, 
         ::WIN_BACKGROUND::,
         (::WIN_HARDWARE:: ? nme.Lib.HARDWARE : 0) |
         (::WIN_ALLOW_SHADERS:: ? nme.Lib.ALLOW_SHADERS : 0) |
         (::WIN_REQUIRE_SHADERS:: ? nme.Lib.REQUIRE_SHADERS : 0) |
         (::WIN_DEPTH_BUFFER:: ? nme.Lib.DEPTH_BUFFER : 0) |
         (::WIN_STENCIL_BUFFER:: ? nme.Lib.STENCIL_BUFFER : 0) |
         (::WIN_RESIZABLE:: ? nme.Lib.RESIZABLE : 0) |
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

   }
}

