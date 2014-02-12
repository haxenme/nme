// Might have waxe without NME
#if nme
import nme.Assets;
#elseif waxe
import wx.Assets;
#end

#if cpp
::foreach ndlls::::importStatic::::end::
#end


#if (nme && !waxe && !cocktail && !Cocktail)
class ApplicationDocument extends ::APP_MAIN::
{
   public function new()
   {
      if (Std.is(this, nme.display.DisplayObject))
         nme.Lib.current.addChild(cast this);

      super();
   }
}
#end



#if iosview
@:buildXml("
<files id='__lib__'>
  <file name='FrameworkInterface.mm'>
  </file>
</files>
")
#end

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
      #if cpp
      ::if MEGATRACE::
      untyped __global__.__hxcpp_execution_trace(2);
      ::end::
      #end

      #if flash

      nme.AssetData.create();

      #elseif nme
      nme.Lib.setPackage("::APP_COMPANY::", "::APP_FILE::", "::APP_PACKAGE::", "::APP_VERSION::");

      nme.AssetData.create();

      ::if (sslCaCert != "")::
      nme.net.URLLoader.initialize(nme.installer.Assets.getResourceName("::sslCaCert::"));
      ::end::

      nme.display.Stage.shouldRotateInterface = function(orientation:Int):Bool
      {
         ::if (WIN_ORIENTATION == "portrait")::
         return (orientation == nme.display.Stage.OrientationPortrait ||
                 orientation == nme.display.Stage.OrientationPortraitUpsideDown);
         ::elseif (WIN_ORIENTATION == "landscape")::
         return (orientation == nme.display.Stage.OrientationLandscapeLeft ||
                 orientation == nme.display.Stage.OrientationLandscapeRight);
         ::else::
         return true;
         ::end::
      }

      #end
   
      var hasMain = false;
      for(methodName in Type.getClassFields(::APP_MAIN::))
         if (methodName == "main")
         {
            hasMain = true;
            break;
         }
   
      #if flash

      var load = function()
      {
          if (hasMain)
               Reflect.callMethod (::APP_MAIN::, Reflect.field (::APP_MAIN::, "main"), []);
            else
            {
               #if (nme && !waxe && !cocktail && !Cocktail)
               new ApplicationDocument();
               #else
               Type.createInstance(::APP_MAIN::, []);
               #end
            }
       };
       ::if (PRELOADER!=null)::
       new ::PRELOADER::(::WIN_WIDTH::, ::WIN_HEIGHT::, ::WIN_BACKGROUND::, load);
       ::else::
       load();
       ::end::


      #elseif waxe
      if (hasMain)
         Reflect.callMethod (::APP_MAIN::, Reflect.field (::APP_MAIN::, "main"), []);
      else
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
            
            Type.createInstance(::APP_MAIN::, []);
            
            if (autoShowFrame)
            {
               wx.App.setTopWindow(frame);
               frame.shown = true;
            }
         });
      #else
      nme.Lib.create(function() { 
            //if ((::WIN_WIDTH:: == 0 && ::WIN_HEIGHT:: == 0) || ::WIN_FULLSCREEN::)
            //{
               nme.Lib.current.stage.align = nme.display.StageAlign.TOP_LEFT;
               nme.Lib.current.stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;
               nme.Lib.current.loaderInfo = nme.display.LoaderInfo.create (null);
            //}
            
            
            if (hasMain)
               Reflect.callMethod (::APP_MAIN::, Reflect.field (::APP_MAIN::, "main"), []);
            else
            {
               #if (nme && !waxe && !cocktail && !Cocktail)
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
         nme.Lib.ALLOW_SHADERS | nme.Lib.REQUIRE_SHADERS |
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
      #end
      
   }

   public static function getAsset(inName:String) : Dynamic
   {
      var i = Assets.info.get(inName);
      if (i==null)
         throw "Asset does not exist: " + inName;
      var cached = i.getCache();
      if (cached!=null)
         return cached;
      switch(i.type)
      {
         case BINARY, TEXT: return Assets.getBytes(inName);
         case FONT: return Assets.getFont(inName);
         case IMAGE: return Assets.getBitmapData(inName);
         case MUSIC, SOUND: return Assets.getSound(inName);
      }

      throw "Unknown asset type: " + i.type;
      return null;
   }
   
   
   #if neko
   public static function __init__ () {
      
      untyped $loader.path = $array ("@executable_path/", $loader.path);
      
   }
   #end
   
   
}

