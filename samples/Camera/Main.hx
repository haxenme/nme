import nme.media.Camera;
import nme.display.Sprite;
import nme.display.Bitmap;
import nme.events.Event;
using StringTools;

class Main extends Sprite
{
   var camera:Camera;
   var bitmap:Bitmap;
   var rot:Int;

   public function new()
   {
      super();

      var cameraName:String = null;
      rot = 0;
      var args = nme.system.System.getArgs();
      var i =0;

      while(i < args.length)
      {
         var a = args[i++];
         if (a.startsWith("-r"))
         {
            switch( args[i++] )
            {
               case "0": rot = 0;
               case "90": rot = 90;
               case "270": rot = 270;
               case "180": rot = 180;
               case x:
                  trace("Unknown arg: " + x);
            }
        }
        else if (a.startsWith("-c"))
        {
           cameraName = args[i++];
           if (cameraName==null)
           {
              trace("Missing Camera Name");
           }
        }
        else
        {
           showHelp();
           nme.Lib.close();
        }
      }



      camera = Camera.getCamera(cameraName);
      if (camera!=null)
         camera.addEventListener(Event.VIDEO_FRAME,onFrame);
      stage.addEventListener(nme.events.Event.RESIZE, function(_) setBmpSize() );
      stage.addEventListener(nme.events.KeyboardEvent.KEY_DOWN, function(_) nme.Lib.close() );
   }

   function showHelp()
   {
       Sys.println("Usage: NmeCamera [-r rotation(0,90,180,270)] [-c cameraName]");
   }

   function setBmpSize()
   {
      if (bitmap!=null)
      {
         var sw:Float = stage.stageWidth;
         var sh:Float = stage.stageHeight;
         var w = bitmap.bitmapData.width;
         var h = bitmap.bitmapData.height;
         if (rot==90 || rot==270)
         {
            w = bitmap.bitmapData.height;
            h = bitmap.bitmapData.width;
         }
         var bmpW = sw;
         var bmpH = sh;
         if (w*sh > h*sw)
            bmpH = h*sw/w;
         else
            bmpW = w*sh/h;

         trace('Stage : $sw,$sh');
         trace('Camera: $w,$h');
         bitmap.rotation = rot;
         bitmap.width = bmpW;
         bitmap.height = bmpH;
         switch(rot)
         {
            case 0:
               bitmap.x = (sw-bmpW)*0.5;
               bitmap.y = (sh-bmpH)*0.5;
            case 90:
               bitmap.x = sw - (sw-bmpW)*0.5;
               bitmap.y = (sh-bmpH)*0.5;
            case 270:
               bitmap.x = (sw-bmpW)*0.5;
               bitmap.y = sh - (sh-bmpH)*0.5;
            case 180:
               bitmap.x = sw - (sw-bmpW)*0.5;
               bitmap.y = sh - (sh-bmpH)*0.5;
            default:
         }
      }
   }

   public function onFrame(_)
   {
      trace("onFrame!");
      if (camera!=null)
      {
         camera.removeEventListener(Event.VIDEO_FRAME,onFrame);
         bitmap = new Bitmap( camera.bitmapData );
         bitmap.smoothing = true;
         addChild(bitmap);
         setBmpSize();

         addChild( new nme.display.FPS(20,20) );
      }

      /*
      #if cpp
      var native = nme.native.ImageBuffer.fromBitmapData(camera.bitmapData);
      if (native!=null)
         trace(native.value.Width() + "x" + native.value.Height());
      #end
      */

      /*
      var s = new Sprite();
      addChild(s);
      s.graphics.beginBitmapFill(camera.bitmapData);
      s.graphics.lineStyle(5,0x000000);
      s.graphics.drawCircle(200,200,200);
      addEventListener(Event.ENTER_FRAME, function(_) s.rotation = s.rotation + 1 );
      x = 200;
      y = 200;
      */
   }
}


