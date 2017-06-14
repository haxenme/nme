import nme.media.Camera;
import nme.display.Sprite;
import nme.display.Bitmap;
import nme.events.Event;

class Main extends Sprite
{
   var camera:Camera;
   var bitmap:Bitmap;

   public function new()
   {
      super();
      camera = Camera.getCamera();
      if (camera!=null)
         camera.addEventListener(Event.VIDEO_FRAME,onFrame);
      stage.addEventListener(nme.events.Event.RESIZE, function(_) setBmpSize() );
   }

   function setBmpSize()
   {
      if (bitmap!=null)
      {
         var sw:Float = stage.stageWidth;
         var sh:Float = stage.stageHeight;
         var w = bitmap.bitmapData.width;
         var h = bitmap.bitmapData.height;
         if (w*sh > h*sw)
         {
            bitmap.width = sw;
            sh = h*sw/w;
            bitmap.height = sh;
            bitmap.x = 0;
            bitmap.y = (stage.stageHeight-sh)*0.5;
         }
         else
         {
            bitmap.height = sh;
            sw = w*sh/h;
            bitmap.width = sw;
            bitmap.y = 0;
            bitmap.x = (stage.stageWidth-sw)*0.5;
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
         addChild(bitmap);
         setBmpSize();
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


